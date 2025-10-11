import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'voice_performance_monitoring_service.dart';
import 'environment_config.dart';

/// Service d'optimisation des appels API Azure pour réduire la latence
/// et la consommation de bande passante
class AzureApiOptimizationService {
  static final AzureApiOptimizationService _instance =
      AzureApiOptimizationService._internal();
  factory AzureApiOptimizationService() => _instance;
  AzureApiOptimizationService._internal();

  // Configuration
  static const Duration _cacheExpiryDuration = Duration(minutes: 30);
  static const Duration _rateLimitWindow = Duration(seconds: 1);
  static const int _maxRequestsPerSecond = 10;
  static const int _maxBatchSize = 5;
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // État du service
  bool _isInitialized = false;
  late EnvironmentConfig _envConfig;
  late VoicePerformanceMonitoringService _performanceService;

  // Cache intelligent
  final Map<String, _CacheEntry> _cache = {};
  final Queue<DateTime> _recentCacheHits = Queue();
  
  // Rate limiting
  final Queue<DateTime> _recentRequests = Queue();
  final Map<String, Queue<DateTime>> _endpointRequests = {};

  // Batching des requêtes
  final Map<String, _BatchProcessor> _batchProcessors = {};
  
  // Pool de connexions
  late http.Client _httpClient;
  final Map<String, http.Client> _endpointClients = {};

  // Circuit breaker
  final Map<String, _CircuitBreaker> _circuitBreakers = {};

  // Compression et optimisation
  bool _compressionEnabled = true;
  bool _cachingEnabled = true;
  bool _batchingEnabled = true;
  bool _rateLimitingEnabled = true;

  // Statistiques
  int _totalRequests = 0;
  int _cachedResponses = 0;
  int _batchedRequests = 0;
  int _rateLimitedRequests = 0;
  int _failedRequests = 0;
  double _averageLatency = 0.0;
  double _cacheHitRatio = 0.0;

  // Accesseurs publics
  bool get isInitialized => _isInitialized;
  double get cacheHitRatio => _totalRequests > 0 ? _cachedResponses / _totalRequests : 0.0;
  double get batchingRatio => _totalRequests > 0 ? _batchedRequests / _totalRequests : 0.0;
  double get averageLatency => _averageLatency;

  Map<String, dynamic> get statistics => {
    'total_requests': _totalRequests,
    'cached_responses': _cachedResponses,
    'batched_requests': _batchedRequests,
    'rate_limited_requests': _rateLimitedRequests,
    'failed_requests': _failedRequests,
    'cache_hit_ratio': cacheHitRatio,
    'batching_ratio': batchingRatio,
    'average_latency_ms': _averageLatency,
    'active_cache_entries': _cache.length,
    'circuit_breakers': _circuitBreakers.map((k, v) => MapEntry(k, v.state.name)),
  };

  /// Initialise le service d'optimisation Azure API
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation Azure API Optimization Service...');

      // Initialiser les services dépendants
      _envConfig = EnvironmentConfig();
      await _envConfig.loadConfig();

      _performanceService = VoicePerformanceMonitoringService();
      await _performanceService.initialize();

      // Initialiser le client HTTP avec optimisations
      _initializeHttpClient();

      // Initialiser les circuit breakers
      _initializeCircuitBreakers();

      // Démarrer le nettoyage périodique
      _startPeriodicCleanup();

