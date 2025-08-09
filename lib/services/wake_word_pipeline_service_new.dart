import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:mic_stream/mic_stream.dart' as mic;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/voice_models.dart';
import '../theme/design_tokens.dart';
import 'permission_manager_service.dart';
import 'voice_calibration_service.dart';
import 'azure_wake_word_service.dart';
import 'unified_hordvoice_service.dart';

final wakeWordPipelineProvider =
    StateNotifierProvider<WakeWordPipelineNotifier, WakeWordPipelineState>(
      (ref) => WakeWordPipelineNotifier(),
    );

class WakeWordPipelineState {
  final WakeWordStatus status;
  final bool isWakeWordEnabled;
  final bool isListening;
  final bool isSpeaking;
  final double audioLevel;
  final List<double> waveformData;
  final String lastTranscription;
  final String currentResponse;
  final EmotionType currentEmotion;
  final double emotionIntensity;
  final VoiceOption selectedVoice;
  final String errorMessage;
  final DateTime lastWakeWordTime;
  final bool isProcessing;
  final bool needsConfirmation;
  final String confirmationQuestion;

  const WakeWordPipelineState({
    this.status = WakeWordStatus.initializing,
    this.isWakeWordEnabled = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
    this.waveformData = const [],
    this.lastTranscription = '',
    this.currentResponse = '',
    this.currentEmotion = EmotionType.neutral,
    this.emotionIntensity = 0.0,
    this.selectedVoice = const VoiceOption(
      id: 'clara',
      name: 'Clara',
      language: 'fr-FR',
      style: 'warm',
      gender: 'female',
      description: 'Voix féminine chaleureuse',
    ),
    this.errorMessage = '',
    required this.lastWakeWordTime,
    this.isProcessing = false,
    this.needsConfirmation = false,
    this.confirmationQuestion = '',
  });

  factory WakeWordPipelineState.initial() {
    return WakeWordPipelineState(lastWakeWordTime: DateTime.now());
  }

  WakeWordPipelineState copyWith({
    WakeWordStatus? status,
    bool? isWakeWordEnabled,
    bool? isListening,
    bool? isSpeaking,
    double? audioLevel,
    List<double>? waveformData,
    String? lastTranscription,
    String? currentResponse,
    EmotionType? currentEmotion,
    double? emotionIntensity,
    VoiceOption? selectedVoice,
    String? errorMessage,
    DateTime? lastWakeWordTime,
    bool? isProcessing,
    bool? needsConfirmation,
    String? confirmationQuestion,
  }) {
    return WakeWordPipelineState(
      status: status ?? this.status,
      isWakeWordEnabled: isWakeWordEnabled ?? this.isWakeWordEnabled,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
      waveformData: waveformData ?? this.waveformData,
      lastTranscription: lastTranscription ?? this.lastTranscription,
      currentResponse: currentResponse ?? this.currentResponse,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      errorMessage: errorMessage ?? this.errorMessage,
      lastWakeWordTime: lastWakeWordTime ?? this.lastWakeWordTime,
      isProcessing: isProcessing ?? this.isProcessing,
      needsConfirmation: needsConfirmation ?? this.needsConfirmation,
      confirmationQuestion: confirmationQuestion ?? this.confirmationQuestion,
    );
  }
}

enum WakeWordStatus {
  initializing,
  ready,
  listening,
  processing,
  speaking,
  error,
  disabled,
  awaitingConfirmation,
}

class WakeWordPipelineNotifier extends StateNotifier<WakeWordPipelineState> {
  WakeWordPipelineNotifier() : super(WakeWordPipelineState.initial()) {
    _initialize();
  }

  late AzureWakeWordService _wakeWordService;
  late UnifiedHordVoiceService _unifiedService;
  late FlutterTts _tts;
  late AudioPlayer _audioPlayer;
  late AudioSession _audioSession;
  late VoiceCalibrationService _calibrationService;

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  StreamSubscription<WakeWordDetectionResult>? _wakeWordSubscription;
  StreamSubscription<WakeWordConfirmationRequest>? _confirmationSubscription;
  Timer? _audioLevelTimer;
  Timer? _listeningTimeoutTimer;

  WakeWordDetectionCandidate? _pendingConfirmation;

  static const Duration listeningTimeout = Duration(seconds: 8);
  static const int sampleRate = 16000;
  static const int waveformBars = 24;

