import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'azure_wake_word_service.dart';
import 'voice_performance_monitoring_service.dart';
import 'audio_buffer_optimization_service.dart';

/// Service de détection intelligente de mots déclencheurs avec pré-filtrage local
/// et détection basée sur l'énergie pour réduire les faux positifs
class SmartWakeWordDetectionService {
  static final SmartWakeWordDetectionService _instance =
      SmartWakeWordDetectionService._internal();
  factory SmartWakeWordDetectionService() => _instance;
  SmartWakeWordDetectionService._internal();

  // Configuration
  static const List<String> _targetWakeWords = [
    'rick', 'ric', 'hey rick', 'salut rick'
  ];
  
  // Seuils adaptatifs
  double _energyThreshold = 0.3;
  double _confidenceThreshold = 0.65;
  double _noiseFloor = 0.1;
  
  // Configuration du pré-filtrage
  static const int _preFilterWindowSize = 1024; // Taille fenêtre audio
  static const int _sampleRate = 16000; // 16kHz
  static const Duration _silenceTimeout = Duration(seconds: 5);
  static const Duration _wakeWordTimeout = Duration(seconds: 2);

  // État du service
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isPreFilteringEnabled = true;
  bool _isAdaptiveThresholding = true;

  // Services dépendants
  late AzureWakeWordService _azureService;
  late VoicePerformanceMonitoringService _performanceService;
  late AudioBufferOptimizationService _bufferService;

  // Buffers et analyse audio
  final List<double> _audioBuffer = [];
  final List<double> _energyHistory = [];
  static const int _energyHistorySize = 50;

  // Détection d'activité vocale (VAD)
  bool _speechActivityDetected = false;
  DateTime _lastSpeechActivity = DateTime.now();
  Timer? _silenceTimer;

  // Statistiques et apprentissage
  int _totalDetections = 0;
  int _falsePositives = 0;
  int _truePositives = 0;
  final List<double> _recentConfidences = [];
  static const int _confidenceHistorySize = 20;

  // Controllers pour les streams
  final StreamController<SmartWakeWordResult> _detectionController =
      StreamController.broadcast();
  final StreamController<VoiceActivityDetection> _vadController =
      StreamController.broadcast();
  final StreamController<AudioEnergyInfo> _energyController =
      StreamController.broadcast();

  // Streams publics
  Stream<SmartWakeWordResult> get detectionStream => _detectionController.stream;
  Stream<VoiceActivityDetection> get vadStream => _vadController.stream;
  Stream<AudioEnergyInfo> get energyStream => _energyController.stream;

  // Accesseurs publics
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get speechActivityDetected => _speechActivityDetected;
  double get currentEnergyThreshold => _energyThreshold;
  double get currentConfidenceThreshold => _confidenceThreshold;
  double get detectionAccuracy => _totalDetections > 0 
      ? _truePositives / _totalDetections 
      : 0.0;

  Map<String, dynamic> get statistics => {
    'total_detections': _totalDetections,
    'true_positives': _truePositives,
    'false_positives': _falsePositives,
    'accuracy': detectionAccuracy,
    'energy_threshold': _energyThreshold,
    'confidence_threshold': _confidenceThreshold,
    'noise_floor': _noiseFloor,
    'pre_filtering_enabled': _isPreFilteringEnabled,
    'adaptive_thresholding': _isAdaptiveThresholding,
  };

  /// Initialise le service de détection intelligente
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initialisation Smart Wake Word Detection Service...');

      // Initialiser les services dépendants
      _azureService = AzureWakeWordService();
      _performanceService = VoicePerformanceMonitoringService();
      _bufferService = AudioBufferOptimizationService();

      await _azureService.initialize();
      await _performanceService.initialize();
      await _bufferService.initialize();

      // Calibrer les seuils initiaux
      await _calibrateInitialThresholds();

      // Configurer les écouteurs
      _setupAzureServiceListeners();

