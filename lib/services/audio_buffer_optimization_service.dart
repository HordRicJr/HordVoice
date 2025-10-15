import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:math';
import '../core/safety/loop_guard.dart';
import '../core/safety/watchdog_service.dart';
import 'package:flutter/foundation.dart';
import 'voice_performance_monitoring_service.dart';

/// Service d'optimisation des buffers audio pour réduire la fragmentation mémoire
/// et améliorer les performances de traitement vocal
class AudioBufferOptimizationService {
  static final AudioBufferOptimizationService _instance =
      AudioBufferOptimizationService._internal();
  factory AudioBufferOptimizationService() => _instance;
  AudioBufferOptimizationService._internal();

  // Configuration des buffers
  static const int _defaultBufferSize = 4096; // 4KB
  static const int _maxBufferSize = 65536; // 64KB
  static const int _minBufferSize = 1024; // 1KB
  static const int _maxPoolSize = 50; // Maximum buffers dans le pool
  static const Duration _bufferCleanupInterval = Duration(minutes: 2);

  // État du service
  bool _isInitialized = false;
  late VoicePerformanceMonitoringService _performanceService;
  Timer? _cleanupTimer;

  // Pools de buffers par taille
  final Map<int, Queue<Uint8List>> _bufferPools = {};
  final Map<int, int> _bufferUsageCount = {};
  final Map<int, DateTime> _bufferLastUsed = {};

  // Gestion dynamique des tailles
  int _currentOptimalSize = _defaultBufferSize;
  final List<int> _recentBufferSizes = [];
  static const int _sizeHistoryLimit = 100;

  // Configuration adaptative
  bool _adaptiveResizing = true;
  double _memoryPressureThreshold = 0.8; // 80%
  int _gcHintThreshold = 10; // Déclenchement GC après N allocations

  // Statistiques
  int _totalAllocations = 0;
  int _totalDeallocations = 0;
  int _poolHits = 0;
  int _poolMisses = 0;
  double _fragmentationRatio = 0.0;

  // Getters publics
  bool get isInitialized => _isInitialized;
  int get currentOptimalSize => _currentOptimalSize;
  double get fragmentationRatio => _fragmentationRatio;
  double get poolHitRatio => _totalAllocations > 0 ? _poolHits / _totalAllocations : 0.0;
  
  Map<String, dynamic> get statistics => {
    'total_allocations': _totalAllocations,
    'total_deallocations': _totalDeallocations,
    'pool_hits': _poolHits,
    'pool_misses': _poolMisses,
    'hit_ratio': poolHitRatio,
    'fragmentation_ratio': _fragmentationRatio,
    'optimal_size': _currentOptimalSize,
    'active_pools': _bufferPools.length,
    'total_pooled_buffers': _bufferPools.values.isEmpty 
        ? 0 
        : _bufferPools.values.map((q) => q.length).reduce((a, b) => a + b),
  };

  /// Initialise le service d'optimisation des buffers
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation Audio Buffer Optimization Service...');

      // Initialiser le service de performance
      _performanceService = VoicePerformanceMonitoringService();
      await _performanceService.initialize();

      // Initialiser les pools de buffers communs
      _initializeBufferPools();

      // Démarrer le nettoyage périodique
      _cleanupTimer = Timer.periodic(_bufferCleanupInterval, _performCleanup);

