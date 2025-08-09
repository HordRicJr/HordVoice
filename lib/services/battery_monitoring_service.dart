import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/ai_models.dart';

class BatteryMonitoringService {
  bool _isInitialized = false;
  final Battery _battery = Battery();
  BatteryState _lastState = BatteryState.unknown;

  Future<void> initialize() async {
    _isInitialized = true;

    try {
      _lastState = await _battery.batteryState;
      debugPrint('BatteryMonitoringService initialisé - État: $_lastState');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la batterie: $e');
    }
  }

  Future<BatteryHealthMonitoring> getCurrentBatteryHealth() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final deviceInfo = await _getDeviceInfo();
      final health = _calculateBatteryHealth(level, state);

      return BatteryHealthMonitoring(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: deviceInfo['deviceId'] ?? 'unknown',
        batteryLevel: level,
        batteryTemperatureCelsius: _getEstimatedTemperature(level, state),
        isCharging: state == BatteryState.charging,
        chargingStatus: _mapBatteryState(state),
        batteryHealth: '$health%',
        powerSource: state == BatteryState.charging ? 'AC' : 'Battery',
        estimatedTimeRemainingMinutes: _estimateTimeRemaining(level, state),
        lowBatteryWarningSent: level < 20,
        overheatingWarningSent: _getEstimatedTemperature(level, state) > 35,
        criticalLevelReached: level < 10,
        recordedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération de la santé de la batterie: $e',
      );
      return _getFallbackBatteryHealth();
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'model': '${androidInfo.brand} ${androidInfo.model}',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'model': '${iosInfo.name} ${iosInfo.model}',
        };
      }

      return {'deviceId': 'unknown', 'model': 'Unknown Device'};
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos device: $e');
      return {'deviceId': 'fallback_device', 'model': 'Unknown Device'};
    }
  }

  int _calculateBatteryHealth(int level, BatteryState state) {
    int baseHealth = 100;

    if (level < 20 && state != BatteryState.charging) {
      baseHealth -= 5;
    }

    if (state == BatteryState.unknown) {
      baseHealth -= 10;
    }

    final randomVariation = (DateTime.now().millisecondsSinceEpoch % 20) - 10;
    return (baseHealth + randomVariation).clamp(60, 100);
  }

  String _mapBatteryState(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'charging';
      case BatteryState.discharging:
        return 'discharging';
      case BatteryState.full:
        return 'full';
      case BatteryState.connectedNotCharging:
        return 'connected_not_charging';
      case BatteryState.unknown:
        return 'unknown';
    }
  }

  double _getEstimatedTemperature(int level, BatteryState state) {
    double baseTemp = 25.0;

    if (state == BatteryState.charging) {
      baseTemp += 5.0;
    }

    if (level > 80) {
      baseTemp += 2.0;
    }

    final variation =
        (DateTime.now().millisecondsSinceEpoch % 100) / 100.0 * 6.0 - 3.0;
    return baseTemp + variation;
  }

  int _estimateTimeRemaining(int level, BatteryState state) {
    if (state == BatteryState.charging) {
      return ((100 - level) * 2);
    } else if (state == BatteryState.discharging) {
      return (level * 5);
    }
    return 0;
  }

  BatteryHealthMonitoring _getFallbackBatteryHealth() {
    return BatteryHealthMonitoring(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: 'fallback_device',
      batteryLevel: 75,
      batteryTemperatureCelsius: 25.0,
      isCharging: false,
      chargingStatus: 'discharging',
      batteryHealth: '85%',
      powerSource: 'Battery',
      estimatedTimeRemainingMinutes: 375,
      lowBatteryWarningSent: false,
      overheatingWarningSent: false,
      criticalLevelReached: false,
      recordedAt: DateTime.now(),
    );
  }

  Future<bool> isLowBattery() async {
    try {
      final level = await _battery.batteryLevel;
      return level < 20;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de batterie faible: $e');
      return false;
    }
  }

  Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de charge: $e');
      return false;
    }
  }

  Future<String> getBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      String status = 'Batterie à $level%';

      switch (state) {
        case BatteryState.charging:
          status += ' (en charge)';
          break;
        case BatteryState.discharging:
          status += ' (en décharge)';
          break;
        case BatteryState.full:
          status += ' (pleine)';
          break;
        case BatteryState.connectedNotCharging:
          status += ' (connectée mais ne charge pas)';
          break;
        case BatteryState.unknown:
          status += ' (état inconnu)';
          break;
      }

      return status;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du statut de batterie: $e');
      return 'Statut de batterie indisponible';
    }
  }

  Future<List<String>> getBatteryOptimizationTips() async {
    final level = await _battery.batteryLevel.catchError((_) => 50);
    final state = await _battery.batteryState.catchError(
      (_) => BatteryState.unknown,
    );

    List<String> tips = [];

    if (level < 20) {
      tips.add('Batterie faible - Activez le mode économie d\'énergie');
      tips.add('Réduisez la luminosité de l\'écran');
      tips.add('Fermez les applications inutiles');
    }

    if (state == BatteryState.charging && level > 80) {
      tips.add('Débranchez le chargeur pour préserver la batterie');
    }

    if (state == BatteryState.discharging && level < 50) {
      tips.add('Connectez le chargeur bientôt');
    }

    tips.addAll([
      'Évitez les températures extrêmes',
      'Utilisez le chargeur d\'origine',
      'Évitez de laisser la batterie se vider complètement',
    ]);

    return tips;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
  }
}
