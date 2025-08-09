import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/design_tokens.dart';

final avatarStateProvider =
    StateNotifierProvider<AvatarStateNotifier, AvatarState>(
      (ref) => AvatarStateNotifier(),
    );

class AvatarState {
  final EmotionType currentEmotion;
  final double emotionIntensity;
  final TimeOfDayPeriod timeOfDay;
  final bool isBreathing;
  final bool isBlinking;
  final bool isSpeaking;
  final bool isListening;
  final GestureType lastGesture;
  final DateTime lastGestureTime;
  final AvatarAnimationState animationState;
  final Map<String, double> faceParameters;
  final Color currentAuraColor;
  final double currentAuraIntensity;

  AvatarState({
    this.currentEmotion = EmotionType.neutral,
    this.emotionIntensity = 0.3,
    this.timeOfDay = TimeOfDayPeriod.afternoon,
    this.isBreathing = true,
    this.isBlinking = false,
    this.isSpeaking = false,
    this.isListening = false,
    this.lastGesture = GestureType.none,
    DateTime? lastGestureTime,
    this.animationState = AvatarAnimationState.idle,
    this.faceParameters = const {},
    this.currentAuraColor = const Color(0xFF6B73FF),
    this.currentAuraIntensity = 0.3,
  }) : lastGestureTime = lastGestureTime ?? DateTime.now();

  AvatarState copyWith({
    EmotionType? currentEmotion,
    double? emotionIntensity,
    TimeOfDayPeriod? timeOfDay,
    bool? isBreathing,
    bool? isBlinking,
    bool? isSpeaking,
    bool? isListening,
    GestureType? lastGesture,
    DateTime? lastGestureTime,
    AvatarAnimationState? animationState,
    Map<String, double>? faceParameters,
    Color? currentAuraColor,
    double? currentAuraIntensity,
  }) {
    return AvatarState(
      currentEmotion: currentEmotion ?? this.currentEmotion,
      emotionIntensity: emotionIntensity ?? this.emotionIntensity,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isBreathing: isBreathing ?? this.isBreathing,
      isBlinking: isBlinking ?? this.isBlinking,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      lastGesture: lastGesture ?? this.lastGesture,
      lastGestureTime: lastGestureTime ?? this.lastGestureTime,
      animationState: animationState ?? this.animationState,
      faceParameters: faceParameters ?? this.faceParameters,
      currentAuraColor: currentAuraColor ?? this.currentAuraColor,
      currentAuraIntensity: currentAuraIntensity ?? this.currentAuraIntensity,
    );
  }
}

enum AvatarAnimationState {
  idle,
  breathing,
  blinking,
  speaking,
  listening,
  reacting,
  tickled,
  surprised,
  concentrating,
}

enum GestureType { none, tap, doubleTap, longPress, swipeUp, swipeDown }

enum TimeOfDayPeriod { morning, afternoon, evening, night }

class AvatarStateNotifier extends StateNotifier<AvatarState> {
  AvatarStateNotifier() : super(AvatarState()) {
    _initialize();
  }

  Timer? _breathingTimer;
  Timer? _blinkingTimer;
  Timer? _emotionSmoothingTimer;
  Timer? _timeOfDayTimer;
  Timer? _gestureTimeoutTimer;

  static const Duration breathingInterval = Duration(milliseconds: 2000);
  static const Duration blinkingInterval = Duration(milliseconds: 3000);
  static const Duration emotionSmoothingInterval = Duration(milliseconds: 100);
  static const Duration gestureTimeout = Duration(seconds: 3);
  static const double emotionSmoothingAlpha = 0.15;

  Map<EmotionType, double> _emotionHistory = {};
  EmotionType _targetEmotion = EmotionType.neutral;
  double _targetIntensity = 0.3;

  void _initialize() {
    _updateTimeOfDay();
    _startBreathingAnimation();
    _startBlinkingAnimation();
    _startEmotionSmoothing();
    _startTimeOfDayUpdates();
  }

