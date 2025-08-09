import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de calibration vocale - Version temporaire
/// Version simplifiée en attendant l'intégration speech_to_text
class VoiceCalibrationService {
  static const String _userVoiceProfileKey = 'user_voice_profile';
  static const String _calibrationCompleteKey = 'calibration_complete';

  // Phrases de calibration standard
  static const List<String> calibrationPhrases = [
    'Hey Ric, quel temps fait-il aujourd\'hui ?',
    'Appelle maman s\'il te plaît',
    'Navigue vers la maison',
    'Lis mes messages',
    'Démarre la musique',
    'Quelle heure est-il ?',
    'Rappelle-moi dans une heure',
    'Envoie un message à Paul',
  ];

  // Commandes de test pour validation
  static const List<String> validationCommands = [
    'météo',
    'appeler',
    'navigation',
    'messages',
    'musique',
    'heure',
    'rappel',
    'envoyer',
  ];

  // TODO: Remplacer par l'implémentation réelle avec speech_to_text
  // final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  List<CalibrationSample> _calibrationSamples = [];
  UserVoiceProfile? _userProfile;

  /// Initialise le service de calibration
  Future<bool> initialize() async {
    try {
      await _loadExistingProfile();
      return true;
    } catch (e) {
      debugPrint('Erreur initialisation calibration: $e');
      return false;
    }
  }

  /// Commence le processus de calibration complet
  Future<bool> startCalibration() async {
    _calibrationSamples.clear();
    return true;
  }

  /// Calibre avec une phrase spécifique (version simulée)
  Future<CalibrationResult> calibrateWithPhrase(String targetPhrase) async {
    // Simulation pour l'onboarding
    await Future.delayed(const Duration(seconds: 2));

    final confidence = 0.8 + Random().nextDouble() * 0.2; // 0.8-1.0
    final sample = CalibrationSample(
      targetPhrase: targetPhrase,
      recognizedText: targetPhrase, // Simulation parfaite
      confidence: confidence,
      timestamp: DateTime.now(),
    );

    _calibrationSamples.add(sample);

    return CalibrationResult(
      success: true,
      accuracy: 0.95,
      recognizedText: targetPhrase,
      sample: sample,
    );
  }

  /// Termine la calibration et génère le profil utilisateur
  Future<UserVoiceProfile> completeCalibration() async {
    if (_calibrationSamples.isEmpty) {
      throw Exception('Aucun échantillon de calibration disponible');
    }

    // Analyser les échantillons pour créer le profil
    final profile = UserVoiceProfile(
      userId: _generateUserId(),
      createdAt: DateTime.now(),
      samples: List.from(_calibrationSamples),
      averageConfidence: _calculateAverageConfidence(),
      voiceCharacteristics: _analyzeVoiceCharacteristics(),
      preferredLanguage: 'fr_FR',
      calibrationVersion: '1.0',
    );

    _userProfile = profile;
    await _saveProfile();
    await _markCalibrationComplete();

    return profile;
  }

  /// Teste la calibration avec des commandes de validation
  Future<List<ValidationResult>> validateCalibration() async {
    final results = <ValidationResult>[];

    for (final command in validationCommands.take(3)) {
      await Future.delayed(const Duration(milliseconds: 500));

      results.add(
        ValidationResult(
          command: command,
          recognized: command,
          confidence: 0.85 + Random().nextDouble() * 0.15,
          accuracy: 0.9,
          success: true,
        ),
      );
    }

    return results;
  }

  /// Améliore le profil avec de nouveaux échantillons
  Future<void> improveProfile(String recognizedText, double confidence) async {
    if (_userProfile == null) return;

    final improvement = VoiceImprovement(
      recognizedText: recognizedText,
      confidence: confidence,
      timestamp: DateTime.now(),
    );

    _userProfile!.improvements.add(improvement);

    // Recalculer les caractéristiques si suffisamment de nouvelles données
    if (_userProfile!.improvements.length % 10 == 0) {
      _userProfile!.voiceCharacteristics = _analyzeVoiceCharacteristics();
      await _saveProfile();
    }
  }

