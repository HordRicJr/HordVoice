import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_onboarding_service.dart';
import '../widgets/animated_avatar.dart';

/// Vue d'onboarding vocal avec support visuel
class VoiceOnboardingView extends StatefulWidget {
  const VoiceOnboardingView({Key? key}) : super(key: key);

  @override
  State<VoiceOnboardingView> createState() => _VoiceOnboardingViewState();
}

class _VoiceOnboardingViewState extends State<VoiceOnboardingView>
    with TickerProviderStateMixin {
  late VoiceOnboardingService _onboardingService;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  String _currentStep = 'initializing';
  String _statusText = 'Initialisation...';
  double _progress = 0.0;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeOnboarding();
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  Future<void> _initializeOnboarding() async {
    try {
      _onboardingService = VoiceOnboardingService();
      await _onboardingService.initialize();

      setState(() {
        _statusText = 'Prêt pour l\'onboarding vocal';
        _currentStep = 'ready';
      });

      // Démarrer après 1 seconde
      await Future.delayed(const Duration(seconds: 1));
      await _startOnboarding();
    } catch (e) {
      setState(() {
        _statusText = 'Erreur d\'initialisation: $e';
        _currentStep = 'error';
      });
    }
  }

  Future<void> _startOnboarding() async {
    try {
      // Démarrer l'onboarding vocal
      await _onboardingService.startOnboarding();

      // Suivre la progression
      _trackOnboardingProgress();
    } catch (e) {
      setState(() {
        _statusText = 'Erreur onboarding: $e';
        _currentStep = 'error';
      });
    }
  }

  void _trackOnboardingProgress() {
    // Timer pour suivre l'état de l'onboarding
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentStep = _onboardingService.currentStep;
      if (currentStep != _currentStep) {
        setState(() {
          _currentStep = currentStep;
          _updateStatusForStep(currentStep);
        });
      }

      // Arrêter si terminé
      if (currentStep == 'completed' ||
          _onboardingService.onboardingData['completed'] == true) {
        timer.cancel();
        _completeOnboarding();
      }
    });
  }

  void _updateStatusForStep(String step) {
    switch (step) {
      case 'welcome_first':
        _statusText = 'Première configuration vocal';
        _progress = 0.1;
        _isListening = false;
        break;
      case 'welcome_returning':
        _statusText = 'Bienvenue !';
        _progress = 1.0;
        _isListening = false;
        break;
      case 'microphone_check':
        _statusText = 'Vérification du microphone';
        _progress = 0.25;
        _isListening = true;
        break;
      case 'voice_selection':
        _statusText = 'Sélection de ma voix';
        _progress = 0.5;
        _isListening = true;
        break;
      case 'personality_selection':
        _statusText = 'Choix de ma personnalité';
        _progress = 0.75;
        _isListening = true;
        break;
      case 'final_test':
        _statusText = 'Test final de configuration';
        _progress = 0.9;
        _isListening = true;
        break;
      default:
        _statusText = 'Configuration en cours...';
        _isListening = false;
    }

    _progressController.animateTo(_progress);
  }

  void _completeOnboarding() {
    setState(() {
      _statusText = 'Configuration terminée !';
      _progress = 1.0;
      _isListening = false;
    });

    _progressController.animateTo(1.0);

    // Retourner à l'écran principal après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  String _getStepDescription(String step) {
    switch (step) {
      case 'welcome_first':
        return 'Je me présente et explique le processus de configuration vocal.';
      case 'microphone_check':
        return 'Je vérifie les permissions microphone pour pouvoir vous écouter.';
      case 'voice_selection':
        return 'Nous choisissons ma voix ensemble. Écoutez les options et dites votre préférence.';
      case 'personality_selection':
        return 'Sélectionnez mon style de conversation : maternel, amical, ou professionnel.';
      case 'final_test':
        return 'Test final pour valider la configuration. Dites "Bonjour Ric" !';
      default:
        return 'Configuration vocal en cours...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 40),

              // Avatar principal
              _buildMainAvatar(),

              const SizedBox(height: 40),

              // Indicateur de progression
              _buildProgressIndicator(),

              const SizedBox(height: 24),

              // Status text
              _buildStatusText(),

              const SizedBox(height: 16),

              // Description de l'étape
              _buildStepDescription(),

              const Spacer(),

              // Indicateur d'écoute
              if (_isListening) _buildListeningIndicator(),

              const SizedBox(height: 20),

              // Boutons d'actions d'urgence
              _buildEmergencyActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Configuration Vocale',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HordVoice v2.0',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMainAvatar() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3498DB),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3498DB).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.1),
            child: const AnimatedAvatar(),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          'Progression',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressController.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_progress * 100).round()}% terminé',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Text(
        _statusText,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStepDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStepDescription(_currentStep),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white70,
          fontSize: 14,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1 + (_pulseController.value * 0.2)),
            border: Border.all(
              color: Colors.red.withOpacity(
                0.3 + (_pulseController.value * 0.4),
              ),
              width: 2,
            ),
          ),
          child: const Icon(Icons.mic, color: Colors.red, size: 30),
        );
      },
    );
  }

  Widget _buildEmergencyActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Redémarrer
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Redémarrer',
          onTap: () async {
            await _onboardingService.resetOnboarding();
            setState(() {
              _currentStep = 'initializing';
              _progress = 0.0;
            });
            await _initializeOnboarding();
          },
        ),

        // Passer
        _buildActionButton(
          icon: Icons.skip_next,
          label: 'Passer',
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),

        // Aide
        _buildActionButton(
          icon: Icons.help_outline,
          label: 'Aide',
          onTap: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: Text(
          'Aide Configuration Vocale',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette configuration se fait entièrement à la voix :',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '• Écoutez les instructions\n'
              '• Répondez à voix haute\n'
              '• Soyez patient entre les étapes\n'
              '• En cas de problème, utilisez "Redémarrer"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Compris',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF3498DB)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _onboardingService.dispose();
    super.dispose();
  }
}
