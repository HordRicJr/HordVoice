import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/avatar_state_service.dart';
import '../services/emotional_avatar_service.dart';
import '../theme/design_tokens.dart'; // Pour EmotionType

class AnimatedAvatar extends ConsumerStatefulWidget {
  final double size;
  final Function(GestureType)? onGesture;
  final bool enableGestures;
  final bool isTTSActive; // Étape 10: Gérer priorité TTS

  const AnimatedAvatar({
    super.key,
    this.size = 200.0,
    this.onGesture,
    this.enableGestures = true,
    this.isTTSActive = false, // Étape 10: TTS actif
  });

  @override
  ConsumerState<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends ConsumerState<AnimatedAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _blinkController;
  late AnimationController _speakingController;
  late AnimationController _reactionController;
  late AnimationController _auraController;
  late AnimationController _tickleController;

  late Animation<double> _breathingAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _speakingAnimation;
  late Animation<double> _reactionAnimation;
  late Animation<double> _auraAnimation;
  late Animation<double> _tickleAnimation;

  DateTime? _lastTapTime;
  int _tapCount = 0;

  // Étape 10: Cooldown et priorités
  DateTime? _lastGestureTime;
  final Duration _gestureCooldown = Duration(seconds: 2); // Cooldown 2-3s
  String _lastGestureType = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _speakingAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.elasticOut),
    );

    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _reactionAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _reactionController, curve: Curves.elasticOut),
    );

    _auraController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _auraAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _tickleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _tickleAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _tickleController, curve: Curves.elasticInOut),
    );

    _startBreathingCycle();
    _startAuraCycle();
  }

  void _startBreathingCycle() {
    _breathingController.repeat(reverse: true);
  }

  void _startAuraCycle() {
    _auraController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarStateProvider);
    final emotionalState = ref.watch(emotionalAvatarServiceProvider);

    return GestureDetector(
      onTap: widget.enableGestures ? _handleTap : null,
      onLongPress: widget.enableGestures ? _handleLongPress : null,
      onPanUpdate: widget.enableGestures ? _handlePanUpdate : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathingAnimation,
          _blinkAnimation,
          _speakingAnimation,
          _reactionAnimation,
          _auraAnimation,
          _tickleAnimation,
        ]),
        builder: (context, child) {
          return _buildAvatar(avatarState, emotionalState);
        },
      ),
    );
  }

  Widget _buildAvatar(
    AvatarState avatarState,
    EmotionalAvatarState emotionalState,
  ) {
    final faceParams = avatarState.faceParameters.isNotEmpty
        ? avatarState.faceParameters
        : ref.read(avatarStateProvider.notifier).getFaceParameters();

    // Intégrer la vitesse d'animation émotionnelle
    double scale = _breathingAnimation.value;
    final emotionalSpeed = emotionalState.animationSpeed;

    if (avatarState.isSpeaking) {
      scale *= _speakingAnimation.value * emotionalSpeed;
    }

    if (avatarState.animationState == AvatarAnimationState.reacting) {
      scale *= _reactionAnimation.value * emotionalSpeed;
    }

    double tickleOffset = 0.0;
    if (avatarState.animationState == AvatarAnimationState.tickled) {
      tickleOffset = _tickleAnimation.value * emotionalState.emotionIntensity;
    }

    // Modifier les transformations selon l'état émotionnel
    final emotionalIntensity = emotionalState.emotionIntensity;
    final breathingMultiplier =
        _getBreathingMultiplier(emotionalState.currentEmotion) *
        emotionalIntensity;

    return Transform.translate(
      offset: Offset(tickleOffset, 0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(
            0.1 *
                math.sin(_breathingAnimation.value * 2 * math.pi) *
                breathingMultiplier,
          )
          ..rotateY(
            0.05 *
                math.cos(_breathingAnimation.value * math.pi) *
                breathingMultiplier,
          )
          ..rotateZ(0.02 * math.sin(_breathingAnimation.value * 3 * math.pi)),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAura(avatarState),
                _buildAvatarBody(avatarState, faceParams),
                _buildSurfaceEffects(avatarState),
                if (avatarState.isListening) _buildListeningIndicator(),
                if (avatarState.isSpeaking) _buildSpeakingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAura(AvatarState avatarState) {
    final intensity = avatarState.currentAuraIntensity * _auraAnimation.value;

    return Container(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            avatarState.currentAuraColor.withOpacity(intensity * 0.3),
            avatarState.currentAuraColor.withOpacity(intensity * 0.1),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildAvatarBody(
    AvatarState avatarState,
    Map<String, double> faceParams,
  ) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF8A2BE2).withOpacity(0.9),
            const Color(0xFF4B0082).withOpacity(0.8),
            const Color(0xFF1E1E2E),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        border: Border.all(
          color: avatarState.currentAuraColor.withOpacity(0.6),
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarState.currentAuraColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildEyes(faceParams),
          _buildMouth(faceParams),
          _buildEyebrows(faceParams),
          _buildEmotionEffects(avatarState),
        ],
      ),
    );
  }

  Widget _buildEyes(Map<String, double> faceParams) {
    final eyeOpenness = faceParams['eyeOpenness'] ?? 0.8;
    final blinkAmount = faceParams['blinkAmount'] ?? 0.0;
    final finalOpenness = eyeOpenness * (1.0 - blinkAmount);

    return Positioned(
      top: widget.size * 0.35,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEye(finalOpenness, isLeft: true),
          SizedBox(width: widget.size * 0.1),
          _buildEye(finalOpenness, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildEye(double openness, {required bool isLeft}) {
    final eyeSize = widget.size * 0.08;

    return Container(
      width: eyeSize,
      height: eyeSize * openness,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(eyeSize / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: openness > 0.3
          ? Center(
              child: Container(
                width: eyeSize * 0.6,
                height: eyeSize * 0.6 * openness,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(eyeSize),
                ),
                child: Center(
                  child: Container(
                    width: eyeSize * 0.2,
                    height: eyeSize * 0.2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMouth(Map<String, double> faceParams) {
    final curvature = faceParams['mouthCurvature'] ?? 0.5;
    final openness = faceParams['mouthOpenness'] ?? 0.1;

    return Positioned(
      top: widget.size * 0.65,
      child: CustomPaint(
        size: Size(widget.size * 0.2, widget.size * 0.1),
        painter: MouthPainter(
          curvature: curvature,
          openness: openness,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildEyebrows(Map<String, double> faceParams) {
    final height = faceParams['eyebrowHeight'] ?? 0.5;
    final eyebrowY = widget.size * (0.25 + (0.1 * (1.0 - height)));

    return Positioned(
      top: eyebrowY,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEyebrow(height, isLeft: true),
          SizedBox(width: widget.size * 0.1),
          _buildEyebrow(height, isLeft: false),
        ],
      ),
    );
  }

  Widget _buildEyebrow(double height, {required bool isLeft}) {
    return Container(
      width: widget.size * 0.06,
      height: widget.size * 0.02,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(widget.size * 0.01),
      ),
    );
  }

  Widget _buildEmotionEffects(AvatarState avatarState) {
    switch (avatarState.currentEmotion) {
      case EmotionType.joy:
        return _buildJoyEffects();
      case EmotionType.surprise:
        return _buildSurpriseEffects();
      case EmotionType.anger:
        return _buildAngerEffects();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildJoyEffects() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SparklesPainter(
          animationValue: _auraAnimation.value,
          color: Colors.yellow.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSurpriseEffects() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2.0),
        ),
      ),
    );
  }

  Widget _buildAngerEffects() {
    return Positioned.fill(
      child: CustomPaint(
        painter: AngerEffectPainter(
          animationValue: _auraAnimation.value,
          color: Colors.red.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSurfaceEffects(AvatarState avatarState) {
    return Positioned(
      top: widget.size * 0.15,
      left: widget.size * 0.25,
      child: Container(
        width: widget.size * 0.15,
        height: widget.size * 0.2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.3), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(widget.size * 0.1),
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Positioned(
      bottom: 0,
      child: Container(
        width: widget.size * 0.1,
        height: widget.size * 0.1,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSpeakingIndicator() {
    return Positioned(
      bottom: 0,
      child: Container(
        width: widget.size * 0.1,
        height: widget.size * 0.1,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.volume_up, color: Colors.white, size: 16),
      ),
    );
  }

  void _handleTap() {
    // Étape 10: Vérifier cooldown et priorité TTS
    if (!_canExecuteGesture('tap')) return;

    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      _tapCount++;
      if (_tapCount >= 2) {
        _executeGesture('doubleTap', GestureType.doubleTap);

        // Intégration service émotionnel - Double tap
        final emotionalService = ref.read(
          emotionalAvatarServiceProvider.notifier,
        );
        emotionalService.onTouchStimulus(
          touchPosition: Offset(widget.size / 2, widget.size / 2),
          touchType: TouchType.doubleTap,
          pressure: 0.8,
        );

        _tapCount = 0;
        _lastTapTime = null;
        return;
      }
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_tapCount == 1 && _lastTapTime == now) {
        _executeGesture('tap', GestureType.tap);

        // Intégration service émotionnel - Single tap
        final emotionalService = ref.read(
          emotionalAvatarServiceProvider.notifier,
        );
        emotionalService.onTouchStimulus(
          touchPosition: Offset(widget.size / 2, widget.size / 2),
          touchType: TouchType.tap,
          pressure: 0.6,
        );

        _tapCount = 0;
        _lastTapTime = null;
      }
    });
  }

  void _handleLongPress() {
    // Étape 10: Long-press peut interrompre TTS si configuré
    if (!_canExecuteGesture('longPress')) return;

    _executeGesture('longPress', GestureType.longPress);
    _triggerTickleAnimation();

    // Intégration service émotionnel - Long press
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.onTouchStimulus(
      touchPosition: Offset(widget.size / 2, widget.size / 2),
      touchType: TouchType.longPress,
      pressure: 0.9,
    );
  }

  /// Étape 10: Vérifier si le geste peut être exécuté
  bool _canExecuteGesture(String gestureType) {
    final now = DateTime.now();

    // Vérifier cooldown (2-3s pour même geste)
    if (_lastGestureTime != null &&
        _lastGestureType == gestureType &&
        now.difference(_lastGestureTime!) < _gestureCooldown) {
      debugPrint('Geste $gestureType en cooldown');
      return false;
    }

    // Étape 10: Si TTS critique est actif, seul long-press peut interrompre
    if (widget.isTTSActive && gestureType != 'longPress') {
      debugPrint('TTS actif - geste $gestureType bloqué');
      return false;
    }

    return true;
  }

  /// Étape 10: Exécuter geste avec tracking cooldown
  void _executeGesture(String gestureType, GestureType gesture) {
    _lastGestureTime = DateTime.now();
    _lastGestureType = gestureType;

    widget.onGesture?.call(gesture);
    ref.read(avatarStateProvider.notifier).handleGesture(gesture);

    if (gestureType != 'longPress') {
      _triggerReactionAnimation();
    }

    debugPrint('Geste exécuté: $gestureType');
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final dy = details.delta.dy;

    if (dy.abs() > 3) {
      if (dy < 0) {
        // Swipe up
        if (_canExecuteGesture('swipeUp')) {
          _executeGesture('swipeUp', GestureType.swipeUp);
        }
      } else {
        // Swipe down
        if (_canExecuteGesture('swipeDown')) {
          _executeGesture('swipeDown', GestureType.swipeDown);
        }
      }
    }
  }

  void _triggerReactionAnimation() {
    _reactionController.reset();
    _reactionController.forward();
  }

  void _triggerTickleAnimation() {
    _tickleController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      _tickleController.stop();
      _tickleController.reset();
    });
  }

  /// Calcule le multiplicateur de respiration selon l'émotion
  double _getBreathingMultiplier(EmotionalState emotion) {
    switch (emotion) {
      case EmotionalState.excited:
        return 2.0; // Respiration rapide et intense
      case EmotionalState.surprised:
        return 1.8; // Respiration accélérée
      case EmotionalState.happy:
        return 1.3; // Respiration joyeuse
      case EmotionalState.alert:
        return 1.5; // Respiration attentive
      case EmotionalState.thinking:
        return 0.8; // Respiration plus lente, concentration
      case EmotionalState.sleepy:
        return 0.4; // Respiration très lente
      case EmotionalState.sad:
        return 0.6; // Respiration ralentie
      case EmotionalState.listening:
        return 1.1; // Respiration attentive mais calme
      case EmotionalState.speaking:
        return 1.2; // Respiration légèrement accélérée
      case EmotionalState.confused:
        return 0.9; // Respiration légèrement perturbée
      case EmotionalState.neutral:
        return 1.0; // Respiration normale
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _blinkController.dispose();
    _speakingController.dispose();
    _reactionController.dispose();
    _auraController.dispose();
    _tickleController.dispose();
    super.dispose();
  }
}

class MouthPainter extends CustomPainter {
  final double curvature;
  final double openness;
  final Color color;

  MouthPainter({
    required this.curvature,
    required this.openness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final curveHeight = (curvature - 0.5) * size.height * 0.8;

    if (openness > 0.3) {
      final mouthWidth = size.width * 0.8;
      final mouthHeight = size.height * openness;

      path.addOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY + curveHeight),
          width: mouthWidth,
          height: mouthHeight,
        ),
      );
    } else {
      path.moveTo(centerX - size.width * 0.4, centerY);
      path.quadraticBezierTo(
        centerX,
        centerY + curveHeight,
        centerX + size.width * 0.4,
        centerY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklesPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  SparklesPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final sparkleCount = 6;

    for (int i = 0; i < sparkleCount; i++) {
      final angle =
          (i / sparkleCount) * 2 * math.pi + animationValue * 2 * math.pi;
      final radius =
          size.width * 0.3 +
          math.sin(animationValue * 4 + i) * size.width * 0.1;

      final x = size.width / 2 + math.cos(angle) * radius;
      final y = size.height / 2 + math.sin(angle) * radius;

      final sparkleSize = 3.0 + math.sin(animationValue * 6 + i) * 2.0;

      _drawSparkle(canvas, Offset(x, y), sparkleSize, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerRadius = size;
      final innerRadius = size * 0.3;

      if (i == 0) {
        path.moveTo(
          center.dx + math.cos(angle) * outerRadius,
          center.dy + math.sin(angle) * outerRadius,
        );
      } else {
        path.lineTo(
          center.dx + math.cos(angle) * outerRadius,
          center.dy + math.sin(angle) * outerRadius,
        );
      }

      final midAngle = angle + math.pi / 4;
      path.lineTo(
        center.dx + math.cos(midAngle) * innerRadius,
        center.dy + math.sin(midAngle) * innerRadius,
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AngerEffectPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  AngerEffectPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + animationValue * 0.5;
      final startRadius = size.width * 0.35;
      final endRadius = size.width * 0.45;

      final startX = centerX + math.cos(angle) * startRadius;
      final startY = centerY + math.sin(angle) * startRadius;
      final endX = centerX + math.cos(angle) * endRadius;
      final endY = centerY + math.sin(angle) * endRadius;

      final vibration = math.sin(animationValue * 10 + i) * 2;

      canvas.drawLine(
        Offset(startX + vibration, startY + vibration),
        Offset(endX + vibration, endY + vibration),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
