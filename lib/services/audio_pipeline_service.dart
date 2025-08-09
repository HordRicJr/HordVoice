import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice_models.dart';
import '../theme/design_tokens.dart';
import 'permission_manager_service.dart';
import 'voice_calibration_service.dart';

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

  // Timers et streams
  Timer? _wakeWordTimer;
  Timer? _volumeTimer;
  StreamSubscription? _audioStreamSubscription;

  // Configuration
  static const Duration _wakeWordTimeout = Duration(seconds: 5);
  static const Duration _listeningTimeout = Duration(seconds: 30);
  static const int _waveformBars = 24;

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

    // TODO: Implémenter la vraie détection wake word
    // Pour l'instant, simulation avec timer
    _wakeWordTimer?.cancel();
    _wakeWordTimer = Timer.periodic(
      const Duration(seconds: 10),
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

    // TODO: Démarrer la vraie reconnaissance vocale
    // Pour l'instant, simulation
    _simulateVoiceRecognition();
  }

  /// Stoppe l'écoute
  void stopListening() {
    _volumeTimer?.cancel();

    state = state.copyWith(
      status: AudioPipelineStatus.idle,
      currentVolume: 0.0,
      waveformData: List.filled(_waveformBars, 0.0),
    );
  }

  /// Simulation de reconnaissance vocale
  void _simulateVoiceRecognition() {
    Timer(const Duration(seconds: 3), () {
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

    // TODO: Implémenter vraie synthèse vocale avec Azure Speech
    // Pour l'instant, simulation
    await _simulateSpeech(text);

    state = state.copyWith(
      status: AudioPipelineStatus.idle,
      currentSpeech: null,
      currentEmotion: EmotionType.neutral,
    );
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

    // TODO: Configurer le TTS avec la nouvelle voix
    debugPrint('Voix changée vers: ${voice.name}');
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

  @override
  void dispose() {
    _wakeWordTimer?.cancel();
    _volumeTimer?.cancel();
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
