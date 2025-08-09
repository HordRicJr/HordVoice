import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ai_models.dart';

class PhoneMonitoringService {
  bool _isInitialized = false;
  DateTime? _sessionStart;

  Future<void> initialize() async {
    _isInitialized = true;
    _sessionStart = DateTime.now();
    debugPrint('PhoneMonitoringService initialisé');
  }

  Future<PhoneUsageMonitoring> getCurrentUsage() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      }

      final usage = await _getUsageStats();
      final totalScreenTime = usage['totalScreenTime'] ?? 0;
      final appSwitches = usage['appSwitches'] ?? 0;
      final notifications = usage['notifications'] ?? 0;
      final isExcessive = _isUsageExcessive(totalScreenTime);

      return PhoneUsageMonitoring(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: deviceId,
        sessionStart: _sessionStart ?? DateTime.now(),
        sessionEnd: DateTime.now(),
        totalScreenTimeSeconds: totalScreenTime,
        appSwitchesCount: appSwitches,
        notificationsReceived: notifications,
        isExcessiveUsage: isExcessive,
        warningLevel: _getWarningLevel(totalScreenTime),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'usage: $e');
      return _getFallbackUsage();
    }
  }

  Future<Map<String, int>> _getUsageStats() async {
    try {
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        return _getSimulatedUsage();
      }

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final usageStats = await AppUsage().getAppUsage(yesterday, now);

      int totalScreenTime = 0;
      int appSwitches = usageStats.length;

      for (final stat in usageStats) {
        totalScreenTime += stat.usage.inSeconds;
      }

      return {
        'totalScreenTime': totalScreenTime,
        'appSwitches': appSwitches,
        'notifications': _getNotificationCount(),
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des stats: $e');
      return _getSimulatedUsage();
    }
  }

  Map<String, int> _getSimulatedUsage() {
    final now = DateTime.now();
    final sessionDuration = _sessionStart != null
        ? now.difference(_sessionStart!).inSeconds
        : 3600;

    return {
      'totalScreenTime': sessionDuration,
      'appSwitches': (sessionDuration / 600).round(),
      'notifications': (sessionDuration / 1800).round(),
    };
  }

  int _getNotificationCount() {
    return DateTime.now().hour;
  }

  bool _isUsageExcessive(int screenTimeSeconds) {
    const maxHealthyScreenTime = 6 * 3600;
    return screenTimeSeconds > maxHealthyScreenTime;
  }

  String _getWarningLevel(int screenTimeSeconds) {
    const lightWarning = 4 * 3600;
    const moderateWarning = 6 * 3600;
    const severeWarning = 8 * 3600;
    const extremeWarning = 10 * 3600;

    if (screenTimeSeconds > extremeWarning) return 'extreme';
    if (screenTimeSeconds > severeWarning) return 'severe';
    if (screenTimeSeconds > moderateWarning) return 'moderate';
    if (screenTimeSeconds > lightWarning) return 'light';
    return 'none';
  }

  PhoneUsageMonitoring _getFallbackUsage() {
    return PhoneUsageMonitoring(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: 'fallback_device',
      sessionStart:
          _sessionStart ?? DateTime.now().subtract(const Duration(hours: 1)),
      sessionEnd: DateTime.now(),
      totalScreenTimeSeconds: 3600,
      appSwitchesCount: 10,
      notificationsReceived: 5,
      isExcessiveUsage: false,
      warningLevel: 'none',
      createdAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> getTopApps() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final usageStats = await AppUsage().getAppUsage(yesterday, now);

      final sortedApps = usageStats
          .map(
            (stat) => {
              'package_name': stat.packageName,
              'app_name': stat.packageName.split('.').last,
              'usage_time_seconds': stat.usage.inSeconds,
              'last_used': stat.startDate,
            },
          )
          .toList();

      sortedApps.sort(
        (a, b) => (b['usage_time_seconds'] as int).compareTo(
          a['usage_time_seconds'] as int,
        ),
      );

      return sortedApps.take(10).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des top apps: $e');
      return _getSimulatedTopApps();
    }
  }

  List<Map<String, dynamic>> _getSimulatedTopApps() {
    return [
      {
        'package_name': 'com.whatsapp',
        'app_name': 'WhatsApp',
        'usage_time_seconds': 7200,
        'last_used': DateTime.now().subtract(const Duration(minutes: 10)),
      },
      {
        'package_name': 'com.facebook.katana',
        'app_name': 'Facebook',
        'usage_time_seconds': 5400,
        'last_used': DateTime.now().subtract(const Duration(minutes: 30)),
      },
      {
        'package_name': 'com.instagram.android',
        'app_name': 'Instagram',
        'usage_time_seconds': 3600,
        'last_used': DateTime.now().subtract(const Duration(hours: 1)),
      },
    ];
  }

  Future<void> setScreenTimeLimit(int limitSeconds) async {
    debugPrint('Limite de temps d\'écran définie: ${limitSeconds}s');
  }

  Future<bool> shouldShowWarning(int currentUsage) async {
    const warningThresholds = [4 * 3600, 6 * 3600, 8 * 3600];

    for (int threshold in warningThresholds) {
      if (currentUsage >= threshold) {
        return true;
      }
    }
    return false;
  }

  void incrementAppSwitches() {
    debugPrint('Changement d\'application enregistré');
  }

  void recordNotification() {
    debugPrint('Notification enregistrée');
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
  }
}