      _isInitialized = true;
      debugPrint('Azure API Optimization Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation API optimization service: $e');
      rethrow;
    }
  }

  /// Initialise le client HTTP optimisé
  void _initializeHttpClient() {
    _httpClient = http.Client();
    
    // Créer des clients spécialisés par endpoint
    final endpoints = ['speech', 'openai', 'cognitive'];
    for (final endpoint in endpoints) {
      _endpointClients[endpoint] = http.Client();
      _endpointRequests[endpoint] = Queue<DateTime>();
    }

    debugPrint('Clients HTTP initialisés pour ${endpoints.length} endpoints');
  }

  /// Initialise les circuit breakers
  void _initializeCircuitBreakers() {
    final endpoints = ['speech', 'openai', 'cognitive'];
    
    for (final endpoint in endpoints) {
      _circuitBreakers[endpoint] = _CircuitBreaker(
        endpoint: endpoint,
        failureThreshold: 5,
        timeoutDuration: const Duration(seconds: 60),
        halfOpenRetryDelay: const Duration(seconds: 30),
      );
    }

    debugPrint('Circuit breakers initialisés');
  }

  /// Effectue une requête Azure optimisée
  Future<Map<String, dynamic>> makeOptimizedRequest({
    required String endpoint,
    required String path,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool useCache = true,
    bool enableBatching = true,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _totalRequests++;

      // Créer la clé de requête pour le cache
      final requestKey = _generateCacheKey(endpoint, path, method, body);

      // Vérifier le cache si activé
      if (_cachingEnabled && useCache) {
        final cachedResponse = _getCachedResponse(requestKey);
        if (cachedResponse != null) {
          _cachedResponses++;
          stopwatch.stop();
          
          _recordRequestMetrics(endpoint, stopwatch.elapsed, true, false);
          return cachedResponse;
        }
      }

      // Vérifier le circuit breaker
      final circuitBreaker = _circuitBreakers[endpoint];
      if (circuitBreaker != null && !circuitBreaker.canExecute()) {
        throw AzureApiException('Circuit breaker ouvert pour $endpoint');
      }

      // Appliquer le rate limiting
      if (_rateLimitingEnabled) {
        await _applyRateLimit(endpoint);
      }

      // Essayer le batching si activé
      if (_batchingEnabled && enableBatching && _canBatch(endpoint, method)) {
        return await _processBatchedRequest(
          endpoint, path, method, body, headers, timeout, requestKey
        );
      }

      // Exécuter la requête normale
      final response = await _executeRequest(
        endpoint, path, method, body, headers, timeout
      );

      stopwatch.stop();

      // Mettre en cache si approprié
      if (_cachingEnabled && useCache && _shouldCache(method, response)) {
        _cacheResponse(requestKey, response);
      }

      // Enregistrer les métriques
      _recordRequestMetrics(endpoint, stopwatch.elapsed, false, false);

      // Notifier le circuit breaker du succès
      circuitBreaker?.recordSuccess();

      return response;

    } catch (e) {
      stopwatch.stop();
      _failedRequests++;

      // Notifier le circuit breaker de l'échec
      final circuitBreaker = _circuitBreakers[endpoint];
      circuitBreaker?.recordFailure();

      // Enregistrer les métriques d'échec
      _recordRequestMetrics(endpoint, stopwatch.elapsed, false, true);

      debugPrint('Erreur requête Azure $endpoint: $e');
      rethrow;
    }
  }

  /// Génère une clé de cache pour la requête
  String _generateCacheKey(
    String endpoint, 
    String path, 
    String method, 
    Map<String, dynamic>? body
  ) {
    final bodyHash = body != null ? body.hashCode.toString() : '';
    return '${endpoint}_${method}_${path}_$bodyHash';
  }

  /// Obtient une réponse du cache
  Map<String, dynamic>? _getCachedResponse(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      _recentCacheHits.add(DateTime.now());
      debugPrint('Cache hit pour: $key');
      return entry.response;
    }

    // Supprimer l'entrée expirée
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
    }

    return null;
  }

  /// Met en cache une réponse
  void _cacheResponse(String key, Map<String, dynamic> response) {
    // Éviter de mettre en cache les réponses d'erreur
    if (response.containsKey('error')) return;

    _cache[key] = _CacheEntry(
      response: Map<String, dynamic>.from(response),
      timestamp: DateTime.now(),
      expiryDuration: _cacheExpiryDuration,
    );

    debugPrint('Réponse mise en cache: $key');
  }

  /// Vérifie si une réponse doit être mise en cache
  bool _shouldCache(String method, Map<String, dynamic> response) {
    // Ne cacher que les GET et les réponses réussies
    return method.toUpperCase() == 'GET' && !response.containsKey('error');
  }

  /// Applique le rate limiting
  Future<void> _applyRateLimit(String endpoint) async {
    final now = DateTime.now();
    final endpointQueue = _endpointRequests[endpoint] ?? Queue<DateTime>();

    // Nettoyer les anciennes requêtes
    while (endpointQueue.isNotEmpty && 
           now.difference(endpointQueue.first) > _rateLimitWindow) {
      endpointQueue.removeFirst();
    }

    // Vérifier si on dépasse la limite
    if (endpointQueue.length >= _maxRequestsPerSecond) {
      final waitTime = _rateLimitWindow - now.difference(endpointQueue.first);
      if (waitTime.inMilliseconds > 0) {
        _rateLimitedRequests++;
        debugPrint('Rate limit atteint pour $endpoint, attente: ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }

    // Ajouter la requête actuelle
    endpointQueue.add(now);
    _endpointRequests[endpoint] = endpointQueue;
  }

  /// Vérifie si une requête peut être groupée
  bool _canBatch(String endpoint, String method) {
    // Le batching n'est supporté que pour certains endpoints et méthodes
    return method.toUpperCase() == 'POST' && 
           (endpoint.contains('openai') || endpoint.contains('cognitive'));
  }

  /// Traite une requête groupée
  Future<Map<String, dynamic>> _processBatchedRequest(
    String endpoint,
    String path,
    String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    String requestKey,
  ) async {
    // Obtenir ou créer le processeur de batch pour cet endpoint
    _batchProcessors[endpoint] ??= _BatchProcessor(
      endpoint: endpoint,
      maxBatchSize: _maxBatchSize,
      batchTimeout: const Duration(milliseconds: 100),
      onBatchReady: _executeBatchRequest,
    );

    final processor = _batchProcessors[endpoint]!;
    
    // Ajouter la requête au batch
    final request = _BatchRequest(
      path: path,
      method: method,
      body: body,
      headers: headers,
      timeout: timeout,
      requestKey: requestKey,
    );

    _batchedRequests++;
    return await processor.addRequest(request);
  }

  /// Exécute un batch de requêtes
  Future<List<Map<String, dynamic>>> _executeBatchRequest(
    String endpoint,
    List<_BatchRequest> requests,
  ) async {
    debugPrint('Exécution batch de ${requests.length} requêtes pour $endpoint');

    final responses = <Map<String, dynamic>>[];

    // Pour l'instant, exécuter les requêtes en parallèle
    // Dans une vraie implémentation, on utiliserait l'API batch d'Azure
    final futures = requests.map((request) => 
      _executeRequest(
        endpoint,
        request.path,
        request.method,
        request.body,
        request.headers,
        request.timeout,
      )
    );

    try {
      final results = await Future.wait(futures);
      responses.addAll(results);
    } catch (e) {
      // En cas d'erreur, retourner des erreurs pour toutes les requêtes
      for (int i = 0; i < requests.length; i++) {
        responses.add({'error': 'Batch execution failed: $e'});
      }
    }

    return responses;
  }

  /// Exécute une requête HTTP
  Future<Map<String, dynamic>> _executeRequest(
    String endpoint,
    String path,
    String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  ) async {
    final client = _endpointClients[endpoint] ?? _httpClient;
    final uri = Uri.parse('${_getBaseUrl(endpoint)}$path');
    
    // Préparer les headers
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_compressionEnabled) 'Accept-Encoding': 'gzip, deflate',
      ...?headers,
    };

    // Ajouter l'authentification
    _addAuthHeaders(endpoint, requestHeaders);

    // Préparer le body
    String? requestBody;
    if (body != null) {
      requestBody = json.encode(body);
    }

    http.Response response;
    final requestTimeout = timeout ?? _requestTimeout;

    try {
      // Exécuter la requête avec retry
      response = await _executeWithRetry(() async {
        switch (method.toUpperCase()) {
          case 'GET':
            return await client.get(uri, headers: requestHeaders)
                .timeout(requestTimeout);
          case 'POST':
            return await client.post(uri, headers: requestHeaders, body: requestBody)
                .timeout(requestTimeout);
          case 'PUT':
            return await client.put(uri, headers: requestHeaders, body: requestBody)
                .timeout(requestTimeout);
          case 'DELETE':
            return await client.delete(uri, headers: requestHeaders)
                .timeout(requestTimeout);
          default:
            throw ArgumentError('Méthode HTTP non supportée: $method');
        }
      });

      // Vérifier le status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Décoder la réponse
        if (response.body.isNotEmpty) {
          return json.decode(response.body) as Map<String, dynamic>;
        } else {
          return {'status': 'success', 'statusCode': response.statusCode};
        }
      } else {
        throw AzureApiException(
          'Erreur HTTP ${response.statusCode}: ${response.body}'
        );
      }

    } on TimeoutException {
      throw AzureApiException('Timeout de la requête Azure ($requestTimeout)');
    } catch (e) {
      throw AzureApiException('Erreur requête Azure: $e');
    }
  }

  /// Exécute une requête avec retry automatique
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() requestFunction
  ) async {
    int attempts = 0;
    late dynamic lastError;

    while (attempts < _maxRetries) {
      try {
        return await requestFunction();
      } catch (e) {
        lastError = e;
        attempts++;

        if (attempts < _maxRetries) {
          final delay = _retryDelay * pow(2, attempts - 1); // Exponential backoff
          debugPrint('Tentative $attempts échouée, retry dans ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
        }
      }
    }

    throw AzureApiException('Échec après $_maxRetries tentatives: $lastError');
  }

  /// Obtient l'URL de base pour un endpoint
  String _getBaseUrl(String endpoint) {
    switch (endpoint) {
      case 'speech':
        return 'https://${_envConfig.azureSpeechRegion}.api.cognitive.microsoft.com/';
      case 'openai':
        return _envConfig.azureOpenAiEndpoint ?? 'https://api.openai.com/v1/';
      case 'cognitive':
        return 'https://${_envConfig.azureSpeechRegion}.cognitiveservices.azure.com/';
      default:
        throw ArgumentError('Endpoint non supporté: $endpoint');
    }
  }

  /// Ajoute les headers d'authentification
  void _addAuthHeaders(String endpoint, Map<String, String> headers) {
    switch (endpoint) {
      case 'speech':
        final speechKey = _envConfig.azureSpeechKey;
        if (speechKey != null) {
          headers['Ocp-Apim-Subscription-Key'] = speechKey;
        }
        break;
      case 'openai':
        final openAiKey = _envConfig.azureOpenAiKey;
        if (openAiKey != null) {
          headers['Authorization'] = 'Bearer $openAiKey';
        }
        break;
      case 'cognitive':
        final cognitiveKey = _envConfig.azureCognitiveKey;
        if (cognitiveKey != null) {
          headers['Ocp-Apim-Subscription-Key'] = cognitiveKey;
        }
        break;
    }
  }

  /// Enregistre les métriques de requête
  void _recordRequestMetrics(
    String endpoint,
    Duration latency,
    bool wasCached,
    bool failed,
  ) {
    // Mettre à jour la latence moyenne
    _averageLatency = ((_averageLatency * (_totalRequests - 1)) + 
                      latency.inMilliseconds) / _totalRequests;

    // Enregistrer dans le service de performance
    _performanceService.recordAzureApiCall(
      endpoint: endpoint,
      latency: latency,
      requestSize: 0, // À implémenter si nécessaire
      responseSize: 0, // À implémenter si nécessaire
      isSuccess: !failed,
      errorMessage: failed ? 'Request failed' : null,
    );

    if (!wasCached) {
      debugPrint('API $endpoint: ${latency.inMilliseconds}ms ${failed ? "(échec)" : "(succès)"}');
    }
  }

  /// Démarre le nettoyage périodique
  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredCaches();
      _cleanupOldRequests();
      _updateCacheHitRatio();
    });
  }

  /// Nettoie les caches expirés
  void _cleanupExpiredCaches() {
    final keysToRemove = <String>[];
    
    _cache.forEach((key, entry) {
      if (entry.isExpired) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('${keysToRemove.length} entrées de cache expirées supprimées');
    }
  }

  /// Nettoie les anciennes requêtes des queues de rate limiting
  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(_rateLimitWindow);
    
    _endpointRequests.forEach((endpoint, queue) {
      while (queue.isNotEmpty && queue.first.isBefore(cutoff)) {
        queue.removeFirst();
      }
    });

    // Nettoyer les cache hits récents
    final cacheHitCutoff = DateTime.now().subtract(const Duration(minutes: 30));
    while (_recentCacheHits.isNotEmpty && 
           _recentCacheHits.first.isBefore(cacheHitCutoff)) {
      _recentCacheHits.removeFirst();
    }
  }

  /// Met à jour le ratio de cache hit
  void _updateCacheHitRatio() {
    _cacheHitRatio = _totalRequests > 0 ? _cachedResponses / _totalRequests : 0.0;
  }

  /// Configure les options d'optimisation
  void configureOptimizations({
    bool? compression,
    bool? caching,
    bool? batching,
    bool? rateLimiting,
  }) {
    if (compression != null) _compressionEnabled = compression;
    if (caching != null) _cachingEnabled = caching;
    if (batching != null) _batchingEnabled = batching;
    if (rateLimiting != null) _rateLimitingEnabled = rateLimiting;

    debugPrint('Optimisations configurées - '
              'Compression: $_compressionEnabled, '
              'Cache: $_cachingEnabled, '
              'Batching: $_batchingEnabled, '
              'Rate limiting: $_rateLimitingEnabled');
  }

  /// Vide le cache manuellement
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('Cache vidé: $count entrées supprimées');
  }

  /// Force l'ouverture d'un circuit breaker (pour tests)
  void openCircuitBreaker(String endpoint) {
    final breaker = _circuitBreakers[endpoint];
    if (breaker != null) {
      breaker.forceOpen();
      debugPrint('Circuit breaker forcé ouvert pour $endpoint');
    }
  }

  /// Obtient un rapport détaillé
  Map<String, dynamic> getDetailedReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': statistics,
      'cache': {
        'entries': _cache.length,
        'hit_ratio': cacheHitRatio,
        'recent_hits': _recentCacheHits.length,
      },
      'rate_limiting': {
        'enabled': _rateLimitingEnabled,
        'requests_per_second_limit': _maxRequestsPerSecond,
        'recent_requests': _endpointRequests.map((k, v) => MapEntry(k, v.length)),
      },
      'circuit_breakers': _circuitBreakers.map((k, v) => MapEntry(k, {
        'state': v.state.name,
        'failure_count': v.failureCount,
        'last_failure': v.lastFailureTime?.toIso8601String(),
      })),
      'optimizations': {
        'compression': _compressionEnabled,
        'caching': _cachingEnabled,
        'batching': _batchingEnabled,
        'rate_limiting': _rateLimitingEnabled,
      },
    };
  }

  /// Nettoie les ressources
  void dispose() {
    _httpClient.close();
    _endpointClients.values.forEach((client) => client.close());
    
    _cache.clear();
    _recentCacheHits.clear();
    _endpointRequests.clear();
    _batchProcessors.clear();
    _circuitBreakers.clear();

    _isInitialized = false;
    debugPrint('Azure API Optimization Service disposé');
  }
}

