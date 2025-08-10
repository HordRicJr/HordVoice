import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/voice_management_service.dart';
import '../services/navigation_service.dart';
import '../widgets/animated_avatar.dart';
import '../widgets/audio_waveform.dart';
import '../views/permissions_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with TickerProviderStateMixin {
  late UnifiedHordVoiceService _unifiedService;
  late VoiceManagementService _voiceService;
  late NavigationService _navigationService;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  bool _isListening = false;
  bool _isInitialized = false;
  String _statusText = "Initialisation...";
  String _currentResponse = "";

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
  }

  void _initializeControllers() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusText = "Démarrage des services...";
      });

      _unifiedService = UnifiedHordVoiceService();
      _voiceService = VoiceManagementService();
      _navigationService = NavigationService();

      await _unifiedService.initialize();
      await _voiceService.initialize();
      await _navigationService.initialize();

      setState(() {
        _isInitialized = true;
        _statusText = "Prêt ! Dites 'Hey Ric' pour commencer";
      });

      _pulseController.repeat();

      // CORRECTION: Démarrer automatiquement l'onboarding vocal
      _startAutomaticOnboarding();

      debugPrint('HomeView services initialisés avec succès');
    } catch (e) {
      setState(() {
        _statusText = "Erreur d'initialisation: ${e.toString()}";
      });
      debugPrint('Erreur initialisation HomeView: $e');
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
      setState(() {
        _isListening = true;
        _statusText = "Je vous écoute...";
        _currentResponse = "";
      });

      _waveController.repeat();

      // Démarrer l'écoute avec le service unifié
      final response = await _unifiedService.processVoiceCommand(
        "start_listening",
      );

      setState(() {
        _currentResponse = response;
      });
    } catch (e) {
      setState(() {
        _isListening = false;
        _statusText = "Erreur d'écoute: ${e.toString()}";
      });
      _waveController.stop();
    }
  }

  Future<void> _stopListening() async {
    try {
      setState(() {
        _isListening = false;
        _statusText = "Traitement...";
      });

      _waveController.stop();

      // Arrêter l'écoute
      await _unifiedService.stopListening();

      setState(() {
        _statusText = "Prêt ! Dites 'Hey Ric' pour commencer";
      });
    } catch (e) {
      setState(() {
        _statusText = "Erreur d'arrêt: ${e.toString()}";
      });
    }
  }

  Future<void> _sendTestCommand(String command) async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _statusText = "Traitement de la commande...";
      });

      final response = await _unifiedService.processVoiceCommand(command);

      setState(() {
        _currentResponse = response;
        _statusText = "Commande traitée";
      });

      // Revenir au statut normal après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusText = "Prêt ! Dites 'Hey Ric' pour commencer";
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusText = "Erreur commande: ${e.toString()}";
      });
    }
  }

  /// Démarre automatiquement l'onboarding vocal sans interface utilisateur
  void _startAutomaticOnboarding() async {
    try {
      // Attendre un délai pour que l'utilisateur voie l'interface
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _statusText = "HordVoice vous écoute - Parlez maintenant";
        });

        // Démarrer l'écoute automatiquement pour l'onboarding
        _startListening();

        debugPrint('Onboarding automatique démarré');
      }
    } catch (e) {
      debugPrint('Erreur onboarding automatique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header simplifié
            _buildSimpleHeader(),

            // Avatar principal centré - Interface Voice-First
            Expanded(child: _buildVoiceFirstInterface()),

            // Contrôles vocaux essentiels uniquement
            if (_isInitialized) _buildVoiceControls(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Header simplifié pour interface voice-first
  Widget _buildSimpleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'HordVoice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isInitialized ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Interface voice-first centrée sur l'avatar
  Widget _buildVoiceFirstInterface() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar principal animé - centre de l'interface
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.08),
              child: Container(
                width: 220,
                height: 220,
                child: const AnimatedAvatar(),
              ),
            );
          },
        ),

        const SizedBox(height: 40),

        // Waveform quand en écoute
        if (_isListening)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AudioWaveform(isActive: _isListening),
          ),

        const SizedBox(height: 30),

        // Status vocal centré
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Text(
            _statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Réponse si disponible
        if (_currentResponse.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            ),
            child: Text(
              _currentResponse,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  /// Contrôles vocaux essentiels
  Widget _buildVoiceControls() {
    return Column(
      children: [
        // Bouton principal d'écoute - Plus grand et centré
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isListening ? Colors.red : Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.red : Colors.green).withOpacity(
                    0.5,
                  ),
                  blurRadius: 25,
                  spreadRadius: _isListening ? 10 : 5,
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Contrôles secondaires simplifiés - Vocal uniquement
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildVoiceButton(
              icon: Icons.record_voice_over,
              label: 'Voix',
              onTap: () => _sendTestCommand('changer voix'),
            ),
            _buildVoiceButton(
              icon: Icons.settings,
              label: 'Config',
              onTap: () => _sendTestCommand('paramètres'),
            ),
            _buildVoiceButton(
              icon: Icons.security,
              label: 'Accès',
              onTap: _showPermissions,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissions() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PermissionsView()));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}
