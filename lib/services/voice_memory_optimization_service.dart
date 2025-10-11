import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'voice_performance_monitoring_service.dart';
import 'audio_buffer_optimization_service.dart';

/// Service d'optimisation mémoire pour le traitement vocal
/// Implémente le pooling d'objets, la gestion des streams et les hints GC
class VoiceMemoryOptimizationService {
  static final VoiceMemoryOptimizationService _instance =
      VoiceMemoryOptimizationService._internal();
  factory VoiceMemoryOptimizationService() => _instance;
  VoiceMemoryOptimizationService._internal();

  // Configuration
  static const int _maxObjectPoolSize = 100;
  static const int _maxStreamBufferSize = 50;
  static const Duration _gcHintInterval = Duration(seconds: 30);
  static const Duration _memoryAnalysisInterval = Duration(seconds: 10);
  static const double _memoryPressureThreshold = 0.85; // 85%

  // État du service
  bool _isInitialized = false;
  bool _isOptimizing = false;
  Timer? _gcTimer;
  Timer? _analysisTimer;

  // Services dépendants
  late VoicePerformanceMonitoringService _performanceService;
  late AudioBufferOptimizationService _bufferService;

  // Pools d'objets réutilisables
  final Queue<_VoiceRecognitionContext> _recognitionContextPool = Queue();
  final Queue<_AudioProcessingContext> _audioContextPool = Queue();
  final Queue<_SpeechSynthesisContext> _synthesisContextPool = Queue();
  final Queue<List<double>> _doubleListPool = Queue();
  final Queue<List<int>> _intListPool = Queue();

  // Gestion des streams
  final Map<String, _StreamManager> _activeStreams = {};
  final Queue<StreamSubscription> _subscriptionPool = Queue();

  // Statistiques mémoire
  double _baselineMemoryUsage = 0.0;
  double _currentMemoryUsage = 0.0;
  double _peakMemoryUsage = 0.0;
  int _totalObjectsPooled = 0;
  int _totalObjectsReused = 0;
  int _gcHintsIssued = 0;
  int _memoryOptimizationsPerformed = 0;

  // Historique de la mémoire
  final Queue<MemorySnapshot> _memoryHistory = Queue();
  static const int _memoryHistorySize = 60; // 10 minutes à 10s par échantillon

  // Accesseurs publics
  bool get isInitialized => _isInitialized;
  bool get isOptimizing => _isOptimizing;
  double get memoryEfficiency => _baselineMemoryUsage > 0 
      ? 1.0 - ((_currentMemoryUsage - _baselineMemoryUsage) / _baselineMemoryUsage)
      : 0.0;
  double get objectReuseRatio => _totalObjectsPooled > 0 
      ? _totalObjectsReused / _totalObjectsPooled 
      : 0.0;

  Map<String, dynamic> get statistics => {
    'baseline_memory_mb': _baselineMemoryUsage,
    'current_memory_mb': _currentMemoryUsage,
    'peak_memory_mb': _peakMemoryUsage,
    'memory_efficiency': memoryEfficiency,
    'total_objects_pooled': _totalObjectsPooled,
    'total_objects_reused': _totalObjectsReused,
    'object_reuse_ratio': objectReuseRatio,
    'gc_hints_issued': _gcHintsIssued,
    'optimizations_performed': _memoryOptimizationsPerformed,
    'active_streams': _activeStreams.length,
    'pooled_contexts': _recognitionContextPool.length + 
                      _audioContextPool.length + 
                      _synthesisContextPool.length,
  };

  /// Initialise le service d'optimisation mémoire
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation Voice Memory Optimization Service...');

      // Initialiser les services dépendants
      _performanceService = VoicePerformanceMonitoringService();
      _bufferService = AudioBufferOptimizationService();

      // Prendre une mesure baseline de la mémoire
      await _establishMemoryBaseline();

      // Pré-allouer les pools d'objets
      _preAllocateObjectPools();

      // Démarrer les timers d'optimisation
      _startOptimizationTimers();

