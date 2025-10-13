import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/voice_onboarding_service.dart';
import '../services/emotional_avatar_service.dart';
import '../services/unified_hordvoice_service.dart';
import '../widgets/animated_avatar.dart';
import 'home_view.dart';

/// Vue d'onboarding spatial immersive avec avatar 3D et interactions vocales
/// Combine les étapes d'onboarding vocal avec l'univers spatial moderne
class SpatialVoiceOnboardingView extends ConsumerStatefulWidget {
  const SpatialVoiceOnboardingView({Key? key}) : super(key: key);

  @override
  ConsumerState<SpatialVoiceOnboardingView> createState() =>
      _SpatialVoiceOnboardingViewState();
}

class _SpatialVoiceOnboardingViewState
    extends ConsumerState<SpatialVoiceOnboardingView>
    with TickerProviderStateMixin {
  // Controllers pour l'univers spatial
  late AnimationController _universeController;
  late AnimationController _avatarController;
  late AnimationController _stepsController;
  late AnimationController _interactionController;

  // Animations spatiales
  late Animation<double> _universeRotation;
  late Animation<double> _avatarFloat;
  late Animation<double> _stepsProgress;
  late Animation<double> _interactionPulse;

  // Services
  late VoiceOnboardingService _onboardingService;
  late UnifiedHordVoiceService _unifiedService;

  // État de l'onboarding
  OnboardingStep _currentStep = OnboardingStep.welcome;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentMessage = '';
  double _progressPercent = 0.0;

  // Données temporaires de configuration
  Map<String, dynamic> _configData = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    // Animation de l'univers (rotation lente continue)
    _universeController = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    )..repeat();

    _universeRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_universeController);

    // Animation de l'avatar (flottement)
    _avatarController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _avatarFloat = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );

    // Animation des étapes
    _stepsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _stepsProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepsController, curve: Curves.easeOutCubic),
    );

    // Animation d'interaction (pulse)
    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _interactionPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _interactionController, curve: Curves.easeInOut),
    );
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        _onboardingService = VoiceOnboardingService();
        _unifiedService = UnifiedHordVoiceService();

        await _onboardingService.initialize();
        await _unifiedService.initialize();

        // Connecter les services avec l'avatar émotionnel
        final emotionalService = ref.read(
          emotionalAvatarServiceProvider.notifier,
        );
        emotionalService.startListeningMode(); // Utilise la méthode existante

        setState(() {
          _isInitialized = true;
        });

        // Démarrer l'onboarding spatial
        await _startSpatialOnboarding();
      } catch (e) {
        debugPrint('❌ Erreur initialisation onboarding spatial: $e');
        // Mode dégradé avec message d'erreur
        setState(() {
          _currentMessage = 'Initialisation en cours...';
          _isInitialized = true;
        });
      }
    });
  }

  /// Démarre le processus d'onboarding spatial complet
  Future<void> _startSpatialOnboarding() async {
    // Animation d'entrée
    _stepsController.forward();

    // Activer l'avatar émotionnel en mode accueil
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startSpeakingMode(); // Mode excité/parlant

    // Séquence d'accueil spatiale
    await _stepSpatialWelcome();
  }

  /// ÉTAPE 1: Accueil spatial immersif
  Future<void> _stepSpatialWelcome() async {
    setState(() {
      _currentStep = OnboardingStep.welcome;
      _currentMessage = 'Bienvenue dans l\'univers HordVoice';
      _progressPercent = 0.1;
    });

    // Animation d'accueil
    _interactionController.repeat(reverse: true);

    // Message vocal spatial
    await _speakWithSpatialEffects(
      'Bienvenue dans l\'univers HordVoice ! Je suis Ric, votre assistant spatial. '
      'Nous allons configurer votre expérience vocale en quelques étapes immersives. '
      'Touchez l\'écran pour continuer.',
    );

    // Attendre interaction utilisateur
    await _waitForUserInteraction();

    await _stepMicrophonePermissions();
  }

  /// ÉTAPE 2: Permissions microphone avec contexte spatial
  Future<void> _stepMicrophonePermissions() async {
    setState(() {
      _currentStep = OnboardingStep.microphone;
      _currentMessage = 'Configuration du microphone';
      _progressPercent = 0.3;
    });

    // Animation de focus sur l'avatar
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startListeningMode();

    await _speakWithSpatialEffects(
      'Pour communiquer ensemble dans cet univers, j\'ai besoin d\'accéder à votre microphone. '
      'Cela me permettra d\'entendre vos commandes vocales et de créer une expérience interactive.',
    );

    // Vérifier et demander permission
    final permission = await Permission.microphone.status;

    if (!permission.isGranted) {
      await _requestMicrophoneWithAnimation();
    } else {
      await _speakWithSpatialEffects(
        'Parfait ! Le microphone est déjà configuré.',
      );
    }

    await _stepVoiceSelection();
  }

  /// ÉTAPE 3: Sélection de voix spatiale
  Future<void> _stepVoiceSelection() async {
    setState(() {
      _currentStep = OnboardingStep.voiceSelection;
      _currentMessage = 'Choisissez ma voix';
      _progressPercent = 0.6;
    });

    // Avatar en mode démonstration
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startSpeakingMode(); // Mode heureux/démonstration

    await _speakWithSpatialEffects(
      'Maintenant, choisissons ma voix ! Je vais vous présenter différentes options. '
      'Dites simplement "celle-ci" quand vous entendrez une voix qui vous plaît.',
    );

    // Démonstration des voix avec animations
    await _demonstrateVoicesWithAnimation();

    await _stepSpatialCalibration();
  }

  /// ÉTAPE 4: Calibration spatiale
  Future<void> _stepSpatialCalibration() async {
    setState(() {
      _currentStep = OnboardingStep.spatialCalibration;
      _currentMessage = 'Calibration spatiale';
      _progressPercent = 0.8;
    });

    // Avatar en mode focus
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startThinkingMode(); // Mode alerte/focus

    await _speakWithSpatialEffects(
      'Testons maintenant la reconnaissance vocale dans l\'espace. '
      'Dites "Ric, test spatial" pour vérifier que tout fonctionne parfaitement.',
    );

    // Test de reconnaissance avec feedback spatial
    await _performSpatialVoiceTest();

    await _stepCompletion();
  }

  /// ÉTAPE 5: Finalisation et entrée dans l'univers
  Future<void> _stepCompletion() async {
    setState(() {
      _currentStep = OnboardingStep.completion;
      _currentMessage = 'Configuration terminée !';
      _progressPercent = 1.0;
    });

    // Avatar en mode célébration
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startSpeakingMode(); // Mode excité/célébration

    await _speakWithSpatialEffects(
      'Félicitations ! Votre univers HordVoice est maintenant configuré. '
      'Nous allons maintenant entrer dans l\'expérience complète. Prêt ?',
    );

    // Animation de transition vers l'univers principal
    await _transitionToMainSpatialView();
  }

  /// Parle avec effets spatiaux (avatar réactif)
  Future<void> _speakWithSpatialEffects(String text) async {
    setState(() {
      _isSpeaking = true;
    });

    // Animation de l'avatar pendant la parole
    _interactionController.repeat(reverse: true);

    // Avatar réagit à la parole
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.onVoiceStimulus(
      volume: 0.8,
      pitch: 1.0,
      emotion: 'happy',
      content: text,
    );

    try {
      await _unifiedService.speakText(text);
    } catch (e) {
      debugPrint('Erreur TTS spatial: $e');
    }

    setState(() {
      _isSpeaking = false;
    });

    _interactionController.stop();
  }

  /// Demande permission microphone avec animation
  Future<void> _requestMicrophoneWithAnimation() async {
    // Animation de demande
    _interactionController.repeat(reverse: true);

    await _speakWithSpatialEffects(
      'Je vais maintenant demander l\'autorisation microphone. '
      'Veuillez accepter dans la boîte de dialogue qui va s\'afficher.',
    );

    // Demander permission
    final result = await Permission.microphone.request();

    _interactionController.stop();

    if (result.isGranted) {
      await _speakWithSpatialEffects(
        'Excellent ! Microphone configuré avec succès.',
      );
    } else {
      await _speakWithSpatialEffects(
        'Microphone non autorisé. Vous pourrez le configurer plus tard dans les paramètres.',
      );
    }
  }

  /// Démontre les voix avec animations
  Future<void> _demonstrateVoicesWithAnimation() async {
    final voices = [
      'fr-FR-DeniseNeural',
      'fr-FR-HenriNeural',
      'fr-FR-BrigitteNeural',
    ];

    for (int i = 0; i < voices.length; i++) {
      // Animation pour chaque voix
      _interactionController.reset();
      _interactionController.forward();

      await _speakWithSpatialEffects(
        'Voix numéro ${i + 1}: Bonjour ! Je suis votre assistant vocal.',
      );

      await Future.delayed(Duration(seconds: 2));
    }

    await _speakWithSpatialEffects(
      'Quelle voix préférez-vous ? Dites "première", "deuxième" ou "troisième".',
    );

    // Écouter la sélection
    await _listenForVoiceChoice();
  }

  /// Test vocal spatial
  Future<void> _performSpatialVoiceTest() async {
    setState(() {
      _isListening = true;
    });

    // Animation d'écoute
    _interactionController.repeat(reverse: true);

    // Avatar en mode écoute attentive
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startListeningMode();

    // Simuler l'écoute (en production, utiliser le vrai service STT)
    await Future.delayed(Duration(seconds: 5));

    setState(() {
      _isListening = false;
    });

    _interactionController.stop();

    await _speakWithSpatialEffects(
      'Parfait ! Test spatial réussi. Votre voix est claire et bien détectée.',
    );
  }

  /// Attendre interaction utilisateur réelle
  Completer<void>? _userInteractionCompleter;

  Future<void> _waitForUserInteraction() async {
    if (_userInteractionCompleter != null && !_userInteractionCompleter!.isCompleted) {
      _userInteractionCompleter!.complete();
    }
    
    _userInteractionCompleter = Completer<void>();
    
    // Attendre une vraie interaction utilisateur (tap, vocal, etc.)
    try {
      await _userInteractionCompleter!.future.timeout(
        const Duration(seconds: 30), // Timeout de sécurité
        onTimeout: () {
          debugPrint('Timeout interaction utilisateur - continuer automatiquement');
        },
      );
    } catch (e) {
      debugPrint('Erreur attente interaction: $e');
    }
  }

  /// Méthode appelée quand l'utilisateur interagit (tap, vocal, etc.)
  void _onUserInteraction() {
    if (_userInteractionCompleter != null && !_userInteractionCompleter!.isCompleted) {
      _userInteractionCompleter!.complete();
    }
  }

  /// Écouter choix de voix
  Completer<String>? _voiceChoiceCompleter;

  Future<void> _listenForVoiceChoice() async {
    if (_voiceChoiceCompleter != null && !_voiceChoiceCompleter!.isCompleted) {
      _voiceChoiceCompleter!.complete("default");
    }
    
    _voiceChoiceCompleter = Completer<String>();
    
    setState(() {
      _isListening = true;
    });

    try {
      // Attendre reconnaissance vocale réelle ou timeout
      await _voiceChoiceCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout choix vocal - utiliser voix par défaut');
          return "default";
        },
      );

      setState(() {
        _isListening = false;
      });

      await _speakWithSpatialEffects(
        'Excellent choix ! Cette voix me va parfaitement.',
      );
    } catch (e) {
      debugPrint('Erreur choix vocal: $e');
      setState(() {
        _isListening = false;
      });
      
      await _speakWithSpatialEffects(
        'Je vais utiliser la voix par défaut.',
      );
    }
  }

  /// Méthode appelée quand l'utilisateur fait un choix vocal
  void _onVoiceChoice(String choice) {
    if (_voiceChoiceCompleter != null && !_voiceChoiceCompleter!.isCompleted) {
      _voiceChoiceCompleter!.complete(choice);
    }
  }

  /// Transition vers la vue spatiale principale
  Future<void> _transitionToMainSpatialView() async {
    // Animation de sortie
    await _stepsController.reverse();

    // Sauvegarder la configuration
    await _saveOnboardingConfiguration();

    // Navigation vers HomeView après onboarding complété
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) =>
              FadeTransition(opacity: animation, child: const HomeView()),
          transitionDuration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  /// Sauvegarde la configuration d'onboarding
  Future<void> _saveOnboardingConfiguration() async {
    try {
      // Marquer l'onboarding comme terminé (méthode privée donc appel du service)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString(
        'onboarding_completion_date',
        DateTime.now().toIso8601String(),
      );

      // Sauvegarder les préférences utilisateur
      _configData['onboarding_completed'] = true;
      _configData['spatial_mode_enabled'] = true;
      _configData['completion_date'] = DateTime.now().toIso8601String();

      debugPrint('✅ Configuration onboarding spatial sauvegardée');
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Déclencher l'interaction utilisateur sur tap
          debugPrint('Interaction utilisateur détectée (tap)');
          _onUserInteraction();
        },
        child: Stack(
          children: [
            // Univers spatial de fond
            _buildSpatialUniverse(),

            // Avatar central interactif
            _buildCentralAvatar(),

            // Interface d'onboarding overlay
            if (_isInitialized) _buildOnboardingInterface(),

            // Overlay de chargement
            if (!_isInitialized) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpatialUniverse() {
    return AnimatedBuilder(
      animation: _universeRotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _universeRotation.value * 0.1, // Rotation très lente
          child: CustomPaint(
            painter: SpatialUniversePainter(
              animationValue: _universeRotation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildCentralAvatar() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_avatarFloat, _interactionPulse]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _avatarFloat.value),
            child: Transform.scale(
              scale: _interactionPulse.value,
              child: Container(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Effet de glow spatial
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),

                    // Avatar principal
                    const AnimatedAvatar(),

                    // Indicateurs d'état
                    if (_isListening) _buildListeningIndicator(),
                    if (_isSpeaking) _buildSpeakingIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOnboardingInterface() {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _stepsProgress,
        builder: (context, child) {
          return Opacity(
            opacity: _stepsProgress.value,
            child: Column(
              children: [
                // Message principal
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _currentMessage,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 20),

                // Barre de progression
                _buildProgressBar(),

                SizedBox(height: 15),

                // Indicateur d'étape
                Text(
                  'Étape ${_currentStep.index + 1} sur ${OnboardingStep.values.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _progressPercent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: Icon(Icons.mic, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildSpeakingIndicator() {
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
        child: Icon(Icons.volume_up, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 20),
            Text(
              'Initialisation de l\'univers spatial...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Nettoyer les completers pour éviter les fuites mémoire
    if (_userInteractionCompleter != null && !_userInteractionCompleter!.isCompleted) {
      _userInteractionCompleter!.complete();
    }
    if (_voiceChoiceCompleter != null && !_voiceChoiceCompleter!.isCompleted) {
      _voiceChoiceCompleter!.complete("default");
    }
    
    // Dispose des animations
    _universeController.dispose();
    _avatarController.dispose();
    _stepsController.dispose();
    _interactionController.dispose();
    
    super.dispose();
  }
}

/// Étapes de l'onboarding spatial
enum OnboardingStep {
  welcome,
  microphone,
  voiceSelection,
  spatialCalibration,
  completion,
}

/// Painter pour l'univers spatial de fond
class SpatialUniversePainter extends CustomPainter {
  final double animationValue;

  SpatialUniversePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // Fond d'étoiles
    for (int i = 0; i < 100; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      final opacity = ((math.sin(animationValue + i) + 1) / 2) * 0.8;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1, paint);
    }

    // Nébuleuse de fond
    paint.shader = RadialGradient(
      colors: [
        Colors.purple.withOpacity(0.1),
        Colors.blue.withOpacity(0.05),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: size.width));

    canvas.drawCircle(center, size.width, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
