import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/emotional_avatar_service.dart';
import '../services/voice_session_manager.dart';
import '../widgets/animated_avatar.dart';
import '../painters/space_painters.dart';

/// Avatar 3D flottant dans un univers spatial avec effets de profondeur
/// et réactivité contextuelle selon les spécifications utilisateur
class SpacialAvatarView extends ConsumerStatefulWidget {
  final VoidCallback? onInitializationComplete;

  const SpacialAvatarView({Key? key, this.onInitializationComplete})
    : super(key: key);

  @override
  ConsumerState<SpacialAvatarView> createState() => _SpacialAvatarViewState();
}

class _SpacialAvatarViewState extends ConsumerState<SpacialAvatarView>
    with TickerProviderStateMixin {
  // Controllers pour l'univers spatial
  late AnimationController _starsController;
  late AnimationController _nebulaController;
  late AnimationController _planetsController;
  late AnimationController _cosmicDustController;

  // Controllers pour l'avatar 3D
  late AnimationController _avatarFloatingController;
  late AnimationController _avatarProximityController;
  late AnimationController _avatarDepthController;
  late AnimationController _avatarGlowController;
  late AnimationController _voicePulseController;

  // Animations spatiales
  late Animation<double> _starsRotation;
  late Animation<double> _nebulaFlow;
  late Animation<double> _cosmicDustDrift;

  // Animations avatar 3D
  late Animation<double> _avatarFloat;
  late Animation<double> _avatarProximity;
  late Animation<double> _avatarDepth;
  late Animation<double> _avatarGlow;
  late Animation<double> _voicePulse;

  // État contextuel
  bool _isListening = false;
  bool _isSpeaking = false;
  EmotionalState _currentEmotion = EmotionalState.neutral;

  // Configuration spatiale
  final List<Star> _stars = [];
  final List<NebulaParticle> _nebulaParticles = [];
  final List<CosmicDust> _cosmicDustParticles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeSpaceEnvironment();
    _initializeAnimations();
    _generateSpaceElements();
    _startUniverseAnimation();

    // Connecter aux services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToServices();
    });
  }

  void _initializeAnimations() {
    // Animations de l'univers spatial
    _starsController = AnimationController(
      duration: const Duration(minutes: 2),
      vsync: this,
    );
    _starsRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _starsController, curve: Curves.linear));

    _nebulaController = AnimationController(
      duration: const Duration(minutes: 3),
      vsync: this,
    );
    _nebulaFlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _nebulaController, curve: Curves.linear));

    _planetsController = AnimationController(
      duration: const Duration(minutes: 5),
      vsync: this,
    );

    _cosmicDustController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    );
    _cosmicDustDrift = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cosmicDustController, curve: Curves.linear),
    );

    // Animations de l'avatar 3D
    _avatarFloatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _avatarFloat = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _avatarFloatingController,
        curve: Curves.easeInOut,
      ),
    );

    _avatarProximityController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _avatarProximity = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _avatarProximityController,
        curve: Curves.easeInOut,
      ),
    );

    _avatarDepthController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _avatarDepth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarDepthController, curve: Curves.easeInOut),
    );

    _avatarGlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _avatarGlow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _avatarGlowController, curve: Curves.easeInOut),
    );

    _voicePulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _voicePulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _voicePulseController, curve: Curves.elasticOut),
    );
  }

  void _initializeSpaceEnvironment() {
    // Configuration initiale de l'univers spatial
  }

  void _generateSpaceElements() {
    // Générer les étoiles
    _stars.clear();
    for (int i = 0; i < 150; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          brightness: 0.3 + _random.nextDouble() * 0.7,
          twinklePhase: _random.nextDouble() * 2 * math.pi,
          distance: 0.1 + _random.nextDouble() * 0.9,
          size: 0.5 + _random.nextDouble() * 2.0,
        ),
      );
    }

    // Générer les particules de nébuleuse
    _nebulaParticles.clear();
    for (int i = 0; i < 80; i++) {
      _nebulaParticles.add(
        NebulaParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          color: _getNebulaColor(),
          size: 20 + _random.nextDouble() * 60,
          opacity: 0.1 + _random.nextDouble() * 0.3,
          flowSpeed: 0.5 + _random.nextDouble() * 1.5,
          driftDirection: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }

    // Générer la poussière cosmique
    _cosmicDustParticles.clear();
    for (int i = 0; i < 200; i++) {
      _cosmicDustParticles.add(
        CosmicDust(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          opacity: 0.1 + _random.nextDouble() * 0.4,
          size: 0.5 + _random.nextDouble() * 1.5,
          velocity: 0.1 + _random.nextDouble() * 0.5,
          direction: _random.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  Color _getNebulaColor() {
    final colors = [
      const Color(0xFF4A90E2), // Bleu
      const Color(0xFF9B59B6), // Violet
      const Color(0xFFE74C3C), // Rouge
      const Color(0xFF2ECC71), // Vert
      const Color(0xFFF39C12), // Orange
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _startUniverseAnimation() {
    // Démarrer toutes les animations de l'univers
    _starsController.repeat();
    _nebulaController.repeat();
    _planetsController.repeat();
    _cosmicDustController.repeat();
    _avatarFloatingController.repeat(reverse: true);
    _avatarGlowController.repeat(reverse: true);
  }

  void _connectToServices() {
    // Connecter au service émotionnel
    final voiceManager = ref.read(voiceSessionManagerProvider.notifier);
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    voiceManager.connectEmotionalService(emotionalService);

    debugPrint('🌌 Avatar spatial connecté aux services');
  }

  // Réactions aux changements d'état vocal
  void _onVoiceStateChanged(VoiceSessionState voiceState) {
    setState(() {
      _isListening = voiceState.isListening;
      _isSpeaking = voiceState.isSpeaking;
    });

    _adaptToVoiceState(voiceState);
  }

  void _adaptToVoiceState(VoiceSessionState voiceState) {
    switch (voiceState.status) {
      case VoiceSessionStatus.listening:
        _avatarApproach(); // Avatar s'approche pour écouter
        _slowDownUniverse(); // Ralentir l'univers pour concentration
        break;
      case VoiceSessionStatus.speaking:
        _avatarSpeakingMode(); // Mode parole avec pulsations
        _accelerateUniverse(); // Accélérer l'univers
        break;
      case VoiceSessionStatus.processing:
        _avatarReflectionMode(); // Avatar recule pour réfléchir
        _dimUniverse(); // Assombrir l'univers
        break;
      case VoiceSessionStatus.idle:
        _avatarNeutralMode(); // Retour mode neutre
        _normalUniverse(); // Vitesse normale
        break;
      default:
        break;
    }
  }

  void _onEmotionChanged(EmotionalAvatarState emotionalState) {
    if (_currentEmotion != emotionalState.currentEmotion) {
      setState(() {
        _currentEmotion = emotionalState.currentEmotion;
      });
      _adaptToEmotion(emotionalState);
    }
  }

  void _adaptToEmotion(EmotionalAvatarState emotionalState) {
    switch (emotionalState.currentEmotion) {
      case EmotionalState.excited:
        _avatarExcitedMode(); // Avatar vibre d'excitation
        break;
      case EmotionalState.happy:
        _avatarHappyMode(); // Avatar rayonne de joie
        break;
      case EmotionalState.surprised:
        _avatarSurprisedMode(); // Avatar sursaute
        break;
      case EmotionalState.sad:
        _avatarSadMode(); // Avatar s'assombrit
        break;
      case EmotionalState.confused:
        _avatarConfusedMode(); // Avatar oscille
        break;
      default:
        _avatarNeutralMode(); // Mode neutre
        break;
    }
  }

  // Modes d'animation de l'avatar

  void _avatarApproach() {
    _avatarProximityController.forward();
    _avatarDepthController.animateTo(0.7);
  }

  void _avatarRetreat() {
    _avatarProximityController.reverse();
    _avatarDepthController.animateTo(0.3);
  }

  void _avatarSpeakingMode() {
    _voicePulseController.repeat();
    _avatarGlowController.repeat(reverse: true);
  }

  void _avatarReflectionMode() {
    _avatarRetreat();
    _avatarGlowController.animateTo(0.5);
  }

  void _avatarNeutralMode() {
    _avatarProximityController.reset();
    _avatarDepthController.animateTo(0.5);
    _voicePulseController.reset();
  }

  void _avatarExcitedMode() {
    _avatarProximityController.repeat(reverse: true);
    _avatarGlowController.repeat(reverse: true);
  }

  void _avatarHappyMode() {
    _avatarGlowController.animateTo(1.0);
    _avatarFloatingController.duration = const Duration(
      seconds: 4,
    ); // Plus rapide
  }

  void _avatarSurprisedMode() {
    _avatarProximityController.forward();
    _avatarDepthController.animateTo(0.8);
  }

  void _avatarSadMode() {
    _avatarGlowController.animateTo(0.2);
    _avatarFloatingController.duration = const Duration(
      seconds: 8,
    ); // Plus lent
  }

  void _avatarConfusedMode() {
    _avatarDepthController.repeat(reverse: true);
  }

  // Contrôles de l'univers spatial

  void _slowDownUniverse() {
    _starsController.duration = const Duration(minutes: 4);
    _nebulaController.duration = const Duration(minutes: 6);
  }

  void _accelerateUniverse() {
    _starsController.duration = const Duration(seconds: 90);
    _nebulaController.duration = const Duration(minutes: 2);
  }

  void _normalUniverse() {
    _starsController.duration = const Duration(minutes: 2);
    _nebulaController.duration = const Duration(minutes: 3);
  }

  void _dimUniverse() {
    // Implémenter l'assombrissement
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceSessionManagerProvider);
    final emotionalState = ref.watch(emotionalAvatarServiceProvider);

    // Réagir aux changements d'état
    ref.listen<VoiceSessionState>(voiceSessionManagerProvider, (
      previous,
      next,
    ) {
      _onVoiceStateChanged(next);
    });

    ref.listen<EmotionalAvatarState>(emotionalAvatarServiceProvider, (
      previous,
      next,
    ) {
      _onEmotionChanged(next);
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fond spatial animé
          _buildSpaceBackground(),

          // Nébuleuses
          _buildNebulae(),

          // Étoiles
          _buildStarField(),

          // Poussière cosmique
          _buildCosmicDust(),

          // Avatar 3D centré avec effets de profondeur
          _buildFloatingAvatar(emotionalState),

          // Effets de lumière et halos
          _buildLightEffects(),

          // Interface overlay (minimal)
          _buildInterfaceOverlay(voiceState),
        ],
      ),
    );
  }

  Widget _buildSpaceBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_starsRotation, _nebulaFlow]),
      builder: (context, child) {
        return CustomPaint(
          painter: SpaceBackgroundPainter(
            starsRotation: _starsRotation.value,
            nebulaFlow: _nebulaFlow.value,
            stars: _stars,
            nebulaParticles: _nebulaParticles,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildNebulae() {
    return AnimatedBuilder(
      animation: _nebulaFlow,
      builder: (context, child) {
        return CustomPaint(
          painter: NebulaePainter(
            animationValue: _nebulaFlow.value,
            particles: _nebulaParticles,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildStarField() {
    return AnimatedBuilder(
      animation: _starsRotation,
      builder: (context, child) {
        return CustomPaint(
          painter: StarFieldPainter(
            rotation: _starsRotation.value,
            stars: _stars,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildCosmicDust() {
    return AnimatedBuilder(
      animation: _cosmicDustDrift,
      builder: (context, child) {
        return CustomPaint(
          painter: CosmicDustPainter(
            driftValue: _cosmicDustDrift.value,
            particles: _cosmicDustParticles,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingAvatar(EmotionalAvatarState emotionalState) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _avatarFloat,
          _avatarProximity,
          _avatarDepth,
          _avatarGlow,
          _voicePulse,
        ]),
        builder: (context, child) {
          // Calculs de transformation 3D
          final floatOffset = _avatarFloat.value;
          final proximityScale = _avatarProximity.value;
          final depthOffset = _avatarDepth.value * 50;
          final glowIntensity = _avatarGlow.value;
          final voiceScale = _isSpeaking ? _voicePulse.value : 1.0;

          final totalScale = proximityScale * voiceScale;

          return Transform.translate(
            offset: Offset(floatOffset, floatOffset * 0.5),
            child: Transform.scale(
              scale: totalScale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Halo principal
                    BoxShadow(
                      color: emotionalState.currentColor.withOpacity(
                        glowIntensity * 0.3,
                      ),
                      blurRadius: 50 + depthOffset,
                      spreadRadius: 20 + depthOffset * 0.5,
                    ),
                    // Halo intérieur
                    BoxShadow(
                      color: emotionalState.currentColor.withOpacity(
                        glowIntensity * 0.6,
                      ),
                      blurRadius: 25 + depthOffset * 0.5,
                      spreadRadius: 10 + depthOffset * 0.3,
                    ),
                  ],
                ),
                child: AnimatedAvatar(
                  size: 200 + depthOffset,
                  enableGestures: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLightEffects() {
    return AnimatedBuilder(
      animation: _avatarGlow,
      builder: (context, child) {
        return CustomPaint(
          painter: LightEffectsPainter(
            glowIntensity: _avatarGlow.value,
            emotionalColor: _currentEmotion == EmotionalState.neutral
                ? Colors.blue
                : ref.read(emotionalAvatarServiceProvider).currentColor,
            isVoiceActive: _isSpeaking || _isListening,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildInterfaceOverlay(VoiceSessionState voiceState) {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: voiceState.status != VoiceSessionStatus.idle ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Text(
            _getStatusText(voiceState),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(VoiceSessionState voiceState) {
    switch (voiceState.status) {
      case VoiceSessionStatus.listening:
        return '👂 Ric vous écoute...';
      case VoiceSessionStatus.processing:
        return '🤔 Ric réfléchit...';
      case VoiceSessionStatus.speaking:
        return '🗣️ Ric vous répond...';
      case VoiceSessionStatus.error:
        return '❌ ${voiceState.errorMessage ?? "Erreur"}';
      default:
        return '✨ Dites "Salut Ric" pour commencer';
    }
  }

  @override
  void dispose() {
    _starsController.dispose();
    _nebulaController.dispose();
    _planetsController.dispose();
    _cosmicDustController.dispose();
    _avatarFloatingController.dispose();
    _avatarProximityController.dispose();
    _avatarDepthController.dispose();
    _avatarGlowController.dispose();
    _voicePulseController.dispose();
    super.dispose();
  }
}

// Modèles de données pour les éléments spatiaux

class Star {
  final double x, y;
  final double brightness;
  final double twinklePhase;
  final double distance;
  final double size;

  Star({
    required this.x,
    required this.y,
    required this.brightness,
    required this.twinklePhase,
    required this.distance,
    required this.size,
  });
}

class NebulaParticle {
  final double x, y;
  final Color color;
  final double size;
  final double opacity;
  final double flowSpeed;
  final double driftDirection;

  NebulaParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.opacity,
    required this.flowSpeed,
    required this.driftDirection,
  });
}

class CosmicDust {
  final double x, y;
  final double opacity;
  final double size;
  final double velocity;
  final double direction;

  CosmicDust({
    required this.x,
    required this.y,
    required this.opacity,
    required this.size,
    required this.velocity,
    required this.direction,
  });
}
