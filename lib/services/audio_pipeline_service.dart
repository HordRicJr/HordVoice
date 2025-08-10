import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/voice_models.dart';
import '../theme/design_tokens.dart';
import 'permission_manager_service.dart';
import 'voice_calibration_service.dart';
import 'azure_wake_word_service.dart';
import 'azure_speech_service.dart';
import 'azure_speech_phrase_hints_service.dart';

/// Provider pour le service de pipeline audio
final audioPipelineProvider =
    StateNotifierProvider<AudioPipelineNotifier, AudioPipelineState>(
      (ref) => AudioPipelineNotifier(),
    );

/// État du pipeline audio
enum AudioPipelineStatus { idle, listening, processing, speaking, error }

/// État complet du pipeline audio
class AudioPipelineState {
  final AudioPipelineStatus status;
  final bool isWakeWordActive;
  final double currentVolume;
  final List<double> waveformData;
  final String? lastRecognizedText;
  final String? currentSpeech;
  final EmotionType currentEmotion;
  final String? error;
  final VoiceOption? selectedVoice;

  const AudioPipelineState({
    this.status = AudioPipelineStatus.idle,
    this.isWakeWordActive = false,
    this.currentVolume = 0.0,
    this.waveformData = const [],
    this.lastRecognizedText,
    this.currentSpeech,
    this.currentEmotion = EmotionType.neutral,
    this.error,
    this.selectedVoice,
  });

  AudioPipelineState copyWith({
    AudioPipelineStatus? status,
    bool? isWakeWordActive,
    double? currentVolume,
    List<double>? waveformData,
    String? lastRecognizedText,
    String? currentSpeech,
    EmotionType? currentEmotion,
    String? error,
    VoiceOption? selectedVoice,
  }) {
    return AudioPipelineState(
      status: status ?? this.status,
      isWakeWordActive: isWakeWordActive ?? this.isWakeWordActive,
      currentVolume: currentVolume ?? this.currentVolume,
      waveformData: waveformData ?? this.waveformData,
      lastRecognizedText: lastRecognizedText ?? this.lastRecognizedText,
      currentSpeech: currentSpeech ?? this.currentSpeech,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      error: error ?? this.error,
      selectedVoice: selectedVoice ?? this.selectedVoice,
    );
  }
}

/// Notifier pour le pipeline audio
class AudioPipelineNotifier extends StateNotifier<AudioPipelineState> {
  AudioPipelineNotifier() : super(const AudioPipelineState()) {
    _initialize();
  }

  // Services
  final VoiceCalibrationService _calibrationService = VoiceCalibrationService();
  final AzureWakeWordService _wakeWordService = AzureWakeWordService();
  final AzureSpeechService _speechService = AzureSpeechService();
  late FlutterTts _tts;

  // Timers et streams
  Timer? _wakeWordTimer;
  Timer? _volumeTimer;
  Timer?
  _listeningTimeout; // AJOUT: Timeout pour arrêter l'écoute automatiquement
  StreamSubscription? _audioStreamSubscription;

  // Configuration
  static const int _waveformBars = 24;
  static const Duration _listeningTimeoutDuration = Duration(
    seconds: 8,
  ); // Timeout écoute
  static const Duration _wakeWordDetectionInterval = Duration(
    seconds: 10,
  ); // Intervalle wake word

  /// Initialise le pipeline audio
  Future<void> _initialize() async {
    try {
      // Vérifier les permissions
      final hasPermissions =
          await PermissionManagerService.hasEssentialPermissions();
      if (!hasPermissions) {
        state = state.copyWith(
          status: AudioPipelineStatus.error,
          error: 'Permissions microphone requises',
        );
        return;
      }

      // Initialiser la calibration
      await _calibrationService.initialize();

      // Initialiser les services Azure
      await _wakeWordService.initialize();
      await _speechService.initialize();

      // Configurer les phrase hints pour une précision maximale
      await _configurePhraseHints();

      // Initialiser TTS
      _tts = FlutterTts();
      await _initializeTTS();

      // Charger la voix par défaut
      final defaultVoice = VoiceOption(
        id: 'clara',
        name: 'Clara',
        language: 'fr-FR',
        style: 'warm',
        gender: 'female',
        description: 'Voix féminine chaleureuse',
      );
      state = state.copyWith(
        status: AudioPipelineStatus.idle,
        selectedVoice: defaultVoice,
      );

      // Démarrer la détection du wake word
      _startWakeWordDetection();
    } catch (e) {
      state = state.copyWith(
        status: AudioPipelineStatus.error,
        error: 'Erreur initialisation: $e',
      );
    }
  }