  Future<void> _initialize() async {
    try {
      state = state.copyWith(status: WakeWordStatus.initializing);

      await _initializeAudioSession();
      await _initializeWakeWordService();
      await _initializeTTS();
      await _initializeServices();

      final hasPermissions =
          await PermissionManagerService.hasEssentialPermissions();

      if (hasPermissions) {
        await _startWakeWordDetection();
        state = state.copyWith(
          status: WakeWordStatus.ready,
          isWakeWordEnabled: true,
        );
        await _playGreeting();
      } else {
        state = state.copyWith(
          status: WakeWordStatus.disabled,
          errorMessage: 'Permissions microphone requises',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: WakeWordStatus.error,
        errorMessage: 'Erreur initialisation: $e',
      );
    }
  }

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
        androidWillPauseWhenDucked: true,
      ),
    );

    _audioPlayer = AudioPlayer();
  }

  Future<void> _initializeWakeWordService() async {
    try {
      _wakeWordService = AzureWakeWordService();
      await _wakeWordService.initialize();

      // Écouter les détections de wake-word
      _wakeWordSubscription = _wakeWordService.detectionStream.listen(
        _onWakeWordDetected,
      );

      // Écouter les demandes de confirmation
      _confirmationSubscription = _wakeWordService.confirmationStream.listen(
        _onConfirmationRequest,
      );

      debugPrint('Azure Wake Word Service initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation Azure Wake Word Service: $e');
      throw Exception('Azure Wake Word Service non disponible: $e');
    }
  }

  Future<void> _initializeTTS() async {
    _tts = FlutterTts();
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      state = state.copyWith(
        isSpeaking: false,
        status: state.isWakeWordEnabled
            ? WakeWordStatus.ready
            : WakeWordStatus.disabled,
      );
    });

    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });
  }

  Future<void> _initializeServices() async {
    _calibrationService = VoiceCalibrationService();
    await _calibrationService.initialize();

    _unifiedService = UnifiedHordVoiceService();
    await _unifiedService.initialize();
  }

  Future<void> _startWakeWordDetection() async {
    if (state.isWakeWordEnabled) return;

    try {
      await WakelockPlus.enable();

      // Démarrer l'écoute des mots déclencheurs avec Azure
      await _wakeWordService.startListening();

      // Démarrer la visualisation audio
      _audioStreamSubscription = mic.MicStream.microphone(
        audioSource: mic.AudioSource.DEFAULT,
        sampleRate: sampleRate,
        channelConfig: mic.ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: mic.AudioFormat.ENCODING_PCM_16BIT,
      ).listen(_processAudioData);

      _startAudioLevelUpdates();

      state = state.copyWith(isWakeWordEnabled: true);
    } catch (e) {
      state = state.copyWith(
        status: WakeWordStatus.error,
        errorMessage: 'Erreur wake word: $e',
      );
    }
  }

  void _processAudioData(Uint8List audioData) {
    final audioLevel = _calculateRMS(audioData);
    final waveformData = _generateWaveform(audioData);

    state = state.copyWith(audioLevel: audioLevel, waveformData: waveformData);
  }

  double _calculateRMS(Uint8List audioData) {
    if (audioData.isEmpty) return 0.0;

    double sum = 0.0;
    for (int i = 0; i < audioData.length; i += 2) {
      if (i + 1 < audioData.length) {
        final sample = (audioData[i] | (audioData[i + 1] << 8)).toSigned(16);
        sum += sample * sample;
      }
    }

    final rms = sqrt(sum / (audioData.length / 2));
    return (rms / 32768.0).clamp(0.0, 1.0);
  }

  List<double> _generateWaveform(Uint8List audioData) {
    final chunkSize = audioData.length ~/ waveformBars;
    final waveform = <double>[];

    for (int i = 0; i < waveformBars; i++) {
      final start = i * chunkSize;
      final end = min(start + chunkSize, audioData.length);

      if (start < audioData.length) {
        final chunk = audioData.sublist(start, end);
        final level = _calculateRMS(chunk);
        waveform.add(level);
      } else {
        waveform.add(0.0);
      }
    }

    return waveform;
  }

  /// Gère la détection d'un wake-word
  void _onWakeWordDetected(WakeWordDetectionResult result) {
    if (!result.isDetected) {
      if (result.error != null) {
        state = state.copyWith(
          status: WakeWordStatus.error,
          errorMessage: result.error!,
        );
      }
      return;
    }

    debugPrint(
      'Wake-word détecté: ${result.matchedText} (conf: ${result.confidence})',
    );

    // Déclencher les retours tactiles et visuels
    HapticFeedback.lightImpact();

    state = state.copyWith(
      status: WakeWordStatus.listening,
      isListening: true,
      lastWakeWordTime: result.timestamp,
      currentEmotion: EmotionType.joy,
      emotionIntensity: 0.8,
      lastTranscription: result.originalText,
    );

    // Démarrer l'écoute de la conversation
    _startConversationListening();
  }

  /// Gère une demande de confirmation pour un wake-word incertain
  void _onConfirmationRequest(WakeWordConfirmationRequest request) {
    debugPrint('Demande de confirmation: ${request.question}');

    _pendingConfirmation = request.candidate;

    state = state.copyWith(
      status: WakeWordStatus.awaitingConfirmation,
      needsConfirmation: true,
      confirmationQuestion: request.question,
    );

    // Poser la question vocalement
    _speakResponse(request.question);
  }

  /// Confirme ou rejette un wake-word en attente
  void confirmWakeWord(bool confirmed) {
    if (_pendingConfirmation == null) return;

    _wakeWordService.confirmWakeWord(_pendingConfirmation!, confirmed);
    _pendingConfirmation = null;

    state = state.copyWith(
      needsConfirmation: false,
      confirmationQuestion: '',
      status: WakeWordStatus.ready,
    );

    if (confirmed) {
      // Si confirmé, démarrer l'écoute
      _startConversationListening();
    }
  }

  Future<void> _startConversationListening() async {
    try {
      _listeningTimeoutTimer?.cancel();
      _listeningTimeoutTimer = Timer(listeningTimeout, _stopListening);

      state = state.copyWith(
        status: WakeWordStatus.listening,
        isListening: true,
      );

      // Attendre la transcription complète depuis Azure
      // Note: Dans la vraie implémentation, on écouterait les résultats finaux
      await Future.delayed(const Duration(seconds: 3)); // Simulation

      // Simulation d'une transcription
      final transcription = "Quelle heure est-il ?";
      _onSpeechResult(transcription);
    } catch (e) {
      state = state.copyWith(
        status: WakeWordStatus.error,
        errorMessage: 'Erreur écoute: $e',
        isListening: false,
      );
    }
  }

  void _onSpeechResult(String transcription) {
    _listeningTimeoutTimer?.cancel();

    state = state.copyWith(
      lastTranscription: transcription,
      isListening: false,
      status: WakeWordStatus.processing,
      isProcessing: true,
    );

    _processTranscription(transcription);
  }

  Future<void> _processTranscription(String transcription) async {
    try {
      // Analyser l'émotion
      final emotion = await _analyzeEmotion(transcription);

      state = state.copyWith(
        currentEmotion: emotion.type,
        emotionIntensity: emotion.intensity,
      );

      // Utiliser le service unifié pour générer la réponse
      final response = await _unifiedService.processVoiceCommand(transcription);

      state = state.copyWith(currentResponse: response, isProcessing: false);

      await _speakResponse(response);
    } catch (e) {
      state = state.copyWith(
        status: WakeWordStatus.error,
        errorMessage: 'Erreur traitement: $e',
        isProcessing: false,
      );
    }
  }

  Future<EmotionAnalysis> _analyzeEmotion(String text) async {
    final emotions = {
      'joie': ['content', 'heureux', 'génial', 'super', 'parfait'],
      'tristesse': ['triste', 'déprimé', 'malheureux', 'déçu'],
      'colère': ['énervé', 'fâché', 'agacé', 'furieux'],
      'peur': ['peur', 'anxieux', 'inquiet', 'stressé'],
      'surprise': ['surpris', 'étonné', 'incroyable', 'wow'],
      'dégoût': ['dégoûtant', 'horrible', 'affreux'],
    };

    final lowerText = text.toLowerCase();

    for (final entry in emotions.entries) {
      for (final word in entry.value) {
        if (lowerText.contains(word)) {
          return EmotionAnalysis(
            type: _stringToEmotion(entry.key),
            intensity: 0.8,
            confidence: 0.9,
          );
        }
      }
    }

    return const EmotionAnalysis(
      type: EmotionType.neutral,
      intensity: 0.3,
      confidence: 0.5,
    );
  }

  EmotionType _stringToEmotion(String emotion) {
    switch (emotion) {
      case 'joie':
        return EmotionType.joy;
      case 'tristesse':
        return EmotionType.sadness;
      case 'colère':
        return EmotionType.anger;
      case 'peur':
        return EmotionType.fear;
      case 'surprise':
        return EmotionType.surprise;
      case 'dégoût':
        return EmotionType.disgust;
      default:
        return EmotionType.neutral;
    }
  }

  Future<void> _speakResponse(String text) async {
    try {
      state = state.copyWith(status: WakeWordStatus.speaking, isSpeaking: true);

      await _configureTTSVoice();
      await _tts.speak(text);
    } catch (e) {
      state = state.copyWith(
        status: WakeWordStatus.error,
        errorMessage: 'Erreur TTS: $e',
        isSpeaking: false,
      );
    }
  }

  Future<void> _configureTTSVoice() async {
    final voice = state.selectedVoice;
    await _tts.setLanguage(voice.language);

    if (voice.id == 'clara') {
      await _tts.setPitch(1.1);
      await _tts.setSpeechRate(0.8);
    } else if (voice.id == 'james') {
      await _tts.setPitch(0.9);
      await _tts.setSpeechRate(0.7);
    }
  }

  Future<void> _playGreeting() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    String greeting;

    if (now.hour < 12) {
      greeting = 'Bonjour, je suis Rick. Dites "Salut Rick" pour commencer.';
    } else if (now.hour < 18) {
      greeting = 'Bon après-midi, je suis Rick. Je vous écoute.';
    } else {
      greeting = 'Bonsoir, je suis Rick. Que puis-je faire pour vous ?';
    }

    await _speakResponse(greeting);
  }

  void _startAudioLevelUpdates() {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _updateAudioVisualization(),
    );
  }

  void _updateAudioVisualization() {
    if (!state.isListening) return;

    final random = Random();
    final baseLevel = state.audioLevel;
    final variation = 0.1;

    final waveform = List.generate(waveformBars, (index) {
      final levelVariation = random.nextDouble() * variation - (variation / 2);
      final adjustedLevel = (baseLevel + levelVariation).clamp(0.0, 1.0);

      final pattern = sin((index / waveformBars) * 2 * pi) * 0.05;
      return (adjustedLevel + pattern).clamp(0.0, 1.0);
    });

    state = state.copyWith(waveformData: waveform);
  }

  void _stopListening() {
    _listeningTimeoutTimer?.cancel();

    state = state.copyWith(
      isListening: false,
      status: state.isWakeWordEnabled
          ? WakeWordStatus.ready
          : WakeWordStatus.disabled,
    );
  }

  void selectVoice(VoiceOption voice) {
    state = state.copyWith(selectedVoice: voice);
    _speakResponse('Salut, je suis ${voice.name} maintenant.');
  }

  void forceWakeWord() {
    if (state.status == WakeWordStatus.ready) {
      _wakeWordService.forceDetection();
    }
  }

  void toggleWakeWord(bool enabled) {
    if (enabled && !state.isWakeWordEnabled) {
      _startWakeWordDetection();
    } else if (!enabled && state.isWakeWordEnabled) {
      _stopWakeWordDetection();
    }
  }

  void _stopWakeWordDetection() {
    _audioStreamSubscription?.cancel();
    _audioLevelTimer?.cancel();
    _wakeWordService.stopListening();
    WakelockPlus.disable();

    state = state.copyWith(
      isWakeWordEnabled: false,
      status: WakeWordStatus.disabled,
    );
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _audioLevelTimer?.cancel();
    _listeningTimeoutTimer?.cancel();
    _wakeWordSubscription?.cancel();
    _confirmationSubscription?.cancel();
    _wakeWordService.stopListening();
    _wakeWordService.dispose();
    _tts.stop();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}

class EmotionAnalysis {
  final EmotionType type;
  final double intensity;
  final double confidence;

  const EmotionAnalysis({
    required this.type,
    required this.intensity,
    required this.confidence,
  });
}