  void _updateTimeOfDay() {
    final hour = DateTime.now().hour;
    TimeOfDayPeriod period;

    if (hour >= 6 && hour < 12) {
      period = TimeOfDayPeriod.morning;
    } else if (hour >= 12 && hour < 18) {
      period = TimeOfDayPeriod.afternoon;
    } else if (hour >= 18 && hour < 22) {
      period = TimeOfDayPeriod.evening;
    } else {
      period = TimeOfDayPeriod.night;
    }

    if (state.timeOfDay != period) {
      state = state.copyWith(timeOfDay: period);
      _updateAuraForTimeOfDay(period);
    }
  }

  void _updateAuraForTimeOfDay(TimeOfDayPeriod period) {
    Color baseColor;
    double baseIntensity;

    switch (period) {
      case TimeOfDayPeriod.morning:
        baseColor = const Color(0xFFFFB347); // Orange chaleureux
        baseIntensity = 0.4;
        break;
      case TimeOfDayPeriod.afternoon:
        baseColor = const Color(0xFF87CEEB); // Bleu ciel
        baseIntensity = 0.5;
        break;
      case TimeOfDayPeriod.evening:
        baseColor = const Color(0xFFDDA0DD); // Violet doux
        baseIntensity = 0.3;
        break;
      case TimeOfDayPeriod.night:
        baseColor = const Color(0xFF483D8B); // Bleu nuit
        baseIntensity = 0.2;
        break;
    }

    final emotionColor = state.currentEmotion.primaryColor;
    final blendedColor =
        Color.lerp(baseColor, emotionColor, state.emotionIntensity) ??
        baseColor;

    state = state.copyWith(
      currentAuraColor: blendedColor,
      currentAuraIntensity: baseIntensity + (state.emotionIntensity * 0.3),
    );
  }

  void _startBreathingAnimation() {
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(breathingInterval, (_) {
      if (state.animationState == AvatarAnimationState.idle ||
          state.animationState == AvatarAnimationState.breathing) {
        _triggerBreathing();
      }
    });
  }