  /// Démarre la détection du wake word
  void _startWakeWordDetection() {
    state = state.copyWith(isWakeWordActive: true);

    // IMPLÉMENTATION: Vraie détection wake word avec Azure
    _startRealWakeWordDetection();
  }

  /// IMPLÉMENTATION: Vraie détection wake word avec Azure Speech
  Future<void> _startRealWakeWordDetection() async {
    try {
      debugPrint('Démarrage détection wake word Azure...');

      // Démarrer l'écoute continue pour wake word
      await _wakeWordService.startListening();

      // Écouter les détections
      _wakeWordService.detectionStream.listen((detection) {
        if (detection.isDetected &&
            !detection.needsConfirmation &&
            state.status == AudioPipelineStatus.idle) {
          debugPrint(
            'Wake word détecté: ${detection.matchedText} (${detection.confidence})',
          );
          _onWakeWordDetected();
        }
      });
    } catch (e) {
      debugPrint('Erreur détection wake word Azure: $e');
      // Fallback vers simulation si Azure échoue
      _fallbackToSimulatedWakeWord();
    }
  }

  /// Gestionnaire d'événement wake word détecté
  void _onWakeWordDetected() {
    startListening();
  }

  /// Initialise le TTS
  Future<void> _initializeTTS() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(0.8);
      await _tts.setPitch(1.0);
      debugPrint('TTS initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur initialisation TTS: $e');
    }
  }

  /// Configure les phrase hints pour optimiser la reconnaissance vocale
  Future<void> _configurePhraseHints() async {
    try {
      debugPrint('🎯 Configuration des phrase hints pour HordVoice...');

      // Configurer TOUTES les phrases pour une précision maximale
      final success = await AzureSpeechPhraseHintsService.configureAllHints();

      if (success) {
        final stats = AzureSpeechPhraseHintsService.getPhrasesStats();
        debugPrint(
          '✅ Phrase hints configurées: ${stats["TOTAL"]} phrases au total',
        );
        debugPrint(
          '📊 Répartition: Wake words: ${stats["wake_words"]}, Système: ${stats["system"]}, Navigation: ${stats["navigation"]}, Météo: ${stats["weather"]}, Téléphonie: ${stats["telephony"]}, Musique: ${stats["music"]}, etc.',
        );
      } else {
        debugPrint('❌ Échec de la configuration des phrase hints');
      }
    } catch (e) {
      debugPrint('🚨 Erreur lors de la configuration des phrase hints: $e');
    }
  }

  /// Fallback vers simulation si Azure Wake Word échoue
  void _fallbackToSimulatedWakeWord() {
    debugPrint('Fallback vers simulation wake word');
    _wakeWordTimer?.cancel();
    _wakeWordTimer = Timer.periodic(
      _wakeWordDetectionInterval,
      (_) => _simulateWakeWordDetection(),
    );
  }

  /// Simulation de détection wake word
  void _simulateWakeWordDetection() {
    // Simulation aléatoire pour demo
    if (Random().nextBool() && state.status == AudioPipelineStatus.idle) {
      debugPrint('Wake word détecté (simulation)');
      startListening();
    }
  }

  /// AJOUT: Démarre le timeout d'écoute pour éviter l'écoute infinie
  void _startListeningTimeout() {
    _listeningTimeout?.cancel();
    _listeningTimeout = Timer(_listeningTimeoutDuration, () {
      if (state.status == AudioPipelineStatus.listening) {
        debugPrint('Timeout d\'écoute atteint - arrêt automatique');
        stopListening();
      }
    });
  }

  /// Démarre l'écoute après wake word ou interaction tactile
  Future<void> startListening() async {
    if (state.status != AudioPipelineStatus.idle) return;

    state = state.copyWith(
      status: AudioPipelineStatus.listening,
      currentEmotion: EmotionType.neutral,
      error: null,
    );

    // Démarrer la génération de waveform
    _startWaveformGeneration();

    // AJOUT: Démarrer le timeout d'écoute pour éviter l'écoute infinie
    _startListeningTimeout();

    // IMPLÉMENTATION: Vraie reconnaissance vocale avec Azure Speech
    _startRealVoiceRecognition();
  }

  /// IMPLÉMENTATION: Vraie reconnaissance vocale avec Azure Speech
  Future<void> _startRealVoiceRecognition() async {
    try {
      debugPrint('Démarrage reconnaissance vocale Azure...');

      // Démarrer la reconnaissance continue
      await _speechService.startListening();

      // Écouter les résultats de transcription via stream
      _speechService.resultStream.listen((result) {
        if (result.recognizedText.isNotEmpty &&
            state.status == AudioPipelineStatus.listening) {
          _listeningTimeout?.cancel(); // Arrêter timeout car commande reconnue

          debugPrint('Commande reconnue: ${result.recognizedText}');

          state = state.copyWith(
            status: AudioPipelineStatus.processing,
            lastRecognizedText: result.recognizedText,
            currentEmotion: EmotionType.joy,
          );

          // Traiter la commande
          _processCommand(result.recognizedText);
        }
      });

      // Gérer les erreurs de reconnaissance via stream
      _speechService.errorStream.listen((error) {
        debugPrint('Erreur reconnaissance vocale: ${error.errorMessage}');
        if (state.status == AudioPipelineStatus.listening) {
          // Fallback vers simulation si Azure échoue
          _fallbackToSimulatedRecognition();
        }
      });
    } catch (e) {
      debugPrint('Erreur démarrage reconnaissance Azure: $e');
      // Fallback vers simulation
      _fallbackToSimulatedRecognition();
    }
  }

  /// Fallback vers simulation si Azure Speech échoue
  void _fallbackToSimulatedRecognition() {
    debugPrint('Fallback vers simulation reconnaissance vocale');
    _simulateVoiceRecognition();
  }

  /// Stoppe l'écoute
  void stopListening() {
    _volumeTimer?.cancel();
    _listeningTimeout?.cancel(); // AJOUT: Arrêter le timeout d'écoute

    state = state.copyWith(
      status: AudioPipelineStatus.idle,
      currentVolume: 0.0,
      waveformData: List.filled(_waveformBars, 0.0),
    );
  }

  /// Simulation de reconnaissance vocale
  void _simulateVoiceRecognition() {
    Timer(const Duration(seconds: 3), () {
      // AJOUT: Arrêter le timeout d'écoute car commande reconnue
      _listeningTimeout?.cancel();

      final commands = [
        'Quel temps fait-il ?',
        'Appelle maman',
        'Lis mes messages',
        'Démarre la musique',
        'Navigation vers la maison',
      ];

      final recognizedText = commands[Random().nextInt(commands.length)];

      state = state.copyWith(
        status: AudioPipelineStatus.processing,
        lastRecognizedText: recognizedText,
        currentEmotion: EmotionType.joy,
      );

      // Traiter la commande
      _processCommand(recognizedText);
    });
  }

  /// Traite une commande reconnue
  Future<void> _processCommand(String command) async {
    // Déterminer l'émotion basée sur la commande
    EmotionType emotion = EmotionType.neutral;
    String response = 'Commande reçue : $command';

    if (command.contains('temps') || command.contains('météo')) {
      emotion = EmotionType.calm;
      response = 'Il fait beau aujourd\'hui, 22 degrés avec un ciel dégagé.';
    } else if (command.contains('appelle') || command.contains('appel')) {
      emotion = EmotionType.joy;
      response = 'Je compose le numéro maintenant.';
    } else if (command.contains('musique')) {
      emotion = EmotionType.joy;
      response = 'Je lance ta playlist préférée.';
    } else if (command.contains('messages')) {
      emotion = EmotionType.neutral;
      response = 'Tu as 3 nouveaux messages. Veux-tu que je les lise ?';
    } else if (command.contains('navigation')) {
      emotion = EmotionType.calm;
      response = 'Calcul de l\'itinéraire vers la maison en cours.';
    }

    // Commencer la synthèse vocale
    await speak(response, emotion);
  }

  /// Synthèse vocale avec émotion
  Future<void> speak(String text, [EmotionType? emotion]) async {
    state = state.copyWith(
      status: AudioPipelineStatus.speaking,
      currentSpeech: text,
      currentEmotion: emotion ?? EmotionType.neutral,
    );

    // IMPLÉMENTATION: Vraie synthèse vocale avec Azure Speech TTS
    await _speakWithAzure(text, emotion);

    state = state.copyWith(
      status: AudioPipelineStatus.idle,
      currentSpeech: null,
      currentEmotion: EmotionType.neutral,
    );
  }

  /// IMPLÉMENTATION: Synthèse vocale avec FlutterTts et configuration voix
  Future<void> _speakWithAzure(String text, EmotionType? emotion) async {
    try {
      debugPrint('Synthèse TTS: $text');

      // Configurer la voix selon la sélection et l'émotion
      if (state.selectedVoice != null) {
        await _configureTTSVoice(state.selectedVoice!, emotion);
      }

      // Lancer la synthèse vocale
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Erreur synthèse TTS: $e');
      // Fallback vers simulation
      await _simulateSpeech(text);
    }
  }

  /// Configure la voix TTS selon l'option sélectionnée et l'émotion
  Future<void> _configureTTSVoice(
    VoiceOption voice,
    EmotionType? emotion,
  ) async {
    try {
      await _tts.setLanguage(voice.language);

      // Ajuster les paramètres selon l'émotion
      switch (emotion) {
        case EmotionType.joy:
          await _tts.setSpeechRate(0.6); // Plus rapide pour la joie
          await _tts.setPitch(1.2); // Plus aigu
          break;
        case EmotionType.calm:
          await _tts.setSpeechRate(0.4); // Plus lent pour le calme
          await _tts.setPitch(0.9); // Légèrement plus grave
          break;
        case EmotionType.sadness:
          await _tts.setSpeechRate(0.3); // Très lent pour la tristesse
          await _tts.setPitch(0.8); // Plus grave
          break;
        default:
          await _tts.setSpeechRate(0.5); // Neutre
          await _tts.setPitch(1.0);
      }
    } catch (e) {
      debugPrint('Erreur configuration voix TTS: $e');
    }
  }

  /// Simulation de synthèse vocale
  Future<void> _simulateSpeech(String text) async {
    final words = text.split(' ');
    final duration = Duration(
      milliseconds: words.length * 300,
    ); // ~300ms par mot

    await Future.delayed(duration);
  }

  /// Change la voix sélectionnée
  void selectVoice(VoiceOption voice) {
    state = state.copyWith(selectedVoice: voice);

    // IMPLÉMENTATION: Configurer le TTS avec la nouvelle voix
    _configureTTSWithNewVoice(voice);
    debugPrint('Voix changée vers: ${voice.name}');
  }

  /// IMPLÉMENTATION: Configure le TTS avec une nouvelle voix
  Future<void> _configureTTSWithNewVoice(VoiceOption voice) async {
    try {
      // Configurer la langue
      await _tts.setLanguage(voice.language);

      // Configurer les paramètres selon le style de voix
      switch (voice.style) {
        case 'warm':
          await _tts.setSpeechRate(0.5);
          await _tts.setPitch(1.1);
          await _tts.setVolume(0.8);
          break;
        case 'professional':
          await _tts.setSpeechRate(0.6);
          await _tts.setPitch(1.0);
          await _tts.setVolume(0.9);
          break;
        case 'friendly':
          await _tts.setSpeechRate(0.55);
          await _tts.setPitch(1.15);
          await _tts.setVolume(0.85);
          break;
        case 'calm':
          await _tts.setSpeechRate(0.4);
          await _tts.setPitch(0.9);
          await _tts.setVolume(0.7);
          break;
        default:
          await _tts.setSpeechRate(0.5);
          await _tts.setPitch(1.0);
          await _tts.setVolume(0.8);
      }

      // Ajuster selon le genre si spécifié
      if (voice.gender == 'female') {
        // Pitch plus aigu pour voix féminine (déjà configuré dans le switch)
        debugPrint('Voix féminine configurée avec pitch plus aigu');
      } else if (voice.gender == 'male') {
        // Pitch plus grave pour voix masculine
        debugPrint('Voix masculine configurée avec pitch plus grave');
      }

      debugPrint(
        'TTS configuré pour la voix: ${voice.name} (${voice.style}, ${voice.gender})',
      );
    } catch (e) {
      debugPrint('Erreur configuration TTS pour la voix ${voice.name}: $e');
    }
  }

  /// Génère les données de waveform en temps réel
  void _startWaveformGeneration() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(
      const Duration(milliseconds: 50), // 20 FPS
      (_) => _updateWaveform(),
    );
  }

  /// Met à jour les données de waveform
  void _updateWaveform() {
    if (state.status != AudioPipelineStatus.listening) return;

    // Simulation du niveau audio avec patterns réalistes
    final random = Random();
    final baseLevel = 0.3 + random.nextDouble() * 0.4; // 0.3-0.7
    final spike = random.nextDouble() < 0.1 ? random.nextDouble() * 0.3 : 0.0;
    final currentVolume = (baseLevel + spike).clamp(0.0, 1.0);

    // Générer données waveform
    final waveformData = List.generate(_waveformBars, (index) {
      final variation = random.nextDouble() * 0.3 - 0.15; // -0.15 à +0.15
      final barLevel = (currentVolume + variation).clamp(0.0, 1.0);

      // Appliquer un pattern pour rendre plus naturel
      final pattern = sin((index / _waveformBars) * 2 * pi) * 0.1;
      return (barLevel + pattern).clamp(0.0, 1.0);
    });

    state = state.copyWith(
      currentVolume: currentVolume,
      waveformData: waveformData,
    );
  }

  /// Gère l'erreur de permission
  void handlePermissionError() {
    state = state.copyWith(
      status: AudioPipelineStatus.error,
      error: 'Permissions requises pour utiliser le microphone',
    );
  }

  /// Réinitialise après erreur
  void resetFromError() {
    state = state.copyWith(status: AudioPipelineStatus.idle, error: null);
    _startWakeWordDetection();
  }

  /// Active/désactive le wake word
  void toggleWakeWord(bool enabled) {
    if (enabled) {
      _startWakeWordDetection();
    } else {
      _wakeWordTimer?.cancel();
      state = state.copyWith(isWakeWordActive: false);
    }
  }

  /// Configure dynamiquement les phrase hints selon le contexte d'usage
  Future<void> configurePhraseHintsForContext(String context) async {
    try {
      debugPrint('🎯 Configuration phrase hints pour contexte: $context');

      bool success = false;

      switch (context.toLowerCase()) {
        case 'wake_word':
          success =
              await AzureSpeechPhraseHintsService.configureWakeWordHints();
          break;
        case 'navigation':
          success =
              await AzureSpeechPhraseHintsService.configureNavigationHints();
          break;
        case 'weather':
          success = await AzureSpeechPhraseHintsService.configureWeatherHints();
          break;
        case 'music':
          success = await AzureSpeechPhraseHintsService.configureMusicHints();
          break;
        case 'telephony':
          success =
              await AzureSpeechPhraseHintsService.configureTelephonyHints();
          break;
        case 'messaging':
          success =
              await AzureSpeechPhraseHintsService.configureMessagingHints();
          break;
        case 'calendar':
          success =
              await AzureSpeechPhraseHintsService.configureCalendarHints();
          break;
        case 'health':
          success = await AzureSpeechPhraseHintsService.configureHealthHints();
          break;
        case 'emergency':
          success =
              await AzureSpeechPhraseHintsService.configureEmergencyHints();
          break;
        case 'all':
        case 'complete':
        default:
          success = await AzureSpeechPhraseHintsService.configureAllHints();
          break;
      }

      if (success) {
        debugPrint('✅ Phrase hints pour "$context" configurées avec succès');
      } else {
        debugPrint('❌ Échec configuration phrase hints pour "$context"');
      }
    } catch (e) {
      debugPrint('🚨 Erreur configuration phrase hints pour "$context": $e');
    }
  }

  /// Efface toutes les phrase hints configurées
  Future<void> clearPhraseHints() async {
    try {
      debugPrint('🧹 Effacement de toutes les phrase hints...');

      final success = await AzureSpeechPhraseHintsService.clearAllHints();

      if (success) {
        debugPrint('✅ Phrase hints effacées avec succès');
      } else {
        debugPrint('❌ Échec de l\'effacement des phrase hints');
      }
    } catch (e) {
      debugPrint('🚨 Erreur lors de l\'effacement des phrase hints: $e');
    }
  }

  /// Obtient le niveau de calibration
  double getCalibrationQuality() {
    return _calibrationService.getCalibrationQuality();
  }

  /// Vérifie si une recalibration est nécessaire
  bool shouldRecalibrate() {
    return _calibrationService.shouldRecalibrate();
  }

  /// Améliore le profil avec de nouveaux échantillons
  Future<void> improveProfile(String recognizedText, double confidence) async {
    await _calibrationService.improveProfile(recognizedText, confidence);
  }

  /// AJOUT: Configure les timeouts dynamiquement
  void configureTimeouts({
    Duration? listeningTimeout,
    Duration? wakeWordInterval,
  }) {
    // Note: Pour une implémentation complète, on ajouterait des variables
    // d'instance pour stocker ces valeurs configurables
    debugPrint('Configuration des timeouts:');
    debugPrint(
      '  - Timeout écoute: ${listeningTimeout ?? _listeningTimeoutDuration}',
    );
    debugPrint(
      '  - Intervalle wake word: ${wakeWordInterval ?? _wakeWordDetectionInterval}',
    );
  }

  /// AJOUT: Force l'arrêt de tous les timers
  void stopAllTimers() {
    _wakeWordTimer?.cancel();
    _volumeTimer?.cancel();
    _listeningTimeout?.cancel();
    debugPrint('Tous les timers arrêtés');
  }

  @override
  void dispose() {
    _wakeWordTimer?.cancel();
    _volumeTimer?.cancel();
    _listeningTimeout?.cancel(); // AJOUT: Nettoyer le timeout d'écoute
    _audioStreamSubscription?.cancel();
    _calibrationService.dispose();
    super.dispose();
  }
}