// === CLASSES INTERNES ===

/// Entrée de cache
class _CacheEntry {
  final Map<String, dynamic> response;
  final DateTime timestamp;
  final Duration expiryDuration;

  _CacheEntry({
    required this.response,
    required this.timestamp,
    required this.expiryDuration,
  });

  bool get isExpired => 
      DateTime.now().difference(timestamp) > expiryDuration;
}

/// Circuit breaker
class _CircuitBreaker {
  final String endpoint;
  final int failureThreshold;
  final Duration timeoutDuration;
  final Duration halfOpenRetryDelay;

  _CircuitBreakerState _state = _CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _nextRetryTime;

  _CircuitBreaker({
    required this.endpoint,
    required this.failureThreshold,
    required this.timeoutDuration,
    required this.halfOpenRetryDelay,
  });

  _CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;
  DateTime? get lastFailureTime => _lastFailureTime;

  bool canExecute() {
    switch (_state) {
      case _CircuitBreakerState.closed:
        return true;
      case _CircuitBreakerState.open:
        if (_nextRetryTime != null && DateTime.now().isAfter(_nextRetryTime!)) {
          _state = _CircuitBreakerState.halfOpen;
          return true;
        }
        return false;
      case _CircuitBreakerState.halfOpen:
        return true;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _state = _CircuitBreakerState.closed;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = _CircuitBreakerState.open;
      _nextRetryTime = DateTime.now().add(timeoutDuration);
    }
  }

