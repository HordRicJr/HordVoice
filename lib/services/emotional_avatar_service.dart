import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service central pour l'avatar émotionnel réactif
/// Réagit aux voix, touches, discussions et tactilité selon le guide
final emotionalAvatarServiceProvider =
    StateNotifierProvider<EmotionalAvatarService, EmotionalAvatarState>((ref) {
      return EmotionalAvatarService();
    });

/// États émotionnels de l'avatar
enum EmotionalState {
  neutral, // État par défaut
  happy, // Réponse positive
  excited, // Très enthousiaste
  listening, // En train d'écouter
  thinking, // Traitement des données
  speaking, // En train de parler
  surprised, // Réaction de surprise
  confused, // Ne comprend pas
  sad, // Réaction négative
  sleepy, // Mode repos
  alert, // Mode attentif
}

/// Types de stimuli détectés
enum StimulusType {
  voice, // Stimulus vocal
  touch, // Stimulus tactile
  discussion, // Stimulus conversationnel
  ambient, // Stimulus environnemental
}

/// Modèle d'état émotionnel complet
@immutable
class EmotionalAvatarState {
  final EmotionalState currentEmotion;
  final double emotionIntensity; // 0.0 à 1.0
  final Duration emotionDuration; // Durée restante
  final Map<StimulusType, double> stimulusLevels;
  final List<EmotionalMemory> recentMemories;
  final bool isReactive; // Avatar réagit aux stimuli
  final Color currentColor; // Couleur émotionnelle
  final double animationSpeed; // Vitesse d'animation
  final Map<String, dynamic> personalityTraits;

  const EmotionalAvatarState({
    this.currentEmotion = EmotionalState.neutral,
    this.emotionIntensity = 0.5,
    this.emotionDuration = const Duration(seconds: 5),
    this.stimulusLevels = const {},
    this.recentMemories = const [],
    this.isReactive = true,
    this.currentColor = Colors.blue,
    this.animationSpeed = 1.0,
    this.personalityTraits = const {},
  });

  EmotionalAvatarState copyWith({
    EmotionalState? currentEmotion,
    double? emotionIntensity,
    Duration? emotionDuration,
    Map<StimulusType, double>? stimulusLevels,
    List<EmotionalMemory>? recentMemories,
    bool? isReactive,
    Color? currentColor,
    double? animationSpeed,
    Map<String, dynamic>? personalityTraits,
  }) {
    return EmotionalAvatarState(
      currentEmotion: currentEmotion ?? this.currentEmotion,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
      emotionDuration: emotionDuration ?? this.emotionDuration,
      stimulusLevels: stimulusLevels ?? this.stimulusLevels,
      recentMemories: recentMemories ?? this.recentMemories,
      isReactive: isReactive ?? this.isReactive,
      currentColor: currentColor ?? this.currentColor,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      personalityTraits: personalityTraits ?? this.personalityTraits,
    );
  }
}

/// Mémoire émotionnelle pour l'apprentissage
@immutable
class EmotionalMemory {
  final StimulusType stimulusType;
  final EmotionalState response;
  final double intensity;
  final DateTime timestamp;
  final String? context;

  const EmotionalMemory({
    required this.stimulusType,
    required this.response,
    required this.intensity,
    required this.timestamp,
    this.context,
  });
}

/// Service principal d'avatar émotionnel
class EmotionalAvatarService extends StateNotifier<EmotionalAvatarState> {
  EmotionalAvatarService() : super(const EmotionalAvatarState()) {
    _initializePersonality();
    _startEmotionDecay();
  }

  final Random _random = Random();
  Timer? _emotionDecayTimer;
  Timer? _animationTimer;

  // Configuration de personnalité
  static const Map<String, dynamic> _defaultPersonality = {
    'reactivity': 0.7, // Réactivité aux stimuli
    'memory_retention': 0.6, // Rétention des souvenirs
    'curiosity': 0.8, // Niveau de curiosité
    'sociability': 0.9, // Tendance sociale
    'patience': 0.5, // Patience face aux difficultés
    'playfulness': 0.7, // Caractère joueur
  };