      _isInitialized = true;
      debugPrint('Voice Memory Optimization Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation memory optimization service: $e');
      rethrow;
    }
  }

  /// Démarre l'optimisation mémoire
  Future<void> startOptimization() async {
    if (!_isInitialized || _isOptimizing) return;

    try {
      _isOptimizing = true;
      debugPrint('Optimisation mémoire vocale démarrée');

      // Effectuer une optimisation initiale
      await _performImmediateOptimization();

    } catch (e) {
      _isOptimizing = false;
      debugPrint('Erreur démarrage optimisation mémoire: $e');
      rethrow;
    }
  }

  /// Arrête l'optimisation mémoire
  void stopOptimization() {
    if (!_isOptimizing) return;

    _isOptimizing = false;
    debugPrint('Optimisation mémoire arrêtée');
  }

  /// Établit la baseline mémoire
  Future<void> _establishMemoryBaseline() async {
    // Effectuer un GC avant la mesure
    if (kDebugMode) {
      developer.Service.gc();
    }

    // Attendre la stabilisation
    await Future.delayed(const Duration(milliseconds: 500));

    // Mesurer la mémoire baseline
    _baselineMemoryUsage = _getCurrentMemoryUsage();
    _currentMemoryUsage = _baselineMemoryUsage;
    
    debugPrint('Baseline mémoire établie: ${_baselineMemoryUsage.toStringAsFixed(1)} MB');
  }

  /// Pré-alloue les pools d'objets
  void _preAllocateObjectPools() {
    // Pré-allouer les contextes de reconnaissance
    for (int i = 0; i < 10; i++) {
      _recognitionContextPool.add(_VoiceRecognitionContext());
    }

    // Pré-allouer les contextes audio
    for (int i = 0; i < 15; i++) {
      _audioContextPool.add(_AudioProcessingContext());
    }

    // Pré-allouer les contextes de synthèse
    for (int i = 0; i < 5; i++) {
      _synthesisContextPool.add(_SpeechSynthesisContext());
    }

    // Pré-allouer des listes réutilisables
    for (int i = 0; i < 20; i++) {
      _doubleListPool.add(<double>[]);
      _intListPool.add(<int>[]);
    }

    debugPrint('Pools d\'objets pré-alloués');
  }

  /// Démarre les timers d'optimisation
  void _startOptimizationTimers() {
    // Timer pour les hints GC
    _gcTimer = Timer.periodic(_gcHintInterval, _performGarbageCollectionHint);

    // Timer pour l'analyse mémoire
    _analysisTimer = Timer.periodic(_memoryAnalysisInterval, _performMemoryAnalysis);
  }

  /// Obtient un contexte de reconnaissance vocal du pool
  _VoiceRecognitionContext getRecognitionContext() {
    _VoiceRecognitionContext context;
    
    if (_recognitionContextPool.isNotEmpty) {
      context = _recognitionContextPool.removeFirst();
      _totalObjectsReused++;
    } else {
      context = _VoiceRecognitionContext();
      _totalObjectsPooled++;
    }

    context.reset();
    return context;
  }

  /// Retourne un contexte de reconnaissance au pool
  void returnRecognitionContext(_VoiceRecognitionContext context) {
    if (_recognitionContextPool.length < _maxObjectPoolSize) {
      context.clear();
      _recognitionContextPool.add(context);
    }
  }

  /// Obtient un contexte de traitement audio du pool
  _AudioProcessingContext getAudioContext() {
    _AudioProcessingContext context;
    
    if (_audioContextPool.isNotEmpty) {
      context = _audioContextPool.removeFirst();
      _totalObjectsReused++;
    } else {
      context = _AudioProcessingContext();
      _totalObjectsPooled++;
    }

    context.reset();
    return context;
  }

  /// Retourne un contexte audio au pool
  void returnAudioContext(_AudioProcessingContext context) {
    if (_audioContextPool.length < _maxObjectPoolSize) {
      context.clear();
      _audioContextPool.add(context);
    }
  }

  /// Obtient un contexte de synthèse vocale du pool
  _SpeechSynthesisContext getSynthesisContext() {
    _SpeechSynthesisContext context;
    
    if (_synthesisContextPool.isNotEmpty) {
      context = _synthesisContextPool.removeFirst();
      _totalObjectsReused++;
    } else {
      context = _SpeechSynthesisContext();
      _totalObjectsPooled++;
    }

    context.reset();
    return context;
  }

  /// Retourne un contexte de synthèse au pool
  void returnSynthesisContext(_SpeechSynthesisContext context) {
    if (_synthesisContextPool.length < _maxObjectPoolSize) {
      context.clear();
      _synthesisContextPool.add(context);
    }
  }

  /// Obtient une liste double réutilisable
  List<double> getDoubleList() {
    if (_doubleListPool.isNotEmpty) {
      final list = _doubleListPool.removeFirst();
      list.clear();
      _totalObjectsReused++;
      return list;
    } else {
      _totalObjectsPooled++;
      return <double>[];
    }
  }

  /// Retourne une liste double au pool
  void returnDoubleList(List<double> list) {
    if (_doubleListPool.length < _maxObjectPoolSize) {
      list.clear();
      _doubleListPool.add(list);
    }
  }

  /// Obtient une liste int réutilisable
  List<int> getIntList() {
    if (_intListPool.isNotEmpty) {
      final list = _intListPool.removeFirst();
      list.clear();
      _totalObjectsReused++;
      return list;
    } else {
      _totalObjectsPooled++;
      return <int>[];
    }
  }

  /// Retourne une liste int au pool
  void returnIntList(List<int> list) {
    if (_intListPool.length < _maxObjectPoolSize) {
      list.clear();
      _intListPool.add(list);
    }
  }

  /// Gère un stream de façon optimisée
  StreamSubscription<T> manageStream<T>(
    Stream<T> stream,
    void Function(T) onData, {
    String? streamId,
    void Function(Object)? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    streamId ??= 'stream_${_activeStreams.length}';

    // Créer le manager de stream
    final manager = _StreamManager<T>(
      streamId: streamId,
      onData: onData,
      onError: onError,
      onDone: onDone,
      bufferSize: _maxStreamBufferSize,
    );

    // Créer la subscription avec gestion des erreurs
    final subscription = stream.listen(
      manager.handleData,
      onError: manager.handleError,
      onDone: () {
        manager.handleDone();
        _activeStreams.remove(streamId);
      },
      cancelOnError: cancelOnError ?? false,
    );

    _activeStreams[streamId] = manager;
    
    debugPrint('Stream géré: $streamId');
    return subscription;
  }

  /// Annule un stream géré
  void cancelManagedStream(String streamId) {
    final manager = _activeStreams.remove(streamId);
    if (manager != null) {
      manager.dispose();
      debugPrint('Stream annulé: $streamId');
    }
  }

  /// Obtient l'usage mémoire actuel
  double _getCurrentMemoryUsage() {
    try {
      // En production, utiliser des métriques réelles
      return developer.Service.memoryUsage['current']?.toDouble() ?? 0.0;
    } catch (e) {
      // Simulation pour développement
      return 50.0 + DateTime.now().millisecondsSinceEpoch % 50;
    }
  }

  /// Effectue une analyse mémoire périodique
  void _performMemoryAnalysis(Timer timer) {
    if (!_isOptimizing) return;

    try {
      // Mesurer l'usage mémoire actuel
      _currentMemoryUsage = _getCurrentMemoryUsage();
      
      // Mettre à jour le pic
      if (_currentMemoryUsage > _peakMemoryUsage) {
        _peakMemoryUsage = _currentMemoryUsage;
      }

      // Créer un snapshot
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        memoryUsage: _currentMemoryUsage,
        objectsPooled: _totalObjectsPooled,
        objectsReused: _totalObjectsReused,
        activeStreams: _activeStreams.length,
      );

      // Ajouter à l'historique
      _memoryHistory.add(snapshot);
      while (_memoryHistory.length > _memoryHistorySize) {
        _memoryHistory.removeFirst();
      }

      // Vérifier si optimisation nécessaire
      _checkMemoryPressure();

      // Émettre les métriques
      _emitMemoryMetrics(snapshot);

    } catch (e) {
      debugPrint('Erreur analyse mémoire: $e');
    }
  }

  /// Vérifie la pression mémoire et agit si nécessaire
  void _checkMemoryPressure() {
    if (_memoryHistory.length < 3) return;

    // Calculer la tendance mémoire
    final recent = _memoryHistory.toList().sublist(_memoryHistory.length - 3);
    final memoryTrend = recent.last.memoryUsage - recent.first.memoryUsage;
    final memoryPressure = _currentMemoryUsage / (_baselineMemoryUsage * 2);

    // Si pression élevée ou tendance croissante rapide
    if (memoryPressure > _memoryPressureThreshold || memoryTrend > 20.0) {
      debugPrint('⚠️ Pression mémoire élevée détectée: ${(memoryPressure * 100).toStringAsFixed(1)}%');
      _performEmergencyOptimization();
    }
  }

  /// Effectue une optimisation d'urgence
  void _performEmergencyOptimization() {
    debugPrint('🚨 Optimisation mémoire d\'urgence...');

    _memoryOptimizationsPerformed++;

    // 1. Nettoyer les pools excessifs
    _cleanupObjectPools();

    // 2. Forcer la libération des buffers
    _bufferService.forceCleanup();

    // 3. Nettoyer les streams inactifs
    _cleanupInactiveStreams();

    // 4. Forcer le garbage collection
    _forceGarbageCollection();

    debugPrint('Optimisation d\'urgence terminée');
  }

  /// Nettoie les pools d'objets
  void _cleanupObjectPools() {
    // Réduire la taille des pools de moitié
    while (_recognitionContextPool.length > _maxObjectPoolSize ~/ 2) {
      _recognitionContextPool.removeFirst();
    }
    
    while (_audioContextPool.length > _maxObjectPoolSize ~/ 2) {
      _audioContextPool.removeFirst();
    }
    
    while (_synthesisContextPool.length > _maxObjectPoolSize ~/ 2) {
      _synthesisContextPool.removeFirst();
    }
    
    while (_doubleListPool.length > _maxObjectPoolSize ~/ 2) {
      _doubleListPool.removeFirst();
    }
    
    while (_intListPool.length > _maxObjectPoolSize ~/ 2) {
      _intListPool.removeFirst();
    }

    debugPrint('Pools d\'objets nettoyés');
  }

  /// Nettoie les streams inactifs
  void _cleanupInactiveStreams() {
    final toRemove = <String>[];
    
    _activeStreams.forEach((id, manager) {
      if (manager.isInactive) {
        toRemove.add(id);
      }
    });

    for (final id in toRemove) {
      cancelManagedStream(id);
    }

    if (toRemove.isNotEmpty) {
      debugPrint('${toRemove.length} streams inactifs nettoyés');
    }
  }

  /// Effectue un hint de garbage collection
  void _performGarbageCollectionHint(Timer timer) {
    if (!_isOptimizing) return;

    // Vérifier si un GC est nécessaire
    if (_shouldPerformGC()) {
      _issueGarbageCollectionHint();
    }
  }

  /// Détermine si un GC est nécessaire
  bool _shouldPerformGC() {
    // Critères pour déclencher un GC
    final memoryIncrease = _currentMemoryUsage - _baselineMemoryUsage;
    final hasHighActivity = _totalObjectsPooled - _totalObjectsReused > 100;
    
    return memoryIncrease > 20.0 || hasHighActivity;
  }

  /// Émet un hint de garbage collection
  void _issueGarbageCollectionHint() {
    if (kDebugMode) {
      developer.Service.gc();
      _gcHintsIssued++;
      debugPrint('🗑️ Hint GC émis (total: $_gcHintsIssued)');
    }
  }

  /// Force un garbage collection immédiat
  void _forceGarbageCollection() {
    if (kDebugMode) {
      developer.Service.gc();
      debugPrint('🗑️ GC forcé');
    }
  }

  /// Effectue une optimisation immédiate
  Future<void> _performImmediateOptimization() async {
    debugPrint('Optimisation mémoire immédiate...');

    // Mesurer avant
    final beforeMemory = _getCurrentMemoryUsage();

    // Nettoyer les pools
    _cleanupObjectPools();

    // Nettoyer les streams
    _cleanupInactiveStreams();

    // Forcer un GC
    _forceGarbageCollection();

    // Attendre la stabilisation
    await Future.delayed(const Duration(milliseconds: 500));

    // Mesurer après
    final afterMemory = _getCurrentMemoryUsage();
    final memoryFreed = beforeMemory - afterMemory;

    debugPrint('Optimisation terminée: ${memoryFreed.toStringAsFixed(1)} MB libérés');
  }

  /// Émet les métriques mémoire
  void _emitMemoryMetrics(MemorySnapshot snapshot) {
    // Enregistrer dans le service de performance
    try {
      _performanceService.currentMetrics['memory_usage'] = snapshot.memoryUsage;
      _performanceService.currentMetrics['memory_efficiency'] = memoryEfficiency;
      _performanceService.currentMetrics['object_reuse_ratio'] = objectReuseRatio;
    } catch (e) {
      // Continuer même en cas d'erreur
    }
  }

  /// Obtient un rapport détaillé de la mémoire
  Map<String, dynamic> getDetailedMemoryReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': statistics,
      'memory_trend': _memoryHistory.length >= 5
          ? _memoryHistory.toList().sublist(_memoryHistory.length - 5)
              .map((s) => s.toJson()).toList()
          : [],
      'pools': {
        'recognition_contexts': _recognitionContextPool.length,
        'audio_contexts': _audioContextPool.length,
        'synthesis_contexts': _synthesisContextPool.length,
        'double_lists': _doubleListPool.length,
        'int_lists': _intListPool.length,
      },
      'streams': {
        'active_count': _activeStreams.length,
        'details': _activeStreams.map((id, manager) => 
            MapEntry(id, manager.getStats())),
      },
      'recommendations': _generateMemoryRecommendations(),
    };
  }

  /// Génère des recommandations d'optimisation mémoire
  List<String> _generateMemoryRecommendations() {
    final recommendations = <String>[];

    // Analyser l'efficacité mémoire
    if (memoryEfficiency < 0.7) {
      recommendations.add('Mémoire inefficace - considérer plus d\'optimisations');
    }

    // Analyser le taux de réutilisation
    if (objectReuseRatio < 0.8) {
      recommendations.add('Faible taux de réutilisation d\'objets - agrandir les pools');
    }

    // Analyser les trends
    if (_memoryHistory.length >= 10) {
      final recentTrend = _memoryHistory.toList().sublist(_memoryHistory.length - 5);
      final memoryIncrease = recentTrend.last.memoryUsage - recentTrend.first.memoryUsage;
      
      if (memoryIncrease > 10.0) {
        recommendations.add('Tendance mémoire croissante - surveillance requise');
      }
    }

    // Analyser les streams
    if (_activeStreams.length > 10) {
      recommendations.add('Nombreux streams actifs - vérifier les fuites');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Optimisation mémoire efficace');
    }

    return recommendations;
  }

  /// Force une optimisation complète
  Future<void> forceOptimization() async {
    debugPrint('🔧 Optimisation mémoire forcée...');
    await _performImmediateOptimization();
  }

  /// Nettoie les ressources
  void dispose() {
    _gcTimer?.cancel();
    _analysisTimer?.cancel();

    // Nettoyer tous les pools
    _recognitionContextPool.clear();
    _audioContextPool.clear();
    _synthesisContextPool.clear();
    _doubleListPool.clear();
    _intListPool.clear();

    // Nettoyer tous les streams
    _activeStreams.values.forEach((manager) => manager.dispose());
    _activeStreams.clear();

    _memoryHistory.clear();

    _isOptimizing = false;
    _isInitialized = false;

    debugPrint('Voice Memory Optimization Service disposé');
  }
}