      _isInitialized = true;
      debugPrint('Smart Wake Word Detection Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation smart wake word service: $e');
      rethrow;
    }
  }

  /// Démarre la détection intelligente
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    try {
      debugPrint('Démarrage détection intelligente wake word...');

      final stopwatch = Stopwatch()..start();

      _isListening = true;
      _lastSpeechActivity = DateTime.now();

      // Démarrer le service Azure
      await _azureService.startListening();

      // Démarrer l'analyse d'énergie audio
      _startEnergyAnalysis();

      // Démarrer la détection d'activité vocale
      _startVoiceActivityDetection();

      stopwatch.stop();

      // Enregistrer les métriques de performance
      _performanceService.recordWakeWordDetectionMetric(
        latency: stopwatch.elapsed,
        confidence: 1.0,
        isDetected: false,
        matchedText: 'start_listening',
      );

      debugPrint('Détection intelligente démarrée en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      _isListening = false;
      debugPrint('Erreur démarrage détection intelligente: $e');
      rethrow;
    }
  }

  /// Arrête la détection intelligente
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;

      // Arrêter le service Azure
      await _azureService.stopListening();

      // Arrêter les timers
      _silenceTimer?.cancel();

      // Nettoyer les buffers
      _audioBuffer.clear();
      _energyHistory.clear();

      debugPrint('Détection intelligente arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt détection intelligente: $e');
    }
  }

  /// Configure les écouteurs du service Azure
  void _setupAzureServiceListeners() {
    // Écouter les détections Azure
    _azureService.detectionStream.listen(_processAzureDetection);

    // Écouter les transcriptions pour analyse
    _azureService.transcriptionStream.listen(_analyzeTranscription);
  }

  /// Traite une détection du service Azure avec filtrage intelligent
  void _processAzureDetection(WakeWordDetectionResult azureResult) {
    if (!_isListening) return;

    final stopwatch = Stopwatch()..start();

    try {
      // Appliquer le pré-filtrage si activé
      if (_isPreFilteringEnabled && !_passesPreFilter(azureResult)) {
        debugPrint('Détection filtrée par pré-filtrage: ${azureResult.matchedText}');
        return;
      }

      // Analyser la confiance avec l'historique
      final adjustedConfidence = _analyzeConfidenceWithHistory(azureResult.confidence);

      // Vérifier les seuils adaptatifs
      if (adjustedConfidence < _confidenceThreshold) {
        debugPrint('Confiance insuffisante: $adjustedConfidence < $_confidenceThreshold');
        return;
      }

      // Vérifier l'activité vocale
      if (!_speechActivityDetected && _isAdaptiveThresholding) {
        debugPrint('Pas d\'activité vocale détectée, détection ignorée');
        return;
      }

      stopwatch.stop();

      // Créer le résultat intelligent
      final smartResult = SmartWakeWordResult(
        originalResult: azureResult,
        adjustedConfidence: adjustedConfidence,
        energyLevel: _getCurrentEnergyLevel(),
        speechActivity: _speechActivityDetected,
        preFilterPassed: true,
        processingTime: stopwatch.elapsed,
        timestamp: DateTime.now(),
      );

      // Enregistrer les statistiques
      _updateDetectionStatistics(smartResult, true);

      // Enregistrer les métriques de performance
      _performanceService.recordWakeWordDetectionMetric(
        latency: stopwatch.elapsed,
        confidence: adjustedConfidence,
        isDetected: true,
        matchedText: azureResult.matchedText,
      );

      // Émettre la détection
      _detectionController.add(smartResult);

      debugPrint('✅ Wake word intelligent détecté: ${azureResult.matchedText} '
                '(conf: ${adjustedConfidence.toStringAsFixed(2)}, '
                'énergie: ${smartResult.energyLevel.toStringAsFixed(2)})');

    } catch (e) {
      debugPrint('Erreur traitement détection Azure: $e');
    }
  }

  /// Applique le pré-filtrage sur une détection
  bool _passesPreFilter(WakeWordDetectionResult result) {
    // Filtre 1: Vérifier la longueur du texte
    if (result.matchedText.length < 2) {
      return false;
    }

    // Filtre 2: Vérifier la correspondance avec les mots cibles
    final normalizedText = result.matchedText.toLowerCase().trim();
    final matchesTarget = _targetWakeWords.any(
      (word) => normalizedText.contains(word) || _fuzzyMatch(normalizedText, word)
    );

    if (!matchesTarget) {
      return false;
    }

    // Filtre 3: Vérifier l'intervalle depuis la dernière détection
    final timeSinceLastDetection = DateTime.now().difference(_lastSpeechActivity);
    if (timeSinceLastDetection < const Duration(milliseconds: 500)) {
      return false; // Trop rapide, probablement un écho
    }

    // Filtre 4: Vérifier l'énergie audio si disponible
    final currentEnergy = _getCurrentEnergyLevel();
    if (currentEnergy < _noiseFloor) {
      return false; // Énergie trop faible
    }

    return true;
  }

  /// Effectue une correspondance floue simple
  bool _fuzzyMatch(String text, String target) {
    if (text.length < target.length - 2) return false;
    
    // Calculer la similarité (algorithme simple)
    int matches = 0;
    int minLength = min(text.length, target.length);
    
    for (int i = 0; i < minLength; i++) {
      if (i < text.length && i < target.length && text[i] == target[i]) {
        matches++;
      }
    }
    
    return matches / minLength > 0.7; // 70% de similarité
  }

  /// Analyse la confiance avec l'historique
  double _analyzeConfidenceWithHistory(double rawConfidence) {
    _recentConfidences.add(rawConfidence);
    
    // Limiter la taille de l'historique
    while (_recentConfidences.length > _confidenceHistorySize) {
      _recentConfidences.removeAt(0);
    }

    if (_recentConfidences.length < 3) {
      return rawConfidence; // Pas assez d'historique
    }

    // Calculer la moyenne pondérée (plus de poids aux valeurs récentes)
    double weightedSum = 0.0;
    double weightSum = 0.0;

    for (int i = 0; i < _recentConfidences.length; i++) {
      final weight = (i + 1) / _recentConfidences.length; // Poids croissant
      weightedSum += _recentConfidences[i] * weight;
      weightSum += weight;
    }

    final avgConfidence = weightedSum / weightSum;

    // Ajuster la confiance actuelle basée sur la tendance
    if (rawConfidence > avgConfidence * 1.2) {
      // Confiance anormalement élevée, la réduire légèrement
      return rawConfidence * 0.9;
    } else if (rawConfidence < avgConfidence * 0.8) {
      // Confiance anormalement faible, l'ajuster
      return max(rawConfidence, avgConfidence * 0.8);
    }

    return rawConfidence;
  }

  /// Démarre l'analyse d'énergie audio
  void _startEnergyAnalysis() {
    // Simuler l'analyse d'énergie audio
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final energy = _calculateCurrentEnergyLevel();
      _updateEnergyHistory(energy);
      
      // Adapter les seuils si nécessaire
      if (_isAdaptiveThresholding) {
        _adaptThresholds();
      }

      // Émettre l'info d'énergie
      _energyController.add(AudioEnergyInfo(
        level: energy,
        threshold: _energyThreshold,
        noiseFloor: _noiseFloor,
        timestamp: DateTime.now(),
      ));
    });
  }

  /// Calcule le niveau d'énergie audio actuel
  double _calculateCurrentEnergyLevel() {
    // Simulation d'analyse d'énergie audio réelle
    // En pratique, ceci analyserait le signal audio en temps réel
    
    final random = Random();
    final baseEnergy = 0.2 + random.nextDouble() * 0.3; // 0.2-0.5
    
    // Simuler des pics d'énergie vocale
    if (random.nextBool() && random.nextDouble() > 0.7) {
      return baseEnergy + random.nextDouble() * 0.4; // Pic d'énergie
    }
    
    return baseEnergy;
  }

  /// Met à jour l'historique d'énergie
  void _updateEnergyHistory(double energy) {
    _energyHistory.add(energy);
    
    // Limiter la taille de l'historique
    while (_energyHistory.length > _energyHistorySize) {
      _energyHistory.removeAt(0);
    }
  }

  /// Obtient le niveau d'énergie actuel
  double _getCurrentEnergyLevel() {
    return _energyHistory.isNotEmpty ? _energyHistory.last : 0.0;
  }

  /// Démarre la détection d'activité vocale
  void _startVoiceActivityDetection() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }

      final currentEnergy = _getCurrentEnergyLevel();
      final wasActive = _speechActivityDetected;
      
      // Détecter l'activité vocale basée sur l'énergie
      _speechActivityDetected = currentEnergy > _energyThreshold;

      if (_speechActivityDetected) {
        _lastSpeechActivity = DateTime.now();
        _resetSilenceTimer();
      } else if (wasActive && !_speechActivityDetected) {
        _startSilenceTimer();
      }

      // Émettre les changements d'état VAD
      if (wasActive != _speechActivityDetected) {
        _vadController.add(VoiceActivityDetection(
          isActive: _speechActivityDetected,
          energyLevel: currentEnergy,
          timestamp: DateTime.now(),
        ));
        
        debugPrint('VAD: ${_speechActivityDetected ? "Activité" : "Silence"} '
                  '(énergie: ${currentEnergy.toStringAsFixed(3)})');
      }
    });
  }

  /// Démarre le timer de silence
  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, () {
      if (!_speechActivityDetected) {
        debugPrint('Timeout de silence atteint');
        // Optionnellement arrêter l'écoute ou adapter les seuils
      }
    });
  }

  /// Réinitialise le timer de silence
  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
  }

  /// Adapte les seuils automatiquement
  void _adaptThresholds() {
    if (_energyHistory.length < 10) return;

    // Calculer le niveau de bruit de fond
    final sortedEnergy = List<double>.from(_energyHistory)..sort();
    final medianEnergy = sortedEnergy[sortedEnergy.length ~/ 2];
    
    // Adapter le seuil de bruit
    _noiseFloor = medianEnergy * 0.8;
    
    // Adapter le seuil d'énergie
    final energyVariance = _calculateEnergyVariance();
    if (energyVariance > 0.1) {
      // Environnement bruyant, augmenter le seuil
      _energyThreshold = max(_noiseFloor * 2.0, _energyThreshold * 1.1);
    } else {
      // Environnement calme, réduire le seuil
      _energyThreshold = max(_noiseFloor * 1.5, _energyThreshold * 0.95);
    }

    // Limiter les seuils
    _energyThreshold = _energyThreshold.clamp(0.1, 0.8);
    _noiseFloor = _noiseFloor.clamp(0.05, 0.4);
  }

  /// Calcule la variance de l'énergie
  double _calculateEnergyVariance() {
    if (_energyHistory.length < 5) return 0.0;

    final mean = _energyHistory.reduce((a, b) => a + b) / _energyHistory.length;
    final variance = _energyHistory
        .map((e) => pow(e - mean, 2))
        .reduce((a, b) => a + b) / _energyHistory.length;
    
    return variance;
  }

  /// Calibre les seuils initiaux
  Future<void> _calibrateInitialThresholds() async {
    debugPrint('Calibrage des seuils initiaux...');
    
    // Simulation d'un calibrage en mesurant l'environnement audio
    await Future.delayed(const Duration(milliseconds: 500));
    
    // En pratique, on analyserait quelques secondes d'audio ambiant
    _noiseFloor = 0.15; // Niveau de bruit typique
    _energyThreshold = _noiseFloor * 2.5; // Seuil initial
    _confidenceThreshold = 0.65; // Seuil de confiance initial
    
    debugPrint('Seuils calibrés - Bruit: $_noiseFloor, '
              'Énergie: $_energyThreshold, Confiance: $_confidenceThreshold');
  }

  /// Analyse une transcription pour apprentissage
  void _analyzeTranscription(String transcription) {
    // Utiliser les transcriptions pour améliorer la détection
    final normalizedText = transcription.toLowerCase().trim();
    
    // Vérifier si c'est un faux positif
    final containsWakeWord = _targetWakeWords.any(
      (word) => normalizedText.contains(word)
    );
    
    if (!containsWakeWord && normalizedText.isNotEmpty) {
      // Possible faux positif
      _updateDetectionStatistics(null, false);
      debugPrint('Possible faux positif détecté: "$transcription"');
    }
  }

  /// Met à jour les statistiques de détection
  void _updateDetectionStatistics(SmartWakeWordResult? result, bool isTruePositive) {
    _totalDetections++;
    
    if (isTruePositive) {
      _truePositives++;
    } else {
      _falsePositives++;
    }

    // Adapter les seuils basés sur les performances
    if (_totalDetections % 10 == 0) {
      _adaptThresholdsBasedOnAccuracy();
    }
  }

  /// Adapte les seuils basés sur l'exactitude
  void _adaptThresholdsBasedOnAccuracy() {
    if (_totalDetections < 10) return;

    final accuracy = detectionAccuracy;
    
    if (accuracy < 0.8) {
      // Exactitude faible, augmenter les seuils
      _confidenceThreshold = min(0.9, _confidenceThreshold * 1.05);
      _energyThreshold = min(0.8, _energyThreshold * 1.1);
      
      debugPrint('Seuils augmentés pour améliorer l\'exactitude: '
                'conf=${_confidenceThreshold.toStringAsFixed(2)}, '
                'énergie=${_energyThreshold.toStringAsFixed(2)}');
    } else if (accuracy > 0.95) {
      // Très bonne exactitude, réduire légèrement les seuils
      _confidenceThreshold = max(0.4, _confidenceThreshold * 0.98);
      _energyThreshold = max(0.1, _energyThreshold * 0.95);
      
      debugPrint('Seuils réduits pour plus de sensibilité: '
                'conf=${_confidenceThreshold.toStringAsFixed(2)}, '
                'énergie=${_energyThreshold.toStringAsFixed(2)}');
    }
  }

  /// Configure la sensibilité
  void setSensitivity(double sensitivity) {
    sensitivity = sensitivity.clamp(0.0, 1.0);
    
    // Ajuster les seuils basés sur la sensibilité
    _confidenceThreshold = 0.9 - (sensitivity * 0.5); // 0.4 à 0.9
    _energyThreshold = 0.6 - (sensitivity * 0.4); // 0.2 à 0.6
    
    debugPrint('Sensibilité configurée: ${(sensitivity * 100).toStringAsFixed(0)}% '
              '(conf: ${_confidenceThreshold.toStringAsFixed(2)}, '
              'énergie: ${_energyThreshold.toStringAsFixed(2)})');
  }

  /// Active/désactive le pré-filtrage
  void setPreFiltering(bool enabled) {
    _isPreFilteringEnabled = enabled;
    debugPrint('Pré-filtrage: ${enabled ? "activé" : "désactivé"}');
  }

  /// Active/désactive les seuils adaptatifs
  void setAdaptiveThresholding(bool enabled) {
    _isAdaptiveThresholding = enabled;
    debugPrint('Seuils adaptatifs: ${enabled ? "activés" : "désactivés"}');
  }

  /// Force une recalibration
  Future<void> recalibrate() async {
    debugPrint('Recalibration forcée...');
    
    // Réinitialiser les statistiques
    _totalDetections = 0;
    _truePositives = 0;
    _falsePositives = 0;
    _recentConfidences.clear();
    _energyHistory.clear();
    
    // Recalibrer les seuils
    await _calibrateInitialThresholds();
    
    debugPrint('Recalibration terminée');
  }

  /// Obtient un rapport détaillé
  Map<String, dynamic> getDetailedReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'statistics': statistics,
      'thresholds': {
        'energy': _energyThreshold,
        'confidence': _confidenceThreshold,
        'noise_floor': _noiseFloor,
      },
      'current_state': {
        'listening': _isListening,
        'speech_activity': _speechActivityDetected,
        'current_energy': _getCurrentEnergyLevel(),
      },
      'history': {
        'recent_confidences': _recentConfidences,
        'energy_history': _energyHistory.length > 10 
            ? _energyHistory.sublist(_energyHistory.length - 10)
            : _energyHistory,
      },
      'configuration': {
        'pre_filtering': _isPreFilteringEnabled,
        'adaptive_thresholding': _isAdaptiveThresholding,
        'target_wake_words': _targetWakeWords,
      }
    };
  }

  /// Nettoie les ressources
  void dispose() {
    _silenceTimer?.cancel();
    
    _detectionController.close();
    _vadController.close();
    _energyController.close();
    
    _audioBuffer.clear();
    _energyHistory.clear();
    _recentConfidences.clear();
    
    _isListening = false;
    _isInitialized = false;
    
    debugPrint('Smart Wake Word Detection Service disposé');
  }
}

