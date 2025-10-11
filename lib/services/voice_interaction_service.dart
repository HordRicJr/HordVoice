import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_resolver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/voice_models.dart';
import '../theme/design_tokens.dart';
import 'environment_config.dart';
import 'azure_speech_service.dart';
import 'avatar_state_service.dart';

final voiceInteractionProvider =
    StateNotifierProvider<VoiceInteractionNotifier, VoiceInteractionState>(
      (ref) => VoiceInteractionNotifier(ref),
    );

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
  wakeWordDetection,
}

enum InteractionMode { continuous, pushToTalk, wakeWordActivated }

class VoiceInteractionState {
  final VoiceState currentState;
  final InteractionMode mode;
  final bool isInitialized;
  final bool microphonePermissionGranted;
  final String? currentTranscription;
  final String? lastError;
  final double confidenceLevel;
  final bool isWakeWordActive;
  final Duration lastInteractionTime;
  final Map<String, dynamic> sessionData;

  const VoiceInteractionState({
    this.currentState = VoiceState.idle,
    this.mode = InteractionMode.wakeWordActivated,
    this.isInitialized = false,
    this.microphonePermissionGranted = false,
    this.currentTranscription,
    this.lastError,
    this.confidenceLevel = 0.0,
    this.isWakeWordActive = false,
    this.lastInteractionTime = Duration.zero,
    this.sessionData = const {},
  });

  VoiceInteractionState copyWith({
    VoiceState? currentState,
    InteractionMode? mode,
    bool? isInitialized,
    bool? microphonePermissionGranted,
    String? currentTranscription,
    String? lastError,
    double? confidenceLevel,
    bool? isWakeWordActive,
    Duration? lastInteractionTime,
    Map<String, dynamic>? sessionData,
  }) {
    return VoiceInteractionState(
      currentState: currentState ?? this.currentState,
      mode: mode ?? this.mode,
      isInitialized: isInitialized ?? this.isInitialized,
      microphonePermissionGranted:
          microphonePermissionGranted ?? this.microphonePermissionGranted,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      lastError: lastError ?? this.lastError,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      isWakeWordActive: isWakeWordActive ?? this.isWakeWordActive,
      lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
      sessionData: sessionData ?? this.sessionData,
    );
  }
}

class VoiceInteractionNotifier extends StateNotifier<VoiceInteractionState> {
  VoiceInteractionNotifier(this.ref) : super(const VoiceInteractionState()) {
    _initialize();
  }

  final Ref ref;

  // Services
  late AzureSpeechService _speechService;
  late FlutterTts _azureTts;
  final EnvironmentConfig _envConfig = EnvironmentConfig();

  // Contrôleurs de flux
  StreamController<String>? _transcriptionController;
  StreamController<VoiceInteractionEvent>? _eventController;

  // Subscriptions aux streams
  StreamSubscription<SpeechRecognitionResult>? _speechResultSubscription;
  StreamSubscription<SpeechRecognitionStatus>? _speechStatusSubscription;
  StreamSubscription<SpeechRecognitionError>? _speechErrorSubscription;

  // Timers et états
  Timer? _sessionTimer;
  Timer? _confidenceTimer;
  Timer? _wakeWordTimer;

  // Configuration
  static const Duration sessionTimeout = Duration(minutes: 5);
  static const Duration confidenceUpdateInterval = Duration(milliseconds: 100);
  static const Duration wakeWordCooldown = Duration(milliseconds: 2000);
  static const double minimumConfidence = 0.6;
  static const String defaultWakeWord = "Hey Ric";

  // Getters pour les streams
  Stream<String> get transcriptionStream =>
      _transcriptionController?.stream ?? const Stream.empty();
  Stream<VoiceInteractionEvent> get eventStream =>
      _eventController?.stream ?? const Stream.empty();

