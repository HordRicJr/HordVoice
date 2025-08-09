import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de détection d'émotion dans la voix pour HordVoice IA
/// Fonctionnalité 4: Détection d'émotion dans la voix
/// Service spécialisé pour l'analyse vocale temps réel
class VoiceEmotionDetectionService {
  static final VoiceEmotionDetectionService _instance =
      VoiceEmotionDetectionService._internal();
  factory VoiceEmotionDetectionService() => _instance;
  VoiceEmotionDetectionService._internal();

  // État du service
  bool _isInitialized = false;
  bool _realTimeDetectionEnabled = false;

  // Configuration de détection vocale
  VoiceDetectionConfig _config = VoiceDetectionConfig.defaultConfig();

  // Données de détection
  final List<VoiceEmotionDetection> _detectionHistory = [];
  final List<VoiceAudioFeatures> _voiceFeatures = [];
  VoiceEmotionProfile? _userVoiceProfile;

  // Timers et streams pour détection temps réel
  Timer? _realTimeDetectionTimer;
  Timer? _voiceAnalysisTimer;
  final StreamController<VoiceEmotionDetection> _detectionController =
      StreamController.broadcast();
  final StreamController<VoiceDetectionEvent> _eventController =
      StreamController.broadcast();

  // Getters
  Stream<VoiceEmotionDetection> get detectionStream =>
      _detectionController.stream;
  Stream<VoiceDetectionEvent> get eventStream => _eventController.stream;
  bool get isInitialized => _isInitialized;
  bool get realTimeDetectionEnabled => _realTimeDetectionEnabled;
  VoiceEmotionProfile? get userVoiceProfile => _userVoiceProfile;

  /// Initialise le service de détection vocale d'émotion
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('VoiceEmotionDetectionService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation VoiceEmotionDetectionService...');

      await _loadUserVoiceProfile();
      await _loadDetectionConfig();
      await _initializeVoiceDetectionModels();

      _isInitialized = true;
      debugPrint('VoiceEmotionDetectionService initialisé avec succès');