  /// Obtient le score de qualité de la calibration
  double getCalibrationQuality() {
    if (_userProfile == null) return 0.0;

    final avgConfidence = _userProfile!.averageConfidence;
    final sampleCount = _userProfile!.samples.length;
    final minSamples = calibrationPhrases.length;

    // Score basé sur la confiance moyenne et le nombre d'échantillons
    final confidenceScore = avgConfidence;
    final completionScore = (sampleCount / minSamples).clamp(0.0, 1.0);

    return (confidenceScore * 0.7 + completionScore * 0.3);
  }

  /// Vérifie si une recalibration est recommandée
  bool shouldRecalibrate() {
    if (_userProfile == null) return true;

    final daysSinceCalibration = DateTime.now()
        .difference(_userProfile!.createdAt)
        .inDays;

    final qualityScore = getCalibrationQuality();

    // Recalibrer si plus de 30 jours ou qualité faible
    return daysSinceCalibration > 30 || qualityScore < 0.6;
  }

  /// Calcule la précision entre le texte cible et reconnu
  double _calculateAccuracy(String target, String recognized) {
    final targetWords = target.toLowerCase().split(' ');
    final recognizedWords = recognized.toLowerCase().split(' ');

    int matchCount = 0;
    int totalWords = targetWords.length;

    for (final word in targetWords) {
      if (recognizedWords.contains(word)) {
        matchCount++;
      }
    }

    return totalWords > 0 ? matchCount / totalWords : 0.0;
  }

  /// Calcule la confiance moyenne des échantillons
  double _calculateAverageConfidence() {
    if (_calibrationSamples.isEmpty) return 0.0;

    final totalConfidence = _calibrationSamples
        .map((sample) => sample.confidence)
        .reduce((a, b) => a + b);

    return totalConfidence / _calibrationSamples.length;
  }

  /// Analyse les caractéristiques vocales de l'utilisateur
  Map<String, dynamic> _analyzeVoiceCharacteristics() {
    final characteristics = <String, dynamic>{};

    if (_calibrationSamples.isEmpty) return characteristics;

    // Analyse de la longueur moyenne des phrases
    final avgLength =
        _calibrationSamples
            .map((s) => s.recognizedText.length)
            .reduce((a, b) => a + b) /
        _calibrationSamples.length;

    // Analyse de la vitesse de parole (mots par échantillon)
    final avgWordCount =
        _calibrationSamples
            .map((s) => s.recognizedText.split(' ').length)
            .reduce((a, b) => a + b) /
        _calibrationSamples.length;

    // Détection des patterns de prononciation
    final commonWords = _findCommonWords();

    characteristics.addAll({
      'averagePhraseLength': avgLength,
      'averageWordCount': avgWordCount,
      'speechPatterns': commonWords,
      'confidenceVariation': _calculateConfidenceVariation(),
      'pronunciationStyle': _detectPronunciationStyle(),
    });

    return characteristics;
  }

  /// Trouve les mots les plus fréquents dans les échantillons
  Map<String, int> _findCommonWords() {
    final wordCounts = <String, int>{};

    for (final sample in _calibrationSamples) {
      final words = sample.recognizedText.toLowerCase().split(' ');
      for (final word in words) {
        if (word.length > 2) {
          // Ignorer les mots trop courts
          wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        }
      }
    }

    return wordCounts;
  }

  /// Calcule la variation de confiance
  double _calculateConfidenceVariation() {
    if (_calibrationSamples.length < 2) return 0.0;

    final avgConfidence = _calculateAverageConfidence();
    final variance =
        _calibrationSamples
            .map((s) => pow(s.confidence - avgConfidence, 2))
            .reduce((a, b) => a + b) /
        _calibrationSamples.length;

    return sqrt(variance);
  }