      _isInitialized = true;
      debugPrint('Audio Buffer Optimization Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation buffer service: $e');
      rethrow;
    }
  }

  /// Initialise les pools de buffers avec les tailles courantes
  void _initializeBufferPools() {
    // Créer des pools pour les tailles standard
    final standardSizes = [
      _minBufferSize,
      _defaultBufferSize,
      _defaultBufferSize * 2,
      _defaultBufferSize * 4,
      _maxBufferSize,
    ];

    for (final size in standardSizes) {
      _bufferPools[size] = Queue<Uint8List>();
      _bufferUsageCount[size] = 0;
      _bufferLastUsed[size] = DateTime.now();
    }

    debugPrint('Pools initialisés pour tailles: $standardSizes');
  }

  /// Alloue un buffer audio optimisé
  Uint8List allocateBuffer({int? requestedSize, String? context}) {
    _totalAllocations++;

    // Déterminer la taille optimale
    final size = requestedSize ?? _determineOptimalSize(context);
    final actualSize = _roundToOptimalSize(size);

    // Essayer d'obtenir un buffer du pool
    final pooledBuffer = _getFromPool(actualSize);
    if (pooledBuffer != null) {
      _poolHits++;
      _updateUsageStats(actualSize);
      _trackBufferSizeUsage(actualSize);
      
      debugPrint('Buffer alloué du pool: ${actualSize} bytes (context: $context)');
      return pooledBuffer;
    }

    // Créer un nouveau buffer si pas disponible dans le pool
    _poolMisses++;
    final newBuffer = _createNewBuffer(actualSize);
    _updateUsageStats(actualSize);
    _trackBufferSizeUsage(actualSize);
    
    debugPrint('Nouveau buffer créé: ${actualSize} bytes (context: $context)');
    
    // Déclencher GC si nécessaire
    _maybePerformGarbageCollection();
    
    return newBuffer;
  }

  /// Libère un buffer et le remet dans le pool si possible
  void deallocateBuffer(Uint8List buffer, {String? context}) {
    _totalDeallocations++;

    final size = buffer.length;
    
    // Vérifier si on peut remettre le buffer dans le pool
    if (_canReturnToPool(size)) {
      _returnToPool(buffer);
      debugPrint('Buffer retourné au pool: ${size} bytes (context: $context)');
    } else {
      // Buffer trop gros ou pool plein, laisser le GC s'en occuper
      debugPrint('Buffer libéré par GC: ${size} bytes (context: $context)');
    }

    // Mettre à jour les statistiques de fragmentation
    _updateFragmentationStats();
  }

  /// Obtient un buffer du pool de la taille demandée
  Uint8List? _getFromPool(int size) {
    final pool = _bufferPools[size];
    if (pool != null && pool.isNotEmpty) {
      return pool.removeFirst();
    }

    // Essayer de trouver un buffer plus grand
    for (final poolSize in _bufferPools.keys.where((s) => s >= size)) {
      final pool = _bufferPools[poolSize];
      if (pool != null && pool.isNotEmpty) {
        final buffer = pool.removeFirst();
        // Retourner une vue de la taille demandée
        return Uint8List.sublistView(buffer, 0, size);
      }
    }

    return null;
  }

  /// Retourne un buffer au pool approprié
  void _returnToPool(Uint8List buffer) {
    final size = buffer.length;
    
    // Créer le pool si nécessaire
    _bufferPools[size] ??= Queue<Uint8List>();
    
    final pool = _bufferPools[size]!;
    
    // Vérifier si le pool a de la place
    if (pool.length < _maxPoolSize) {
      // Effacer le buffer avant de le remettre dans le pool
      buffer.fillRange(0, buffer.length, 0);
      pool.add(buffer);
      _bufferLastUsed[size] = DateTime.now();
    }
  }

  /// Vérifie si un buffer peut être retourné au pool
  bool _canReturnToPool(int size) {
    // Ne pas pooler les buffers trop grands
    if (size > _maxBufferSize) return false;
    
    // Vérifier la pression mémoire
    if (_isMemoryPressureHigh()) return false;
    
    // Vérifier si le pool existe et a de la place
    final pool = _bufferPools[size];
    return pool == null || pool.length < _maxPoolSize;
  }

  /// Créer un nouveau buffer avec optimisations
  Uint8List _createNewBuffer(int size) {
    try {
      // Allouer le buffer avec la taille exacte
      return Uint8List(size);
    } catch (e) {
      debugPrint('Erreur allocation buffer $size bytes: $e');
      
      // Fallback avec une taille plus petite
      final fallbackSize = max(_minBufferSize, size ~/ 2);
      debugPrint('Fallback allocation: $fallbackSize bytes');
      return Uint8List(fallbackSize);
    }
  }

  /// Détermine la taille optimale basée sur le contexte
  int _determineOptimalSize(String? context) {
    // Utiliser l'analyse adaptative si activée
    if (_adaptiveResizing) {
      return _currentOptimalSize;
    }

    // Tailles spécifiques au contexte
    switch (context) {
      case 'wake_word':
        return _minBufferSize; // Wake word needs smaller buffers
      case 'streaming':
        return _defaultBufferSize * 2; // Streaming needs bigger buffers
      case 'synthesis':
        return _maxBufferSize; // TTS output can be large
      case 'recognition':
      default:
        return _defaultBufferSize;
    }
  }

  /// Arrondit la taille à une valeur optimale (puissance de 2)
  int _roundToOptimalSize(int requestedSize) {
    // Assurer les limites min/max
    if (requestedSize < _minBufferSize) return _minBufferSize;
    if (requestedSize > _maxBufferSize) return _maxBufferSize;

    // Arrondir à la prochaine puissance de 2 pour optimiser l'allocation
    int optimalSize = _minBufferSize;
    while (optimalSize < requestedSize && optimalSize < _maxBufferSize) {
      optimalSize *= 2;
    }

    return optimalSize;
  }

  /// Suit l'utilisation des tailles de buffers pour l'optimisation adaptative
  void _trackBufferSizeUsage(int size) {
    _recentBufferSizes.add(size);
    
    // Limiter l'historique avec protection contre les boucles infinies
    if (_recentBufferSizes.length > _sizeHistoryLimit) {
      final _historyTrimGuard = LoopGuard(
        maxIterations: 100, 
        timeBudget: Duration(milliseconds: 500), 
        label: 'BufferHistoryTrim'
      );
      
      while (_recentBufferSizes.length > _sizeHistoryLimit && _historyTrimGuard.next()) {
        _recentBufferSizes.removeAt(0);
      }
      
      if (!_historyTrimGuard.next()) {
        WatchdogService.instance.notifyTimerCallback('audio_buffer_history_trim_exceeded');
        debugPrint('⚠️ Buffer history trimming exceeded safe limits, forcing cleanup');
        
        // Nettoyage d'urgence : garder seulement les dernières valeurs
        final keepSize = (_sizeHistoryLimit * 0.5).round();
        if (_recentBufferSizes.length > keepSize) {
          _recentBufferSizes.removeRange(0, _recentBufferSizes.length - keepSize);
        }
      }
    }

    // Mettre à jour la taille optimale si on a assez de données
    if (_recentBufferSizes.length >= 20) {
      _updateOptimalSize();
    }
  }

  /// Met à jour la taille optimale basée sur l'usage récent
  void _updateOptimalSize() {
    if (!_adaptiveResizing || _recentBufferSizes.isEmpty) return;

    // Calculer la taille la plus fréquemment utilisée
    final sizeFrequency = <int, int>{};
    for (final size in _recentBufferSizes) {
      sizeFrequency[size] = (sizeFrequency[size] ?? 0) + 1;
    }

    // Trouver la taille la plus populaire
    int mostUsedSize = _defaultBufferSize;
    int maxFrequency = 0;

    sizeFrequency.forEach((size, frequency) {
      if (frequency > maxFrequency) {
        maxFrequency = frequency;
        mostUsedSize = size;
      }
    });

    // Mettre à jour si significativement différent
    if ((mostUsedSize - _currentOptimalSize).abs() > _minBufferSize) {
      final oldSize = _currentOptimalSize;
      _currentOptimalSize = mostUsedSize;
      
      debugPrint('Taille optimale mise à jour: $oldSize -> $mostUsedSize bytes');
      
      // Pré-allouer quelques buffers de la nouvelle taille optimale
      _preAllocateOptimalBuffers();
    }
  }

  /// Pré-alloue des buffers de la taille optimale
  void _preAllocateOptimalBuffers() {
    final targetSize = _currentOptimalSize;
    _bufferPools[targetSize] ??= Queue<Uint8List>();
    
    final pool = _bufferPools[targetSize]!;
    const preAllocCount = 5;
    
    for (int i = 0; i < preAllocCount && pool.length < _maxPoolSize; i++) {
      pool.add(Uint8List(targetSize));
    }
    
    debugPrint('Pré-allocation: $preAllocCount buffers de $targetSize bytes');
  }

  /// Met à jour les statistiques d'usage
  void _updateUsageStats(int size) {
    _bufferUsageCount[size] = (_bufferUsageCount[size] ?? 0) + 1;
    _bufferLastUsed[size] = DateTime.now();
  }

  /// Met à jour les statistiques de fragmentation
  void _updateFragmentationStats() {
    if (_totalAllocations == 0) {
      _fragmentationRatio = 0.0;
      return;
    }

    // Calculer la fragmentation basée sur la variation des tailles
    if (_recentBufferSizes.length < 10) return;

    final avgSize = _recentBufferSizes.reduce((a, b) => a + b) / _recentBufferSizes.length;
    final variance = _recentBufferSizes
        .map((size) => pow(size - avgSize, 2))
        .reduce((a, b) => a + b) / _recentBufferSizes.length;
    
    _fragmentationRatio = sqrt(variance) / avgSize;
  }

  /// Vérifie si la pression mémoire est élevée
  bool _isMemoryPressureHigh() {
    try {
      // Utiliser les métriques du service de performance
      final currentMetrics = _performanceService.currentMetrics;
      final memoryPressure = currentMetrics['memory_pressure'] ?? 0.0;
      
      return memoryPressure > _memoryPressureThreshold;
    } catch (e) {
      // En cas d'erreur, être conservateur
      return false;
    }
  }

  /// Déclenche le garbage collection si nécessaire
  void _maybePerformGarbageCollection() {
    if (_totalAllocations % _gcHintThreshold == 0) {
      if (_isMemoryPressureHigh()) {
        // Suggérer un garbage collection
        debugPrint('Suggestion GC après $_totalAllocations allocations');
        
        // En mode debug, forcer le GC
        if (kDebugMode) {
          // Note: En production, on laisserait Dart gérer le GC automatiquement
          debugPrint('GC forcé en mode debug');
        }
      }
    }
  }

  /// Effectue le nettoyage périodique des pools
  void _performCleanup(Timer timer) {
    try {
      final now = DateTime.now();
      int buffersRemoved = 0;
      int poolsRemoved = 0;

      // Nettoyer les pools non utilisés
      _bufferPools.removeWhere((size, pool) {
        final lastUsed = _bufferLastUsed[size] ?? DateTime(1970);
        final isOld = now.difference(lastUsed).inMinutes > 10;
        final hasLowUsage = (_bufferUsageCount[size] ?? 0) < 5;
        
        if (isOld && hasLowUsage && pool.isNotEmpty) {
          buffersRemoved += pool.length;
          poolsRemoved++;
          
          // Nettoyer les statistiques associées
          _bufferUsageCount.remove(size);
          _bufferLastUsed.remove(size);
          
          return true;
        }
        
        return false;
      });

      // Réduire la taille des pools très grands
      _bufferPools.forEach((size, pool) {
        const maxIdleBuffers = _maxPoolSize ~/ 2;
        if (pool.length > maxIdleBuffers) {
          final _poolTrimGuard = LoopGuard(
            maxIterations: 100, 
            timeBudget: Duration(milliseconds: 500), 
            label: 'BufferPoolTrim'
          );
          
          while (pool.length > maxIdleBuffers && _poolTrimGuard.next()) {
            pool.removeFirst();
            buffersRemoved++;
          }
          
          if (!_poolTrimGuard.next()) {
            WatchdogService.instance.notifyTimerCallback('audio_buffer_pool_trim_exceeded');
            debugPrint('⚠️ Buffer pool trimming exceeded safe limits for size $size');
            
            // Nettoyage d'urgence : vider le pool complètement si nécessaire
            if (pool.length > _maxPoolSize) {
              final removedInEmergency = pool.length;
              pool.clear();
              buffersRemoved += removedInEmergency;
              debugPrint('🚨 Emergency pool cleanup: removed $removedInEmergency buffers of size $size');
            }
          }
        }
      });

      if (buffersRemoved > 0 || poolsRemoved > 0) {
        debugPrint('🧹 Nettoyage buffers: $buffersRemoved buffers, $poolsRemoved pools supprimés');
      }

      // Réinitialiser les statistiques périodiquement
      if (now.minute % 30 == 0) {
        _resetLongTermStatistics();
      }

    } catch (e) {
      debugPrint('Erreur nettoyage buffers: $e');
    }
  }

  /// Réinitialise les statistiques à long terme
  void _resetLongTermStatistics() {
    // Garder les statistiques importantes mais réinitialiser les compteurs
    _totalAllocations = 0;
    _totalDeallocations = 0;
    _poolHits = 0;
    _poolMisses = 0;
    
    // Vider l'historique des tailles mais garder les dernières valeurs
    if (_recentBufferSizes.length > 20) {
      final lastSizes = _recentBufferSizes.skip(_recentBufferSizes.length - 20).toList();
      _recentBufferSizes.clear();
      _recentBufferSizes.addAll(lastSizes);
    }

    debugPrint('📊 Statistiques buffers réinitialisées');
  }

  /// Configure le mode adaptatif
  void setAdaptiveResizing(bool enabled) {
    _adaptiveResizing = enabled;
    debugPrint('Redimensionnement adaptatif: ${enabled ? "activé" : "désactivé"}');
  }

  /// Configure le seuil de pression mémoire
  void setMemoryPressureThreshold(double threshold) {
    _memoryPressureThreshold = threshold.clamp(0.0, 1.0);
    debugPrint('Seuil pression mémoire: ${(_memoryPressureThreshold * 100).toStringAsFixed(1)}%');
  }

  /// Force le nettoyage immédiat
  void forceCleanup() {
    debugPrint('🧹 Force nettoyage des buffers...');
    
    int totalBuffersRemoved = 0;
    
    // Vider tous les pools
    _bufferPools.forEach((size, pool) {
      totalBuffersRemoved += pool.length;
      pool.clear();
    });
    
    // Réinitialiser les statistiques
    _bufferUsageCount.clear();
    _bufferLastUsed.clear();
    _recentBufferSizes.clear();
    
    debugPrint('🧹 Nettoyage forcé terminé: $totalBuffersRemoved buffers supprimés');
  }

  /// Obtient un rapport détaillé des performances
  Map<String, dynamic> getDetailedReport() {
    final now = DateTime.now();
    
    return {
      'timestamp': now.toIso8601String(),
      'statistics': statistics,
      'optimal_size': _currentOptimalSize,
      'adaptive_resizing': _adaptiveResizing,
      'memory_pressure_threshold': _memoryPressureThreshold,
      'pools': _bufferPools.map((size, pool) => MapEntry(
        size.toString(),
        {
          'size': size,
          'count': pool.length,
          'usage_count': _bufferUsageCount[size] ?? 0,
          'last_used': _bufferLastUsed[size]?.toIso8601String(),
        }
      )),
      'recent_sizes_histogram': _getSizeHistogram(),
      'recommendations': _generateOptimizationRecommendations(),
    };
  }

  /// Génère un histogramme des tailles récentes
  Map<String, int> _getSizeHistogram() {
    final histogram = <String, int>{};
    
    for (final size in _recentBufferSizes) {
      final key = size.toString();
      histogram[key] = (histogram[key] ?? 0) + 1;
    }
    
    return histogram;
  }

  /// Génère des recommandations d'optimisation
  List<String> _generateOptimizationRecommendations() {
    final recommendations = <String>[];
    
    // Analyser le ratio de succès du pool
    if (poolHitRatio < 0.7) {
      recommendations.add('Augmenter la taille des pools (hit ratio: ${(poolHitRatio * 100).toStringAsFixed(1)}%)');
    }
    
    // Analyser la fragmentation
    if (_fragmentationRatio > 0.5) {
      recommendations.add('Réduire la fragmentation en normalisant les tailles de buffers');
    }
    
    // Analyser l'usage des pools
    final unusedPools = _bufferPools.entries
        .where((entry) => (_bufferUsageCount[entry.key] ?? 0) == 0)
        .length;
    
    if (unusedPools > 2) {
      recommendations.add('Supprimer $unusedPools pools non utilisés');
    }
    
    // Analyser la pression mémoire
    if (_isMemoryPressureHigh()) {
      recommendations.add('Réduire la taille des pools en raison de la pression mémoire élevée');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Configuration des buffers optimale');
    }
    
    return recommendations;
  }

  /// Nettoie les ressources
  void dispose() {
    _cleanupTimer?.cancel();
    
    // Nettoyer tous les pools
    _bufferPools.clear();
    _bufferUsageCount.clear();
    _bufferLastUsed.clear();
    _recentBufferSizes.clear();
    
    _isInitialized = false;
    
    debugPrint('Audio Buffer Optimization Service disposé');
  }
}

/// Extension pour faciliter l'utilisation avec les streams audio
extension AudioBufferExtensions on AudioBufferOptimizationService {
  /// Alloue un buffer pour le streaming audio
  Uint8List allocateStreamingBuffer(int sampleRate, int channels, Duration duration) {
    final bytesPerSample = 2; // 16-bit audio
    final totalSamples = (sampleRate * channels * duration.inMilliseconds / 1000).ceil();
    final bufferSize = totalSamples * bytesPerSample;
    
    return allocateBuffer(requestedSize: bufferSize, context: 'streaming');
  }
  
  /// Alloue un buffer pour la reconnaissance vocale
  Uint8List allocateRecognitionBuffer() {
    return allocateBuffer(context: 'recognition');
  }
  
  /// Alloue un buffer pour la synthèse vocale
  Uint8List allocateSynthesisBuffer(int estimatedSize) {
    return allocateBuffer(requestedSize: estimatedSize, context: 'synthesis');
  }
  
  /// Alloue un buffer pour le wake word
  Uint8List allocateWakeWordBuffer() {
    return allocateBuffer(context: 'wake_word');
  }
}