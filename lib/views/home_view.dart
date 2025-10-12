import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../controllers/persistent_ai_controller.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/voice_management_service.dart';
import '../services/navigation_service.dart';
import '../widgets/spacial_avatar_view.dart';
import '../widgets/audio_waveform.dart';

/// Vue principale HordVoice avec design spatial intégré
/// Interface voice-first avec avatar 3D flottant dans l'univers spatial
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin {
  // Services
  late UnifiedHordVoiceService _unifiedService;
  late PersistentAIController _persistentController;
  late VoiceManagementService _voiceService;
  late NavigationService _navigationService;

  // Animation Controllers
  late AnimationController _spatialController;
  late AnimationController _waveController;
  late AnimationController _floatingController;
  late AnimationController _transitionController;

  // Animations
  late Animation<double> _spatialAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _fadeAnimation;

  // État
  bool _isListening = false;
  bool _isInitialized = false;
  String _statusText = "";
  String _currentResponse = "";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    // Animation spatiale principale pour l'avatar - ACCÉLÉRÉE
    _spatialController = AnimationController(
      duration: const Duration(milliseconds: 1200), // 4s -> 1.2s
      vsync: this,
    );

    // Animation de flottement continu - ACCÉLÉRÉE
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 3s -> 1.5s
      vsync: this,
    );

    // Animation des ondes audio - ACCÉLÉRÉE
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 400), // 800ms -> 400ms
      vsync: this,
    );

    // Animation de transition - ACCÉLÉRÉE
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600), // 1.5s -> 600ms
      vsync: this,
    );

    // Configuration des animations
    _spatialAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _spatialController,
        curve: Curves.easeOutCubic,
      ), // Curve plus rapide
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeOut),
    );

    // DÉMARRAGE AUTOMATIQUE IMMÉDIAT DES ANIMATIONS
    _floatingController.repeat(reverse: true);
    _spatialController.forward(); // Démarrer immédiatement
    _transitionController.forward(); // Démarrer immédiatement
  }

  Future<void> _initializeServices() async {
    try {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _statusText = l10n?.initializing ?? "Initializing HordVoice...";
      });

      // Démarrer immédiatement l'UI sans attendre
      setState(() {
        _isInitialized = true; // Marquer comme initialisé pour l'UI
        _statusText = l10n?.homeWelcome ?? "Welcome to HordVoice";
      });

      // Initialisation DIFFÉRÉE en arrière-plan
      _initializeServicesInBackground();
    } catch (e) {
      debugPrint('Erreur initialisation: $e');
      final l10n = AppLocalizations.of(context);
      setState(() {
        _statusText = l10n?.errorInitialization(e.toString()) ?? "Error during initialization: $e";
        _isInitialized = true;
      });
    }
  }

  /// Initialisation des services en arrière-plan pour ne pas bloquer l'UI
  Future<void> _initializeServicesInBackground() async {
    // Attendre 100ms pour laisser l'UI se dessiner
    await Future.delayed(Duration(milliseconds: 100));

    try {
      // Initialiser les services de base SANS ATTENDRE
      _unifiedService = UnifiedHordVoiceService();
      _voiceService = VoiceManagementService();
      _navigationService = NavigationService();

      // Initialisation PARALLÈLE et ROBUSTE avec timeouts ultra-courts
      final initFutures = <Future<void>>[];

      // Service unifié avec timeout court
      initFutures.add(
        _unifiedService
            .initialize()
            .timeout(
              Duration(seconds: 5), // Réduit de 10s à 5s
              onTimeout: () {
                debugPrint('Timeout UnifiedService - continuer sans');
              },
            )
            .catchError((e) {
              debugPrint('Erreur UnifiedService: $e - continuer');
            }),
      );

      // Service vocal avec timeout court
      initFutures.add(
        _voiceService
            .initialize()
            .timeout(
              Duration(seconds: 2), // Réduit de 5s à 2s
              onTimeout: () {
                debugPrint('Timeout VoiceService - continuer sans');
              },
            )
            .catchError((e) {
              debugPrint('Erreur VoiceService: $e - continuer');
            }),
      );

      // Service navigation avec timeout court
      initFutures.add(
        _navigationService
            .initialize()
            .timeout(
              Duration(seconds: 1), // Réduit de 3s à 1s
              onTimeout: () {
                debugPrint('Timeout NavigationService - mode fallback');
              },
            )
            .catchError((e) {
              debugPrint('Erreur NavigationService: $e - mode fallback');
            }),
      );

      // Attendre SEULEMENT 1 seconde max pour les services critiques
      try {
        await Future.wait(initFutures).timeout(
          Duration(seconds: 1), // Réduit drastiquement à 1s
          onTimeout: () {
            debugPrint('Timeout global initialisation - continuer quand même');
            return <void>[]; // Retourner liste vide
          },
        );
      } catch (e) {
        debugPrint('Erreur initialisation parallèle: $e - continuer');
      }

      // Initialiser IA persistante en arrière-plan
      _initializePersistentAIInBackground();

      debugPrint('🌌 Univers spatial HordVoice initialisé (mode robuste)');
    } catch (e) {
      debugPrint('❌ Erreur initialisation (continuons): $e');
    }
  }

  /// Initialise l'IA persistante en arrière-plan
  Future<void> _initializePersistentAIInBackground() async {
    // Attendre 500ms pour laisser l'UI se stabiliser
    await Future.delayed(Duration(milliseconds: 500));

    try {
      debugPrint('Initialisation PersistentAIController...');
      _persistentController = PersistentAIController();

      await _persistentController.initialize().timeout(
        Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Timeout PersistentController - mode dégradé');
        },
      );

      // Activer automatiquement seulement si succès
      await _enablePersistentAIAutomatically();

      if (mounted) {
        setState(() {
          _statusText = "Ric est connecté dans l'univers spatial";
        });
      }
    } catch (e) {
      debugPrint('PersistentController échoué: $e - continuer sans');
      if (mounted) {
        setState(() {
          _statusText = "Mode spatial disponible";
        });
      }
    }
  }

  /// Active automatiquement l'IA persistante de manière transparente
  Future<void> _enablePersistentAIAutomatically() async {
    try {
      debugPrint('🚀 Activation automatique de l\'IA persistante spatiale...');

      await _persistentController.enablePersistentAI(
        showWelcomeAnimation: false, // Plus discret dans l'univers spatial
      );

      debugPrint('✨ IA persistante spatiale activée automatiquement');
    } catch (e) {
      debugPrint('⚠️ Erreur activation automatique IA persistante: $e');
      // Ne pas bloquer l'initialisation si l'IA persistante échoue
    }
  }

  void _toggleListening() async {
    if (!_isInitialized) return;

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isListening = true;
        _statusText = l10n?.ricIsListening ?? "Ric is listening from the spatial universe...";
        _currentResponse = "";
      });

      _waveController.repeat();

      // Démarrer l'écoute avec le service unifié
      await _unifiedService.startListening();

      final response = await _unifiedService.processVoiceCommand(
        "start_listening",
      );

      setState(() {
        _currentResponse = response;
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isListening = false;
        _statusText = l10n?.spatialListeningError(e.toString()) ?? "Spatial listening error: ${e.toString()}";
      });
      _waveController.stop();
    }
  }

  Future<void> _stopListening() async {
    try {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _isListening = false;
        _statusText = l10n?.spatialProcessing ?? "Processing in spatial universe...";
      });

      _waveController.stop();
      await _unifiedService.stopListening();

      setState(() {
        _statusText = l10n?.listenHint ?? "Say 'Hey Ric' to start listening";
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _statusText = l10n?.stopError(e.toString()) ?? "Stop error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A), // Fond spatial plus profond
      body: Container(
        decoration: _buildSpatialBackground(),
        child: SafeArea(
          child: Stack(
            children: [
              // Étoiles et particules spatiales en arrière-plan
              _buildSpatialParticles(),

              // Interface principale
              Column(
                children: [
                  // Header spatial minimal
                  _buildSpatialHeader(),

                  // Avatar spatial principal centré
                  Expanded(child: _buildSpatialAvatarInterface()),

                  // Contrôles voice-first spatiaux
                  if (_isInitialized) _buildSpatialVoiceControls(),

                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Arrière-plan spatial avec dégradé et effet d'univers
  BoxDecoration _buildSpatialBackground() {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 1.5,
        colors: [
          Color(0xFF1A1A3A), // Centre plus clair
          Color(0xFF0D0D1F), // Bords plus sombres
          Color(0xFF050508), // Noir spatial
        ],
      ),
    );
  }

  /// Particules et étoiles flottantes dans l'univers spatial
  Widget _buildSpatialParticles() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: SpatialParticlesPainter(
              animationValue: _floatingAnimation.value,
              alpha: _fadeAnimation.value,
            ),
          ),
        );
      },
    );
  }

  /// Header spatial minimal et élégant
  Widget _buildSpatialHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo avec effet spatial
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF64B5F6),
                  Color(0xFF42A5F5),
                  Color(0xFF1976D2),
                ],
              ).createShader(bounds),
              child: Text(
                AppLocalizations.of(context)?.appTitle ?? 'HordVoice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),

            // Settings button
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: const Center(child: Text('Settings Page - Coming Soon')),
                  )),
                );
              },
            ),

            // Indicateur de connexion spatial
            AnimatedBuilder(
              animation: _spatialController,
              builder: (context, child) {
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _isInitialized
                        ? Color.lerp(
                            Colors.blue,
                            Colors.cyan,
                            _spatialController.value,
                          )
                        : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isInitialized ? Colors.cyan : Colors.orange)
                            .withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Interface principale avec avatar spatial 3D
  Widget _buildSpatialAvatarInterface() {
    return AnimatedBuilder(
      animation: Listenable.merge([_spatialAnimation, _floatingAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Transform.scale(
            scale: 0.3 + (_spatialAnimation.value * 0.7),
            child: Opacity(
              opacity: _spatialAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar spatial principal
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyan.withValues(alpha: 0.3),
                          Colors.blue.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.3),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child:
                        const SpacialAvatarView(), // Widget avatar spatial existant
                  ),

                  const SizedBox(height: 40),

                  // Ondes audio spatiales quand en écoute
                  if (_isListening)
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: AudioWaveform(isActive: _isListening),
                    ),

                  const SizedBox(height: 30),

                  // Status spatial avec effet holographique
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 20,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Réponse avec effet spatial si disponible
                  if (_currentResponse.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        _currentResponse,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Contrôles vocaux spatiaux - Interface voice-first pure
  Widget _buildSpatialVoiceControls() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Bouton principal d'écoute spatial
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _spatialController,
                _waveController,
              ]),
              builder: (context, child) {
                final pulseValue = _isListening
                    ? (1.0 + (_waveController.value * 0.2))
                    : 1.0;

                return Transform.scale(
                  scale: pulseValue,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: _isListening
                            ? [
                                Colors.red.withValues(alpha: 0.8),
                                Colors.red.withValues(alpha: 0.6),
                                Colors.red.withValues(alpha: 0.3),
                              ]
                            : [
                                Colors.cyan.withValues(alpha: 0.8),
                                Colors.blue.withValues(alpha: 0.6),
                                Colors.blue.withValues(alpha: 0.3),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.cyan)
                              .withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: _isListening ? 15 : 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // Instruction vocale spatiale
          Text(
            _isListening
                ? "🎙️ ${AppLocalizations.of(context)?.listeningInSpatial ?? 'Listening in the spatial universe...'}"
                : "🌌 ${AppLocalizations.of(context)?.listenHint ?? 'Say \'Hey Ric\' to start listening'}",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _waveController.dispose();
    _floatingController.dispose();
    _transitionController.dispose();
    super.dispose();
  }
}

/// Painter pour les particules et étoiles spatiales
class SpatialParticlesPainter extends CustomPainter {
  final double animationValue;
  final double alpha;

  SpatialParticlesPainter({required this.animationValue, required this.alpha});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * alpha)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.3 * alpha)
      ..style = PaintingStyle.fill;

    // Dessiner des étoiles animées
    for (int i = 0; i < 50; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 67.0) % size.height;
      final offset = animationValue * 2.0;

      final starX = (x + offset) % size.width;
      final starY = (y + offset * 0.5) % size.height;

      // Étoile principale
      canvas.drawCircle(Offset(starX, starY), 1.5, paint);

      // Effet de lueur pour certaines étoiles
      if (i % 7 == 0) {
        canvas.drawCircle(Offset(starX, starY), 4.0, glowPaint);
      }
    }

    // Dessiner des particules flottantes
    for (int i = 0; i < 20; i++) {
      final x = (i * 73.0) % size.width;
      final y = (i * 109.0) % size.height;
      final particleOffset = animationValue * 1.5;

      final particleX = (x + particleOffset) % size.width;
      final particleY = (y + particleOffset * 0.3) % size.height;

      paint.color = Colors.cyan.withValues(alpha: 0.4 * alpha);
      canvas.drawCircle(Offset(particleX, particleY), 2.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
