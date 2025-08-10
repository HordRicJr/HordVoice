import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service pour gérer la transition animée entre onboarding et home
/// avec avatar 3D, effets sonores et animations fluides
class TransitionAnimationService {
  static final TransitionAnimationService _instance =
      TransitionAnimationService._internal();
  factory TransitionAnimationService() => _instance;
  TransitionAnimationService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      debugPrint('TransitionAnimationService initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation TransitionAnimationService: $e');
    }
  }

  /// Transition principale onboarding -> home avec avatar
  Future<void> executeOnboardingToHomeTransition(
    BuildContext context, {
    required Widget homeWidget,
    Duration duration = const Duration(milliseconds: 2500),
  }) async {
    if (!_isInitialized) await initialize();

    // Feedback haptique de démarrage
    HapticFeedback.lightImpact();

    // Lancer l'animation avec overlay
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => homeWidget,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return _buildTransitionAnimation(
            context: context,
            animation: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Construction de l'animation complexe
  Widget _buildTransitionAnimation({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          children: [
            // Arrière-plan qui évolue
            _buildBackgroundTransition(animation),

            // Avatar central qui reste visible
            _buildAvatarTransition(animation),

            // Overlay de contenu qui apparaît
            _buildContentTransition(animation, child),

            // Effets visuels et particules
            _buildVisualEffects(animation),
          ],
        );
      },
    );
  }

  /// Arrière-plan avec transition de couleurs
  Widget _buildBackgroundTransition(Animation<double> animation) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: Tween<double>(begin: 0.5, end: 1.5)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              )
              .value,
          colors: [
            Color.lerp(
              const Color(0xFF1A1A2E), // Onboarding color
              const Color(0xFF0F0F23), // Home color
              animation.value,
            )!,
            Color.lerp(
              const Color(0xFF16213E),
              const Color(0xFF1A1A2E),
              animation.value,
            )!,
          ],
        ),
      ),
    );
  }

  /// Avatar central qui s'anime et évolue
  Widget _buildAvatarTransition(Animation<double> animation) {
    return Positioned.fill(
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective 3D
            ..rotateY(
              Tween<double>(begin: 0, end: 0.3)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
                    ),
                  )
                  .value,
            )
            ..scale(
              Tween<double>(begin: 1.0, end: 1.2)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                    ),
                  )
                  .value,
            ),
          child: Container(
            width: Tween<double>(begin: 180, end: 220)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                )
                .value,
            height: Tween<double>(begin: 180, end: 220)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                )
                .value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(
                    Tween<double>(
                      begin: 0.3,
                      end: 0.6,
                    ).animate(animation).value,
                  ),
                  blurRadius: Tween<double>(
                    begin: 20,
                    end: 40,
                  ).animate(animation).value,
                  spreadRadius: Tween<double>(
                    begin: 5,
                    end: 15,
                  ).animate(animation).value,
                ),
              ],
              gradient: RadialGradient(
                colors: [
                  Color.lerp(
                    Colors.blue.shade300,
                    Colors.cyan.shade400,
                    animation.value,
                  )!,
                  Color.lerp(
                    Colors.blue.shade600,
                    Colors.blue.shade800,
                    animation.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Avatar de base
                const Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  ),
                ),

                // Effet de lueur pulsante
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.3 + (0.4 * (animation.value % 1.0)),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Contenu qui apparaît progressivement
  Widget _buildContentTransition(Animation<double> animation, Widget child) {
    return Opacity(
      opacity: Tween<double>(begin: 0.0, end: 1.0)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
            ),
          )
          .value,
      child: Transform.translate(
        offset: Offset(
          0,
          Tween<double>(begin: 50, end: 0)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                ),
              )
              .value,
        ),
        child: child,
      ),
    );
  }

  /// Effets visuels - particules et lueurs
  Widget _buildVisualEffects(Animation<double> animation) {
    return Positioned.fill(
      child: CustomPaint(
        painter: TransitionEffectsPainter(animation: animation),
      ),
    );
  }

  /// Jouer le son de transition
  Future<void> playTransitionSound() async {
    try {
      // Son futuriste de transition (whoosh + carillon)
      await _audioPlayer.play(AssetSource('sounds/transition_whoosh.mp3'));

      // Petit délai puis son de confirmation
      await Future.delayed(const Duration(milliseconds: 1500));
      await _audioPlayer.play(AssetSource('sounds/transition_complete.mp3'));
    } catch (e) {
      debugPrint('Erreur lecture son transition: $e');
    }
  }

  /// Transition rapide pour interactions vocales (avatar popup)
  Future<void> showVoiceInteractionAvatar(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const VoiceInteractionAvatarDialog(),
    );
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Painter pour les effets visuels de transition
class TransitionEffectsPainter extends CustomPainter {
  final Animation<double> animation;

  TransitionEffectsPainter({required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // Dessiner des cercles concentriques qui s'expandent
    for (int i = 0; i < 3; i++) {
      final radius = (50 + i * 30) * animation.value;
      paint
        ..color = Colors.blue.withOpacity(0.1 - (i * 0.03))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    // Dessiner des particules scintillantes
    final random = [0.2, 0.5, 0.8, 0.3, 0.7, 0.9, 0.1, 0.6];
    for (int i = 0; i < random.length; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final distance = 100 + (50 * animation.value);
      final x = center.dx + (distance * math.cos(angle));
      final y = center.dy + (distance * math.sin(angle));

      paint
        ..color = Colors.white.withOpacity(random[i] * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dialog pour avatar d'interaction vocale
class VoiceInteractionAvatarDialog extends StatefulWidget {
  const VoiceInteractionAvatarDialog({Key? key}) : super(key: key);

  @override
  State<VoiceInteractionAvatarDialog> createState() =>
      _VoiceInteractionAvatarDialogState();
}

class _VoiceInteractionAvatarDialogState
    extends State<VoiceInteractionAvatarDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.1),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, size: 60, color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}
