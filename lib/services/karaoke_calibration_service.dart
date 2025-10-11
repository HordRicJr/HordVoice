import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/language_resolver.dart';

/// Service de mode karaoké calibration pour HordVoice IA
/// Fonctionnalité 3: Mode Karaoké calibration
class KaraokeCalibrationService {
  static final KaraokeCalibrationService _instance =
      KaraokeCalibrationService._internal();
  factory KaraokeCalibrationService() => _instance;
  KaraokeCalibrationService._internal();

  // Services et contrôleurs
  FlutterTts? _tts;

  // État du service
  bool _isInitialized = false;
  bool _isKaraokeModeActive = false;
  bool _isCalibrationMode = false;
  VocalCalibration? _currentCalibration;
  KaraokeSong? _currentSong;

  // Données de calibration
  double _userPitchRange = 0.0;
  double _userTempoPreference = 1.0;
  double _userVolumePreference = 0.8;
  List<double> _pitchHistory = [];
  List<double> _tempoHistory = [];

  // Streams pour les événements
  final StreamController<KaraokeEvent> _karaokeController =
      StreamController.broadcast();
  final StreamController<CalibrationData> _calibrationController =
      StreamController.broadcast();

  // Getters
  Stream<KaraokeEvent> get karaokeStream => _karaokeController.stream;
  Stream<CalibrationData> get calibrationStream =>
      _calibrationController.stream;
  bool get isInitialized => _isInitialized;
  bool get isKaraokeModeActive => _isKaraokeModeActive;
  bool get isCalibrationMode => _isCalibrationMode;
  VocalCalibration? get currentCalibration => _currentCalibration;

  /// Initialise le service de karaoké calibration
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('KaraokeCalibrationService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation KaraokeCalibrationService...');

      _tts = FlutterTts();
      await _configureTts();
      await _loadCalibrationData();

      _isInitialized = true;
      debugPrint('KaraokeCalibrationService initialisé avec succès');

