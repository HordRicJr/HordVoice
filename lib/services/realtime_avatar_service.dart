import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/avatar_state_service.dart';
import '../theme/design_tokens.dart';

/// Service d'avatar IA expressif en temps réel pour HordVoice IA
/// Fonctionnalité 1: Avatar IA expressif en temps réel
class RealtimeAvatarService {
  static final RealtimeAvatarService _instance =
      RealtimeAvatarService._internal();
  factory RealtimeAvatarService() => _instance;
  RealtimeAvatarService._internal();

  // État du service
  bool _isInitialized = false;
  bool _realtimeMode = false;
  WidgetRef? _ref;

  // Configuration temps réel
  late Timer? _realtimeUpdateTimer;
  late Timer? _emotionSyncTimer;
  late Timer? _contextualUpdateTimer;

  // Données temps réel
  RealtimeContext _currentContext = RealtimeContext.idle();
  final List<EmotionalState> _emotionHistory = [];
  final List<ContextualTrigger> _contextualTriggers = [];

  // Streams pour les événements
  final StreamController<RealtimeAvatarEvent> _avatarController =
      StreamController.broadcast();
  final StreamController<EmotionalTransition> _emotionController =
      StreamController.broadcast();

  // Getters
  Stream<RealtimeAvatarEvent> get avatarStream => _avatarController.stream;
  Stream<EmotionalTransition> get emotionStream => _emotionController.stream;
  bool get isInitialized => _isInitialized;
  bool get realtimeMode => _realtimeMode;
  RealtimeContext get currentContext => _currentContext;

  /// Initialise le service d'avatar temps réel
  Future<void> initialize([WidgetRef? ref]) async {
    if (_isInitialized) {
      debugPrint('RealtimeAvatarService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation RealtimeAvatarService...');

      if (ref != null) {
        _ref = ref;
      }
      await _initializeContextualTriggers();
      await _setupRealtimeUpdates();

      _isInitialized = true;
      debugPrint('RealtimeAvatarService initialisé avec succès');

      _avatarController.add(RealtimeAvatarEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation RealtimeAvatarService: $e');
      throw Exception(
        'Impossible d\'initialiser le service avatar temps réel: $e',
      );
    }
  }

  /// Initialise les déclencheurs contextuels
  Future<void> _initializeContextualTriggers() async {
    _contextualTriggers.addAll([
      // Déclencheurs basés sur l'heure
      ContextualTrigger(
        id: 'time_morning',
        type: TriggerType.timeOfDay,
        condition: (context) => _isTimeOfDay(TimeOfDayPeriod.morning),
        emotion: EmotionType.joy,
        intensity: 0.6,
        animation: AvatarAnimationState.breathing,
        description: 'Animation matinale énergique',
      ),

      ContextualTrigger(
        id: 'time_evening',
        type: TriggerType.timeOfDay,
        condition: (context) => _isTimeOfDay(TimeOfDayPeriod.evening),
        emotion: EmotionType.calm,
        intensity: 0.4,
        animation: AvatarAnimationState.idle,
        description: 'Animation calme du soir',
      ),

      // Déclencheurs basés sur l'interaction
      ContextualTrigger(
        id: 'user_speaking',
        type: TriggerType.userActivity,
        condition: (context) => context.userSpeaking,
        emotion: EmotionType.neutral,
        intensity: 0.8,
        animation: AvatarAnimationState.listening,
        description: 'Attention lors de la parole utilisateur',
      ),

      ContextualTrigger(
        id: 'ai_responding',
        type: TriggerType.aiActivity,
        condition: (context) => context.aiSpeaking,
        emotion: EmotionType.calm,
        intensity: 0.7,
        animation: AvatarAnimationState.speaking,
        description: 'Expression lors de la réponse IA',
      ),

      // Déclencheurs basés sur l'émotion
      ContextualTrigger(
        id: 'user_happy',
        type: TriggerType.emotionDetected,
        condition: (context) => context.detectedEmotion == 'joy',
        emotion: EmotionType.joy,
        intensity: 0.9,
        animation: AvatarAnimationState.reacting,
        description: 'Réaction à la joie de l\'utilisateur',
      ),

      ContextualTrigger(
        id: 'user_frustrated',
        type: TriggerType.emotionDetected,
        condition: (context) => context.detectedEmotion == 'frustration',
        emotion: EmotionType.sadness,
        intensity: 0.6,
        animation: AvatarAnimationState.concentrating,
        description: 'Empathie lors de frustration',
      ),

      // Déclencheurs basés sur l'environnement
      ContextualTrigger(
        id: 'noise_detected',
        type: TriggerType.environmental,
        condition: (context) => context.noiseLevel > 0.7,
        emotion: EmotionType.surprise,
        intensity: 0.5,
        animation: AvatarAnimationState.concentrating,
        description: 'Concentration dans un environnement bruyant',
      ),

      ContextualTrigger(
        id: 'quiet_environment',
        type: TriggerType.environmental,
        condition: (context) => context.noiseLevel < 0.2,
        emotion: EmotionType.calm,
        intensity: 0.3,
        animation: AvatarAnimationState.idle,
        description: 'Sérénité dans un environnement calme',
      ),
    ]);

    debugPrint(
      '${_contextualTriggers.length} déclencheurs contextuels initialisés',
    );
  }

  /// Configure les mises à jour temps réel
  Future<void> _setupRealtimeUpdates() async {
    // Mise à jour générale toutes les 100ms
    _realtimeUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      _performRealtimeUpdate,
    );

    // Synchronisation émotionnelle toutes les 200ms
    _emotionSyncTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      _syncEmotionalState,
    );