  void forceOpen() {
    _state = _CircuitBreakerState.open;
    _nextRetryTime = DateTime.now().add(timeoutDuration);
  }
}

enum _CircuitBreakerState { closed, open, halfOpen }

/// Processeur de batch
class _BatchProcessor {
  final String endpoint;
  final int maxBatchSize;
  final Duration batchTimeout;
  final Future<List<Map<String, dynamic>>> Function(String, List<_BatchRequest>) onBatchReady;

  final List<_BatchRequest> _pendingRequests = [];
  final Map<String, Completer<Map<String, dynamic>>> _requestCompleters = {};
  Timer? _batchTimer;

  _BatchProcessor({
    required this.endpoint,
    required this.maxBatchSize,
    required this.batchTimeout,
    required this.onBatchReady,
  });

  Future<Map<String, dynamic>> addRequest(_BatchRequest request) async {
    final completer = Completer<Map<String, dynamic>>();
    _requestCompleters[request.requestKey] = completer;
    _pendingRequests.add(request);

    // Déclencher le batch si on atteint la taille max
    if (_pendingRequests.length >= maxBatchSize) {
      await _processBatch();
    } else {
      // Sinon, démarrer/redémarrer le timer
      _batchTimer?.cancel();
      _batchTimer = Timer(batchTimeout, () => _processBatch());
    }

    return completer.future;
  }

