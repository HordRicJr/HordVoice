import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget pour les paramètres rapides de HordVoice
class QuickSettingWidget extends StatefulWidget {
  const QuickSettingWidget({super.key});

  @override
  State<QuickSettingWidget> createState() => _QuickSettingWidgetState();
}

class _QuickSettingWidgetState extends State<QuickSettingWidget> {
  static const platform = MethodChannel('com.hordvoice/quick_settings');
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final result = await platform.invokeMethod('test');
      print('Quick Settings test: $result');
    } on PlatformException catch (e) {
      print("Failed to communicate with platform: '${e.message}'.");
    }
  }

  Future<void> _toggleListening() async {
    setState(() {
      _isListening = !_isListening;
    });

    try {
      await platform.invokeMethod('updateTileState', {
        'isListening': _isListening,
      });
    } on PlatformException catch (e) {
      print("Failed to update tile state: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HordVoice Quick Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_off,
              size: 100,
              color: _isListening ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? 'HordVoice Listening...' : 'HordVoice Stopped',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _toggleListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              child: Text(
                _isListening ? 'Stop Listening' : 'Start Listening',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickAction(
                          icon: Icons.volume_up,
                          label: 'Volume',
                          onTap: () => _handleQuickAction('volume'),
                        ),
                        _buildQuickAction(
                          icon: Icons.brightness_6,
                          label: 'Brightness',
                          onTap: () => _handleQuickAction('brightness'),
                        ),
                        _buildQuickAction(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => _handleQuickAction('settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleQuickAction(String action) async {
    try {
      await platform.invokeMethod('quickAction', {'action': action});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action action executed'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute $action: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