  /// Interface publique - Réaction à un stimulus vocal
  void onVoiceStimulus({
    required double volume, // Volume 0.0 à 1.0
    required double pitch, // Pitch détecté
    required String? emotion, // Émotion détectée dans la voix
    String? content, // Contenu vocal si disponible
  }) {
    if (!state.isReactive) return;

    debugPrint(
      '🎤 Avatar réagit au stimulus vocal: volume=$volume, pitch=$pitch, emotion=$emotion',
    );

    // Déterminer la réaction émotionnelle
    EmotionalState newEmotion = EmotionalState.listening;
    double intensity = volume * 0.8;

    // Analyse de l'émotion vocale
    if (emotion != null) {
      switch (emotion.toLowerCase()) {
        case 'happy':
        case 'joy':
          newEmotion = EmotionalState.happy;
          intensity = min(1.0, intensity + 0.3);
          break;
        case 'excited':
        case 'enthusiasm':
          newEmotion = EmotionalState.excited;
          intensity = min(1.0, intensity + 0.4);
          break;
        case 'sad':
        case 'sadness':
          newEmotion = EmotionalState.sad;
          intensity = max(0.2, intensity - 0.2);
          break;
        case 'angry':
        case 'anger':
          newEmotion = EmotionalState.alert;
          intensity = min(1.0, intensity + 0.2);
          break;
        case 'surprise':
        case 'surprised':
          newEmotion = EmotionalState.surprised;
          intensity = min(1.0, intensity + 0.5);
          break;
      }
    }

    // Réaction selon le pitch
    if (pitch > 300) {
      // Voix aiguë -> plus de réactivité
      intensity = min(1.0, intensity + 0.2);
      if (newEmotion == EmotionalState.listening) {
        newEmotion = EmotionalState.alert;
      }
    } else if (pitch < 150) {
      // Voix grave -> plus calme
      intensity = max(0.3, intensity - 0.1);
    }

    _updateEmotion(
      newEmotion,
      intensity,
      const Duration(seconds: 3),
      StimulusType.voice,
      context: 'Voice: $emotion, vol:$volume, pitch:$pitch',
    );
  }

  /// Interface publique - Réaction à un stimulus tactile
  void onTouchStimulus({
    required Offset touchPosition,
    required TouchType touchType,
    double pressure = 0.5,
  }) {
    if (!state.isReactive) return;

    debugPrint(
      '👆 Avatar réagit au stimulus tactile: $touchType à $touchPosition',
    );

    EmotionalState newEmotion;
    double intensity = 0.6;

    switch (touchType) {
      case TouchType.tap:
        newEmotion = EmotionalState.surprised;
        intensity = 0.7;
        break;
      case TouchType.longPress:
        newEmotion = EmotionalState.happy;
        intensity = 0.8;
        break;
      case TouchType.doubleTap:
        newEmotion = EmotionalState.excited;
        intensity = 0.9;
        break;
      case TouchType.swipe:
        newEmotion = EmotionalState.alert;
        intensity = 0.6;
        break;
    }

    // Intensité basée sur la pression
    intensity = min(1.0, intensity + (pressure * 0.3));

    _updateEmotion(
      newEmotion,
      intensity,
      const Duration(seconds: 2),
      StimulusType.touch,
      context: 'Touch: $touchType, pressure:$pressure',
    );
  }