      _eventController.add(VoiceDetectionEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation VoiceEmotionDetectionService: $e');
      throw Exception(
        'Impossible d\'initialiser la détection vocale d\'émotion: $e',
      );
    }
  }

  /// Initialise les modèles de détection vocale
  Future<void> _initializeVoiceDetectionModels() async {
    // Simulation de l'initialisation des modèles spécialisés voix
    // En réalité, cela chargerait des modèles TensorFlow Lite spécifiques à l'audio
    await Future.delayed(const Duration(milliseconds: 800));
    debugPrint('Modèles de détection vocale d\'émotion initialisés');
  }

  /// Active la détection temps réel sur la voix
  Future<void> enableRealTimeVoiceDetection({
    Duration detectionInterval = const Duration(milliseconds: 150),
    Duration analysisInterval = const Duration(milliseconds: 300),
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _realTimeDetectionEnabled = true;

    // Timer pour la détection rapide (tonalité, volume)
    _realTimeDetectionTimer?.cancel();
    _realTimeDetectionTimer = Timer.periodic(detectionInterval, (_) {
      _performRapidVoiceDetection();
    });

    // Timer pour l'analyse approfondie (spectral, formants)
    _voiceAnalysisTimer?.cancel();
    _voiceAnalysisTimer = Timer.periodic(analysisInterval, (_) {
      _performDeepVoiceAnalysis();
    });

    _eventController.add(VoiceDetectionEvent.realTimeDetectionEnabled());
    debugPrint('Détection vocale d\'émotion temps réel activée');
  }

  /// Désactive la détection temps réel
  void disableRealTimeVoiceDetection() {
    _realTimeDetectionEnabled = false;
    _realTimeDetectionTimer?.cancel();
    _voiceAnalysisTimer?.cancel();

    _eventController.add(VoiceDetectionEvent.realTimeDetectionDisabled());
    debugPrint('Détection vocale d\'émotion temps réel désactivée');
  }

  /// Détecte l'émotion dans un échantillon vocal
  Future<VoiceEmotionDetection> detectVoiceEmotion({
    required List<double> audioSamples,
    required double sampleRate,
    Duration? duration,
    Map<String, dynamic>? voiceContext,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Extraire les caractéristiques vocales spécialisées
      final voiceFeatures = await _extractVoiceFeatures(
        audioSamples,
        sampleRate,
      );

      // Analyser les émotions vocales
      final voiceEmotions = await _analyzeVoiceEmotions(voiceFeatures);

      // Créer le résultat de détection
      final detection = VoiceEmotionDetection(
        voiceEmotions: voiceEmotions,
        voiceFeatures: voiceFeatures,
        overallConfidence: _calculateVoiceConfidence(voiceEmotions),
        timestamp: DateTime.now(),
        duration:
            duration ??
            Duration(
              milliseconds: (audioSamples.length / sampleRate * 1000).round(),
            ),
        voiceContext: voiceContext ?? {},
      );

      // Enregistrer dans l'historique vocal
      _recordVoiceDetection(detection);

      // Émettre le résultat
      _detectionController.add(detection);

      return detection;
    } catch (e) {
      debugPrint('Erreur détection émotion vocale: $e');

      final errorDetection = VoiceEmotionDetection.error(
        'Erreur de détection vocale: $e',
        DateTime.now(),
      );

      _detectionController.add(errorDetection);
      return errorDetection;
    }
  }

  /// Analyse continue d'un stream audio vocal
  Stream<VoiceEmotionDetection> detectEmotionFromVoiceStream(
    Stream<List<double>> voiceStream,
  ) async* {
    if (!_isInitialized) {
      await initialize();
    }

    await for (final voiceChunk in voiceStream) {
      if (voiceChunk.length < _config.minimumVoiceSampleLength) {
        continue; // Ignorer les échantillons vocaux trop courts
      }

      final detection = await detectVoiceEmotion(
        audioSamples: voiceChunk,
        sampleRate: _config.voiceSampleRate,
      );

      yield detection;
    }
  }

  /// Calibre le profil vocal émotionnel de l'utilisateur
  Future<VoiceEmotionProfile> calibrateUserVoiceProfile({
    required List<VoiceCalibrationSample> voiceSamples,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _eventController.add(VoiceDetectionEvent.voiceCalibrationStarted());

      // Analyser les échantillons vocaux de calibration
      final voiceProfileData = <VoiceEmotionType, VoiceCharacteristics>{};

      for (final emotionType in VoiceEmotionType.values) {
        final voiceSamplesForEmotion = voiceSamples
            .where((s) => s.expectedVoiceEmotion == emotionType)
            .toList();

        if (voiceSamplesForEmotion.isNotEmpty) {
          final voiceCharacteristics = await _calculateVoiceCharacteristics(
            voiceSamplesForEmotion,
          );
          voiceProfileData[emotionType] = voiceCharacteristics;
        }
      }

      // Créer le profil vocal utilisateur
      final voiceProfile = VoiceEmotionProfile(
        userId: 'current_user', // TODO: Récupérer l'ID utilisateur réel
        voiceCharacteristics: voiceProfileData,
        calibrationDate: DateTime.now(),
        voiceAccuracy: _calculateVoiceCalibrationAccuracy(voiceSamples),
        voiceSampleCount: voiceSamples.length,
      );

      _userVoiceProfile = voiceProfile;
      await _saveUserVoiceProfile();

      _eventController.add(
        VoiceDetectionEvent.voiceCalibrationCompleted(voiceProfile),
      );
      debugPrint(
        'Profil vocal émotionnel calibré avec ${voiceSamples.length} échantillons',
      );

      return voiceProfile;
    } catch (e) {
      debugPrint('Erreur calibration profil vocal: $e');
      _eventController.add(
        VoiceDetectionEvent.error('Erreur calibration vocale: $e'),
      );
      rethrow;
    }
  }

  /// Obtient les statistiques de détection vocale
  VoiceDetectionStats getVoiceDetectionStats() {
    if (_detectionHistory.isEmpty) {
      return VoiceDetectionStats.empty();
    }

    final voiceEmotionCounts = <VoiceEmotionType, int>{};
    final voiceConfidenceSums = <VoiceEmotionType, double>{};
    final voiceIntensitySums = <VoiceEmotionType, double>{};

    for (final detection in _detectionHistory) {
      for (final voiceEmotion in detection.voiceEmotions) {
        voiceEmotionCounts[voiceEmotion.type] =
            (voiceEmotionCounts[voiceEmotion.type] ?? 0) + 1;
        voiceConfidenceSums[voiceEmotion.type] =
            (voiceConfidenceSums[voiceEmotion.type] ?? 0.0) +
            voiceEmotion.confidence;
        voiceIntensitySums[voiceEmotion.type] =
            (voiceIntensitySums[voiceEmotion.type] ?? 0.0) +
            voiceEmotion.intensity;
      }
    }

    final averageVoiceConfidences = <VoiceEmotionType, double>{};
    final averageVoiceIntensities = <VoiceEmotionType, double>{};

    for (final entry in voiceEmotionCounts.entries) {
      averageVoiceConfidences[entry.key] =
          voiceConfidenceSums[entry.key]! / entry.value;
      averageVoiceIntensities[entry.key] =
          voiceIntensitySums[entry.key]! / entry.value;
    }

    final dominantVoiceEmotion = voiceEmotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return VoiceDetectionStats(
      totalVoiceDetections: _detectionHistory.length,
      voiceEmotionDistribution: voiceEmotionCounts,
      averageVoiceConfidences: averageVoiceConfidences,
      averageVoiceIntensities: averageVoiceIntensities,
      dominantVoiceEmotion: dominantVoiceEmotion,
      detectionTimeSpan: _detectionHistory.isNotEmpty
          ? _detectionHistory.last.timestamp.difference(
              _detectionHistory.first.timestamp,
            )
          : Duration.zero,
    );
  }

  /// Configure les paramètres de détection vocale
  void configureVoiceDetection({
    double? voiceConfidenceThreshold,
    double? voiceIntensityThreshold,
    int? maxVoiceHistorySize,
    bool? enableContextualVoiceAnalysis,
  }) {
    _config = _config.copyWith(
      voiceConfidenceThreshold: voiceConfidenceThreshold,
      voiceIntensityThreshold: voiceIntensityThreshold,
      maxVoiceHistorySize: maxVoiceHistorySize,
      enableContextualVoiceAnalysis: enableContextualVoiceAnalysis,
    );

    _eventController.add(VoiceDetectionEvent.configurationChanged(_config));
    debugPrint('Configuration de détection vocale mise à jour');
  }

  // ==================== MÉTHODES PRIVÉES ====================

  void _performRapidVoiceDetection() {
    // Détection rapide pour feedback immédiat
    if (!_realTimeDetectionEnabled) return;

    // Simuler capture audio en temps réel
    final simulatedVoiceAudio = _generateSimulatedVoiceAudio();

    detectVoiceEmotion(
      audioSamples: simulatedVoiceAudio,
      sampleRate: _config.voiceSampleRate,
    );
  }

  void _performDeepVoiceAnalysis() {
    // Analyse approfondie des caractéristiques vocales
    if (!_realTimeDetectionEnabled || _voiceFeatures.isEmpty) return;

    // Analyser les tendances dans les dernières caractéristiques vocales
    final recentFeatures = _voiceFeatures.take(5).toList();

    if (recentFeatures.length >= 3) {
      _analyzeVoiceTrends(recentFeatures);
    }
  }

  void _analyzeVoiceTrends(List<VoiceAudioFeatures> recentFeatures) {
    // Analyser les tendances temporelles dans la voix
    final pitchTrend = _calculateTrend(
      recentFeatures.map((f) => f.voicePitch).toList(),
    );
    final energyTrend = _calculateTrend(
      recentFeatures.map((f) => f.voiceEnergy).toList(),
    );

    if (pitchTrend > 0.1) {
      debugPrint(
        'Tendance montante détectée dans la voix (excitation possible)',
      );
    } else if (pitchTrend < -0.1) {
      debugPrint(
        'Tendance descendante détectée dans la voix (fatigue possible)',
      );
    }

    if (energyTrend > 0.15) {
      debugPrint(
        'Augmentation d\'énergie vocale détectée (intensité émotionnelle)',
      );
    } else if (energyTrend < -0.15) {
      debugPrint('Diminution d\'énergie vocale détectée (apaisement)');
    }
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;

    double trend = 0.0;
    for (int i = 1; i < values.length; i++) {
      trend += values[i] - values[i - 1];
    }

    return trend / (values.length - 1);
  }

  List<double> _generateSimulatedVoiceAudio() {
    // Générer des échantillons audio vocaux simulés
    final random = Random();
    final samples = <double>[];

    // Simuler des caractéristiques vocales plus réalistes
    for (int i = 0; i < 2048; i++) {
      // Simuler harmoniques vocales
      final fundamental = sin(
        2 * pi * 120 * i / _config.voiceSampleRate,
      ); // 120 Hz fondamentale
      final harmonic2 = sin(2 * pi * 240 * i / _config.voiceSampleRate) * 0.5;
      final harmonic3 = sin(2 * pi * 360 * i / _config.voiceSampleRate) * 0.3;
      final noise = (random.nextDouble() - 0.5) * 0.1;

      samples.add((fundamental + harmonic2 + harmonic3 + noise) * 0.5);
    }

    return samples;
  }

  Future<VoiceAudioFeatures> _extractVoiceFeatures(
    List<double> samples,
    double sampleRate,
  ) async {
    // Extraction de caractéristiques spécialisées pour la voix
    await Future.delayed(
      const Duration(milliseconds: 15),
    ); // Simulation temps de traitement

    final random = Random();

    // Simuler analyse spécialisée vocale
    final voicePitch = _extractFundamentalFrequency(samples);
    final voiceEnergy = _calculateRMSEnergy(samples);
    final voiceShimmer = _calculateShimmer(samples);
    final voiceJitter = _calculateJitter(samples);

    return VoiceAudioFeatures(
      voicePitch: voicePitch,
      voicePitchVariation: random.nextDouble() * 20 + 5,
      voiceEnergy: voiceEnergy,
      voiceEnergyVariation: random.nextDouble() * 0.2,
      voiceSpeechRate: 140 + random.nextDouble() * 40, // 140-180 mots/min
      voiceShimmer: voiceShimmer,
      voiceJitter: voiceJitter,
      voiceHNR: 15 + random.nextDouble() * 10, // Harmonic-to-Noise Ratio
      voiceSpectralCentroid: 1200 + random.nextDouble() * 1000,
      voiceFormants: [
        600 + random.nextDouble() * 200, // F1
        1200 + random.nextDouble() * 400, // F2
        2400 + random.nextDouble() * 400, // F3
      ],
      voiceMFCC: List.generate(13, (_) => random.nextDouble() - 0.5),
      voiceSpectralRolloff: 2500 + random.nextDouble() * 1500,
    );
  }

  double _extractFundamentalFrequency(List<double> samples) {
    // Simulation d'extraction de fréquence fondamentale (F0)
    // En réalité, utiliserait autocorrélation ou YIN algorithm
    return 80 + Random().nextDouble() * 120; // 80-200 Hz
  }

  double _calculateRMSEnergy(List<double> samples) {
    double sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    return sqrt(sumSquares / samples.length);
  }

  double _calculateShimmer(List<double> samples) {
    // Simulation du calcul de shimmer (variation d'amplitude)
    return Random().nextDouble() * 0.05; // 0-5%
  }

  double _calculateJitter(List<double> samples) {
    // Simulation du calcul de jitter (variation de période)
    return Random().nextDouble() * 0.02; // 0-2%
  }

  Future<List<DetectedVoiceEmotion>> _analyzeVoiceEmotions(
    VoiceAudioFeatures features,
  ) async {
    // Analyse spécialisée pour les émotions vocales
    final voiceEmotions = <DetectedVoiceEmotion>[];
    final random = Random();

    // Analyse basée sur la fréquence fondamentale (pitch)
    if (features.voicePitch > 160) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceJoy,
          confidence: 0.75 + random.nextDouble() * 0.2,
          intensity: 0.7 + random.nextDouble() * 0.25,
        ),
      );
    } else if (features.voicePitch < 100) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceSadness,
          confidence: 0.7 + random.nextDouble() * 0.25,
          intensity: 0.6 + random.nextDouble() * 0.3,
        ),
      );
    }

    // Analyse basée sur l'énergie vocale
    if (features.voiceEnergy > 0.7) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceAnger,
          confidence: 0.65 + random.nextDouble() * 0.3,
          intensity: features.voiceEnergy,
        ),
      );
    } else if (features.voiceEnergy < 0.2) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceCalm,
          confidence: 0.8 + random.nextDouble() * 0.15,
          intensity: 1.0 - features.voiceEnergy,
        ),
      );
    }

    // Analyse basée sur le shimmer et jitter (qualité vocale)
    if (features.voiceShimmer > 0.03 || features.voiceJitter > 0.015) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceStress,
          confidence: 0.6 + random.nextDouble() * 0.3,
          intensity: (features.voiceShimmer + features.voiceJitter) * 10,
        ),
      );
    }

    // Analyse basée sur le ratio harmonique-bruit
    if (features.voiceHNR < 12) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceFatigue,
          confidence: 0.55 + random.nextDouble() * 0.35,
          intensity: (20 - features.voiceHNR) / 20,
        ),
      );
    }

    // Si aucune émotion spécifique détectée
    if (voiceEmotions.isEmpty) {
      voiceEmotions.add(
        DetectedVoiceEmotion(
          type: VoiceEmotionType.voiceNeutral,
          confidence: 0.85,
          intensity: 0.5,
        ),
      );
    }

    return voiceEmotions;
  }

  double _calculateVoiceConfidence(List<DetectedVoiceEmotion> voiceEmotions) {
    if (voiceEmotions.isEmpty) return 0.0;

    final totalConfidence = voiceEmotions
        .map((e) => e.confidence)
        .reduce((a, b) => a + b);

    return totalConfidence / voiceEmotions.length;
  }

  void _recordVoiceDetection(VoiceEmotionDetection detection) {
    _detectionHistory.add(detection);
    _voiceFeatures.add(detection.voiceFeatures);

    // Maintenir la taille de l'historique vocal
    if (_detectionHistory.length > _config.maxVoiceHistorySize) {
      _detectionHistory.removeAt(0);
    }

    if (_voiceFeatures.length > _config.maxVoiceHistorySize) {
      _voiceFeatures.removeAt(0);
    }
  }

  Future<VoiceCharacteristics> _calculateVoiceCharacteristics(
    List<VoiceCalibrationSample> voiceSamples,
  ) async {
    double totalPitch = 0;
    double totalEnergy = 0;
    double totalSpeechRate = 0;
    final mfccSums = List.filled(13, 0.0);

    for (final sample in voiceSamples) {
      final features = await _extractVoiceFeatures(
        sample.voiceAudioSamples,
        _config.voiceSampleRate,
      );

      totalPitch += features.voicePitch;
      totalEnergy += features.voiceEnergy;
      totalSpeechRate += features.voiceSpeechRate;

      for (
        int i = 0;
        i < features.voiceMFCC.length && i < mfccSums.length;
        i++
      ) {
        mfccSums[i] += features.voiceMFCC[i];
      }
    }

    final count = voiceSamples.length;

    return VoiceCharacteristics(
      averageVoicePitch: totalPitch / count,
      averageVoiceEnergy: totalEnergy / count,
      averageVoiceSpeechRate: totalSpeechRate / count,
      averageVoiceMfcc: mfccSums.map((sum) => sum / count).toList(),
      voiceSampleCount: count,
    );
  }

  double _calculateVoiceCalibrationAccuracy(
    List<VoiceCalibrationSample> voiceSamples,
  ) {
    // Simuler le calcul de précision de calibration vocale
    return 0.82 + Random().nextDouble() * 0.13; // 82-95%
  }

  Future<void> _loadUserVoiceProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceProfileJson = prefs.getString('voice_emotion_profile');

      if (voiceProfileJson != null) {
        debugPrint('Profil vocal émotionnel utilisateur chargé');
      }
    } catch (e) {
      debugPrint('Erreur chargement profil vocal: $e');
    }
  }

  Future<void> _saveUserVoiceProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_userVoiceProfile != null) {
        await prefs.setString('voice_emotion_profile', 'voice_profile_data');
        debugPrint('Profil vocal émotionnel utilisateur sauvegardé');
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde profil vocal: $e');
    }
  }

  Future<void> _loadDetectionConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('voice_detection_config');

      if (configJson != null) {
        debugPrint('Configuration de détection vocale chargée');
      }
    } catch (e) {
      debugPrint('Erreur chargement configuration vocale: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _realTimeDetectionTimer?.cancel();
    _voiceAnalysisTimer?.cancel();
    _detectionController.close();
    _eventController.close();
    debugPrint('VoiceEmotionDetectionService disposé');
  }
}