// === CLASSES INTERNES ===

/// Contexte de reconnaissance vocale réutilisable
class _VoiceRecognitionContext {
  String? recognizedText;
  double confidence = 0.0;
  Duration? latency;
  DateTime? timestamp;
  List<String> alternativeTexts = [];

  void reset() {
    recognizedText = null;
    confidence = 0.0;
    latency = null;
    timestamp = DateTime.now();
    alternativeTexts.clear();
  }

  void clear() {
    recognizedText = null;
    confidence = 0.0;
    latency = null;
    timestamp = null;
    alternativeTexts.clear();
  }
}

/// Contexte de traitement audio réutilisable
class _AudioProcessingContext {
  Uint8List? audioData;
  int sampleRate = 16000;
  int channels = 1;
  double energy = 0.0;
  List<double> features = [];

  void reset() {
    audioData = null;
    sampleRate = 16000;
    channels = 1;
    energy = 0.0;
    features.clear();
  }

  void clear() {
    audioData = null;
    sampleRate = 16000;
    channels = 1;
    energy = 0.0;
    features.clear();
  }
}

/// Contexte de synthèse vocale réutilisable
class _SpeechSynthesisContext {
  String? textToSpeak;
  String? voiceId;
  double speed = 1.0;
  double pitch = 1.0;
  Uint8List? audioOutput;