      _karaokeController.add(KaraokeEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation KaraokeCalibrationService: $e');
      throw Exception('Impossible d\'initialiser le service karaoké: $e');
    }
  }

  /// Configure le TTS pour le mode karaoké
  Future<void> _configureTts() async {
    if (_tts == null) return;

    final ttsLang = await LanguageResolver.getTtsLanguage();
    await _tts!.setLanguage(ttsLang);
    await _tts!.setSpeechRate(_userTempoPreference);
    await _tts!.setVolume(_userVolumePreference);
    await _tts!.setPitch(1.0);
  }

  /// Démarre le mode calibration vocale
  Future<void> startVocalCalibration() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _isCalibrationMode = true;
      _pitchHistory.clear();
      _tempoHistory.clear();

      _karaokeController.add(KaraokeEvent.calibrationStarted());

      // Phase 1: Test de tonalité
      await _testPitchRange();

      // Phase 2: Test de tempo
      await _testTempoPreference();

      // Phase 3: Test de volume
      await _testVolumePreference();

      // Phase 4: Analyse des résultats
      final calibration = await _analyzeCalibrationResults();

      _currentCalibration = calibration;
      _isCalibrationMode = false;

      await _saveCalibrationData();

      _karaokeController.add(KaraokeEvent.calibrationCompleted(calibration));
      debugPrint('Calibration vocale terminée');
    } catch (e) {
      _isCalibrationMode = false;
      debugPrint('Erreur calibration vocale: $e');
      _karaokeController.add(KaraokeEvent.error('Erreur calibration: $e'));
    }
  }

  /// Test de la plage de tonalité de l'utilisateur
  Future<void> _testPitchRange() async {
    _karaokeController.add(KaraokeEvent.phaseStarted('pitch_test'));

    // Instructions pour l'utilisateur
    await _speakInstruction(
      'Nous allons maintenant tester votre plage vocale. '
      'Répétez après moi en essayant de suivre ma tonalité.',
    );

    await Future.delayed(const Duration(seconds: 2));

    // Série de tests de tonalité
    final pitchTests = [0.7, 0.8, 1.0, 1.2, 1.4, 1.6];

    for (final pitch in pitchTests) {
      await _tts!.setPitch(pitch);
      await _tts!.speak('Lalalala');

      await Future.delayed(const Duration(seconds: 3));

      // Simuler la capture du pitch utilisateur
      final userPitch = _simulateUserPitch(pitch);
      _pitchHistory.add(userPitch);

      _calibrationController.add(
        CalibrationData(
          type: CalibrationType.pitch,
          targetValue: pitch,
          userValue: userPitch,
          accuracy: _calculatePitchAccuracy(pitch, userPitch),
        ),
      );
    }

    _karaokeController.add(KaraokeEvent.phaseCompleted('pitch_test'));
  }

  /// Test des préférences de tempo
  Future<void> _testTempoPreference() async {
    _karaokeController.add(KaraokeEvent.phaseStarted('tempo_test'));

    await _speakInstruction(
      'Maintenant, nous allons tester votre tempo préféré. '
      'Écoutez et dites-moi si c\'est trop rapide, trop lent, ou parfait.',
    );

    await Future.delayed(const Duration(seconds: 2));

    final tempoTests = [0.6, 0.8, 1.0, 1.2, 1.4];
    const testText = 'Ceci est un test de tempo pour le karaoké vocal';

    for (final tempo in tempoTests) {
      await _tts!.setSpeechRate(tempo);
      await _tts!.speak(testText);

      await Future.delayed(const Duration(seconds: 4));

      // Simuler la réponse utilisateur
      final userPreference = _simulateUserTempoFeedback(tempo);
      _tempoHistory.add(userPreference);

      _calibrationController.add(
        CalibrationData(
          type: CalibrationType.tempo,
          targetValue: tempo,
          userValue: userPreference,
          accuracy: _calculateTempoAccuracy(tempo, userPreference),
        ),
      );
    }

    _karaokeController.add(KaraokeEvent.phaseCompleted('tempo_test'));
  }

  /// Test des préférences de volume
  Future<void> _testVolumePreference() async {
    _karaokeController.add(KaraokeEvent.phaseStarted('volume_test'));

    await _speakInstruction(
      'Enfin, nous allons ajuster le volume. '
      'Dites-moi quand le volume vous convient.',
    );

    await Future.delayed(const Duration(seconds: 2));

    final volumeTests = [0.4, 0.6, 0.8, 1.0];
    const testText = 'Test de volume pour le karaoké';

    for (final volume in volumeTests) {
      await _tts!.setVolume(volume);
      await _tts!.speak(testText);

      await Future.delayed(const Duration(seconds: 3));

      // Simuler la préférence utilisateur
      final userFeedback = _simulateUserVolumeFeedback(volume);

      _calibrationController.add(
        CalibrationData(
          type: CalibrationType.volume,
          targetValue: volume,
          userValue: userFeedback,
          accuracy: _calculateVolumeAccuracy(volume, userFeedback),
        ),
      );
    }

    _karaokeController.add(KaraokeEvent.phaseCompleted('volume_test'));
  }

  /// Analyse les résultats de calibration
  Future<VocalCalibration> _analyzeCalibrationResults() async {
    // Calculer la plage de pitch optimale
    final optimalPitch = _calculateOptimalPitch();

    // Calculer le tempo préféré
    final optimalTempo = _calculateOptimalTempo();

    // Calculer le volume préféré
    final optimalVolume = _calculateOptimalVolume();

    // Déterminer le profil vocal
    final vocalProfile = _determineVocalProfile(optimalPitch);

    return VocalCalibration(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // TODO: Récupérer l'ID utilisateur réel
      optimalPitch: optimalPitch,
      pitchRange: _userPitchRange,
      optimalTempo: optimalTempo,
      optimalVolume: optimalVolume,
      vocalProfile: vocalProfile,
      calibrationDate: DateTime.now(),
      accuracy: _calculateOverallAccuracy(),
    );
  }

  /// Démarre le mode karaoké avec la calibration actuelle
  Future<void> startKaraokeMode([KaraokeSong? song]) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentCalibration == null) {
      await startVocalCalibration();
    }

    try {
      _isKaraokeModeActive = true;
      _currentSong = song ?? _getDefaultSong();

      await _applyKaraokeSettings();

      _karaokeController.add(KaraokeEvent.karaokeStarted(_currentSong!));

      await _speakInstruction('Mode karaoké activé! Prêt à chanter?');

      debugPrint('Mode karaoké démarré');
    } catch (e) {
      _isKaraokeModeActive = false;
      debugPrint('Erreur démarrage karaoké: $e');
      _karaokeController.add(KaraokeEvent.error('Erreur karaoké: $e'));
    }
  }

  /// Applique les paramètres de karaoké optimisés
  Future<void> _applyKaraokeSettings() async {
    if (_tts == null || _currentCalibration == null) return;

    await _tts!.setPitch(_currentCalibration!.optimalPitch);
    await _tts!.setSpeechRate(_currentCalibration!.optimalTempo);
    await _tts!.setVolume(_currentCalibration!.optimalVolume);
  }

  /// Chante une chanson avec l'accompagnement vocal
  Future<void> singWithAccompaniment(
    String lyrics, {
    bool showLyrics = true,
  }) async {
    if (!_isKaraokeModeActive) {
      await startKaraokeMode();
    }

    try {
      if (showLyrics) {
        _karaokeController.add(KaraokeEvent.lyricsDisplayed(lyrics));
      }

      // Adapter les paroles au profil vocal
      final adaptedLyrics = _adaptLyricsToProfile(lyrics);

      await _tts!.speak(adaptedLyrics);

      _karaokeController.add(KaraokeEvent.singingStarted(lyrics));
    } catch (e) {
      debugPrint('Erreur chant karaoké: $e');
      _karaokeController.add(KaraokeEvent.error('Erreur chant: $e'));
    }
  }

  /// Arrête le mode karaoké
  Future<void> stopKaraokeMode() async {
    _isKaraokeModeActive = false;
    _currentSong = null;

    await _tts?.stop();

    _karaokeController.add(KaraokeEvent.karaokeStopped());
    debugPrint('Mode karaoké arrêté');
  }

  /// Obtient la liste des chansons disponibles
  List<KaraokeSong> getAvailableSongs() {
    return [
      KaraokeSong(
        id: '1',
        title: 'La Marseillaise',
        artist: 'Hymne National',
        lyrics: 'Allons enfants de la Patrie, le jour de gloire est arrivé...',
        difficulty: KaraokeDifficulty.beginner,
        duration: const Duration(minutes: 2),
      ),
      KaraokeSong(
        id: '2',
        title: 'Frère Jacques',
        artist: 'Traditionnel',
        lyrics: 'Frère Jacques, Frère Jacques, dormez-vous?...',
        difficulty: KaraokeDifficulty.beginner,
        duration: const Duration(minutes: 1),
      ),
      KaraokeSong(
        id: '3',
        title: 'Happy Birthday',
        artist: 'Traditionnel',
        lyrics: 'Happy birthday to you, happy birthday to you...',
        difficulty: KaraokeDifficulty.intermediate,
        duration: const Duration(seconds: 30),
      ),
    ];
  }

  /// Évalue la performance de chant de l'utilisateur
  Future<KaraokeScore> evaluatePerformance(
    String originalLyrics,
    String userSinging,
  ) async {
    // Analyse de la performance (simulée pour l'instant)
    final pitchAccuracy = _evaluatePitchAccuracy(userSinging);
    final timingAccuracy = _evaluateTimingAccuracy(userSinging);
    final lyricAccuracy = _evaluateLyricAccuracy(originalLyrics, userSinging);

    final overallScore = (pitchAccuracy + timingAccuracy + lyricAccuracy) / 3;

    final score = KaraokeScore(
      overallScore: overallScore,
      pitchAccuracy: pitchAccuracy,
      timingAccuracy: timingAccuracy,
      lyricAccuracy: lyricAccuracy,
      feedback: _generateFeedback(overallScore),
    );

    _karaokeController.add(KaraokeEvent.performanceEvaluated(score));
    return score;
  }

  // ==================== MÉTHODES PRIVÉES ====================

  double _simulateUserPitch(double targetPitch) {
    final random = Random();
    final variation = (random.nextDouble() - 0.5) * 0.2; // ±10% variation
    return (targetPitch + variation).clamp(0.5, 2.0);
  }

  double _simulateUserTempoFeedback(double tempo) {
    // Simuler une préférence utilisateur pour des tempos modérés
    if (tempo >= 0.9 && tempo <= 1.1) {
      return 1.0; // Parfait
    } else if (tempo < 0.9) {
      return 0.7; // Trop lent
    } else {
      return 0.5; // Trop rapide
    }
  }

  double _simulateUserVolumeFeedback(double volume) {
    // Simuler une préférence pour un volume modéré
    if (volume >= 0.7 && volume <= 0.9) {
      return 1.0; // Parfait
    } else {
      return 0.5; // Pas optimal
    }
  }

  double _calculatePitchAccuracy(double target, double user) {
    final difference = (target - user).abs();
    return (1.0 - (difference / target)).clamp(0.0, 1.0);
  }

  double _calculateTempoAccuracy(double target, double user) {
    return user; // La valeur utilisateur est déjà l'exactitude
  }

  double _calculateVolumeAccuracy(double target, double user) {
    return user; // La valeur utilisateur est déjà l'exactitude
  }

  double _calculateOptimalPitch() {
    if (_pitchHistory.isEmpty) return 1.0;

    // Calculer la moyenne pondérée des pitch les plus réussis
    final sortedHistory = List<double>.from(_pitchHistory)..sort();
    final median = sortedHistory[sortedHistory.length ~/ 2];

    _userPitchRange = sortedHistory.last - sortedHistory.first;
    return median;
  }

  double _calculateOptimalTempo() {
    if (_tempoHistory.isEmpty) return 1.0;

    // Trouver le tempo avec le meilleur feedback
    double bestTempo = 1.0;
    double bestScore = 0.0;

    for (int i = 0; i < _tempoHistory.length; i++) {
      if (_tempoHistory[i] > bestScore) {
        bestScore = _tempoHistory[i];
        bestTempo = [0.6, 0.8, 1.0, 1.2, 1.4][i];
      }
    }

    return bestTempo;
  }

  double _calculateOptimalVolume() {
    // Retourner le volume préféré de l'utilisateur
    return _userVolumePreference;
  }

  VocalProfile _determineVocalProfile(double pitch) {
    if (pitch < 0.8) {
      return VocalProfile.bass;
    } else if (pitch < 1.0) {
      return VocalProfile.baritone;
    } else if (pitch < 1.3) {
      return VocalProfile.tenor;
    } else {
      return VocalProfile.soprano;
    }
  }

  double _calculateOverallAccuracy() {
    // Calculer la précision globale basée sur tous les tests
    double totalAccuracy = 0.0;
    int count = 0;

    if (_pitchHistory.isNotEmpty) {
      totalAccuracy +=
          _pitchHistory.reduce((a, b) => a + b) / _pitchHistory.length;
      count++;
    }

    if (_tempoHistory.isNotEmpty) {
      totalAccuracy +=
          _tempoHistory.reduce((a, b) => a + b) / _tempoHistory.length;
      count++;
    }

    return count > 0 ? totalAccuracy / count : 0.8;
  }

  KaraokeSong _getDefaultSong() {
    return KaraokeSong(
      id: 'default',
      title: 'Exercice Vocal',
      artist: 'HordVoice',
      lyrics: 'Do, Ré, Mi, Fa, Sol, La, Si, Do',
      difficulty: KaraokeDifficulty.beginner,
      duration: const Duration(seconds: 30),
    );
  }

  String _adaptLyricsToProfile(String lyrics) {
    if (_currentCalibration == null) return lyrics;

    // Adapter les paroles selon le profil vocal
    switch (_currentCalibration!.vocalProfile) {
      case VocalProfile.bass:
        return _addBassMarkers(lyrics);
      case VocalProfile.soprano:
        return _addSopranoMarkers(lyrics);
      default:
        return lyrics;
    }
  }

  String _addBassMarkers(String lyrics) {
    // Ajouter des marqueurs pour les voix graves
    return lyrics.replaceAll('.', '... (grave)');
  }

  String _addSopranoMarkers(String lyrics) {
    // Ajouter des marqueurs pour les voix aiguës
    return lyrics.replaceAll('.', '... (aigu)');
  }

  double _evaluatePitchAccuracy(String userSinging) {
    // Évaluation simulée de la justesse
    final random = Random();
    return 0.7 + (random.nextDouble() * 0.3); // 70-100%
  }

  double _evaluateTimingAccuracy(String userSinging) {
    // Évaluation simulée du timing
    final random = Random();
    return 0.6 + (random.nextDouble() * 0.4); // 60-100%
  }

  double _evaluateLyricAccuracy(String original, String user) {
    // Évaluation simulée des paroles
    final random = Random();
    return 0.8 + (random.nextDouble() * 0.2); // 80-100%
  }

  String _generateFeedback(double score) {
    if (score >= 0.9) {
      return 'Excellent! Vous avez une voix magnifique!';
    } else if (score >= 0.8) {
      return 'Très bien! Continuez comme ça!';
    } else if (score >= 0.7) {
      return 'Bien joué! Il y a quelques points à améliorer.';
    } else if (score >= 0.6) {
      return 'Pas mal! Entraînez-vous encore un peu.';
    } else {
      return 'Continuez à vous entraîner, vous allez y arriver!';
    }
  }

  Future<void> _speakInstruction(String instruction) async {
    if (_tts != null) {
      await _tts!.speak(instruction);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _saveCalibrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentCalibration != null) {
        await prefs.setString(
          'karaoke_calibration',
          _currentCalibration!.toJson(),
        );
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde calibration: $e');
    }
  }

  Future<void> _loadCalibrationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calibrationData = prefs.getString('karaoke_calibration');
      if (calibrationData != null) {
        _currentCalibration = VocalCalibration.fromJson(calibrationData);
      }
    } catch (e) {
      debugPrint('Erreur chargement calibration: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _tts?.stop();
    _karaokeController.close();
    _calibrationController.close();
    debugPrint('KaraokeCalibrationService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class VocalCalibration {
  final String id;
  final String userId;
  final double optimalPitch;
  final double pitchRange;
  final double optimalTempo;
  final double optimalVolume;
  final VocalProfile vocalProfile;
  final DateTime calibrationDate;
  final double accuracy;

  VocalCalibration({
    required this.id,
    required this.userId,
    required this.optimalPitch,
    required this.pitchRange,
    required this.optimalTempo,
    required this.optimalVolume,
    required this.vocalProfile,
    required this.calibrationDate,
    required this.accuracy,
  });

  String toJson() {
    return '''
    {
      "id": "$id",
      "userId": "$userId",
      "optimalPitch": $optimalPitch,
      "pitchRange": $pitchRange,
      "optimalTempo": $optimalTempo,
      "optimalVolume": $optimalVolume,
      "vocalProfile": "${vocalProfile.name}",
      "calibrationDate": "${calibrationDate.toIso8601String()}",
      "accuracy": $accuracy
    }
    ''';
  }

  factory VocalCalibration.fromJson(String jsonStr) {
    final json = jsonStr; // Simplification pour l'exemple
    return VocalCalibration(
      id: 'loaded',
      userId: 'current_user',
      optimalPitch: 1.0,
      pitchRange: 0.5,
      optimalTempo: 1.0,
      optimalVolume: 0.8,
      vocalProfile: VocalProfile.tenor,
      calibrationDate: DateTime.now(),
      accuracy: 0.8,
    );
  }
}

class KaraokeSong {
  final String id;
  final String title;
  final String artist;
  final String lyrics;
  final KaraokeDifficulty difficulty;
  final Duration duration;

  KaraokeSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.difficulty,
    required this.duration,
  });
}

