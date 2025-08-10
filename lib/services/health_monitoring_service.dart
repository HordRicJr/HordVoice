import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthMonitoringService {
  bool _isInitialized = false;
  Health? _health;
  List<HealthDataType> _healthDataTypes = [];

  Future<void> initialize() async {
    _isInitialized = true;
    _health = Health();

    // Types de données de santé compatibles Android et iOS
    _healthDataTypes = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.WEIGHT,
      HealthDataType.HEIGHT,
      HealthDataType.BODY_MASS_INDEX,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WATER,
    ];

    // Ajouter des types spécifiques selon la plateforme
    if (!kIsWeb) {
      try {
        // Types additionnels pour Android/iOS si disponibles
        _healthDataTypes.addAll([
          HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
          HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        ]);
      } catch (e) {
        debugPrint('Certains types de données santé non disponibles: $e');
      }
    }

    try {
      await _requestHealthPermissions();
      debugPrint('HealthMonitoringService initialisé');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du monitoring santé: $e');
    }
  }

  Future<void> _requestHealthPermissions() async {
    try {
      bool? hasPermissions = await _health?.hasPermissions(_healthDataTypes);
      if (hasPermissions == false) {
        hasPermissions = await _health?.requestAuthorization(_healthDataTypes);
      }

      if (hasPermissions == true) {
        debugPrint('Permissions de santé accordées');
      } else {
        debugPrint('Permissions de santé refusées');
      }
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions santé: $e');
    }
  }

  Future<Map<String, dynamic>> getHealthSummary() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final now = DateTime.now();

      final steps = await getStepsToday();
      final heartRate = await getLatestHeartRate();
      final calories = await getCaloriesToday();
      final sleepHours = await getSleepHours();
      final weight = await getWeight();

      return {
        'steps': steps,
        'heartRate': heartRate,
        'calories': calories,
        'sleepHours': sleepHours,
        'weight': weight,
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération du résumé santé: $e');
      return {
        'steps': 0,
        'heartRate': 0,
        'calories': 0,
        'sleepHours': 0,
        'weight': 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<int> getStepsToday() async {
    if (!_isInitialized) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        int totalSteps = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalSteps += (data.value as NumericHealthValue).numericValue
                .toInt();
          }
        }
        return totalSteps;
      }

      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des pas: $e');
      return 0;
    }
  }

  Future<double> getLatestHeartRate() async {
    if (!_isInitialized) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        final latestData = healthData.last;
        if (latestData.value is NumericHealthValue) {
          return (latestData.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }

      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du rythme cardiaque: $e');
      return 0;
    }
  }

  Future<double> getCaloriesToday() async {
    if (!_isInitialized) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        double totalCalories = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalCalories += (data.value as NumericHealthValue).numericValue
                .toDouble();
          }
        }
        return totalCalories;
      }

      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des calories: $e');
      return 0;
    }
  }

  Future<double> getSleepHours() async {
    if (!_isInitialized) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 1));

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_IN_BED],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        double totalSleepMinutes = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalSleepMinutes += (data.value as NumericHealthValue).numericValue
                .toDouble();
          }
        }
        return totalSleepMinutes / 60; // Convertir en heures
      }

      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du sommeil: $e');
      return 0;
    }
  }

  Future<double> getWaterIntake() async {
    if (!_isInitialized) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        double totalWater = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalWater += (data.value as NumericHealthValue).numericValue
                .toDouble();
          }
        }
        return totalWater;
      }

      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'hydratation: $e');
      return 0;
    }
  }

  Future<Map<String, double>?> getBloodPressure() async {
    if (!_isInitialized) return null;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final systolicData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
        startTime: startOfDay,
        endTime: now,
      );

      final diastolicData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        startTime: startOfDay,
        endTime: now,
      );

      double? systolic;
      double? diastolic;

      if (systolicData != null && systolicData.isNotEmpty) {
        final latestSystolic = systolicData.last;
        if (latestSystolic.value is NumericHealthValue) {
          systolic = (latestSystolic.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }

      if (diastolicData != null && diastolicData.isNotEmpty) {
        final latestDiastolic = diastolicData.last;
        if (latestDiastolic.value is NumericHealthValue) {
          diastolic = (latestDiastolic.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }

      if (systolic != null && diastolic != null) {
        return {'systolic': systolic, 'diastolic': diastolic};
      }

      return null;
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération de la pression artérielle: $e',
      );
      return null;
    }
  }

  Future<double?> getWeight() async {
    if (!_isInitialized) return null;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: 7));

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: startOfWeek,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        final latestData = healthData.last;
        if (latestData.value is NumericHealthValue) {
          return (latestData.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du poids: $e');
      return null;
    }
  }

  Future<double?> getHeight() async {
    if (!_isInitialized) return null;

    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: startOfYear,
        endTime: now,
      );

      if (healthData != null && healthData.isNotEmpty) {
        final latestData = healthData.last;
        if (latestData.value is NumericHealthValue) {
          return (latestData.value as NumericHealthValue).numericValue
              .toDouble();
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la taille: $e');
      return null;
    }
  }

  Future<bool> writeHealthData(double value, HealthDataType type) async {
    if (!_isInitialized) return false;

    try {
      final now = DateTime.now();
      final success = await _health?.writeHealthData(
        value: value,
        type: type,
        startTime: now,
        endTime: now,
      );

      return success ?? false;
    } catch (e) {
      debugPrint('Erreur lors de l\'écriture des données de santé: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyHealthReport() async {
    if (!_isInitialized) return [];

    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> weeklyData = [];

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

        final steps = await _getDailySteps(startOfDay, endOfDay);
        final calories = await _getDailyCalories(startOfDay, endOfDay);

        weeklyData.add({
          'date': startOfDay.toIso8601String(),
          'steps': steps,
          'calories': calories,
        });
      }

      return weeklyData;
    } catch (e) {
      debugPrint('Erreur lors de la génération du rapport hebdomadaire: $e');
      return [];
    }
  }

  Future<int> _getDailySteps(DateTime start, DateTime end) async {
    try {
      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: start,
        endTime: end,
      );

      if (healthData != null && healthData.isNotEmpty) {
        int totalSteps = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalSteps += (data.value as NumericHealthValue).numericValue
                .toInt();
          }
        }
        return totalSteps;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getDailyCalories(DateTime start, DateTime end) async {
    try {
      final healthData = await _health?.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );

      if (healthData != null && healthData.isNotEmpty) {
        double totalCalories = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalCalories += (data.value as NumericHealthValue).numericValue;
          }
        }
        return totalCalories;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void dispose() {
    _isInitialized = false;
    debugPrint('HealthMonitoringService fermé');
  }
}