  void reset() {
    textToSpeak = null;
    voiceId = null;
    speed = 1.0;
    pitch = 1.0;
    audioOutput = null;
  }

  void clear() {
    textToSpeak = null;
    voiceId = null;
    speed = 1.0;
    pitch = 1.0;
    audioOutput = null;
  }
}

/// Manager de stream optimisé
class _StreamManager<T> {
  final String streamId;
  final void Function(T) onData;
  final void Function(Object)? onError;
  final void Function()? onDone;
  final int bufferSize;

  final Queue<T> _buffer = Queue();
  DateTime _lastActivity = DateTime.now();
  int _dataCount = 0;
  int _errorCount = 0;

  _StreamManager({
    required this.streamId,
    required this.onData,
    this.onError,
    this.onDone,
    required this.bufferSize,
  });

  void handleData(T data) {
    _lastActivity = DateTime.now();
    _dataCount++;

    // Ajouter au buffer si nécessaire
    if (_buffer.length >= bufferSize) {
      _buffer.removeFirst();
    }
    _buffer.add(data);

    // Traiter les données
    try {
      onData(data);
    } catch (e) {
      handleError(e);
    }
  }

  void handleError(Object error) {
    _errorCount++;
    if (onError != null) {
      onError!(error);
    }
  }

  void handleDone() {
    if (onDone != null) {
      onDone!();
    }
  }

  bool get isInactive {
    return DateTime.now().difference(_lastActivity).inMinutes > 5;
  }

  Map<String, dynamic> getStats() {
    return {
      'data_count': _dataCount,
      'error_count': _errorCount,
      'buffer_size': _buffer.length,
      'last_activity': _lastActivity.toIso8601String(),
      'is_inactive': isInactive,
    };
  }

  void dispose() {
    _buffer.clear();
  }
}

/// Snapshot de l'état mémoire
class MemorySnapshot {
  final DateTime timestamp;
  final double memoryUsage;
  final int objectsPooled;
  final int objectsReused;
  final int activeStreams;

  const MemorySnapshot({
    required this.timestamp,
    required this.memoryUsage,
    required this.objectsPooled,
    required this.objectsReused,
    required this.activeStreams,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'memory_usage': memoryUsage,
    'objects_pooled': objectsPooled,
    'objects_reused': objectsReused,
    'active_streams': activeStreams,
  };
}