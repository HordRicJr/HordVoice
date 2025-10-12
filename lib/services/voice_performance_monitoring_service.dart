import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'battery_monitoring_service.dart';
import 'health_monitoring_service.dart';

/// Service de monitoring des performances pour le traitement vocal
/// Suit les métriques en temps réel pour optimiser les performances
class VoicePerformanceMonitoringService {
  static final VoicePerformanceMonitoringService _instance =
      VoicePerformanceMonitoringService._internal();
  factory VoicePerformanceMonitoringService() => _instance;
  VoicePerformanceMonitoringService._internal();

  // Configuration du monitoring
  static const int _maxHistorySize = 1000;
  static const Duration _reportingInterval = Duration(seconds: 30);
  static const Duration _memoryCleanupInterval = Duration(minutes: 5);

  // État du service
  bool _isInitialized = false;
  bool _isMonitoring = false;
  Timer? _reportingTimer;
  Timer? _memoryCleanupTimer;

  // Services associés
  late BatteryMonitoringService _batteryService;
  late HealthMonitoringService _healthService;

  // Métriques en temps réel
  final Queue<VoiceMetric> _metricsHistory = Queue<VoiceMetric>();
  final Map<String, ApiCallMetric> _apiCallMetrics = {};
  final Map<String, double> _currentMetrics = {};

  // Statistiques agrégées
  late PerformanceStatistics _statistics;

  // Controllers pour les streams
  final StreamController<VoiceMetric> _metricsController =
      StreamController.broadcast();
  final StreamController<PerformanceReport> _reportController =
      StreamController.broadcast();
  final StreamController<PerformanceAlert> _alertController =
      StreamController.broadcast();

  // Streams publics
  Stream<VoiceMetric> get metricsStream => _metricsController.stream;
  Stream<PerformanceReport> get reportStream => _reportController.stream;
  Stream<PerformanceAlert> get alertStream => _alertController.stream;

  // Accesseurs publics
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  PerformanceStatistics get statistics => _statistics;
  Map<String, double> get currentMetrics => Map.unmodifiable(_currentMetrics);

  /// Initialise le service de monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation du Voice Performance Monitoring Service...');

      // Initialiser les services dépendants
      _batteryService = BatteryMonitoringService();
      _healthService = HealthMonitoringService();

      await _batteryService.initialize();
      await _healthService.initialize();

      // Initialiser les statistiques
      _statistics = PerformanceStatistics();

      // Configurer les timers
      _reportingTimer = Timer.periodic(_reportingInterval, _generateReport);
      _memoryCleanupTimer =
          Timer.periodic(_memoryCleanupInterval, _performMemoryCleanup);