// ==================== CLASSES DE DONNÉES VOCALES ====================

class VoiceEmotionDetection {
  final List<DetectedVoiceEmotion> voiceEmotions;
  final VoiceAudioFeatures voiceFeatures;
  final double overallConfidence;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic> voiceContext;
  final String? error;

  VoiceEmotionDetection({
    required this.voiceEmotions,
    required this.voiceFeatures,
    required this.overallConfidence,
    required this.timestamp,
    required this.duration,
    required this.voiceContext,
    this.error,
  });

  factory VoiceEmotionDetection.error(String error, DateTime timestamp) {
    return VoiceEmotionDetection(
      voiceEmotions: [],
      voiceFeatures: VoiceAudioFeatures.empty(),
      overallConfidence: 0.0,
      timestamp: timestamp,
      duration: Duration.zero,
      voiceContext: {},
      error: error,
    );
  }

  DetectedVoiceEmotion? get primaryVoiceEmotion {
    if (voiceEmotions.isEmpty) return null;

    return voiceEmotions.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  bool get hasError => error != null;
}

class DetectedVoiceEmotion {
  final VoiceEmotionType type;
  final double confidence;
  final double intensity;

  DetectedVoiceEmotion({
    required this.type,
    required this.confidence,
    required this.intensity,
  });
}

class VoiceAudioFeatures {
  final double voicePitch;
  final double voicePitchVariation;
  final double voiceEnergy;
  final double voiceEnergyVariation;
  final double voiceSpeechRate;
  final double voiceShimmer;
  final double voiceJitter;
  final double voiceHNR;
  final double voiceSpectralCentroid;
  final List<double> voiceFormants;
  final List<double> voiceMFCC;
  final double voiceSpectralRolloff;

