import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_session_manager.dart';
import '../services/progressive_permission_service.dart';
import '../services/emotional_avatar_service.dart';
import '../widgets/animated_avatar.dart';
import '../views/main_spatial_view.dart';

/// Vue d'onboarding vocal minimaliste - Avatar 3D centré + fond animé spatial
/// SANS BOUTONS - Interface pure selon les spécifications utilisateur
class VoiceOnboardingView extends ConsumerStatefulWidget {
  const VoiceOnboardingView({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceOnboardingView> createState() =>
      _VoiceOnboardingViewState();
}

class _VoiceOnboardingViewState extends ConsumerState<VoiceOnboardingView>
    with TickerProviderStateMixin {
  // Animation controllers pour effets 3D et spatiaux
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _starsController;
  late AnimationController _nebulaController;
  late AnimationController _breathingController;

  // État onboarding
  String _statusText = 'Initialisation de Ric...';
  bool _isAvatarActive = false;
  bool _showWelcomeText = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startOnboardingSequence();

    // Connecter le service émotionnel au VoiceSessionManager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceManager = ref.read(voiceSessionManagerProvider.notifier);
      final emotionalService = ref.read(
        emotionalAvatarServiceProvider.notifier,
      );
      voiceManager.connectEmotionalService(emotionalService);
      debugPrint('🎭 Service émotionnel connecté dans l\'onboarding');
    });
  }

  /// Initialise tous les contrôleurs d'animation
  void _initializeAnimations() {
    // Rotation avatar 3D
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulsation avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Animation étoiles
    _starsController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Animation nébuleuse
    _nebulaController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();

    // Respiration avatar
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  /// Séquence d'onboarding avec permissions progressives
  Future<void> _startOnboardingSequence() async {
    try {
      debugPrint(
        '🚀 Démarrage séquence onboarding avec permissions progressives',
      );

      // Délai d'attente pour l'effet visuel initial
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _statusText = 'Bienvenue ! Ric va vous accompagner...';
          _isAvatarActive = true;
        });
      }

      await Future.delayed(const Duration(seconds: 2));

      // Démarrer le processus de permissions progressives
      if (mounted) {
        setState(() {
          _statusText = 'Configuration des permissions...';
        });
      }

      // Utiliser le service de permissions progressives
      if (!context.mounted) return;

      final permissionService = ProgressivePermissionService();
      final result = await permissionService.startProgressivePermissionFlow(
        context,
      );

      // Traiter le résultat du flux de permissions
      await _handlePermissionFlowResult(result);
    } catch (e) {
      debugPrint('❌ Erreur séquence onboarding: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Erreur d\'initialisation - Tap pour réessayer';
        });
      }
    }
  }

  /// Traite le résultat du flux de permissions progressives
  Future<void> _handlePermissionFlowResult(PermissionFlowResult result) async {
    switch (result.status) {
      case PermissionFlowStatus.success:
        debugPrint('✅ Permissions configurées: ${result.summary}');

        if (mounted) {
          setState(() {
            _statusText = 'Ric se prépare à vous écouter...';
          });
        }

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          setState(() {
            _statusText = 'Ric vous écoute maintenant';
            _showWelcomeText = false;
          });

          // Démarrer l'écoute automatiquement
          _startVoiceSession();
        }
        break;

      case PermissionFlowStatus.essentialDenied:
        debugPrint(
          '❌ Permission essentielle refusée: ${result.essentialPermissionDenied}',
        );

        if (mounted) {
          setState(() {
            _statusText = 'Permission microphone requise - Tap pour configurer';
          });
        }
        break;

      case PermissionFlowStatus.error:
        debugPrint('❌ Erreur permissions: ${result.errorMessage}');

        if (mounted) {
          setState(() {
            _statusText = 'Erreur permissions - Tap pour réessayer';
          });
        }
        break;

      case PermissionFlowStatus.alreadyInProgress:
        debugPrint('⚠️ Processus déjà en cours');

        if (mounted) {
          setState(() {
            _statusText = 'Configuration en cours...';
          });
        }
        break;
    }
  }

  /// Démarre la session vocale automatiquement
  Future<void> _startVoiceSession() async {
    try {
      debugPrint('🎤 Démarrage session vocale automatique');

      final sessionManager = ref.read(voiceSessionManagerProvider.notifier);
      final canStart = await sessionManager.startListening();

      if (mounted) {
        setState(() {
          _statusText = canStart
              ? 'Dites "Salut Ric" pour commencer'
              : 'Problème microphone - Vérifiez les permissions';
        });

        // Si tout est prêt, transitionner vers la vue spatiale après un délai
        if (canStart) {
          Future.delayed(const Duration(seconds: 3), () {
            _transitionToSpatialView();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur démarrage session: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Erreur microphone - Tap pour réessayer';
        });
      }
    }
  }

  /// Transition vers la vue spatiale immersive
  void _transitionToSpatialView() {
    if (!mounted) return;

    debugPrint('🌌 Transition vers l\'univers spatial');

    // Navigation avec animation personnalisée
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainSpatialView(),
        transitionDuration: const Duration(milliseconds: 2000),
        reverseTransitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animation de zoom vers l'univers spatial
          final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
        },
      ),
    );
  }

  /// Gestion des touches (pas de boutons visibles mais réactif)
  void _handleTap() {
    // Micro-animation seulement (pas de contrôles)
    HapticFeedback.lightImpact();

    // Animation de reconnaissance tactile
    _pulseController.reset();
    _pulseController.forward();

    debugPrint('👆 Tap détecté - micro-animation');

    // Gestion contextuelle selon le statut
    if (_statusText.contains('Permission microphone requise')) {
      // Ouvrir les paramètres pour configurer le microphone
      _openMicrophoneSettings();
    } else if (_statusText.contains('Erreur') ||
        _statusText.contains('Problème')) {
      // Relancer la session vocale ou les permissions
      if (_statusText.contains('permission')) {
        _startOnboardingSequence();
      } else {
        _startVoiceSession();
      }
    }
  }

  /// Ouvre les paramètres pour configurer le microphone
  Future<void> _openMicrophoneSettings() async {
    try {
      debugPrint('🔧 Ouverture paramètres microphone');

      final permissionService = ProgressivePermissionService();
      final opened = await permissionService.openSettingsForPermission(
        Permission.microphone,
      );

      if (mounted) {
        setState(() {
          _statusText = opened
              ? 'Revenez après avoir activé le microphone'
              : 'Impossible d\'ouvrir les paramètres';
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture paramètres: $e');
      if (mounted) {
        setState(() {
          _statusText = 'Erreur paramètres - Configurez manuellement';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(voiceSessionManagerProvider);

    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Fond animé spatial
              _buildSpaceBackground(),

              // Avatar 3D centré
              _buildCentralAvatar(),

              // Texte de statut (optionnel et minimaliste)
              if (_showWelcomeText) _buildStatusText(),

              // Indicateur d'état vocal (discret)
              _buildVoiceStateIndicator(sessionState),
            ],
          ),
        ),
      ),
    );
  }

  /// Fond animé "espace" avec effets GPU-friendly
  Widget _buildSpaceBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_starsController, _nebulaController]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color.lerp(
                  const Color(0xFF0A0A2E),
                  const Color(0xFF1A1A3E),
                  (_nebulaController.value * 0.3).clamp(0.0, 1.0),
                )!,
                Color.lerp(
                  const Color(0xFF000011),
                  const Color(0xFF001122),
                  (_nebulaController.value * 0.2).clamp(0.0, 1.0),
                )!,
              ],
            ),
          ),
          child: CustomPaint(
            painter: SpaceBackgroundPainter(
              starsAnimation: _starsController.value,
              nebulaAnimation: _nebulaController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  /// Avatar 3D centré avec effets avancés
  Widget _buildCentralAvatar() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _pulseController,
          _breathingController,
        ]),
        builder: (context, child) {
          // Effet 3D avec Matrix4
          final rotationY = _rotationController.value * 2 * math.pi * 0.1;
          final pulse = 1.0 + (_pulseController.value * 0.1);
          final breathing = 1.0 + (_breathingController.value * 0.05);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(rotationY)
              ..scale(pulse * breathing),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isAvatarActive
                        ? Colors.blue.withOpacity(
                            0.3 + _pulseController.value * 0.2,
                          )
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 20 + (_pulseController.value * 10),
                    spreadRadius: 5 + (_pulseController.value * 3),
                  ),
                ],
              ),
              child: AnimatedAvatar(size: 200),
            ),
          );
        },
      ),
    );
  }

  /// Texte de statut minimaliste (fade out automatique)
  Widget _buildStatusText() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showWelcomeText ? 1.0 : 0.0,
        duration: const Duration(seconds: 2),
        child: Text(
          _statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  /// Indicateur d'état vocal discret
  Widget _buildVoiceStateIndicator(VoiceSessionState sessionState) {
    if (sessionState.status == VoiceSessionStatus.idle)
      return const SizedBox.shrink();

    Color indicatorColor;
    String stateText;

    switch (sessionState.status) {
      case VoiceSessionStatus.listening:
        indicatorColor = Colors.green;
        stateText = '🎤 Écoute...';
        break;
      case VoiceSessionStatus.processing:
        indicatorColor = Colors.orange;
        stateText = '🧠 Traitement...';
        break;
      case VoiceSessionStatus.speaking:
        indicatorColor = Colors.blue;
        stateText = '🗣️ Ric parle...';
        break;
      case VoiceSessionStatus.error:
        indicatorColor = Colors.red;
        stateText = '❌ Erreur';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            stateText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _starsController.dispose();
    _nebulaController.dispose();
    _breathingController.dispose();
    super.dispose();
  }
}

/// Painter pour le fond spatial animé
class SpaceBackgroundPainter extends CustomPainter {
  final double starsAnimation;
  final double nebulaAnimation;

  SpaceBackgroundPainter({
    required this.starsAnimation,
    required this.nebulaAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42); // Seed fixe pour cohérence

    // Dessiner les étoiles
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity =
          (0.3 + random.nextDouble() * 0.7) *
          (0.5 + 0.5 * math.sin(starsAnimation * 2 * math.pi + i));

      paint.color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), 0.5 + random.nextDouble() * 1.5, paint);
    }

    // Effet nébuleuse subtil
    paint.color = Colors.purple.withOpacity(0.05);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    final nebulaCenterX =
        size.width * 0.3 +
        (size.width * 0.4 * math.sin(nebulaAnimation * 2 * math.pi));
    final nebulaCenterY =
        size.height * 0.7 +
        (size.height * 0.2 * math.cos(nebulaAnimation * 2 * math.pi));

    canvas.drawCircle(
      Offset(nebulaCenterX, nebulaCenterY),
      50 + 20 * math.sin(nebulaAnimation * 2 * math.pi),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