  Future<void> _initialize() async {
    try {
      // Initialiser les contrôleurs de flux
      _transcriptionController = StreamController<String>.broadcast();
      _eventController = StreamController<VoiceInteractionEvent>.broadcast();

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les services Azure
      await _initializeAzureServices();

      // Configurer la session
      await _setupSession();

      // Activer le wake lock pour éviter la mise en veille
      await WakelockPlus.enable();

      state = state.copyWith(
        isInitialized: true,
        currentState: VoiceState.idle,
      );

      // Démarrer en mode wake word si configuré
      if (state.mode == InteractionMode.wakeWordActivated) {
        await startWakeWordDetection();
      }

      _emitEvent(VoiceInteractionEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation VoiceInteractionService: $e');
      state = state.copyWith(
        lastError: 'Erreur d\'initialisation: $e',
        currentState: VoiceState.error,
      );
      _emitEvent(
        VoiceInteractionEvent.error('Erreur d\'initialisation', e.toString()),
      );
    }
  }

  Future<void> _requestPermissions() async {
    final micPermission = await Permission.microphone.request();

    state = state.copyWith(
      microphonePermissionGranted: micPermission.isGranted,
    );

    if (!micPermission.isGranted) {
      throw Exception('Permission microphone refusée');
    }
  }

  Future<void> _initializeAzureServices() async {
    // Initialiser Azure Speech Service
    _speechService = AzureSpeechService();
    await _speechService.initialize();

    // S'abonner aux streams de reconnaissance
    _speechResultSubscription = _speechService.resultStream.listen((result) {
      _handleSpeechResult(result);
    });

    _speechStatusSubscription = _speechService.statusStream.listen((status) {
      _handleSpeechStatus(status);
    });

    _speechErrorSubscription = _speechService.errorStream.listen((error) {
      _handleSpeechError(error);
    });

    // Initialiser TTS avec fallback
    _azureTts = FlutterTts();
    await _envConfig.loadConfig();

  // Configuration TTS
  final ttsLang = await LanguageResolver.getTtsLanguage();
  await _azureTts.setLanguage(ttsLang);
    await _azureTts.setSpeechRate(0.8);
    await _azureTts.setVolume(1.0);
    await _azureTts.setPitch(1.0);

    // Configurer les callbacks TTS
    _azureTts.setStartHandler(() {
      _handleTtsStart();
    });

    _azureTts.setCompletionHandler(() {
      _handleTtsEnd();
    });

    _azureTts.setErrorHandler((message) {
      debugPrint('Erreur TTS: $message');
      _handleTtsError(message);
    });
  }

  Future<void> _setupSession() async {
    // Démarrer le timer de session
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(sessionTimeout, (_) {
      _handleSessionTimeout();
    });

    // Démarrer les mises à jour de confiance
    _confidenceTimer?.cancel();
    _confidenceTimer = Timer.periodic(confidenceUpdateInterval, (_) {
      _updateConfidenceLevel();
    });
  }

  // Gestion du Wake Word
  Future<void> startWakeWordDetection() async {
    if (!state.isInitialized ||
        state.currentState == VoiceState.wakeWordDetection) {
      return;
    }

    try {
      state = state.copyWith(
        currentState: VoiceState.wakeWordDetection,
        isWakeWordActive: true,
      );

      // Démarrer la reconnaissance continue pour le wake word
      await _speechService.startSimpleRecognition();

      _emitEvent(VoiceInteractionEvent.wakeWordActivated());
      debugPrint('Wake word detection démarré');
    } catch (e) {
      debugPrint('Erreur démarrage wake word: $e');
      state = state.copyWith(
        lastError: 'Erreur wake word: $e',
        currentState: VoiceState.error,
        isWakeWordActive: false,
      );
    }
  }

  Future<void> stopWakeWordDetection() async {
    if (!state.isWakeWordActive) return;

    try {
      await _speechService.stopRecognition();

      state = state.copyWith(
        isWakeWordActive: false,
        currentState: VoiceState.idle,
      );

      _emitEvent(VoiceInteractionEvent.wakeWordDeactivated());
      debugPrint('Wake word detection arrêté');
    } catch (e) {
      debugPrint('Erreur arrêt wake word: $e');
    }
  }

  // Gestion de la reconnaissance vocale
  Future<void> startListening() async {
    if (!state.isInitialized || !state.microphonePermissionGranted) {
      throw Exception('Service non initialisé ou permissions manquantes');
    }

    if (state.currentState == VoiceState.listening) {
      return;
    }

    try {
      // Arrêter le wake word si actif
      if (state.isWakeWordActive) {
        await stopWakeWordDetection();
      }

      state = state.copyWith(
        currentState: VoiceState.listening,
        lastError: null,
        currentTranscription: null,
      );

      // Mettre à jour l'avatar
      ref.read(avatarStateProvider.notifier).setListening(true);

      // Configurer et démarrer la reconnaissance
      _speechService.clearPhraseHints();
      await _speechService.startSimpleRecognition();

      _emitEvent(VoiceInteractionEvent.listeningStarted());
      debugPrint('Écoute démarrée');
    } catch (e) {
      debugPrint('Erreur démarrage écoute: $e');
      state = state.copyWith(
        lastError: 'Erreur de reconnaissance: $e',
        currentState: VoiceState.error,
      );
      _emitEvent(
        VoiceInteractionEvent.error('Erreur reconnaissance', e.toString()),
      );
    }
  }

  Future<void> stopListening() async {
    if (state.currentState != VoiceState.listening) {
      return;
    }

    try {
      await _speechService.stopRecognition();

      state = state.copyWith(currentState: VoiceState.processing);

      // Mettre à jour l'avatar
      ref.read(avatarStateProvider.notifier).setListening(false);

      _emitEvent(VoiceInteractionEvent.listeningStopped());
      debugPrint('Écoute arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt écoute: $e');
    }
  }

  // Gestion de la synthèse vocale
  Future<void> speak(String text, {VoiceOption? voice}) async {
    if (!state.isInitialized || text.isEmpty) {
      return;
    }

    try {
      // Suspendre la reconnaissance pendant la parole
      if (state.currentState == VoiceState.listening) {
        await stopListening();
      }

      state = state.copyWith(
        currentState: VoiceState.speaking,
        lastError: null,
      );

      // Mettre à jour l'avatar
      ref.read(avatarStateProvider.notifier).setSpeaking(true);

      // Configurer la voix si spécifiée
      if (voice != null) {
        await _azureTts.setVoice({'name': voice.id, 'locale': voice.language});
      }

      // Démarrer la synthèse
      await _azureTts.speak(text);

      _emitEvent(VoiceInteractionEvent.speakingStarted(text));
      debugPrint('Synthèse démarrée: $text');
    } catch (e) {
      debugPrint('Erreur synthèse vocale: $e');
      state = state.copyWith(
        lastError: 'Erreur de synthèse: $e',
        currentState: VoiceState.error,
      );
      _emitEvent(VoiceInteractionEvent.error('Erreur synthèse', e.toString()));
    }
  }

  Future<void> stopSpeaking() async {
    if (state.currentState != VoiceState.speaking) {
      return;
    }

    try {
      await _azureTts.stop();

      // Mettre à jour l'avatar
      ref.read(avatarStateProvider.notifier).setSpeaking(false);

      _emitEvent(VoiceInteractionEvent.speakingStopped());
      debugPrint('Synthèse arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt synthèse: $e');
    }
  }

  // Traitement des résultats de reconnaissance
  void _handleSpeechResult(SpeechRecognitionResult result) {
    try {
      final text = result.text.trim();

      if (text.isEmpty) return;

      debugPrint(
        'Résultat reconnaissance: $text (confidence: ${result.confidence})',
      );

      // Vérifier si c'est un wake word
      if (state.currentState == VoiceState.wakeWordDetection) {
        if (_isWakeWordDetected(text)) {
          _handleWakeWordDetected(text);
          return;
        }
        // Sinon, continuer la détection du wake word
        return;
      }

      // Traitement normal de la reconnaissance
      state = state.copyWith(
        currentTranscription: text,
        confidenceLevel: result.confidence,
        lastInteractionTime: Duration(
          milliseconds: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      _transcriptionController?.add(text);
      _emitEvent(
        VoiceInteractionEvent.transcriptionReceived(text, result.confidence),
      );

      // Si c'est un résultat final, traiter le texte
      if (result.isFinal && result.confidence >= minimumConfidence) {
        _processRecognizedText(text);
      }
    } catch (e) {
      debugPrint('Erreur traitement résultat: $e');
      _handleSpeechError(
        SpeechRecognitionError(
          errorMessage: 'Erreur traitement résultat: $e',
          errorType: SpeechErrorType.unknown,
        ),
      );
    }
  }

  void _handleSpeechStatus(SpeechRecognitionStatus status) {
    debugPrint('Statut reconnaissance: $status');

    switch (status) {
      case SpeechRecognitionStatus.listening:
        if (state.currentState != VoiceState.listening &&
            state.currentState != VoiceState.wakeWordDetection) {
          state = state.copyWith(currentState: VoiceState.listening);
        }
        break;
      case SpeechRecognitionStatus.stopped:
        if (state.currentState == VoiceState.listening) {
          state = state.copyWith(currentState: VoiceState.processing);
        }
        break;
      case SpeechRecognitionStatus.timeout:
        _handleTimeout();
        break;
      case SpeechRecognitionStatus.noMatch:
        _handleNoMatch();
        break;
      default:
        break;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint('Erreur reconnaissance: $error');

    state = state.copyWith(
      lastError: 'Erreur reconnaissance: ${error.message}',
      currentState: VoiceState.error,
    );

    // Mettre à jour l'avatar
    ref.read(avatarStateProvider.notifier).setListening(false);

    _emitEvent(
      VoiceInteractionEvent.error('Erreur reconnaissance', error.message),
    );

    // Redémarrer le wake word après une erreur
    if (state.mode == InteractionMode.wakeWordActivated) {
      Timer(const Duration(seconds: 2), () {
        startWakeWordDetection();
      });
    }
  }

  void _handleTimeout() {
    debugPrint('Timeout de reconnaissance');

    if (state.currentState == VoiceState.listening) {
      // Redémarrer l'écoute en mode continu
      if (state.mode == InteractionMode.continuous) {
        startListening();
      } else {
        startWakeWordDetection();
      }
    }
  }

  void _handleNoMatch() {
    debugPrint('Aucune correspondance trouvée');

    // Retourner en mode approprié
    if (state.mode == InteractionMode.continuous) {
      startListening();
    } else {
      startWakeWordDetection();
    }
  }

  // Gestion TTS
  void _handleTtsStart() {
    debugPrint('TTS démarré');
    state = state.copyWith(currentState: VoiceState.speaking);
    ref.read(avatarStateProvider.notifier).setSpeaking(true);
  }

  void _handleTtsEnd() {
    debugPrint('TTS terminé');

    ref.read(avatarStateProvider.notifier).setSpeaking(false);

    state = state.copyWith(currentState: VoiceState.idle);

    // Redémarrer la reconnaissance selon le mode
    Timer(const Duration(milliseconds: 500), () {
      if (state.mode == InteractionMode.continuous) {
        startListening();
      } else if (state.mode == InteractionMode.wakeWordActivated) {
        startWakeWordDetection();
      }
    });

    _emitEvent(VoiceInteractionEvent.speakingStopped());
  }

  void _handleTtsError(String error) {
    debugPrint('Erreur TTS: $error');
    ref.read(avatarStateProvider.notifier).setSpeaking(false);
    state = state.copyWith(
      lastError: 'Erreur TTS: $error',
      currentState: VoiceState.error,
    );
  }

  // Détection et traitement du wake word
  bool _isWakeWordDetected(String text) {
    final normalizedText = text.toLowerCase().trim();
    final wakeWords = ['hey ric', 'héric', 'eric', 'hey rick', 'hé ric', 'ric'];

    return wakeWords.any(
      (wakeWord) =>
          normalizedText.contains(wakeWord) ||
          _calculateSimilarity(normalizedText, wakeWord) > 0.7,
    );
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;

    if (longer.length == 0) return 1.0;

    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  void _handleWakeWordDetected(String text) {
    debugPrint('Wake word détecté: $text');

    // Cooldown pour éviter les détections multiples
    if (_wakeWordTimer?.isActive == true) {
      return;
    }

    _wakeWordTimer = Timer(wakeWordCooldown, () {});

    // Déclencher l'animation de réveil de l'avatar
    ref
        .read(avatarStateProvider.notifier)
        .setEmotion(EmotionType.surprise, 0.7);

    _emitEvent(VoiceInteractionEvent.wakeWordDetected(text));

    // Démarrer l'écoute active
    Timer(const Duration(milliseconds: 500), () {
      startListening();
    });
  }

  // Traitement du texte reconnu
  Future<void> _processRecognizedText(String text) async {
    if (text.isEmpty) return;

    try {
      state = state.copyWith(currentState: VoiceState.processing);

      // Simuler le traitement (à remplacer par l'intégration avec OpenAI)
      final response = _generateMockResponse(text);

      if (response.isNotEmpty) {
        // Synthétiser la réponse
        await speak(response);
      } else {
        // Pas de réponse, retourner en mode écoute
        if (state.mode == InteractionMode.continuous) {
          await startListening();
        } else {
          await startWakeWordDetection();
        }
      }

      _emitEvent(VoiceInteractionEvent.textProcessed(text, response));
    } catch (e) {
      debugPrint('Erreur traitement texte: $e');
      state = state.copyWith(
        lastError: 'Erreur traitement: $e',
        currentState: VoiceState.error,
      );
      _emitEvent(
        VoiceInteractionEvent.error('Erreur traitement', e.toString()),
      );
    }
  }

  String _generateMockResponse(String input) {
    // Réponses simulées - à remplacer par l'intégration OpenAI
    final responses = {
      'bonjour': 'Bonjour ! Comment allez-vous ?',
      'salut': 'Salut ! Que puis-je faire pour vous ?',
      'ça va': 'Très bien, merci ! Et vous ?',
      'merci': 'De rien, c\'est un plaisir de vous aider !',
      'au revoir': 'Au revoir ! À bientôt !',
    };

    for (final key in responses.keys) {
      if (input.toLowerCase().contains(key)) {
        return responses[key]!;
      }
    }

    return 'Je vous écoute, que puis-je faire pour vous ?';
  }

  // Gestion des sessions
  void _handleSessionTimeout() {
    debugPrint('Session timeout');

    if (state.currentState == VoiceState.listening) {
      stopListening();
    }

    // Redémarrer en mode wake word
    if (state.mode == InteractionMode.wakeWordActivated) {
      startWakeWordDetection();
    }

    _emitEvent(VoiceInteractionEvent.sessionTimeout());
  }

  void _updateConfidenceLevel() {
    // Mise à jour du niveau de confiance basé sur l'état actuel
    if (state.currentState == VoiceState.listening &&
        _speechService.isListening) {
      // Le niveau de confiance viendrait normalement du service de reconnaissance
      // Pour l'instant, on simule une valeur
      final confidence = 0.5 + (DateTime.now().millisecond % 500) / 1000;
      state = state.copyWith(confidenceLevel: confidence);
    }
  }

  // Contrôle des modes
  Future<void> setInteractionMode(InteractionMode mode) async {
    if (state.mode == mode) return;

    // Arrêter l'état actuel
    switch (state.currentState) {
      case VoiceState.listening:
        await stopListening();
        break;
      case VoiceState.wakeWordDetection:
        await stopWakeWordDetection();
        break;
      case VoiceState.speaking:
        await stopSpeaking();
        break;
      default:
        break;
    }

    state = state.copyWith(mode: mode);

    // Démarrer le nouveau mode
    switch (mode) {
      case InteractionMode.wakeWordActivated:
        await startWakeWordDetection();
        break;
      case InteractionMode.continuous:
        await startListening();
        break;
      case InteractionMode.pushToTalk:
        // Ne rien faire, attendre l'activation manuelle
        break;
    }

    _emitEvent(VoiceInteractionEvent.modeChanged(mode));
  }

  // Utilitaires
  void _emitEvent(VoiceInteractionEvent event) {
    _eventController?.add(event);
  }

  // Nettoyage
  @override
  void dispose() {
    _sessionTimer?.cancel();
    _confidenceTimer?.cancel();
    _wakeWordTimer?.cancel();

    _speechResultSubscription?.cancel();
    _speechStatusSubscription?.cancel();
    _speechErrorSubscription?.cancel();

    _transcriptionController?.close();
    _eventController?.close();

    WakelockPlus.disable();

    super.dispose();
  }
}

// Classe pour les événements d'interaction vocale
class VoiceInteractionEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VoiceInteractionEvent._(this.type, this.data) : timestamp = DateTime.now();

  factory VoiceInteractionEvent.initialized() =>
      VoiceInteractionEvent._('initialized', {});

  factory VoiceInteractionEvent.wakeWordActivated() =>
      VoiceInteractionEvent._('wakeWordActivated', {});

  factory VoiceInteractionEvent.wakeWordDeactivated() =>
      VoiceInteractionEvent._('wakeWordDeactivated', {});

  factory VoiceInteractionEvent.wakeWordDetected(String text) =>
      VoiceInteractionEvent._('wakeWordDetected', {'text': text});

  factory VoiceInteractionEvent.listeningStarted() =>
      VoiceInteractionEvent._('listeningStarted', {});

  factory VoiceInteractionEvent.listeningStopped() =>
      VoiceInteractionEvent._('listeningStopped', {});

  factory VoiceInteractionEvent.transcriptionReceived(
    String text,
    double confidence,
  ) => VoiceInteractionEvent._('transcriptionReceived', {
    'text': text,
    'confidence': confidence,
  });

  factory VoiceInteractionEvent.speakingStarted(String text) =>
      VoiceInteractionEvent._('speakingStarted', {'text': text});

  factory VoiceInteractionEvent.speakingStopped() =>
      VoiceInteractionEvent._('speakingStopped', {});

  factory VoiceInteractionEvent.textProcessed(String input, String response) =>
      VoiceInteractionEvent._('textProcessed', {
        'input': input,
        'response': response,
      });

  factory VoiceInteractionEvent.modeChanged(InteractionMode mode) =>
      VoiceInteractionEvent._('modeChanged', {'mode': mode.toString()});

  factory VoiceInteractionEvent.sessionTimeout() =>
      VoiceInteractionEvent._('sessionTimeout', {});

  factory VoiceInteractionEvent.error(String message, String details) =>
      VoiceInteractionEvent._('error', {
        'message': message,
        'details': details,
      });
}