  VoiceAudioFeatures({
    required this.voicePitch,
    required this.voicePitchVariation,
    required this.voiceEnergy,
    required this.voiceEnergyVariation,
    required this.voiceSpeechRate,
    required this.voiceShimmer,
    required this.voiceJitter,
    required this.voiceHNR,
    required this.voiceSpectralCentroid,
    required this.voiceFormants,
    required this.voiceMFCC,
    required this.voiceSpectralRolloff,
  });

  factory VoiceAudioFeatures.empty() {
    return VoiceAudioFeatures(
      voicePitch: 0.0,
      voicePitchVariation: 0.0,
      voiceEnergy: 0.0,
      voiceEnergyVariation: 0.0,
      voiceSpeechRate: 0.0,
      voiceShimmer: 0.0,
      voiceJitter: 0.0,
      voiceHNR: 0.0,
      voiceSpectralCentroid: 0.0,
      voiceFormants: [],
      voiceMFCC: [],
      voiceSpectralRolloff: 0.0,
    );
  }
}

class VoiceDetectionConfig {
  final double voiceConfidenceThreshold;
  final double voiceIntensityThreshold;
  final int maxVoiceHistorySize;
  final bool enableContextualVoiceAnalysis;
  final double voiceSampleRate;
  final int minimumVoiceSampleLength;