    // Analyse contextuelle toutes les 500ms
    _contextualUpdateTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      _analyzeContextualTriggers,
    );
  }

  /// Active le mode temps réel
  Future<void> activateRealtimeMode() async {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }

    _realtimeMode = true;

    _avatarController.add(RealtimeAvatarEvent.realtimeModeActivated());
    debugPrint('Mode avatar temps réel activé');
  }

  /// Désactive le mode temps réel
  Future<void> deactivateRealtimeMode() async {
    _realtimeMode = false;

    _avatarController.add(RealtimeAvatarEvent.realtimeModeDeactivated());
    debugPrint('Mode avatar temps réel désactivé');
  }

  /// Met à jour le contexte temps réel
  void updateRealtimeContext({
    bool? userSpeaking,
    bool? aiSpeaking,
    String? detectedEmotion,
    double? noiseLevel,
    double? confidenceLevel,
    Map<String, dynamic>? additionalData,
  }) {
    _currentContext = _currentContext.copyWith(
      userSpeaking: userSpeaking,
      aiSpeaking: aiSpeaking,
      detectedEmotion: detectedEmotion,
      noiseLevel: noiseLevel,
      confidenceLevel: confidenceLevel,
      additionalData: additionalData,
      lastUpdate: DateTime.now(),
    );

    if (_realtimeMode) {
      _analyzeContextualTriggers(null);
    }
  }

  /// Déclenche une émotion spécifique avec transition fluide
  Future<void> triggerEmotionalTransition({
    required EmotionType emotion,
    required double intensity,
    Duration? duration,
    Curve? curve,
  }) async {
    if (!_isInitialized || _ref == null) return;

    final transition = EmotionalTransition(
      fromEmotion: _ref!.read(avatarStateProvider).currentEmotion,
      toEmotion: emotion,
      fromIntensity: _ref!.read(avatarStateProvider).emotionIntensity,
      toIntensity: intensity,
      duration: duration ?? const Duration(milliseconds: 800),
      curve: curve ?? Curves.easeInOut,
      timestamp: DateTime.now(),
    );

    _emotionHistory.add(
      EmotionalState(
        emotion: emotion,
        intensity: intensity,
        timestamp: DateTime.now(),
        context: _currentContext,
      ),
    );

    // Maintenir seulement les 100 dernières émotions
    if (_emotionHistory.length > 100) {
      _emotionHistory.removeAt(0);
    }

    _emotionController.add(transition);

    // Appliquer la transition à l'avatar
    _ref!.read(avatarStateProvider.notifier).setEmotion(emotion, intensity);

    _avatarController.add(
      RealtimeAvatarEvent.emotionTriggered(
        emotion: emotion,
        intensity: intensity,
        duration: transition.duration,
      ),
    );
  }

  /// Crée une séquence d'animations personnalisée
  Future<void> createAnimationSequence({
    required String sequenceId,
    required List<AnimationStep> steps,
    bool loop = false,
  }) async {
    if (!_isInitialized || _ref == null) return;

    _avatarController.add(
      RealtimeAvatarEvent.animationSequenceStarted(
        sequenceId: sequenceId,
        stepCount: steps.length,
        loop: loop,
      ),
    );

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      // Appliquer l'étape d'animation
      await _applyAnimationStep(step);

      // Attendre la durée spécifiée
      await Future.delayed(step.duration);

      // Si ce n'est pas la dernière étape ou si on boucle
      if (i < steps.length - 1 || (loop && i == steps.length - 1)) {
        if (loop && i == steps.length - 1) {
          i = -1; // Recommencer la boucle
        }
      }
    }

    _avatarController.add(
      RealtimeAvatarEvent.animationSequenceCompleted(sequenceId),
    );
  }

  /// Synchronise l'avatar avec l'audio en temps réel
  void syncWithAudio({
    required double audioLevel,
    required double frequency,
    List<double>? frequencySpectrum,
  }) {
    if (!_realtimeMode || _ref == null) return;

    // Calculer l'intensité de l'animation basée sur l'audio
    final speakingIntensity = (audioLevel * 2.0).clamp(0.0, 1.0);

    // Adapter l'animation à la fréquence
    final pitchInfluence = _calculatePitchInfluence(frequency);

    // Mettre à jour l'état de parole
    final avatarNotifier = _ref!.read(avatarStateProvider.notifier);
    avatarNotifier.setSpeaking(audioLevel > 0.1);

    // Ajuster l'intensité émotionnelle selon l'audio
    if (audioLevel > 0.3) {
      final currentEmotion = _ref!.read(avatarStateProvider).currentEmotion;
      final adjustedIntensity = (speakingIntensity + pitchInfluence) / 2;
      avatarNotifier.setEmotion(currentEmotion, adjustedIntensity);
    }

    _avatarController.add(
      RealtimeAvatarEvent.audioSynchronized(
        audioLevel: audioLevel,
        frequency: frequency,
        speakingIntensity: speakingIntensity,
      ),
    );
  }

  /// Obtient les statistiques d'utilisation émotionnelle
  EmotionalAnalytics getEmotionalAnalytics() {
    if (_emotionHistory.isEmpty) {
      return EmotionalAnalytics.empty();
    }

    final emotionCounts = <EmotionType, int>{};
    final intensitySum = <EmotionType, double>{};
    final transitionCounts = <String, int>{};

    for (int i = 0; i < _emotionHistory.length; i++) {
      final state = _emotionHistory[i];
      emotionCounts[state.emotion] = (emotionCounts[state.emotion] ?? 0) + 1;
      intensitySum[state.emotion] =
          (intensitySum[state.emotion] ?? 0.0) + state.intensity;

      if (i > 0) {
        final prevEmotion = _emotionHistory[i - 1].emotion;
        final transitionKey = '${prevEmotion.name}_to_${state.emotion.name}';
        transitionCounts[transitionKey] =
            (transitionCounts[transitionKey] ?? 0) + 1;
      }
    }

    final averageIntensities = <EmotionType, double>{};
    for (final entry in intensitySum.entries) {
      averageIntensities[entry.key] = entry.value / emotionCounts[entry.key]!;
    }

    final dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return EmotionalAnalytics(
      totalEmotions: _emotionHistory.length,
      emotionDistribution: emotionCounts,
      averageIntensities: averageIntensities,
      transitionPatterns: transitionCounts,
      dominantEmotion: dominantEmotion,
      timeSpan: _emotionHistory.isNotEmpty
          ? _emotionHistory.last.timestamp.difference(
              _emotionHistory.first.timestamp,
            )
          : Duration.zero,
    );
  }

  // ==================== MÉTHODES PRIVÉES ====================

  void _performRealtimeUpdate(Timer timer) {
    if (!_realtimeMode || _ref == null) return;

    // Mise à jour générale du contexte
    _currentContext = _currentContext.copyWith(lastUpdate: DateTime.now());

    // Vérifier l'état actuel de l'avatar
    final currentAvatarState = _ref!.read(avatarStateProvider);

    // Appliquer les micro-ajustements
    _applyMicroAdjustments(currentAvatarState);
  }

  void _syncEmotionalState(Timer timer) {
    if (!_realtimeMode || _ref == null) return;

    // Analyser les tendances émotionnelles récentes
    final recentEmotions = _emotionHistory
        .where(
          (e) =>
              DateTime.now().difference(e.timestamp) <
              const Duration(seconds: 10),
        )
        .toList();

    if (recentEmotions.isNotEmpty) {
      final emotionalTrend = _calculateEmotionalTrend(recentEmotions);
      _applyEmotionalTrend(emotionalTrend);
    }
  }

  void _analyzeContextualTriggers(Timer? timer) {
    if (!_realtimeMode || _ref == null) return;

    for (final trigger in _contextualTriggers) {
      if (trigger.condition(_currentContext)) {
        _applyContextualTrigger(trigger);
      }
    }
  }

  void _applyMicroAdjustments(AvatarState currentState) {
    // Micro-ajustements basés sur le temps
    final now = DateTime.now();

    // Ajustement subtil de l'aura selon l'heure
    // (pour future implémentation)
    final currentTimeOfDay = now.hour + (now.minute / 60.0);
    if (currentTimeOfDay >= 6 && currentTimeOfDay < 12) {
      // Plus vif le matin
    } else if (currentTimeOfDay >= 20 || currentTimeOfDay < 6) {
      // Plus doux la nuit
    }

    // Appliquer les ajustements via l'avatar state notifier
    // (micro-ajustements non invasifs)
  }

  EmotionalTrend _calculateEmotionalTrend(List<EmotionalState> recentEmotions) {
    if (recentEmotions.length < 2) {
      return EmotionalTrend.stable;
    }

    final intensityValues = recentEmotions.map((e) => e.intensity).toList();
    final firstHalf = intensityValues
        .take(intensityValues.length ~/ 2)
        .toList();
    final secondHalf = intensityValues
        .skip(intensityValues.length ~/ 2)
        .toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    if (secondAvg > firstAvg + 0.2) {
      return EmotionalTrend.increasing;
    } else if (secondAvg < firstAvg - 0.2) {
      return EmotionalTrend.decreasing;
    } else {
      return EmotionalTrend.stable;
    }
  }

  void _applyEmotionalTrend(EmotionalTrend trend) {
    // Appliquer les ajustements selon la tendance émotionnelle
    switch (trend) {
      case EmotionalTrend.increasing:
        // Augmenter subtilement l'énergie de l'avatar
        break;
      case EmotionalTrend.decreasing:
        // Diminuer subtilement l'énergie de l'avatar
        break;
      case EmotionalTrend.stable:
        // Maintenir l'état actuel
        break;
    }
  }

  void _applyContextualTrigger(ContextualTrigger trigger) {
    if (_ref == null) return;

    final avatarNotifier = _ref!.read(avatarStateProvider.notifier);

    // Appliquer l'émotion du déclencheur
    avatarNotifier.setEmotion(trigger.emotion, trigger.intensity);

    // Appliquer l'animation si nécessaire
    // Note: Cette implémentation dépend de l'API exacte d'AvatarStateNotifier

    _avatarController.add(
      RealtimeAvatarEvent.contextualTriggerActivated(
        triggerId: trigger.id,
        emotion: trigger.emotion,
        intensity: trigger.intensity,
      ),
    );
  }

  Future<void> _applyAnimationStep(AnimationStep step) async {
    if (_ref == null) return;

    final avatarNotifier = _ref!.read(avatarStateProvider.notifier);

    // Appliquer l'émotion de l'étape
    if (step.emotion != null) {
      avatarNotifier.setEmotion(step.emotion!, step.intensity);
    }

    // Appliquer l'animation
    // Note: L'implémentation exacte dépend de l'API d'AvatarStateNotifier
  }

  double _calculatePitchInfluence(double frequency) {
    // Calculer l'influence de la fréquence sur l'animation
    // Fréquences plus hautes = plus d'énergie
    if (frequency < 100) return 0.2;
    if (frequency < 300) return 0.5;
    if (frequency < 1000) return 0.8;
    return 1.0;
  }

  bool _isTimeOfDay(TimeOfDayPeriod period) {
    final hour = DateTime.now().hour;
    switch (period) {
      case TimeOfDayPeriod.morning:
        return hour >= 6 && hour < 12;
      case TimeOfDayPeriod.afternoon:
        return hour >= 12 && hour < 18;
      case TimeOfDayPeriod.evening:
        return hour >= 18 && hour < 22;
      case TimeOfDayPeriod.night:
        return hour >= 22 || hour < 6;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _realtimeUpdateTimer?.cancel();
    _emotionSyncTimer?.cancel();
    _contextualUpdateTimer?.cancel();
    _avatarController.close();
    _emotionController.close();
    debugPrint('RealtimeAvatarService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class RealtimeContext {
  final bool userSpeaking;
  final bool aiSpeaking;
  final String? detectedEmotion;
  final double noiseLevel;
  final double confidenceLevel;
  final Map<String, dynamic> additionalData;
  final DateTime lastUpdate;

  RealtimeContext({
    required this.userSpeaking,
    required this.aiSpeaking,
    this.detectedEmotion,
    required this.noiseLevel,
    required this.confidenceLevel,
    required this.additionalData,
    required this.lastUpdate,
  });

  factory RealtimeContext.idle() {
    return RealtimeContext(
      userSpeaking: false,
      aiSpeaking: false,
      noiseLevel: 0.0,
      confidenceLevel: 0.0,
      additionalData: {},
      lastUpdate: DateTime.now(),
    );
  }

  RealtimeContext copyWith({
    bool? userSpeaking,
    bool? aiSpeaking,
    String? detectedEmotion,
    double? noiseLevel,
    double? confidenceLevel,
    Map<String, dynamic>? additionalData,
    DateTime? lastUpdate,
  }) {
    return RealtimeContext(
      userSpeaking: userSpeaking ?? this.userSpeaking,
      aiSpeaking: aiSpeaking ?? this.aiSpeaking,
      detectedEmotion: detectedEmotion ?? this.detectedEmotion,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      additionalData: additionalData ?? this.additionalData,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class EmotionalState {
  final EmotionType emotion;
  final double intensity;
  final DateTime timestamp;
  final RealtimeContext context;

  EmotionalState({
    required this.emotion,
    required this.intensity,
    required this.timestamp,
    required this.context,
  });
}

class ContextualTrigger {
  final String id;
  final TriggerType type;
  final bool Function(RealtimeContext) condition;
  final EmotionType emotion;
  final double intensity;
  final AvatarAnimationState animation;
  final String description;

  ContextualTrigger({
    required this.id,
    required this.type,
    required this.condition,
    required this.emotion,
    required this.intensity,
    required this.animation,
    required this.description,
  });
}

class AnimationStep {
  final EmotionType? emotion;
  final double intensity;
  final Duration duration;
  final Curve curve;

  AnimationStep({
    this.emotion,
    required this.intensity,
    required this.duration,
    this.curve = Curves.easeInOut,
  });
}

class EmotionalTransition {
  final EmotionType fromEmotion;
  final EmotionType toEmotion;
  final double fromIntensity;
  final double toIntensity;
  final Duration duration;
  final Curve curve;
  final DateTime timestamp;

  EmotionalTransition({
    required this.fromEmotion,
    required this.toEmotion,
    required this.fromIntensity,
    required this.toIntensity,
    required this.duration,
    required this.curve,
    required this.timestamp,
  });
}

class EmotionalAnalytics {
  final int totalEmotions;
  final Map<EmotionType, int> emotionDistribution;
  final Map<EmotionType, double> averageIntensities;
  final Map<String, int> transitionPatterns;
  final EmotionType dominantEmotion;
  final Duration timeSpan;

  EmotionalAnalytics({
    required this.totalEmotions,
    required this.emotionDistribution,
    required this.averageIntensities,
    required this.transitionPatterns,
    required this.dominantEmotion,
    required this.timeSpan,
  });

  factory EmotionalAnalytics.empty() {
    return EmotionalAnalytics(
      totalEmotions: 0,
      emotionDistribution: {},
      averageIntensities: {},
      transitionPatterns: {},
      dominantEmotion: EmotionType.neutral,
      timeSpan: Duration.zero,
    );
  }
}

class RealtimeAvatarEvent {
  final RealtimeAvatarEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeAvatarEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory RealtimeAvatarEvent.initialized() {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.realtimeModeActivated() {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.realtimeModeActivated,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.realtimeModeDeactivated() {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.realtimeModeDeactivated,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.emotionTriggered({
    required EmotionType emotion,
    required double intensity,
    required Duration duration,
  }) {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.emotionTriggered,
      data: {
        'emotion': emotion.name,
        'intensity': intensity,
        'duration': duration.inMilliseconds,
      },
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.animationSequenceStarted({
    required String sequenceId,
    required int stepCount,
    required bool loop,
  }) {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.animationSequenceStarted,
      data: {'sequenceId': sequenceId, 'stepCount': stepCount, 'loop': loop},
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.animationSequenceCompleted(String sequenceId) {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.animationSequenceCompleted,
      data: {'sequenceId': sequenceId},
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.audioSynchronized({
    required double audioLevel,
    required double frequency,
    required double speakingIntensity,
  }) {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.audioSynchronized,
      data: {
        'audioLevel': audioLevel,
        'frequency': frequency,
        'speakingIntensity': speakingIntensity,
      },
      timestamp: DateTime.now(),
    );
  }

  factory RealtimeAvatarEvent.contextualTriggerActivated({
    required String triggerId,
    required EmotionType emotion,
    required double intensity,
  }) {
    return RealtimeAvatarEvent(
      type: RealtimeAvatarEventType.contextualTriggerActivated,
      data: {
        'triggerId': triggerId,
        'emotion': emotion.name,
        'intensity': intensity,
      },
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS ====================

enum TriggerType {
  timeOfDay,
  userActivity,
  aiActivity,
  emotionDetected,
  environmental,
}

enum EmotionalTrend { increasing, decreasing, stable }

enum RealtimeAvatarEventType {
  initialized,
  realtimeModeActivated,
  realtimeModeDeactivated,
  emotionTriggered,
  animationSequenceStarted,
  animationSequenceCompleted,
  audioSynchronized,
  contextualTriggerActivated,
}
