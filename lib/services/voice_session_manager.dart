import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_session/audio_session.dart';
import 'azure_speech_service.dart';
import 'azure_openai_service.dart';
import 'permission_manager_service.dart';
import 'emotional_avatar_service.dart';

/// Provider pour le gestionnaire de session vocale
final voiceSessionManagerProvider =
    StateNotifierProvider<VoiceSessionManager, VoiceSessionState>(
      (ref) => VoiceSessionManager(),
    );

/// États possibles du gestionnaire de session vocale
enum VoiceSessionStatus {
  idle, // Inactif - prêt à écouter
  listening, // En écoute active (STT)
  processing, // Traitement de la requête (GPT)
  speaking, // Synthèse vocale en cours (TTS)
  error, // Erreur rencontrée
  interrupted, // Interrompu par l'utilisateur
}

/// État complet de la session vocale
class VoiceSessionState {
  final VoiceSessionStatus status;
  final String? currentTranscript;
  final String? currentResponse;
  final String? errorMessage;
  final double confidenceLevel;
  final bool isMuted;
  final bool isListening;
  final bool isSpeaking;
  final List<String> sessionHistory;
  final DateTime? lastActivity;
  final String? currentEmotion;
  final double audioLevel;

  const VoiceSessionState({
    this.status = VoiceSessionStatus.idle,
    this.currentTranscript,
    this.currentResponse,
    this.errorMessage,
    this.confidenceLevel = 0.0,
    this.isMuted = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.sessionHistory = const [],
    this.lastActivity,
    this.currentEmotion,
    this.audioLevel = 0.0,
  });

  VoiceSessionState copyWith({
    VoiceSessionStatus? status,
    String? currentTranscript,
    String? currentResponse,
    String? errorMessage,
    double? confidenceLevel,
    bool? isMuted,
    bool? isListening,
    bool? isSpeaking,
    List<String>? sessionHistory,
    DateTime? lastActivity,
    String? currentEmotion,
    double? audioLevel,
  }) {
    return VoiceSessionState(
      status: status ?? this.status,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      currentResponse: currentResponse ?? this.currentResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      isMuted: isMuted ?? this.isMuted,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      lastActivity: lastActivity ?? this.lastActivity,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}

/// Gestionnaire centralisé des sessions vocales - Évite les conflits STT/TTS
class VoiceSessionManager extends StateNotifier<VoiceSessionState> {
  VoiceSessionManager() : super(const VoiceSessionState()) {
    _initialize();
  }

  // Services
  late AzureSpeechService _speechService;
  late AzureOpenAIService _aiService;
  late FlutterTts _tts;
  late AudioSession _audioSession;

  // Service émotionnel pour réactivité avatar
  EmotionalAvatarService? _emotionalService;

  // Controllers & Streams
  StreamSubscription? _speechSubscription;
  StreamSubscription? _speechErrorSubscription;
  Timer? _sessionTimer;
  Timer? _confidenceTimer;

  // Configuration
  static const Duration _silenceTimeout = Duration(seconds: 5);

  // Flags de contrôle - CRITIQUES pour éviter concurrence
  bool _isInitialized = false;
  bool _isSttActive = false;
  bool _isTtsActive = false;
  bool _isProcessingRequest = false;
  final List<VoidCallback> _pendingActions = [];

  /// Initialisation des services
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🎤 Initialisation VoiceSessionManager...');

      // Vérifier les permissions micro
      final hasPermissions =
          await PermissionManagerService.hasEssentialPermissions();

      if (!hasPermissions) {
        _setError('Permission microphone requise');
        return;
      }

      // Initialiser session audio
      await _initializeAudioSession();

      // Initialiser Azure Speech
      _speechService = AzureSpeechService();
      await _speechService.initialize();

      // Initialiser Azure OpenAI
      _aiService = AzureOpenAIService();
      await _aiService.initialize();

      // Initialiser TTS
      await _initializeTts();

      // Écouter les événements de reconnaissance
      _setupSpeechListeners();

      _isInitialized = true;
      state = state.copyWith(
        status: VoiceSessionStatus.idle,
        lastActivity: DateTime.now(),
      );

      debugPrint('✅ VoiceSessionManager initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation VoiceSessionManager: $e');
      _setError('Erreur initialisation: $e');
    }
  }