  VoiceDetectionConfig({
    required this.voiceConfidenceThreshold,
    required this.voiceIntensityThreshold,
    required this.maxVoiceHistorySize,
    required this.enableContextualVoiceAnalysis,
    required this.voiceSampleRate,
    required this.minimumVoiceSampleLength,
  });

  factory VoiceDetectionConfig.defaultConfig() {
    return VoiceDetectionConfig(
      voiceConfidenceThreshold: 0.65,
      voiceIntensityThreshold: 0.45,
      maxVoiceHistorySize: 150,
      enableContextualVoiceAnalysis: true,
      voiceSampleRate: 16000.0,
      minimumVoiceSampleLength: 1024,
    );
  }

  VoiceDetectionConfig copyWith({
    double? voiceConfidenceThreshold,
    double? voiceIntensityThreshold,
    int? maxVoiceHistorySize,
    bool? enableContextualVoiceAnalysis,
    double? voiceSampleRate,
    int? minimumVoiceSampleLength,
  }) {
    return VoiceDetectionConfig(
      voiceConfidenceThreshold:
          voiceConfidenceThreshold ?? this.voiceConfidenceThreshold,
      voiceIntensityThreshold:
          voiceIntensityThreshold ?? this.voiceIntensityThreshold,
      maxVoiceHistorySize: maxVoiceHistorySize ?? this.maxVoiceHistorySize,
      enableContextualVoiceAnalysis:
          enableContextualVoiceAnalysis ?? this.enableContextualVoiceAnalysis,
      voiceSampleRate: voiceSampleRate ?? this.voiceSampleRate,
      minimumVoiceSampleLength:
          minimumVoiceSampleLength ?? this.minimumVoiceSampleLength,
    );
  }
}

class VoiceEmotionProfile {
  final String userId;
  final Map<VoiceEmotionType, VoiceCharacteristics> voiceCharacteristics;
  final DateTime calibrationDate;
  final double voiceAccuracy;
  final int voiceSampleCount;