// === MODÈLES DE DONNÉES ===

/// Résultat de détection intelligente
class SmartWakeWordResult {
  final WakeWordDetectionResult originalResult;
  final double adjustedConfidence;
  final double energyLevel;
  final bool speechActivity;
  final bool preFilterPassed;
  final Duration processingTime;
  final DateTime timestamp;

  const SmartWakeWordResult({
    required this.originalResult,
    required this.adjustedConfidence,
    required this.energyLevel,
    required this.speechActivity,
    required this.preFilterPassed,
    required this.processingTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'original_confidence': originalResult.confidence,
    'adjusted_confidence': adjustedConfidence,
    'energy_level': energyLevel,
    'speech_activity': speechActivity,
    'pre_filter_passed': preFilterPassed,
    'processing_time_ms': processingTime.inMilliseconds,
    'matched_text': originalResult.matchedText,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Détection d'activité vocale
class VoiceActivityDetection {
  final bool isActive;
  final double energyLevel;
  final DateTime timestamp;

  const VoiceActivityDetection({
    required this.isActive,
    required this.energyLevel,
    required this.timestamp,
  });
}

/// Information d'énergie audio
class AudioEnergyInfo {
  final double level;
  final double threshold;
  final double noiseFloor;
  final DateTime timestamp;

  const AudioEnergyInfo({
    required this.level,
    required this.threshold,
    required this.noiseFloor,
    required this.timestamp,
  });
}