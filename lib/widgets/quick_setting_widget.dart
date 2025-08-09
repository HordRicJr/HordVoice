import 'package:flutter/material.dart';
import '../services/quick_settings_service.dart';
import '../services/home_widget_service.dart';

/// Widget pour tester et gérer les Quick Settings et Home Widgets
class QuickSettingWidget extends StatefulWidget {
  const QuickSettingWidget({super.key});

  @override
  State<QuickSettingWidget> createState() => _QuickSettingWidgetState();
}

class _QuickSettingWidgetState extends State<QuickSettingWidget> {
  final QuickSettingsService _quickSettingsService = QuickSettingsService();
  final HomeWidgetService _homeWidgetService = HomeWidgetService();

  bool _isListening = false;
  bool _quickSettingsReady = false;
  bool _homeWidgetReady = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Vérifier l'état des services
      await _quickSettingsService.initialize();
      setState(() {
        _quickSettingsReady = _quickSettingsService.isInitialized;
      });

      await _homeWidgetService.initialize();
      setState(() {
        _homeWidgetReady = _homeWidgetService.isInitialized;
        _isListening = _homeWidgetService.isListening;
      });

      debugPrint('Services Quick Settings et Widget initialisés');
    } catch (e) {
      debugPrint('Erreur initialisation services: $e');
    }
  }

  Future<void> _toggleListening() async {
    try {
      setState(() {
        _isListening = !_isListening;
      });

      // Mettre à jour Quick Settings
      await _quickSettingsService.updateQuickSettingsState(_isListening);

      // Mettre à jour Home Widget
      await _homeWidgetService.setListeningState(_isListening);

      debugPrint('État écoute mis à jour: $_isListening');
    } catch (e) {
      debugPrint('Erreur toggle listening: $e');
    }
  }

  Future<void> _testQuickSettings() async {
    try {
      final success = await _quickSettingsService.testQuickSettings();
      _showSnackBar(success ? 'Quick Settings OK' : 'Quick Settings KO');
    } catch (e) {
      _showSnackBar('Erreur Quick Settings: $e');
    }
  }

  Future<void> _testHomeWidget() async {
    try {
      final success = await _homeWidgetService.testWidget();
      _showSnackBar(success ? 'Home Widget OK' : 'Home Widget KO');
    } catch (e) {
      _showSnackBar('Erreur Home Widget: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Settings & Widgets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // État des services
            _buildServiceStatus(),
            const SizedBox(height: 16),

            // Contrôles principaux
            _buildMainControls(),
            const SizedBox(height: 16),

            // Tests
            _buildTestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des services:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusIndicator('Quick Settings', _quickSettingsReady),
            const SizedBox(width: 16),
            _buildStatusIndicator('Home Widget', _homeWidgetReady),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool isReady) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.error,
          color: isReady ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isReady ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contrôles:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _toggleListening,
            icon: Icon(_isListening ? Icons.mic : Icons.mic_off),
            label: Text(
              _isListening ? 'Désactiver Assistant' : 'Activer Assistant',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tests:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testQuickSettings,
                icon: const Icon(Icons.flash_on),
                label: const Text('Test QS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testHomeWidget,
                icon: const Icon(Icons.widgets),
                label: const Text('Test Widget'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