  /// Interface publique - Réaction au contenu de discussion
  void onDiscussionStimulus({
    required String content,
    required DiscussionSentiment sentiment,
    Map<String, dynamic>? context,
  }) {
    if (!state.isReactive) return;

    debugPrint('💬 Avatar réagit au stimulus de discussion: $sentiment');

    EmotionalState newEmotion;
    double intensity = 0.6;

    switch (sentiment) {
      case DiscussionSentiment.positive:
        newEmotion = EmotionalState.happy;
        intensity = 0.8;
        break;
      case DiscussionSentiment.negative:
        newEmotion = EmotionalState.sad;
        intensity = 0.7;
        break;
      case DiscussionSentiment.neutral:
        newEmotion = EmotionalState.thinking;
        intensity = 0.5;
        break;
      case DiscussionSentiment.excited:
        newEmotion = EmotionalState.excited;
        intensity = 0.9;
        break;
      case DiscussionSentiment.confused:
        newEmotion = EmotionalState.confused;
        intensity = 0.6;
        break;
      case DiscussionSentiment.questioning:
        newEmotion = EmotionalState.thinking;
        intensity = 0.7;
        break;
    }

    // Analyser le contenu pour des réactions spécifiques
    final lowerContent = content.toLowerCase();
    if (lowerContent.contains('merci') || lowerContent.contains('bravo')) {
      newEmotion = EmotionalState.happy;
      intensity = min(1.0, intensity + 0.2);
    } else if (lowerContent.contains('problème') ||
        lowerContent.contains('erreur')) {
      newEmotion = EmotionalState.confused;
      intensity = min(1.0, intensity + 0.1);
    }

    _updateEmotion(
      newEmotion,
      intensity,
      const Duration(seconds: 4),
      StimulusType.discussion,
      context:
          'Discussion: $sentiment, content: ${content.substring(0, min(50, content.length))}',
    );
  }

  /// Interface publique - Activation mode d'écoute
  void startListeningMode() {
    debugPrint('👂 Avatar entre en mode écoute');
    _updateEmotion(
      EmotionalState.listening,
      0.7,
      const Duration(seconds: 30),
      StimulusType.ambient,
      context: 'Listening mode activated',
    );
  }

  /// Interface publique - Activation mode de parole
  void startSpeakingMode() {
    debugPrint('🗣️ Avatar entre en mode parole');
    _updateEmotion(
      EmotionalState.speaking,
      0.8,
      const Duration(seconds: 10),
      StimulusType.ambient,
      context: 'Speaking mode activated',
    );
  }

  /// Interface publique - Activation mode de réflexion
  void startThinkingMode() {
    debugPrint('🤔 Avatar entre en mode réflexion');
    _updateEmotion(
      EmotionalState.thinking,
      0.6,
      const Duration(seconds: 5),
      StimulusType.ambient,
      context: 'Thinking mode activated',
    );
  }

  /// Interface publique - Retour au mode neutre
  void returnToNeutral() {
    debugPrint('😐 Avatar retourne au mode neutre');
    _updateEmotion(
      EmotionalState.neutral,
      0.5,
      const Duration(seconds: 2),
      StimulusType.ambient,
      context: 'Manual reset to neutral',
    );
  }

  /// Interface publique - Bascule réactivité
  void toggleReactivity() {
    state = state.copyWith(isReactive: !state.isReactive);
    debugPrint(
      '🔄 Réactivité avatar: ${state.isReactive ? "activée" : "désactivée"}',
    );
  }

  /// Met à jour l'état émotionnel
  void _updateEmotion(
    EmotionalState emotion,
    double intensity,
    Duration duration,
    StimulusType stimulusType, {
    String? context,
  }) {
    // Créer la mémoire émotionnelle
    final memory = EmotionalMemory(
      stimulusType: stimulusType,
      response: emotion,
      intensity: intensity,
      timestamp: DateTime.now(),
      context: context,
    );

    // Calculer la couleur émotionnelle
    final color = _getEmotionalColor(emotion, intensity);

    // Calculer la vitesse d'animation
    final animSpeed = _getAnimationSpeed(emotion, intensity);

    // Mettre à jour les niveaux de stimulus
    final newStimulusLevels = Map<StimulusType, double>.from(
      state.stimulusLevels,
    );
    newStimulusLevels[stimulusType] = intensity;

    // Garder seulement les 10 dernières mémoires
    final newMemories = [...state.recentMemories, memory];
    if (newMemories.length > 10) {
      newMemories.removeAt(0);
    }

    state = state.copyWith(
      currentEmotion: emotion,
      emotionIntensity: intensity,
      emotionDuration: duration,
      stimulusLevels: newStimulusLevels,
      recentMemories: newMemories,
      currentColor: color,
      animationSpeed: animSpeed,
    );

    debugPrint(
      '🎭 Émotion mise à jour: $emotion (intensité: $intensity, durée: ${duration.inSeconds}s)',
    );
  }

