import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/spacial_avatar_view.dart';
import '../services/voice_session_manager.dart';
import '../services/emotional_avatar_service.dart';

/// Vue principale avec avatar spatial 3D flottant
/// Remplace l'interface d'onboarding basique par un univers spatial immersif
class MainSpatialView extends ConsumerStatefulWidget {
  const MainSpatialView({Key? key}) : super(key: key);

  @override
  ConsumerState<MainSpatialView> createState() => _MainSpatialViewState();
}

class _MainSpatialViewState extends ConsumerState<MainSpatialView>
    with TickerProviderStateMixin {
  bool _isInitialized = false;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTransition();
    _initializeServices();
  }

  void _initializeTransition() {
    _transitionController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialiser les services
      final voiceManager = ref.read(voiceSessionManagerProvider.notifier);
      final emotionalService = ref.read(
        emotionalAvatarServiceProvider.notifier,
      );

      // Connecter les services
      voiceManager.connectEmotionalService(emotionalService);

      // Démarrer le processus d'entrée spatial
      await _performSpatialEntry();

      setState(() {
        _isInitialized = true;
      });
    });
  }

  Future<void> _performSpatialEntry() async {
    // Animation d'entrée dans l'univers spatial
    debugPrint('🌌 Entrée dans l\'univers spatial...');

    // Démarrer l'animation de fondu
    _transitionController.forward();

    // Attendre que l'animation soit visible
    await Future.delayed(const Duration(milliseconds: 1500));

    // Activer l'avatar émotionnel
    final emotionalService = ref.read(emotionalAvatarServiceProvider.notifier);
    emotionalService.startListeningMode();

    debugPrint('✨ Avatar spatial activé et prêt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Vue spatiale principale
              Opacity(
                opacity: _fadeAnimation.value,
                child: const SpacialAvatarView(),
              ),

              // Overlay d'initialisation
              if (!_isInitialized) _buildInitializationOverlay(),

              // Instructions d'aide (optionnelles)
              if (_isInitialized) _buildHelpOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInitializationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur de chargement spatial
            _buildSpatialLoader(),
            const SizedBox(height: 30),
            Text(
              'Initialisation de l\'univers spatial...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ric se prépare à vous accueillir',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpatialLoader() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildHelpOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: 0.7,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Touchez l\'avatar pour interagir • Dites "Salut Ric" pour parler',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }
}