  VoiceEmotionProfile({
    required this.userId,
    required this.voiceCharacteristics,
    required this.calibrationDate,
    required this.voiceAccuracy,
    required this.voiceSampleCount,
  });
}

class VoiceCharacteristics {
  final double averageVoicePitch;
  final double averageVoiceEnergy;
  final double averageVoiceSpeechRate;
  final List<double> averageVoiceMfcc;
  final int voiceSampleCount;

  VoiceCharacteristics({
    required this.averageVoicePitch,
    required this.averageVoiceEnergy,
    required this.averageVoiceSpeechRate,
    required this.averageVoiceMfcc,
    required this.voiceSampleCount,
  });
}

class VoiceCalibrationSample {
  final List<double> voiceAudioSamples;
  final VoiceEmotionType expectedVoiceEmotion;
  final double expectedVoiceIntensity;

  VoiceCalibrationSample({
    required this.voiceAudioSamples,
    required this.expectedVoiceEmotion,
    required this.expectedVoiceIntensity,
  });
}

class VoiceDetectionStats {
  final int totalVoiceDetections;
  final Map<VoiceEmotionType, int> voiceEmotionDistribution;
  final Map<VoiceEmotionType, double> averageVoiceConfidences;
  final Map<VoiceEmotionType, double> averageVoiceIntensities;
  final VoiceEmotionType dominantVoiceEmotion;
  final Duration detectionTimeSpan;