class KaraokeScore {
  final double overallScore;
  final double pitchAccuracy;
  final double timingAccuracy;
  final double lyricAccuracy;
  final String feedback;

  KaraokeScore({
    required this.overallScore,
    required this.pitchAccuracy,
    required this.timingAccuracy,
    required this.lyricAccuracy,
    required this.feedback,
  });
}

class CalibrationData {
  final CalibrationType type;
  final double targetValue;
  final double userValue;
  final double accuracy;

  CalibrationData({
    required this.type,
    required this.targetValue,
    required this.userValue,
    required this.accuracy,
  });
}

class KaraokeEvent {
  final KaraokeEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  KaraokeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory KaraokeEvent.initialized() {
    return KaraokeEvent(
      type: KaraokeEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.calibrationStarted() {
    return KaraokeEvent(
      type: KaraokeEventType.calibrationStarted,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.phaseStarted(String phase) {
    return KaraokeEvent(
      type: KaraokeEventType.phaseStarted,
      data: {'phase': phase},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.phaseCompleted(String phase) {
    return KaraokeEvent(
      type: KaraokeEventType.phaseCompleted,
      data: {'phase': phase},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.calibrationCompleted(VocalCalibration calibration) {
    return KaraokeEvent(
      type: KaraokeEventType.calibrationCompleted,
      data: {'calibration': calibration.toJson()},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.karaokeStarted(KaraokeSong song) {
    return KaraokeEvent(
      type: KaraokeEventType.karaokeStarted,
      data: {'song': song.title},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.lyricsDisplayed(String lyrics) {
    return KaraokeEvent(
      type: KaraokeEventType.lyricsDisplayed,
      data: {'lyrics': lyrics},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.singingStarted(String lyrics) {
    return KaraokeEvent(
      type: KaraokeEventType.singingStarted,
      data: {'lyrics': lyrics},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.performanceEvaluated(KaraokeScore score) {
    return KaraokeEvent(
      type: KaraokeEventType.performanceEvaluated,
      data: {'score': score.overallScore, 'feedback': score.feedback},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.karaokeStopped() {
    return KaraokeEvent(
      type: KaraokeEventType.karaokeStopped,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory KaraokeEvent.error(String message) {
    return KaraokeEvent(
      type: KaraokeEventType.error,
      data: {'message': message},
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS ====================

enum VocalProfile { bass, baritone, tenor, soprano }

enum KaraokeDifficulty { beginner, intermediate, advanced, expert }

enum CalibrationType { pitch, tempo, volume }

enum KaraokeEventType {
  initialized,
  calibrationStarted,
  phaseStarted,
  phaseCompleted,
  calibrationCompleted,
  karaokeStarted,
  lyricsDisplayed,
  singingStarted,
  performanceEvaluated,
  karaokeStopped,
  error,
}
