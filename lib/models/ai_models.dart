enum AIPersonalityType { mere_africaine, grand_frere, petite_amie, ami }

class AIPersonalityResponse {
  final String id;
  final String responseType;
  final String triggerContext;
  final String personalityType;
  final String responseText;
  final int intensityLevel;
  final String languageCode;
  final bool useAfricanExpressions;
  final bool includeProverb;
  final String voiceTone;
  final int usageCount;
  final int userReactionPositive;
  final int userReactionNegative;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIPersonalityResponse({
    required this.id,
    required this.responseType,
    required this.triggerContext,
    required this.personalityType,
    required this.responseText,
    this.intensityLevel = 3,
    this.languageCode = 'fr',
    this.useAfricanExpressions = true,
    this.includeProverb = false,
    this.voiceTone = 'ferme',
    this.usageCount = 0,
    this.userReactionPositive = 0,
    this.userReactionNegative = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIPersonalityResponse.fromJson(Map<String, dynamic> json) {
    return AIPersonalityResponse(
      id: json['id'],
      responseType: json['response_type'],
      triggerContext: json['trigger_context'],
      personalityType: json['personality_type'],
      responseText: json['response_text'],
      intensityLevel: json['intensity_level'] ?? 3,
      languageCode: json['language_code'] ?? 'fr',
      useAfricanExpressions: json['use_african_expressions'] ?? true,
      includeProverb: json['include_proverb'] ?? false,
      voiceTone: json['voice_tone'] ?? 'ferme',
      usageCount: json['usage_count'] ?? 0,
      userReactionPositive: json['user_reaction_positive'] ?? 0,
      userReactionNegative: json['user_reaction_negative'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'response_type': responseType,
      'trigger_context': triggerContext,
      'personality_type': personalityType,
      'response_text': responseText,
      'intensity_level': intensityLevel,
      'language_code': languageCode,
      'use_african_expressions': useAfricanExpressions,
      'include_proverb': includeProverb,
      'voice_tone': voiceTone,
      'usage_count': usageCount,
      'user_reaction_positive': userReactionPositive,
      'user_reaction_negative': userReactionNegative,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PhoneUsageMonitoring {
  final String id;
  final String? userId;
  final String deviceId;
  final DateTime sessionStart;
  final DateTime? sessionEnd;
  final int totalScreenTimeSeconds;
  final int appSwitchesCount;
  final int notificationsReceived;
  final bool isExcessiveUsage;
  final String warningLevel;
  final DateTime? lastWarningSent;
  final String? userResponseToWarning;
  final DateTime createdAt;

  PhoneUsageMonitoring({
    required this.id,
    this.userId,
    required this.deviceId,
    required this.sessionStart,
    this.sessionEnd,
    this.totalScreenTimeSeconds = 0,
    this.appSwitchesCount = 0,
    this.notificationsReceived = 0,
    this.isExcessiveUsage = false,
    this.warningLevel = 'none',
    this.lastWarningSent,
    this.userResponseToWarning,
    required this.createdAt,
  });

  factory PhoneUsageMonitoring.fromJson(Map<String, dynamic> json) {
    return PhoneUsageMonitoring(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      sessionStart: DateTime.parse(json['session_start']),
      sessionEnd: json['session_end'] != null
          ? DateTime.parse(json['session_end'])
          : null,
      totalScreenTimeSeconds: json['total_screen_time_seconds'] ?? 0,
      appSwitchesCount: json['app_switches_count'] ?? 0,
      notificationsReceived: json['notifications_received'] ?? 0,
      isExcessiveUsage: json['is_excessive_usage'] ?? false,
      warningLevel: json['warning_level'] ?? 'none',
      lastWarningSent: json['last_warning_sent'] != null
          ? DateTime.parse(json['last_warning_sent'])
          : null,
      userResponseToWarning: json['user_response_to_warning'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'session_start': sessionStart.toIso8601String(),
      'session_end': sessionEnd?.toIso8601String(),
      'total_screen_time_seconds': totalScreenTimeSeconds,
      'app_switches_count': appSwitchesCount,
      'notifications_received': notificationsReceived,
      'is_excessive_usage': isExcessiveUsage,
      'warning_level': warningLevel,
      'last_warning_sent': lastWarningSent?.toIso8601String(),
      'user_response_to_warning': userResponseToWarning,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BatteryHealthMonitoring {
  final String id;
  final String? userId;
  final String deviceId;
  final int batteryLevel;
  final double? batteryTemperatureCelsius;
  final bool isCharging;
  final String? chargingStatus;
  final String? batteryHealth;
  final String? powerSource;
  final int? estimatedTimeRemainingMinutes;
  final bool lowBatteryWarningSent;
  final bool overheatingWarningSent;
  final bool criticalLevelReached;
  final DateTime recordedAt;

  BatteryHealthMonitoring({
    required this.id,
    this.userId,
    required this.deviceId,
    required this.batteryLevel,
    this.batteryTemperatureCelsius,
    this.isCharging = false,
    this.chargingStatus,
    this.batteryHealth,
    this.powerSource,
    this.estimatedTimeRemainingMinutes,
    this.lowBatteryWarningSent = false,
    this.overheatingWarningSent = false,
    this.criticalLevelReached = false,
    required this.recordedAt,
  });

  factory BatteryHealthMonitoring.fromJson(Map<String, dynamic> json) {
    return BatteryHealthMonitoring(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      batteryLevel: json['battery_level'],
      batteryTemperatureCelsius: json['battery_temperature_celsius']
          ?.toDouble(),
      isCharging: json['is_charging'] ?? false,
      chargingStatus: json['charging_status'],
      batteryHealth: json['battery_health'],
      powerSource: json['power_source'],
      estimatedTimeRemainingMinutes: json['estimated_time_remaining_minutes'],
      lowBatteryWarningSent: json['low_battery_warning_sent'] ?? false,
      overheatingWarningSent: json['overheating_warning_sent'] ?? false,
      criticalLevelReached: json['critical_level_reached'] ?? false,
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'battery_level': batteryLevel,
      'battery_temperature_celsius': batteryTemperatureCelsius,
      'is_charging': isCharging,
      'charging_status': chargingStatus,
      'battery_health': batteryHealth,
      'power_source': powerSource,
      'estimated_time_remaining_minutes': estimatedTimeRemainingMinutes,
      'low_battery_warning_sent': lowBatteryWarningSent,
      'overheating_warning_sent': overheatingWarningSent,
      'critical_level_reached': criticalLevelReached,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

class WellnessGoal {
  final String id;
  final String? userId;
  final String goalType;
  final String goalTitle;
  final double targetValue;
  final double currentValue;
  final String targetUnit;
  final String goalPeriod;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAchieved;
  final double achievementPercentage;
  final int streakDays;
  final int bestStreak;
  final List<dynamic> rewardUnlocked;
  final List<dynamic> motivationalMessages;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WellnessGoal({
    required this.id,
    this.userId,
    required this.goalType,
    required this.goalTitle,
    required this.targetValue,
    this.currentValue = 0,
    required this.targetUnit,
    this.goalPeriod = 'daily',
    required this.startDate,
    this.endDate,
    this.isAchieved = false,
    this.achievementPercentage = 0,
    this.streakDays = 0,
    this.bestStreak = 0,
    this.rewardUnlocked = const [],
    this.motivationalMessages = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WellnessGoal.fromJson(Map<String, dynamic> json) {
    return WellnessGoal(
      id: json['id'],
      userId: json['user_id'],
      goalType: json['goal_type'],
      goalTitle: json['goal_title'],
      targetValue: json['target_value'].toDouble(),
      currentValue: json['current_value']?.toDouble() ?? 0,
      targetUnit: json['target_unit'],
      goalPeriod: json['goal_period'] ?? 'daily',
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isAchieved: json['is_achieved'] ?? false,
      achievementPercentage: json['achievement_percentage']?.toDouble() ?? 0,
      streakDays: json['streak_days'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      rewardUnlocked: List<dynamic>.from(json['reward_unlocked'] ?? []),
      motivationalMessages: List<dynamic>.from(
        json['motivational_messages'] ?? [],
      ),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'goal_title': goalTitle,
      'target_value': targetValue,
      'current_value': currentValue,
      'target_unit': targetUnit,
      'goal_period': goalPeriod,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_achieved': isAchieved,
      'achievement_percentage': achievementPercentage,
      'streak_days': streakDays,
      'best_streak': bestStreak,
      'reward_unlocked': rewardUnlocked,
      'motivational_messages': motivationalMessages,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
