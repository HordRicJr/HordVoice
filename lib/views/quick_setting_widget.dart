import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/voice_controller.dart';

class QuickSettingWidget extends ConsumerWidget {
  const QuickSettingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthData = ref.watch(healthDataProvider);
    final weatherData = ref.watch(weatherDataProvider);
    final batteryStatus = ref.watch(batteryStatusProvider);
    final calendarEvents = ref.watch(calendarEventsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu rapide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Ligne de widgets d'information
          Row(
            children: [
              Expanded(child: _buildBatteryWidget(batteryStatus)),
              const SizedBox(width: 12),
              Expanded(child: _buildWeatherWidget(weatherData)),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildHealthWidget(healthData)),
              const SizedBox(width: 12),
              Expanded(child: _buildCalendarWidget(calendarEvents)),
            ],
          ),

          const SizedBox(height: 16),

          // Raccourcis d'actions
          _buildQuickActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildBatteryWidget(Map<String, dynamic>? batteryStatus) {
    final level = batteryStatus?['batteryLevel'] ?? 0;
    final isCharging = batteryStatus?['isCharging'] ?? false;

    return _buildInfoCard(
      icon: isCharging ? Icons.battery_charging_full : Icons.battery_std,
      title: 'Batterie',
      value: '$level%',
      color: level < 20
          ? Colors.red
          : (level < 50 ? Colors.orange : Colors.green),
    );
  }

  Widget _buildWeatherWidget(Map<String, dynamic>? weatherData) {
    final temp = weatherData?['temperature'] ?? '--';
    final condition = weatherData?['condition'] ?? 'Inconnue';

    return _buildInfoCard(
      icon: _getWeatherIcon(condition),
      title: 'Météo',
      value: '$temp°C',
      color: Colors.blue,
    );
  }

  Widget _buildHealthWidget(Map<String, dynamic>? healthData) {
    final steps = healthData?['steps'] ?? 0;

    return _buildInfoCard(
      icon: Icons.directions_walk,
      title: 'Pas',
      value: '$steps',
      color: steps >= 10000 ? Colors.green : Colors.orange,
    );
  }

  Widget _buildCalendarWidget(List<Map<String, dynamic>> events) {
    final count = events.length;

    return _buildInfoCard(
      icon: Icons.event,
      title: 'Événements',
      value: '$count',
      color: Colors.purple,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.phone,
              label: 'Appeler',
              onTap: () => _showCallDialog(context),
            ),
            _buildActionButton(
              icon: Icons.message,
              label: 'SMS',
              onTap: () => _showSMSDialog(context),
            ),
            _buildActionButton(
              icon: Icons.navigation,
              label: 'Navigation',
              onTap: () => _showNavigationDialog(context),
            ),
            _buildActionButton(
              icon: Icons.music_note,
              label: 'Musique',
              onTap: () => _showMusicDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleillé':
      case 'sunny':
        return Icons.wb_sunny;
      case 'nuageux':
      case 'cloudy':
        return Icons.cloud;
      case 'pluvieux':
      case 'rainy':
        return Icons.water_drop;
      case 'orageux':
      case 'stormy':
        return Icons.thunderstorm;
      default:
        return Icons.wb_cloudy;
    }
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Passer un appel', style: TextStyle(color: Colors.white)),
        content: Text(
          'Dites "Appeler [nom du contact]" pour passer un appel vocal',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showSMSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Envoyer un SMS', style: TextStyle(color: Colors.white)),
        content: Text(
          'Dites "Envoyer un message à [nom] : [message]" pour envoyer un SMS',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showNavigationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Navigation', style: TextStyle(color: Colors.white)),
        content: Text(
          'Dites "Aller à [destination]" pour démarrer la navigation',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showMusicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Contrôle musical', style: TextStyle(color: Colors.white)),
        content: Text(
          'Dites "Jouer [nom de la chanson]" ou "Mettre en pause" pour contrôler la musique',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }
}