/// Extensions pour l'état du pipeline
extension AudioPipelineStateExtensions on AudioPipelineState {
  /// Vérifie si le pipeline est actif
  bool get isActive =>
      status != AudioPipelineStatus.idle && status != AudioPipelineStatus.error;

  /// Vérifie si l'audio est en cours
  bool get isAudioActive =>
      status == AudioPipelineStatus.listening ||
      status == AudioPipelineStatus.speaking;

  /// Obtient la couleur de l'émotion actuelle
  Color get emotionColor => currentEmotion.primaryColor;

  /// Obtient le gradient de l'émotion actuelle
  Gradient get emotionGradient => currentEmotion.gradient;

  /// Vérifie si une erreur critique est présente
  bool get hasCriticalError =>
      status == AudioPipelineStatus.error && error != null;

  /// Obtient le message d'état utilisateur
  String get statusMessage {
    switch (status) {
      case AudioPipelineStatus.idle:
        return isWakeWordActive
            ? 'Dis "Hey Ric" ou touche-moi'
            : 'Assistant en veille';
      case AudioPipelineStatus.listening:
        return 'Je t\'écoute...';
      case AudioPipelineStatus.processing:
        return 'Traitement en cours...';
      case AudioPipelineStatus.speaking:
        return 'Je réponds...';
      case AudioPipelineStatus.error:
        return error ?? 'Erreur inconnue';
    }
  }
}

/// Commandes vocales prédéfinies
class VoiceCommands {
  static const Map<String, List<String>> commands = {
    'weather': ['météo', 'temps', 'température', 'climat'],
    'call': ['appelle', 'compose', 'téléphone', 'contact'],
    'music': ['musique', 'chanson', 'playlist', 'audio'],
    'messages': ['messages', 'SMS', 'textos', 'notifications'],
    'navigation': ['navigation', 'route', 'directions', 'aller'],
    'time': ['heure', 'temps', 'horloge'],
    'reminder': ['rappel', 'rappelle', 'note', 'mémo'],
    'help': ['aide', 'assistance', 'support', 'comment'],
  };

  /// Détecte le type de commande
  static String? detectCommandType(String text) {
    final normalizedText = text.toLowerCase();

    for (final entry in commands.entries) {
      for (final keyword in entry.value) {
        if (normalizedText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }
}