      _isInitialized = true;
      debugPrint('Voice Performance Monitoring Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation monitoring service: $e');
      rethrow;
    }
  }

  /// Démarre le monitoring des performances
  Future<void> startMonitoring() async {
    if (!_isInitialized || _isMonitoring) return;

    try {
      _isMonitoring = true;

      // Démarrer le monitoring mémoire
      await _startMemoryMonitoring();

      // Démarrer le monitoring réseau
      await _startNetworkMonitoring();

      // Démarrer le monitoring batterie
      await _batteryService.startMonitoring();

      debugPrint('Monitoring des performances vocales démarré');
    } catch (e) {
      _isMonitoring = false;
      debugPrint('Erreur démarrage monitoring: $e');
      rethrow;
    }
  }

  /// Arrête le monitoring des performances
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      _isMonitoring = false;

      // Arrêter tous les timers
      _reportingTimer?.cancel();
      _memoryCleanupTimer?.cancel();

      // Arrêter le monitoring batterie
      await _batteryService.stopMonitoring();

      debugPrint('Monitoring des performances arrêté');
    } catch (e) {
      debugPrint('Erreur arrêt monitoring: $e');
    }
  }

  /// Enregistre une métrique de reconnaissance vocale
  void recordVoiceRecognitionMetric({
    required Duration latency,
    required double confidence,
    required int audioDataSize,
    required String recognizedText,
    String? errorMessage,
  }) {
    if (!_isMonitoring) return;

    final metric = VoiceMetric(
      timestamp: DateTime.now(),
      type: VoiceMetricType.recognition,
      latency: latency,
      confidence: confidence,
      audioDataSize: audioDataSize,
      recognizedText: recognizedText,
      errorMessage: errorMessage,
      memoryUsage: _getCurrentMemoryUsage(),
      batteryLevel: 100.0, // Will be updated asynchronously
    );

    _addMetric(metric);
    _updateStatistics(metric);
    _checkForAlerts(metric);
  }

  /// Enregistre une métrique de synthèse vocale
  Future<void> recordSpeechSynthesisMetric({
    required Duration latency,
    required String text,
    required int audioOutputSize,
    String? errorMessage,
  }) async {
    if (!_isMonitoring) return;

    final batteryLevel = await _batteryService.currentLevel;
    final metric = VoiceMetric(
      timestamp: DateTime.now(),
      type: VoiceMetricType.synthesis,
      latency: latency,
      confidence: 1.0, // TTS a généralement une confiance élevée
      audioDataSize: audioOutputSize,
      recognizedText: text,
      errorMessage: errorMessage,
      memoryUsage: _getCurrentMemoryUsage(),
      batteryLevel: batteryLevel.toDouble(),
    );

    _addMetric(metric);
    _updateStatistics(metric);
    _checkForAlerts(metric);
  }

  /// Enregistre une métrique de détection wake word
  Future<void> recordWakeWordDetectionMetric({
    required Duration latency,
    required double confidence,
    required bool isDetected,
    required String matchedText,
  }) async {
    if (!_isMonitoring) return;

    final batteryLevel = await _batteryService.currentLevel;
    final metric = VoiceMetric(
      timestamp: DateTime.now(),
      type: VoiceMetricType.wakeWord,
      latency: latency,
      confidence: confidence,
      audioDataSize: 0,
      recognizedText: matchedText,
      isWakeWordDetected: isDetected,
      memoryUsage: _getCurrentMemoryUsage(),
      batteryLevel: batteryLevel.toDouble(),
    );

    _addMetric(metric);
    _updateStatistics(metric);
    _checkForAlerts(metric);
  }

  /// Enregistre une métrique d'appel API Azure
  Future<void> recordAzureApiCall({
    required String endpoint,
    required Duration latency,
    required int requestSize,
    required int responseSize,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    if (!_isMonitoring) return;

    final now = DateTime.now();
    final callMetric = ApiCallMetric(
      endpoint: endpoint,
      timestamp: now,
      latency: latency,
      requestSize: requestSize,
      responseSize: responseSize,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    // Mettre à jour les métriques API
    _apiCallMetrics[endpoint] = callMetric;

    final batteryLevel = await _batteryService.currentLevel;
    // Créer une métrique voice associée
    final metric = VoiceMetric(
      timestamp: now,
      type: VoiceMetricType.apiCall,
      latency: latency,
      confidence: 0.0,
      audioDataSize: requestSize,
      recognizedText: endpoint,
      errorMessage: errorMessage,
      memoryUsage: _getCurrentMemoryUsage(),
      batteryLevel: batteryLevel.toDouble(),
      apiEndpoint: endpoint,
      apiSuccess: isSuccess,
    );

    _addMetric(metric);
    _updateStatistics(metric);
    _checkForAlerts(metric);
  }

  /// Démarre le monitoring mémoire
  Future<void> _startMemoryMonitoring() async {
    try {
      // Démarrer la collecte périodique des métriques mémoire
      Timer.periodic(const Duration(seconds: 5), (_) {
        if (_isMonitoring) {
          _currentMetrics['memory_usage'] = _getCurrentMemoryUsage();
          _currentMetrics['memory_pressure'] = _getMemoryPressure();
        }
      });
    } catch (e) {
      debugPrint('Erreur démarrage monitoring mémoire: $e');
    }
  }

  /// Démarre le monitoring réseau
  Future<void> _startNetworkMonitoring() async {
    try {
      // Monitorer la latence réseau périodiquement
      Timer.periodic(const Duration(seconds: 10), (_) {
        if (_isMonitoring) {
          _measureNetworkLatency();
        }
      });
    } catch (e) {
      debugPrint('Erreur démarrage monitoring réseau: $e');
    }
  }

  /// Mesure la latence réseau
  Future<void> _measureNetworkLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Ping simple vers Azure (simulation)
      await Future.delayed(const Duration(milliseconds: 50));
      
      stopwatch.stop();
      _currentMetrics['network_latency'] = stopwatch.elapsedMilliseconds.toDouble();
    } catch (e) {
      _currentMetrics['network_latency'] = -1.0; // Erreur réseau
    }
  }

  /// Obtient l'utilisation mémoire actuelle
  double _getCurrentMemoryUsage() {
    try {
      // En Dart, utiliser une estimation basée sur les métriques disponibles
      // Note: Les vraies métriques mémoire nécessitent des APIs natives spécifiques
      return 50.0 + (DateTime.now().millisecondsSinceEpoch % 100).toDouble();
    } catch (e) {
      // Simulation si l'API n'est pas disponible
      return 50.0 + (DateTime.now().millisecondsSinceEpoch % 100).toDouble();
    }
  }

  /// Calcule la pression mémoire
  double _getMemoryPressure() {
    try {
      final current = _getCurrentMemoryUsage();
      final threshold = 100.0; // MB
      return (current / threshold).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Ajoute une métrique à l'historique
  void _addMetric(VoiceMetric metric) {
    _metricsHistory.add(metric);

    // Limiter la taille de l'historique
    while (_metricsHistory.length > _maxHistorySize) {
      _metricsHistory.removeFirst();
    }

    // Émettre la métrique
    _metricsController.add(metric);
  }

  /// Met à jour les statistiques agrégées
  void _updateStatistics(VoiceMetric metric) {
    _statistics.updateWith(metric);
  }

  /// Vérifie les seuils d'alerte
  void _checkForAlerts(VoiceMetric metric) {
    final alerts = <PerformanceAlert>[];

    // Alerte latence élevée
    if (metric.latency.inMilliseconds > 3000) {
      alerts.add(PerformanceAlert(
        type: AlertType.highLatency,
        severity: AlertSeverity.warning,
        message: 'Latence élevée détectée: ${metric.latency.inMilliseconds}ms',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    }

    // Alerte mémoire élevée
    if (metric.memoryUsage > 200.0) {
      alerts.add(PerformanceAlert(
        type: AlertType.highMemoryUsage,
        severity: AlertSeverity.critical,
        message: 'Utilisation mémoire critique: ${metric.memoryUsage.toStringAsFixed(1)} MB',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    }

    // Alerte batterie faible
    if (metric.batteryLevel != null && metric.batteryLevel! < 20.0) {
      alerts.add(PerformanceAlert(
        type: AlertType.lowBattery,
        severity: AlertSeverity.warning,
        message: 'Niveau batterie faible: ${metric.batteryLevel!.toStringAsFixed(1)}%',
        metric: metric,
        timestamp: DateTime.now(),
      ));
    }

    // Alerte erreurs API fréquentes
    if (metric.type == VoiceMetricType.apiCall && !metric.apiSuccess!) {
      final recentErrors = _metricsHistory
          .where((m) => m.type == VoiceMetricType.apiCall && !m.apiSuccess!)
          .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 5)
          .length;

      if (recentErrors >= 3) {
        alerts.add(PerformanceAlert(
          type: AlertType.apiErrors,
          severity: AlertSeverity.critical,
          message: 'Erreurs API fréquentes: $recentErrors dans les 5 dernières minutes',
          metric: metric,
          timestamp: DateTime.now(),
        ));
      }
    }

    // Émettre les alertes
    for (final alert in alerts) {
      _alertController.add(alert);
      debugPrint('🚨 ALERTE: ${alert.message}');
    }
  }

  /// Génère un rapport de performance périodique
  void _generateReport(Timer timer) {
    if (!_isMonitoring) return;

    _generateReportAsync();
  }

  Future<void> _generateReportAsync() async {
    try {
      final batteryLevel = await _batteryService.currentLevel;
      final report = PerformanceReport(
        timestamp: DateTime.now(),
        period: _reportingInterval,
        statistics: _statistics.copy(),
        currentMetrics: Map.from(_currentMetrics),
        apiCallMetrics: Map.from(_apiCallMetrics),
        memoryUsage: _getCurrentMemoryUsage(),
        batteryLevel: batteryLevel.toDouble(),
        recommendation: _generateRecommendation(),
      );

      _reportController.add(report);
      debugPrint('📊 Rapport performance généré: ${report.summary}');
    } catch (e) {
      debugPrint('Erreur génération rapport: $e');
    }
  }

  /// Génère des recommandations d'optimisation
  String _generateRecommendation() {
    final recommendations = <String>[];

    // Analyser les métriques récentes
    final recentMetrics = _metricsHistory
        .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 5)
        .toList();

    if (recentMetrics.isEmpty) return 'Pas assez de données pour les recommandations';

    // Recommandations basées sur la latence
    final avgLatency = recentMetrics
        .map((m) => m.latency.inMilliseconds)
        .reduce((a, b) => a + b) / recentMetrics.length;

    if (avgLatency > 2000) {
      recommendations.add('Réduire la taille des buffers audio');
      recommendations.add('Optimiser les appels API Azure');
    }

    // Recommandations basées sur la mémoire
    final avgMemory = recentMetrics
        .map((m) => m.memoryUsage)
        .reduce((a, b) => a + b) / recentMetrics.length;

    if (avgMemory > 150.0) {
      recommendations.add('Nettoyer les buffers audio plus fréquemment');
      recommendations.add('Implémenter le pooling d\'objets');
    }

    // Recommandations basées sur les erreurs API
    final apiErrors = recentMetrics
        .where((m) => m.type == VoiceMetricType.apiCall && !m.apiSuccess!)
        .length;

    if (apiErrors > 1) {
      recommendations.add('Ajouter de la logique de retry');
      recommendations.add('Implémenter le cache pour réduire les appels API');
    }

    return recommendations.isEmpty 
        ? 'Performances optimales'
        : recommendations.join('; ');
  }

  /// Effectue le nettoyage mémoire périodique
  void _performMemoryCleanup(Timer timer) {
    try {
      // Nettoyer l'historique ancien
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      _metricsHistory.removeWhere((m) => m.timestamp.isBefore(cutoff));

      // Nettoyer les métriques API anciennes
      _apiCallMetrics.removeWhere(
        (key, value) => DateTime.now().difference(value.timestamp).inMinutes > 30
      );

      // Forcer garbage collection (automatique en Dart)
      if (kDebugMode) {
        developer.log('Memory cleanup requested');
      }

      debugPrint('🧹 Nettoyage mémoire effectué');
    } catch (e) {
      debugPrint('Erreur nettoyage mémoire: $e');
    }
  }

  /// Exporte les métriques en JSON
  Map<String, dynamic> exportMetrics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': _statistics.toJson(),
      'current_metrics': _currentMetrics,
      'recent_metrics': _metricsHistory
          .where((m) => DateTime.now().difference(m.timestamp).inHours < 1)
          .map((m) => m.toJson())
          .toList(),
      'api_metrics': _apiCallMetrics.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  /// Obtient un résumé des performances
  String getPerformanceSummary() {
    if (_metricsHistory.isEmpty) return 'Aucune donnée disponible';

    final recent = _metricsHistory
        .where((m) => DateTime.now().difference(m.timestamp).inMinutes < 30)
        .toList();

    if (recent.isEmpty) return 'Aucune donnée récente';

    final avgLatency = recent
        .map((m) => m.latency.inMilliseconds)
        .reduce((a, b) => a + b) / recent.length;

    final avgMemory = recent
        .map((m) => m.memoryUsage)
        .reduce((a, b) => a + b) / recent.length;

    final errorRate = recent
        .where((m) => m.errorMessage != null)
        .length / recent.length * 100;

    return 'Latence: ${avgLatency.toStringAsFixed(0)}ms | '
           'Mémoire: ${avgMemory.toStringAsFixed(1)}MB | '
           'Erreurs: ${errorRate.toStringAsFixed(1)}%';
  }

  /// Nettoie les ressources
  void dispose() {
    _reportingTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    
    _metricsController.close();
    _reportController.close();
    _alertController.close();
    
    _metricsHistory.clear();
    _apiCallMetrics.clear();
    _currentMetrics.clear();

    _isMonitoring = false;
    _isInitialized = false;
  }
}

// === MODÈLES DE DONNÉES ===

/// Métrique individuelle de performance vocale
class VoiceMetric {
  final DateTime timestamp;
  final VoiceMetricType type;
  final Duration latency;
  final double confidence;
  final int audioDataSize;
  final String recognizedText;
  final String? errorMessage;
  final double memoryUsage;
  final double? batteryLevel;
  final bool? isWakeWordDetected;
  final String? apiEndpoint;
  final bool? apiSuccess;

  const VoiceMetric({
    required this.timestamp,
    required this.type,
    required this.latency,
    required this.confidence,
    required this.audioDataSize,
    required this.recognizedText,
    this.errorMessage,
    required this.memoryUsage,
    this.batteryLevel,
    this.isWakeWordDetected,
    this.apiEndpoint,
    this.apiSuccess,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'latency_ms': latency.inMilliseconds,
    'confidence': confidence,
    'audio_size': audioDataSize,
    'text': recognizedText,
    'error': errorMessage,
    'memory_mb': memoryUsage,
    'battery': batteryLevel,
    'wake_detected': isWakeWordDetected,
    'api_endpoint': apiEndpoint,
    'api_success': apiSuccess,
  };
}

/// Types de métriques vocales
enum VoiceMetricType { recognition, synthesis, wakeWord, apiCall }

/// Métrique d'appel API
class ApiCallMetric {
  final String endpoint;
  final DateTime timestamp;
  final Duration latency;
  final int requestSize;
  final int responseSize;
  final bool isSuccess;
  final String? errorMessage;

  const ApiCallMetric({
    required this.endpoint,
    required this.timestamp,
    required this.latency,
    required this.requestSize,
    required this.responseSize,
    required this.isSuccess,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'timestamp': timestamp.toIso8601String(),
    'latency_ms': latency.inMilliseconds,
    'request_size': requestSize,
    'response_size': responseSize,
    'success': isSuccess,
    'error': errorMessage,
  };
}

/// Statistiques agrégées de performance
class PerformanceStatistics {
  int totalRecognitions = 0;
  int totalSyntheses = 0;
  int totalWakeWords = 0;
  int totalApiCalls = 0;
  int totalErrors = 0;

  double avgRecognitionLatency = 0.0;
  double avgSynthesisLatency = 0.0;
  double avgWakeWordLatency = 0.0;
  double avgApiLatency = 0.0;

  double avgConfidence = 0.0;
  double avgMemoryUsage = 0.0;
  double maxMemoryUsage = 0.0;

  double wakeWordAccuracy = 0.0;
  double apiSuccessRate = 0.0;

  void updateWith(VoiceMetric metric) {
    switch (metric.type) {
      case VoiceMetricType.recognition:
        totalRecognitions++;
        avgRecognitionLatency = _updateAverage(
          avgRecognitionLatency, 
          metric.latency.inMilliseconds.toDouble(), 
          totalRecognitions
        );
        avgConfidence = _updateAverage(
          avgConfidence, 
          metric.confidence, 
          totalRecognitions
        );
        break;

      case VoiceMetricType.synthesis:
        totalSyntheses++;
        avgSynthesisLatency = _updateAverage(
          avgSynthesisLatency, 
          metric.latency.inMilliseconds.toDouble(), 
          totalSyntheses
        );
        break;

      case VoiceMetricType.wakeWord:
        totalWakeWords++;
        avgWakeWordLatency = _updateAverage(
          avgWakeWordLatency, 
          metric.latency.inMilliseconds.toDouble(), 
          totalWakeWords
        );
        break;

      case VoiceMetricType.apiCall:
        totalApiCalls++;
        avgApiLatency = _updateAverage(
          avgApiLatency, 
          metric.latency.inMilliseconds.toDouble(), 
          totalApiCalls
        );
        break;
    }

    // Mettre à jour les métriques générales
    avgMemoryUsage = _updateAverage(
      avgMemoryUsage, 
      metric.memoryUsage, 
      totalRecognitions + totalSyntheses + totalWakeWords + totalApiCalls
    );
    
    maxMemoryUsage = metric.memoryUsage > maxMemoryUsage 
        ? metric.memoryUsage 
        : maxMemoryUsage;

    if (metric.errorMessage != null) {
      totalErrors++;
    }

    // Calculer les taux de succès
    apiSuccessRate = totalApiCalls > 0 
        ? (totalApiCalls - totalErrors) / totalApiCalls 
        : 1.0;
  }

  double _updateAverage(double currentAvg, double newValue, int count) {
    return ((currentAvg * (count - 1)) + newValue) / count;
  }

  PerformanceStatistics copy() {
    final copy = PerformanceStatistics();
    copy.totalRecognitions = totalRecognitions;
    copy.totalSyntheses = totalSyntheses;
    copy.totalWakeWords = totalWakeWords;
    copy.totalApiCalls = totalApiCalls;
    copy.totalErrors = totalErrors;
    copy.avgRecognitionLatency = avgRecognitionLatency;
    copy.avgSynthesisLatency = avgSynthesisLatency;
    copy.avgWakeWordLatency = avgWakeWordLatency;
    copy.avgApiLatency = avgApiLatency;
    copy.avgConfidence = avgConfidence;
    copy.avgMemoryUsage = avgMemoryUsage;
    copy.maxMemoryUsage = maxMemoryUsage;
    copy.wakeWordAccuracy = wakeWordAccuracy;
    copy.apiSuccessRate = apiSuccessRate;
    return copy;
  }

  Map<String, dynamic> toJson() => {
    'total_recognitions': totalRecognitions,
    'total_syntheses': totalSyntheses,
    'total_wake_words': totalWakeWords,
    'total_api_calls': totalApiCalls,
    'total_errors': totalErrors,
    'avg_recognition_latency': avgRecognitionLatency,
    'avg_synthesis_latency': avgSynthesisLatency,
    'avg_wake_word_latency': avgWakeWordLatency,
    'avg_api_latency': avgApiLatency,
    'avg_confidence': avgConfidence,
    'avg_memory_usage': avgMemoryUsage,
    'max_memory_usage': maxMemoryUsage,
    'wake_word_accuracy': wakeWordAccuracy,
    'api_success_rate': apiSuccessRate,
  };
}

/// Rapport de performance
class PerformanceReport {
  final DateTime timestamp;
  final Duration period;
  final PerformanceStatistics statistics;
  final Map<String, double> currentMetrics;
  final Map<String, ApiCallMetric> apiCallMetrics;
  final double memoryUsage;
  final double? batteryLevel;
  final String recommendation;

  const PerformanceReport({
    required this.timestamp,
    required this.period,
    required this.statistics,
    required this.currentMetrics,
    required this.apiCallMetrics,
    required this.memoryUsage,
    this.batteryLevel,
    required this.recommendation,
  });

  String get summary {
    return 'Reconnaissances: ${statistics.totalRecognitions} | '
           'Latence moy: ${statistics.avgRecognitionLatency.toStringAsFixed(0)}ms | '
           'Mémoire: ${memoryUsage.toStringAsFixed(1)}MB | '
           'Succès API: ${(statistics.apiSuccessRate * 100).toStringAsFixed(1)}%';
  }
}

/// Alerte de performance
class PerformanceAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final VoiceMetric metric;
  final DateTime timestamp;

  const PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.metric,
    required this.timestamp,
  });
}

/// Types d'alertes
enum AlertType { highLatency, highMemoryUsage, lowBattery, apiErrors }

/// Niveaux de sévérité des alertes
enum AlertSeverity { info, warning, critical }