  /// Obtient la couleur associée à une émotion
  Color _getEmotionalColor(EmotionalState emotion, double intensity) {
    Color baseColor;

    switch (emotion) {
      case EmotionalState.happy:
        baseColor = Colors.yellow;
        break;
      case EmotionalState.excited:
        baseColor = Colors.orange;
        break;
      case EmotionalState.sad:
        baseColor = Colors.blue;
        break;
      case EmotionalState.listening:
        baseColor = Colors.green;
        break;
      case EmotionalState.thinking:
        baseColor = Colors.purple;
        break;
      case EmotionalState.speaking:
        baseColor = Colors.cyan;
        break;
      case EmotionalState.surprised:
        baseColor = Colors.pink;
        break;
      case EmotionalState.confused:
        baseColor = Colors.grey;
        break;
      case EmotionalState.alert:
        baseColor = Colors.red;
        break;
      case EmotionalState.sleepy:
        baseColor = Colors.indigo;
        break;
      case EmotionalState.neutral:
      default:
        baseColor = Colors.blue;
        break;
    }

    // Moduler l'intensité de la couleur
    return Color.lerp(baseColor.withOpacity(0.3), baseColor, intensity) ??
        baseColor;
  }

  /// Obtient la vitesse d'animation selon l'émotion
  double _getAnimationSpeed(EmotionalState emotion, double intensity) {
    double baseSpeed = 1.0;

    switch (emotion) {
      case EmotionalState.excited:
        baseSpeed = 1.8;
        break;
      case EmotionalState.surprised:
        baseSpeed = 2.0;
        break;
      case EmotionalState.happy:
        baseSpeed = 1.4;
        break;
      case EmotionalState.alert:
        baseSpeed = 1.6;
        break;
      case EmotionalState.thinking:
        baseSpeed = 0.8;
        break;
      case EmotionalState.sleepy:
        baseSpeed = 0.5;
        break;
      case EmotionalState.sad:
        baseSpeed = 0.7;
        break;
      default:
        baseSpeed = 1.0;
        break;
    }

    // Moduler avec l'intensité
    return baseSpeed * (0.5 + (intensity * 0.5));
  }

  /// Initialise la personnalité de l'avatar
  void _initializePersonality() {
    state = state.copyWith(personalityTraits: _defaultPersonality);
  }

  /// Démarre le système de déclin émotionnel
  void _startEmotionDecay() {
    _emotionDecayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.emotionDuration.inSeconds <= 0) {
        // Retourner progressivement au neutre
        if (state.currentEmotion != EmotionalState.neutral) {
          _updateEmotion(
            EmotionalState.neutral,
            max(0.3, state.emotionIntensity - 0.1),
            const Duration(seconds: 5),
            StimulusType.ambient,
            context: 'Natural emotion decay',
          );
        }
      } else {
        // Décrémenter la durée
        state = state.copyWith(
          emotionDuration: Duration(
            seconds: state.emotionDuration.inSeconds - 1,
          ),
        );
      }
    });
  }

  /// Interface publique - Obtient l'état émotionnel actuel
  EmotionalState getCurrentEmotion() => state.currentEmotion;

  /// Interface publique - Obtient l'intensité émotionnelle
  double getEmotionIntensity() => state.emotionIntensity;

  /// Interface publique - Obtient la couleur émotionnelle
  Color getEmotionalColor() => state.currentColor;

  /// Interface publique - Obtient la vitesse d'animation
  double getAnimationSpeed() => state.animationSpeed;

  @override
  void dispose() {
    _emotionDecayTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }
}

/// Types de toucher détectés
enum TouchType { tap, longPress, doubleTap, swipe }

/// Types de sentiment de discussion
enum DiscussionSentiment {
  positive,
  negative,
  neutral,
  excited,
  confused,
  questioning,
}