  void _triggerBreathing() {
    state = state.copyWith(
      isBreathing: true,
      animationState: AvatarAnimationState.breathing,
    );

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        state = state.copyWith(
          isBreathing: false,
          animationState: AvatarAnimationState.idle,
        );
      }
    });
  }

  void _startBlinkingAnimation() {
    _blinkingTimer?.cancel();

    void scheduleNextBlink() {
      final random = Random();
      final nextBlinkDelay = Duration(
        milliseconds: 2000 + random.nextInt(4000), // 2-6 secondes
      );

      _blinkingTimer = Timer(nextBlinkDelay, () {
        if (mounted && !state.isSpeaking) {
          _triggerBlink();
        }
        scheduleNextBlink();
      });
    }

    scheduleNextBlink();
  }

  void _triggerBlink() {
    state = state.copyWith(isBlinking: true);

    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        state = state.copyWith(isBlinking: false);
      }
    });
  }

  void _startEmotionSmoothing() {
    _emotionSmoothingTimer?.cancel();
    _emotionSmoothingTimer = Timer.periodic(emotionSmoothingInterval, (_) {
      _smoothEmotionTransition();
    });
  }

  void _smoothEmotionTransition() {
    if (state.currentEmotion == _targetEmotion &&
        (state.emotionIntensity - _targetIntensity).abs() < 0.01) {
      return;
    }

    final currentIntensity = state.emotionIntensity;
    final newIntensity =
        currentIntensity +
        ((_targetIntensity - currentIntensity) * emotionSmoothingAlpha);

    if (state.currentEmotion != _targetEmotion) {
      final emotionTransitionThreshold = 0.6;
      if (_targetIntensity > emotionTransitionThreshold) {
        state = state.copyWith(currentEmotion: _targetEmotion);
      }
    }

    state = state.copyWith(emotionIntensity: newIntensity);
    _updateAuraForTimeOfDay(state.timeOfDay);
  }

  void _startTimeOfDayUpdates() {
    _timeOfDayTimer?.cancel();
    _timeOfDayTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateTimeOfDay(),
    );
  }

  void setEmotion(EmotionType emotion, double intensity) {
    _targetEmotion = emotion;
    _targetIntensity = intensity.clamp(0.0, 1.0);

    _emotionHistory[emotion] = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (intensity > 0.8) {
      state = state.copyWith(animationState: AvatarAnimationState.reacting);

      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          state = state.copyWith(animationState: AvatarAnimationState.idle);
        }
      });
    }
  }

  void setSpeaking(bool speaking) {
    state = state.copyWith(
      isSpeaking: speaking,
      animationState: speaking
          ? AvatarAnimationState.speaking
          : AvatarAnimationState.idle,
    );
  }

  void setListening(bool listening) {
    state = state.copyWith(
      isListening: listening,
      animationState: listening
          ? AvatarAnimationState.listening
          : AvatarAnimationState.idle,
    );
  }

  void handleGesture(GestureType gestureType) {
    final now = DateTime.now();

    if (now.difference(state.lastGestureTime) < gestureTimeout) {
      final cooldownRemaining =
          gestureTimeout.inMilliseconds -
          now.difference(state.lastGestureTime).inMilliseconds;
      if (cooldownRemaining > 0) {
        return;
      }
    }

    state = state.copyWith(lastGesture: gestureType, lastGestureTime: now);

    _processGesture(gestureType);
  }

  void _processGesture(GestureType gestureType) {
    switch (gestureType) {
      case GestureType.tap:
        setEmotion(EmotionType.joy, 0.6);
        state = state.copyWith(animationState: AvatarAnimationState.reacting);
        _scheduleGestureReset(Duration(milliseconds: 300));
        break;

      case GestureType.doubleTap:
        setEmotion(EmotionType.joy, 0.9);
        state = state.copyWith(animationState: AvatarAnimationState.surprised);
        _scheduleGestureReset(Duration(milliseconds: 600));
        break;

      case GestureType.longPress:
        setEmotion(EmotionType.joy, 1.0);
        state = state.copyWith(animationState: AvatarAnimationState.tickled);
        _triggerTickleSequence();
        break;

      case GestureType.swipeUp:
        setEmotion(EmotionType.surprise, 0.7);
        break;

      case GestureType.swipeDown:
        setEmotion(EmotionType.calm, 0.5);
        break;

      case GestureType.none:
        break;
    }
  }

  void _triggerTickleSequence() {
    int tickleCount = 0;
    const maxTickles = 3;

    void nextTickle() {
      if (tickleCount < maxTickles && mounted) {
        setEmotion(EmotionType.joy, 1.0);
        state = state.copyWith(animationState: AvatarAnimationState.tickled);

        Timer(const Duration(milliseconds: 400), () {
          tickleCount++;
          if (tickleCount < maxTickles) {
            nextTickle();
          } else {
            _scheduleGestureReset(Duration(milliseconds: 200));
          }
        });
      }
    }

    nextTickle();
  }

  void _scheduleGestureReset(Duration delay) {
    _gestureTimeoutTimer?.cancel();
    _gestureTimeoutTimer = Timer(delay, () {
      if (mounted) {
        state = state.copyWith(
          animationState: AvatarAnimationState.idle,
          lastGesture: GestureType.none,
        );
        setEmotion(EmotionType.neutral, 0.3);
      }
    });
  }

  Map<String, double> getFaceParameters() {
    final emotion = state.currentEmotion;
    final intensity = state.emotionIntensity;
    final timeModifier = _getTimeOfDayModifier();

    Map<String, double> parameters = {
      'eyeOpenness': _getEyeOpenness(emotion, intensity),
      'eyebrowHeight': _getEyebrowHeight(emotion, intensity),
      'mouthCurvature': _getMouthCurvature(emotion, intensity),
      'mouthOpenness': state.isSpeaking ? 0.6 : 0.1,
      'blinkAmount': state.isBlinking ? 1.0 : 0.0,
      'breathingScale': state.isBreathing ? 1.05 : 1.0,
      'auraIntensity': state.currentAuraIntensity * timeModifier,
      'emotionIntensity': intensity,
    };

    if (state.animationState == AvatarAnimationState.tickled) {
      parameters['vibrationAmount'] =
          sin(DateTime.now().millisecondsSinceEpoch / 50) * 0.1;
    }

    return parameters;
  }

  double _getEyeOpenness(EmotionType emotion, double intensity) {
    switch (emotion) {
      case EmotionType.joy:
        return 0.8 - (intensity * 0.3); // Yeux qui se ferment en souriant
      case EmotionType.surprise:
        return 1.0; // Yeux grand ouverts
      case EmotionType.sadness:
        return 0.6 - (intensity * 0.2); // Yeux lourds
      case EmotionType.anger:
        return 0.9; // Yeux ouverts et fixe
      case EmotionType.fear:
        return 1.0; // Yeux écarquillés
      case EmotionType.disgust:
        return 0.7; // Yeux plissés
      case EmotionType.calm:
        return 0.8; // Yeux détendus
      default:
        return 0.8;
    }
  }

  double _getEyebrowHeight(EmotionType emotion, double intensity) {
    switch (emotion) {
      case EmotionType.joy:
        return 0.6 + (intensity * 0.2); // Sourcils relevés
      case EmotionType.surprise:
        return 0.9; // Sourcils très hauts
      case EmotionType.sadness:
        return 0.3 - (intensity * 0.1); // Sourcils abaissés
      case EmotionType.anger:
        return 0.2; // Sourcils froncés
      case EmotionType.fear:
        return 0.8; // Sourcils hauts
      case EmotionType.disgust:
        return 0.4; // Sourcils légèrement froncés
      case EmotionType.calm:
        return 0.5; // Position neutre
      default:
        return 0.5;
    }
  }

  double _getMouthCurvature(EmotionType emotion, double intensity) {
    switch (emotion) {
      case EmotionType.joy:
        return 0.8 + (intensity * 0.2); // Grand sourire
      case EmotionType.surprise:
        return 0.5; // Bouche neutre légèrement ouverte
      case EmotionType.sadness:
        return 0.2 - (intensity * 0.2); // Bouche tombante
      case EmotionType.anger:
        return 0.3; // Bouche serrée
      case EmotionType.fear:
        return 0.4; // Bouche légèrement ouverte
      case EmotionType.disgust:
        return 0.1; // Moue de dégoût
      case EmotionType.calm:
        return 0.6; // Léger sourire
      default:
        return 0.5;
    }
  }

  double _getTimeOfDayModifier() {
    switch (state.timeOfDay) {
      case TimeOfDayPeriod.morning:
        return 1.2; // Plus lumineux le matin
      case TimeOfDayPeriod.afternoon:
        return 1.0; // Intensité normale
      case TimeOfDayPeriod.evening:
        return 0.8; // Légèrement atténué
      case TimeOfDayPeriod.night:
        return 0.6; // Plus tamisé la nuit
    }
  }

  Color getEmotionColor() {
    final baseColor = state.currentEmotion.primaryColor;
    final timeColor = _getTimeOfDayColor();
    final blendRatio = state.emotionIntensity * 0.7;

    return Color.lerp(timeColor, baseColor, blendRatio) ?? baseColor;
  }

  Color _getTimeOfDayColor() {
    switch (state.timeOfDay) {
      case TimeOfDayPeriod.morning:
        return const Color(0xFFFFE5B4); // Beige chaud
      case TimeOfDayPeriod.afternoon:
        return const Color(0xFFE6F3FF); // Bleu très clair
      case TimeOfDayPeriod.evening:
        return const Color(0xFFFFE4E1); // Rose très pâle
      case TimeOfDayPeriod.night:
        return const Color(0xFFE6E6FA); // Lavande très pâle
    }
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _blinkingTimer?.cancel();
    _emotionSmoothingTimer?.cancel();
    _timeOfDayTimer?.cancel();
    _gestureTimeoutTimer?.cancel();
    super.dispose();
  }
}