  /// Détecte le style de prononciation
  String _detectPronunciationStyle() {
    final avgConfidence = _calculateAverageConfidence();

    if (avgConfidence > 0.9) return 'claire';
    if (avgConfidence > 0.8) return 'normale';
    if (avgConfidence > 0.6) return 'variable';
    return 'difficile';
  }

  /// Nettoie les ressources
  void dispose() {
    // Nettoyage si nécessaire
  }

  /// Génère un ID utilisateur unique
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Sauvegarde le profil utilisateur
  Future<void> _saveProfile() async {
    if (_userProfile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userVoiceProfileKey, 'profile_saved'); // Simplifié
  }

  /// Charge le profil existant
  Future<void> _loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hasProfile = prefs.getString(_userVoiceProfileKey) != null;

    if (hasProfile) {
      _userProfile = UserVoiceProfile(
        userId: 'default_user',
        createdAt: DateTime.now(),
        samples: [],
        averageConfidence: 0.85,
        voiceCharacteristics: {'pronunciationStyle': 'claire'},
        preferredLanguage: 'fr_FR',
        calibrationVersion: '1.0',
      );
    }
  }

  /// Marque la calibration comme terminée
  Future<void> _markCalibrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calibrationCompleteKey, true);
  }

  /// Vérifie si la calibration est terminée
  Future<bool> isCalibrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_calibrationCompleteKey) ?? false;
  }

  // Getters
  bool get isListening => _isListening;
  UserVoiceProfile? get userProfile => _userProfile;
  List<CalibrationSample> get samples => List.from(_calibrationSamples);
}

/// Modèle pour un échantillon de calibration
class CalibrationSample {
  final String targetPhrase;
  final String recognizedText;
  final double confidence;
  final DateTime timestamp;

  CalibrationSample({
    required this.targetPhrase,
    required this.recognizedText,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetPhrase': targetPhrase,
      'recognizedText': recognizedText,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalibrationSample.fromMap(Map<String, dynamic> map) {
    return CalibrationSample(
      targetPhrase: map['targetPhrase'],
      recognizedText: map['recognizedText'],
      confidence: map['confidence'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Résultat d'une calibration
class CalibrationResult {
  final bool success;
  final double accuracy;
  final String recognizedText;
  final CalibrationSample? sample;
  final String? error;

  CalibrationResult({
    required this.success,
    required this.accuracy,
    required this.recognizedText,
    this.sample,
    this.error,
  });
}

/// Résultat de validation
class ValidationResult {
  final String command;
  final String recognized;
  final double confidence;
  final double accuracy;
  final bool success;
  final String? error;

  ValidationResult({
    required this.command,
    required this.recognized,
    required this.confidence,
    required this.accuracy,
    required this.success,
    this.error,
  });
}

/// Amélioration du profil vocal
class VoiceImprovement {
  final String recognizedText;
  final double confidence;
  final DateTime timestamp;

  VoiceImprovement({
    required this.recognizedText,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'recognizedText': recognizedText,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VoiceImprovement.fromMap(Map<String, dynamic> map) {
    return VoiceImprovement(
      recognizedText: map['recognizedText'],
      confidence: map['confidence'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Profil vocal de l'utilisateur
class UserVoiceProfile {
  final String userId;
  final DateTime createdAt;
  final List<CalibrationSample> samples;
  final double averageConfidence;
  final String preferredLanguage;
  final String calibrationVersion;
  Map<String, dynamic> voiceCharacteristics;
  final List<VoiceImprovement> improvements;

  UserVoiceProfile({
    required this.userId,
    required this.createdAt,
    required this.samples,
    required this.averageConfidence,
    required this.voiceCharacteristics,
    required this.preferredLanguage,
    required this.calibrationVersion,
    List<VoiceImprovement>? improvements,
  }) : improvements = improvements ?? [];

  String toJson() {
    // Implémentation simple - en production utiliser json_annotation
    return '';
  }

  factory UserVoiceProfile.fromJson(String json) {
    // Implémentation simple - en production utiliser json_annotation
    throw UnimplementedError();
  }
}