  VoiceDetectionStats({
    required this.totalVoiceDetections,
    required this.voiceEmotionDistribution,
    required this.averageVoiceConfidences,
    required this.averageVoiceIntensities,
    required this.dominantVoiceEmotion,
    required this.detectionTimeSpan,
  });

  factory VoiceDetectionStats.empty() {
    return VoiceDetectionStats(
      totalVoiceDetections: 0,
      voiceEmotionDistribution: {},
      averageVoiceConfidences: {},
      averageVoiceIntensities: {},
      dominantVoiceEmotion: VoiceEmotionType.voiceNeutral,
      detectionTimeSpan: Duration.zero,
    );
  }
}

class VoiceDetectionEvent {
  final VoiceDetectionEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VoiceDetectionEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory VoiceDetectionEvent.initialized() {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.realTimeDetectionEnabled() {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.realTimeDetectionEnabled,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.realTimeDetectionDisabled() {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.realTimeDetectionDisabled,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.voiceCalibrationStarted() {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.voiceCalibrationStarted,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.voiceCalibrationCompleted(
    VoiceEmotionProfile profile,
  ) {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.voiceCalibrationCompleted,
      data: {
        'voiceAccuracy': profile.voiceAccuracy,
        'voiceSampleCount': profile.voiceSampleCount,
      },
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.configurationChanged(
    VoiceDetectionConfig config,
  ) {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.configurationChanged,
      data: {'voiceConfig': config.voiceConfidenceThreshold},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceDetectionEvent.error(String message) {
    return VoiceDetectionEvent(
      type: VoiceDetectionEventType.error,
      data: {'message': message},
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS SPÉCIALISÉS VOIX ====================

enum VoiceEmotionType {
  voiceJoy,
  voiceSadness,
  voiceAnger,
  voiceCalm,
  voiceNeutral,
  voiceSurprise,
  voiceFear,
  voiceStress,
  voiceFatigue,
  voiceExcitement,
}

enum VoiceDetectionEventType {
  initialized,
  realTimeDetectionEnabled,
  realTimeDetectionDisabled,
  voiceCalibrationStarted,
  voiceCalibrationCompleted,
  configurationChanged,
  error,
}