  /// Configuration session audio - CRITIQUE pour éviter conflits
  Future<void> _initializeAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );

    debugPrint('🔊 Session audio configurée');
  }

  /// Initialisation TTS avec callbacks
  Future<void> _initializeTts() async {
    _tts = FlutterTts();

    // Configuration de base
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(0.9);
    await _tts.setPitch(1.0);

    // Callbacks critiques pour tracking état
    _tts.setStartHandler(() {
      debugPrint('🗣️ TTS démarré');
      _isTtsActive = true;
      state = state.copyWith(
        status: VoiceSessionStatus.speaking,
        isSpeaking: true,
        lastActivity: DateTime.now(),
      );
    });

    _tts.setCompletionHandler(() {
      debugPrint('✅ TTS terminé');
      _isTtsActive = false;
      _onTtsCompleted();
    });

    _tts.setErrorHandler((message) {
      debugPrint('❌ Erreur TTS: $message');
      _isTtsActive = false;
      _handleTtsError(message);
    });

    debugPrint('🗣️ TTS initialisé');
  }

  /// Configuration des listeners pour Azure Speech
  void _setupSpeechListeners() {
    _speechSubscription = _speechService.resultStream.listen(
      (result) => _handleSpeechResult(result),
      onError: (error) => _handleSpeechError(error),
    );
  }

  /// **MÉTHODE PUBLIQUE** - Connecter le service émotionnel pour réactivité avatar
  void connectEmotionalService(EmotionalAvatarService emotionalService) {
    _emotionalService = emotionalService;
    debugPrint('🎭 Service émotionnel connecté au VoiceSessionManager');
  }

  /// **MÉTHODE PUBLIQUE** - Démarrer l'écoute (respecte séquencement)
  Future<bool> startListening() async {
    if (!_isInitialized) {
      debugPrint('⚠️ VoiceSessionManager non initialisé');
      return false;
    }

    // VÉRIFICATION CRITIQUE: Pas de TTS en cours
    if (_isTtsActive) {
      debugPrint('⚠️ TTS en cours - écoute bloquée');
      return false;
    }

    // VÉRIFICATION CRITIQUE: Déjà en écoute
    if (_isSttActive) {
      debugPrint('⚠️ STT déjà actif');
      return false;
    }

    try {
      debugPrint('🎤 Démarrage écoute...');

      // Demander audio focus
      await _audioSession.setActive(true);

      // Démarrer reconnaissance
      await _speechService.startListening();

      _isSttActive = true;
      state = state.copyWith(
        status: VoiceSessionStatus.listening,
        isListening: true,
        currentTranscript: null,
        errorMessage: null,
        lastActivity: DateTime.now(),
      );

      // Timeout de silence
      _startSilenceTimer();

      debugPrint('✅ Écoute démarrée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur démarrage écoute: $e');
      _isSttActive = false;
      _setError('Erreur démarrage écoute: $e');
      return false;
    }
  }

  /// **MÉTHODE PUBLIQUE** - Arrêter l'écoute
  Future<void> stopListening() async {
    if (!_isSttActive) return;

    try {
      debugPrint('🛑 Arrêt écoute...');

      await _speechService.stopListening();
      _isSttActive = false;

      state = state.copyWith(
        status: VoiceSessionStatus.idle,
        isListening: false,
      );

      _cancelSilenceTimer();
      debugPrint('✅ Écoute arrêtée');
    } catch (e) {
      debugPrint('❌ Erreur arrêt écoute: $e');
      _isSttActive = false;
    }
  }

  /// **MÉTHODE PUBLIQUE** - Synthèse vocale (respecte séquencement)
  Future<bool> speak(String text, {String? emotion}) async {
    if (!_isInitialized || text.isEmpty) return false;

    // VÉRIFICATION CRITIQUE: Arrêter STT d'abord
    if (_isSttActive) {
      debugPrint('🛑 Arrêt STT avant TTS');
      await stopListening();
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Délai stabilisation
    }

    // VÉRIFICATION CRITIQUE: Pas de TTS concurrent
    if (_isTtsActive) {
      debugPrint('⚠️ TTS déjà actif - arrêt forcé');
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      debugPrint(
        '🗣️ Démarrage TTS: ${text.substring(0, min(50, text.length))}...',
      );

      // Configurer émotion si fournie
      if (emotion != null) {
        await _configureEmotionalTts(emotion);
      }

      // Demander audio focus
      await _audioSession.setActive(true);

      state = state.copyWith(currentResponse: text, currentEmotion: emotion);

      // Démarrer synthèse
      await _tts.speak(text);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur TTS: $e');
      _isTtsActive = false;
      _setError('Erreur synthèse vocale: $e');
      return false;
    }
  }

  /// **MÉTHODE PUBLIQUE** - Arrêter toute activité
  Future<void> stopAll() async {
    debugPrint('🛑 Arrêt complet session vocale');

    try {
      // Arrêter TTS immédiatement
      if (_isTtsActive) {
        await _tts.stop();
        _isTtsActive = false;
      }

      // Arrêter STT
      if (_isSttActive) {
        await _speechService.stopListening();
        _isSttActive = false;
      }

      // Libérer audio focus
      await _audioSession.setActive(false);

      state = state.copyWith(
        status: VoiceSessionStatus.idle,
        isListening: false,
        isSpeaking: false,
        currentTranscript: null,
        currentResponse: null,
      );

      _cancelAllTimers();
      debugPrint('✅ Session arrêtée');
    } catch (e) {
      debugPrint('❌ Erreur arrêt session: $e');
    }
  }

  /// **MÉTHODE PUBLIQUE** - Traitement complet requête vocale
  Future<void> processVoiceRequest(String transcript) async {
    if (_isProcessingRequest) {
      debugPrint('⚠️ Traitement déjà en cours');
      return;
    }

    _isProcessingRequest = true;

    try {
      debugPrint('🧠 Traitement requête: $transcript');

      state = state.copyWith(
        status: VoiceSessionStatus.processing,
        currentTranscript: transcript,
      );

      // Analyser intention et extraire slots
      final response = await _aiService.generatePersonalizedResponse(
        transcript,
        'voice_assistant',
        'user_${DateTime.now().millisecondsSinceEpoch}',
        state.sessionHistory.take(5).toList(),
      );

      if (response.isNotEmpty) {
        // Démarrer TTS avec la réponse
        await speak(response, emotion: 'neutral');

        // Ajouter à l'historique
        final newHistory = [
          ...state.sessionHistory,
          'U: $transcript',
          'A: $response',
        ];
        state = state.copyWith(sessionHistory: newHistory);
      } else {
        await speak(
          'Je n\'ai pas bien compris votre demande. Pouvez-vous répéter ?',
          emotion: 'apologetic',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur traitement requête: $e');
      await speak(
        'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        emotion: 'apologetic',
      );
    } finally {
      _isProcessingRequest = false;
    }
  }

  /// Gestion résultat reconnaissance vocale
  void _handleSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedText;
    final isInterim = !result.isFinal;
    final confidence = result.confidence;

    if (text.isNotEmpty) {
      state = state.copyWith(
        currentTranscript: text,
        confidenceLevel: confidence,
        lastActivity: DateTime.now(),
      );

      // Réaction émotionnelle à la voix détectée
      if (_emotionalService != null && !isInterim) {
        _emotionalService!.onVoiceStimulus(
          volume: confidence, // Utiliser la confiance comme proxy du volume
          pitch:
              200, // Pitch par défaut (pourrait être amélioré avec analyse audio)
          emotion: _detectVoiceEmotion(text),
          content: text,
        );
      }

      // Si résultat final avec bonne confiance
      if (!isInterim && confidence > 0.7) {
        debugPrint(
          '✅ Transcription finale: $text (conf: ${(confidence * 100).toInt()}%)',
        );

        // Arrêter l'écoute et traiter
        stopListening().then((_) {
          processVoiceRequest(text);
        });
      }
    }
  }

  /// Gestion erreurs reconnaissance
  void _handleSpeechError(dynamic error) {
    debugPrint('❌ Erreur STT: $error');
    _isSttActive = false;
    _setError('Erreur reconnaissance: $error');
  }

  /// Callback fin TTS
  void _onTtsCompleted() {
    state = state.copyWith(
      status: VoiceSessionStatus.idle,
      isSpeaking: false,
      lastActivity: DateTime.now(),
    );

    // Traiter actions en attente
    _processPendingActions();
  }

  /// Gestion erreur TTS
  void _handleTtsError(String message) {
    _setError('Erreur TTS: $message');
    _onTtsCompleted(); // Reset état
  }

  /// Configuration TTS émotionnel
  Future<void> _configureEmotionalTts(String emotion) async {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'joie':
        await _tts.setPitch(1.2);
        await _tts.setSpeechRate(0.9);
        break;
      case 'calm':
      case 'calme':
        await _tts.setPitch(0.9);
        await _tts.setSpeechRate(0.7);
        break;
      case 'apologetic':
      case 'désolé':
        await _tts.setPitch(0.8);
        await _tts.setSpeechRate(0.6);
        break;
      default:
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.8);
    }
  }

  /// Timer silence - arrête écoute si pas d'activité
  void _startSilenceTimer() {
    _cancelSilenceTimer();
    _sessionTimer = Timer(_silenceTimeout, () {
      if (_isSttActive && state.currentTranscript?.isEmpty != false) {
        debugPrint('⏰ Timeout silence - arrêt écoute');
        stopListening();
      }
    });
  }

  void _cancelSilenceTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _cancelAllTimers() {
    _cancelSilenceTimer();
    _confidenceTimer?.cancel();
    _confidenceTimer = null;
  }

  /// Gestion actions en attente
  void _processPendingActions() {
    if (_pendingActions.isNotEmpty) {
      final action = _pendingActions.removeAt(0);
      action();
    }
  }

  /// Set erreur avec cleanup
  void _setError(String message) {
    debugPrint('❌ VoiceSessionManager Error: $message');
    state = state.copyWith(
      status: VoiceSessionStatus.error,
      errorMessage: message,
      isListening: false,
      isSpeaking: false,
    );

    // Cleanup
    _isSttActive = false;
    _isTtsActive = false;
    _cancelAllTimers();
  }

  /// Détecte l'émotion basée sur le contenu vocal (simple analyse de mots-clés)
  String? _detectVoiceEmotion(String text) {
    final lowerText = text.toLowerCase();

    // Mots joyeux
    if (lowerText.contains(
      RegExp(
        r'\b(super|génial|fantastique|excellent|bravo|merci|content|heureux|joie)\b',
      ),
    )) {
      return 'happy';
    }

    // Mots excités
    if (lowerText.contains(
      RegExp(r'\b(wow|incroyable|amazing|parfait|formidable|magnifique)\b'),
    )) {
      return 'excited';
    }

    // Mots tristes
    if (lowerText.contains(
      RegExp(r'\b(triste|déprimé|mal|problème|erreur|dommage)\b'),
    )) {
      return 'sad';
    }

    // Mots de surprise
    if (lowerText.contains(
      RegExp(r'\b(quoi|vraiment|surprise|étonnant|inattendu)\b'),
    )) {
      return 'surprised';
    }

    // Questions (confusion potentielle)
    if (lowerText.contains(RegExp(r'\b(comment|pourquoi|que|quoi)\b')) ||
        lowerText.contains('?')) {
      return 'confused';
    }

    return null; // Neutre par défaut
  }

  /// Cleanup à la destruction
  @override
  void dispose() {
    debugPrint('🧹 Cleanup VoiceSessionManager');

    stopAll();
    _speechSubscription?.cancel();
    _cancelAllTimers();

    super.dispose();
  }

  /// Méthodes utilitaires publiques
  bool get isReady => _isInitialized && state.status == VoiceSessionStatus.idle;
  bool get isBusy => _isSttActive || _isTtsActive || _isProcessingRequest;
  bool get canStartListening => isReady && !_isTtsActive;
}
