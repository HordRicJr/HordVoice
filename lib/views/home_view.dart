import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/voice_management_service.dart';
import '../services/navigation_service.dart';
import '../widgets/animated_avatar.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/voice_selector.dart';
import '../widgets/quick_setting_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Avatar principal avec status
            Expanded(flex: 4, child: _buildMainSection()),

            // Zone de réponse
            if (_currentResponse.isNotEmpty) _buildResponseSection(),

            // Contrôles principaux
            _buildMainControls(),

            // Contrôles secondaires
            _buildSecondaryControls(),

            // Quick Settings et Widget
            const QuickSettingWidget(),

            // Bouton Permissions
            _buildPermissionsButton(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HordVoice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Assistant Vocal v2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Indicateur de statut
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isInitialized ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 15),
              IconButton(
                onPressed: _showSettings,
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar principal
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.05),
              child: Container(
                width: 180,
                height: 180,
                child: const AnimatedAvatar(),
              ),
            );
          },
        ),

        const SizedBox(height: 30),

        // Waveform si en écoute
        if (_isListening)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: AudioWaveform(isActive: _isListening),
          ),

        const SizedBox(height: 20),

        // Texte de statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Text(
            _statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Réponse:',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentResponse,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton principal d'écoute
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isListening ? Colors.red : Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : Colors.green)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: _isListening ? 8 : 5,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Voice selector
          _buildControlButton(
            icon: Icons.record_voice_over,
            label: 'Voix',
            color: Colors.blue,
            onTap: _showVoiceSelector,
          ),

          // Navigation
          _buildControlButton(
            icon: Icons.navigation,
            label: 'Navigation',
            color: Colors.purple,
            onTap: () => _sendTestCommand('navigation'),
          ),

          // Météo
          _buildControlButton(
            icon: Icons.wb_sunny,
            label: 'Météo',
            color: Colors.orange,
            onTap: () => _sendTestCommand('météo'),
          ),

          // News
          _buildControlButton(
            icon: Icons.newspaper,
            label: 'Actualités',
            color: Colors.teal,
            onTap: () => _sendTestCommand('actualités'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
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

  void _showVoiceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const VoiceSelector(),
    );
  }

  void _showSettings() {
    // TODO: Implémenter les paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Bouton pour accéder aux permissions
  Widget _buildPermissionsButton() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Icon(Icons.security, color: Theme.of(context).primaryColor),
        title: const Text('Gestion des Permissions'),
        subtitle: const Text('Configurer les accès et autorisations'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PermissionsView()),
          );
        },
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