  Future<void> _processBatch() async {
    if (_pendingRequests.isEmpty) return;

    _batchTimer?.cancel();

    final requests = List<_BatchRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    try {
      final responses = await onBatchReady(endpoint, requests);

      // Distribuer les réponses
      for (int i = 0; i < requests.length && i < responses.length; i++) {
        final request = requests[i];
        final response = responses[i];
        final completer = _requestCompleters.remove(request.requestKey);
        completer?.complete(response);
      }

      // Compléter les requêtes restantes avec une erreur
      for (int i = responses.length; i < requests.length; i++) {
        final request = requests[i];
        final completer = _requestCompleters.remove(request.requestKey);
        completer?.completeError(AzureApiException('Réponse batch manquante'));
      }

    } catch (e) {
      // En cas d'erreur, compléter toutes les requêtes avec l'erreur
      for (final request in requests) {
        final completer = _requestCompleters.remove(request.requestKey);
        completer?.completeError(e);
      }
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    
    // Compléter les requêtes en attente avec une erreur
    for (final completer in _requestCompleters.values) {
      completer.completeError(AzureApiException('Batch processor disposed'));
    }
    
    _requestCompleters.clear();
    _pendingRequests.clear();
  }
}

/// Requête en batch
class _BatchRequest {
  final String path;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final Duration? timeout;
  final String requestKey;

  _BatchRequest({
    required this.path,
    required this.method,
    this.body,
    this.headers,
    this.timeout,
    required this.requestKey,
  });
}

/// Exception spécifique aux API Azure
class AzureApiException implements Exception {
  final String message;
  
  const AzureApiException(this.message);
  
  @override
  String toString() => 'AzureApiException: $message';
}