import 'ai_models.dart';

class UserProfile {
  final String id;
  final String deviceId;
  final String? email;
  final String? phoneNumber;
  final String firstName;
  final String? lastName;
  final String? nickname;
  final int? age;
  final String gender;
  final String country;
  final String? city;
  final DateTime? birthDate;
  final String relationshipType;
  final String personalityPreference;
  final AIPersonalityType personalityType;
  final String languagePreference;
  final String voicePreference;
  final String accentPreference;
  final String wakeWord;
  final String assistantName;
  final String? favoriteFootballTeam;
  final String? favoriteSport;
  final Map<String, dynamic> otherTeams;
  final bool sportsNotifications;
  final bool matchAlerts;
  final bool scoreNotifications;
  final String? profession;
  final String? industry;
  final String? careerLevel;
  final bool jobAlerts;
  final bool careerTips;
  final Map<String, dynamic> workSchedule;
  final List<String> musicGenres;
  final List<String> hobbies;
  final List<String> weekendActivities;
  final Map<String, dynamic> entertainmentPreferences;
  final String? zodiacSign;
  final bool dailyHoroscope;
  final bool spiritualQuotes;
  final Map<String, dynamic> healthProfile;
  final bool healthReminders;
  final bool medicationAlerts;
  final bool exerciseTracking;
  final List<String> allergies;
  final Map<String, dynamic> dailyRoutine;
  final String morningBriefingTime;
  final String eveningBriefingTime;
  final bool weatherUpdates;
  final bool newsUpdates;
  final bool trafficUpdates;
  final List<String> newsCategories;
  final double speechSpeed;
  final double volume;
  final bool autoTranslate;
  final bool offlineMode;
  final bool useEmojis;
  final bool useProverbs;
  final bool useHumor;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final int dailyScreenLimitMinutes;
  final bool appUsageWarnings;
  final bool temperatureMonitoring;
  final String bedtime;
  final String wakeupTime;
  final int totalMessages;
  final int totalConversations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActive;
  final bool isPremium;
  final int aiStrictnessLevel;
  final bool allowReproches;
  final String preferredMotivationStyle;
  final bool wellnessGoalsActive;
  final bool dailyCheckInEnabled;
  final bool stressMonitoringEnabled;
  final String relationshipMode;
  final double emotionalIntelligenceLevel;
  final bool adaptivePersonality;

  UserProfile({
    required this.id,
    required this.deviceId,
    this.email,
    this.phoneNumber,
    required this.firstName,
    this.lastName,
    this.nickname,
    this.age,
    this.gender = 'autre',
    this.country = 'Togo',
    this.city,
    this.birthDate,
    this.relationshipType = 'ami',
    this.personalityPreference = 'mere_africaine',
    this.personalityType = AIPersonalityType.ami,
    this.languagePreference = 'fr',
    this.voicePreference = 'feminine',
    this.accentPreference = 'africain',
    this.wakeWord = 'Hey Ric',
    this.assistantName = 'Ric',
    this.favoriteFootballTeam,
    this.favoriteSport,
    this.otherTeams = const {},
    this.sportsNotifications = false,
    this.matchAlerts = false,
    this.scoreNotifications = false,
    this.profession,
    this.industry,
    this.careerLevel,
    this.jobAlerts = false,
    this.careerTips = false,
    this.workSchedule = const {},
    this.musicGenres = const [],
    this.hobbies = const [],
    this.weekendActivities = const [],
    this.entertainmentPreferences = const {},
    this.zodiacSign,
    this.dailyHoroscope = false,
    this.spiritualQuotes = false,
    this.healthProfile = const {},
    this.healthReminders = false,
    this.medicationAlerts = false,
    this.exerciseTracking = false,
    this.allergies = const [],
    this.dailyRoutine = const {},
    this.morningBriefingTime = '08:00',
    this.eveningBriefingTime = '19:00',
    this.weatherUpdates = true,
    this.newsUpdates = true,
    this.trafficUpdates = false,
    this.newsCategories = const ['tech', 'sport', 'economie'],
    this.speechSpeed = 1.0,
    this.volume = 0.8,
    this.autoTranslate = false,
    this.offlineMode = false,
    this.useEmojis = true,
    this.useProverbs = true,
    this.useHumor = true,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    this.dailyScreenLimitMinutes = 480,
    this.appUsageWarnings = true,
    this.temperatureMonitoring = true,
    this.bedtime = '23:00',
    this.wakeupTime = '07:00',
    this.totalMessages = 0,
    this.totalConversations = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActive,
    this.isPremium = false,
    this.aiStrictnessLevel = 3,
    this.allowReproches = true,
    this.preferredMotivationStyle = 'encourageant',
    this.wellnessGoalsActive = true,
    this.dailyCheckInEnabled = true,
    this.stressMonitoringEnabled = true,
    this.relationshipMode = 'ami',
    this.emotionalIntelligenceLevel = 5.0,
    this.adaptivePersonality = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      deviceId: json['device_id'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      nickname: json['nickname'],
      age: json['age'],
      gender: json['gender'] ?? 'autre',
      country: json['country'] ?? 'Togo',
      city: json['city'],
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
      relationshipType: json['relationship_type'] ?? 'ami',
      personalityPreference: json['personality_preference'] ?? 'mere_africaine',
      languagePreference: json['language_preference'] ?? 'fr',
      voicePreference: json['voice_preference'] ?? 'feminine',
      accentPreference: json['accent_preference'] ?? 'africain',
      wakeWord: json['wake_word'] ?? 'Hey Ric',
      assistantName: json['assistant_name'] ?? 'Ric',
      favoriteFootballTeam: json['favorite_football_team'],
      favoriteSport: json['favorite_sport'],
      otherTeams: Map<String, dynamic>.from(json['other_teams'] ?? {}),
      sportsNotifications: json['sports_notifications'] ?? false,
      matchAlerts: json['match_alerts'] ?? false,
      scoreNotifications: json['score_notifications'] ?? false,
      profession: json['profession'],
      industry: json['industry'],
      careerLevel: json['career_level'],
      jobAlerts: json['job_alerts'] ?? false,
      careerTips: json['career_tips'] ?? false,
      workSchedule: Map<String, dynamic>.from(json['work_schedule'] ?? {}),
      musicGenres: List<String>.from(json['music_genres'] ?? []),
      hobbies: List<String>.from(json['hobbies'] ?? []),
      weekendActivities: List<String>.from(json['weekend_activities'] ?? []),
      entertainmentPreferences: Map<String, dynamic>.from(
        json['entertainment_preferences'] ?? {},
      ),
      zodiacSign: json['zodiac_sign'],
      dailyHoroscope: json['daily_horoscope'] ?? false,
      spiritualQuotes: json['spiritual_quotes'] ?? false,
      healthProfile: Map<String, dynamic>.from(json['health_profile'] ?? {}),
      healthReminders: json['health_reminders'] ?? false,
      medicationAlerts: json['medication_alerts'] ?? false,
      exerciseTracking: json['exercise_tracking'] ?? false,
      allergies: List<String>.from(json['allergies'] ?? []),
      dailyRoutine: Map<String, dynamic>.from(json['daily_routine'] ?? {}),
      morningBriefingTime: json['morning_briefing_time'] ?? '08:00',
      eveningBriefingTime: json['evening_briefing_time'] ?? '19:00',
      weatherUpdates: json['weather_updates'] ?? true,
      newsUpdates: json['news_updates'] ?? true,
      trafficUpdates: json['traffic_updates'] ?? false,
      newsCategories: List<String>.from(
        json['news_categories'] ?? ['tech', 'sport', 'economie'],
      ),
      speechSpeed: json['speech_speed']?.toDouble() ?? 1.0,
      volume: json['volume']?.toDouble() ?? 0.8,
      autoTranslate: json['auto_translate'] ?? false,
      offlineMode: json['offline_mode'] ?? false,
      useEmojis: json['use_emojis'] ?? true,
      useProverbs: json['use_proverbs'] ?? true,
      useHumor: json['use_humor'] ?? true,
      currentLatitude: json['current_latitude']?.toDouble(),
      currentLongitude: json['current_longitude']?.toDouble(),
      lastLocationUpdate: json['last_location_update'] != null
          ? DateTime.parse(json['last_location_update'])
          : null,
      dailyScreenLimitMinutes: json['daily_screen_limit_minutes'] ?? 480,
      appUsageWarnings: json['app_usage_warnings'] ?? true,
      temperatureMonitoring: json['temperature_monitoring'] ?? true,
      bedtime: json['bedtime'] ?? '23:00',
      wakeupTime: json['wakeup_time'] ?? '07:00',
      totalMessages: json['total_messages'] ?? 0,
      totalConversations: json['total_conversations'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastActive: DateTime.parse(json['last_active']),
      isPremium: json['is_premium'] ?? false,
      aiStrictnessLevel: json['ai_strictness_level'] ?? 3,
      allowReproches: json['allow_reproches'] ?? true,
      preferredMotivationStyle:
          json['preferred_motivation_style'] ?? 'encourageant',
      wellnessGoalsActive: json['wellness_goals_active'] ?? true,
      dailyCheckInEnabled: json['daily_check_in_enabled'] ?? true,
      stressMonitoringEnabled: json['stress_monitoring_enabled'] ?? true,
      relationshipMode: json['relationship_mode'] ?? 'ami',
      emotionalIntelligenceLevel:
          json['emotional_intelligence_level']?.toDouble() ?? 5.0,
      adaptivePersonality: json['adaptive_personality'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'country': country,
      'city': city,
      'birth_date': birthDate?.toIso8601String(),
      'relationship_type': relationshipType,
      'personality_preference': personalityPreference,
      'language_preference': languagePreference,
      'voice_preference': voicePreference,
      'accent_preference': accentPreference,
      'wake_word': wakeWord,
      'assistant_name': assistantName,
      'favorite_football_team': favoriteFootballTeam,
      'favorite_sport': favoriteSport,
      'other_teams': otherTeams,
      'sports_notifications': sportsNotifications,
      'match_alerts': matchAlerts,
      'score_notifications': scoreNotifications,
      'profession': profession,
      'industry': industry,
      'career_level': careerLevel,
      'job_alerts': jobAlerts,
      'career_tips': careerTips,
      'work_schedule': workSchedule,
      'music_genres': musicGenres,
      'hobbies': hobbies,
      'weekend_activities': weekendActivities,
      'entertainment_preferences': entertainmentPreferences,
      'zodiac_sign': zodiacSign,
      'daily_horoscope': dailyHoroscope,
      'spiritual_quotes': spiritualQuotes,
      'health_profile': healthProfile,
      'health_reminders': healthReminders,
      'medication_alerts': medicationAlerts,
      'exercise_tracking': exerciseTracking,
      'allergies': allergies,
      'daily_routine': dailyRoutine,
      'morning_briefing_time': morningBriefingTime,
      'evening_briefing_time': eveningBriefingTime,
      'weather_updates': weatherUpdates,
      'news_updates': newsUpdates,
      'traffic_updates': trafficUpdates,
      'news_categories': newsCategories,
      'speech_speed': speechSpeed,
      'volume': volume,
      'auto_translate': autoTranslate,
      'offline_mode': offlineMode,
      'use_emojis': useEmojis,
      'use_proverbs': useProverbs,
      'use_humor': useHumor,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
      'daily_screen_limit_minutes': dailyScreenLimitMinutes,
      'app_usage_warnings': appUsageWarnings,
      'temperature_monitoring': temperatureMonitoring,
      'bedtime': bedtime,
      'wakeup_time': wakeupTime,
      'total_messages': totalMessages,
      'total_conversations': totalConversations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'is_premium': isPremium,
      'ai_strictness_level': aiStrictnessLevel,
      'allow_reproches': allowReproches,
      'preferred_motivation_style': preferredMotivationStyle,
      'wellness_goals_active': wellnessGoalsActive,
      'daily_check_in_enabled': dailyCheckInEnabled,
      'stress_monitoring_enabled': stressMonitoringEnabled,
      'relationship_mode': relationshipMode,
      'emotional_intelligence_level': emotionalIntelligenceLevel,
      'adaptive_personality': adaptivePersonality,
    };
  }

  UserProfile copyWith({
    String? id,
    String? deviceId,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? nickname,
    int? age,
    String? gender,
    String? country,
    String? city,
    DateTime? birthDate,
    String? relationshipType,
    String? personalityPreference,
    String? languagePreference,
    String? voicePreference,
    String? accentPreference,
    String? wakeWord,
    String? assistantName,
    String? favoriteFootballTeam,
    String? favoriteSport,
    Map<String, dynamic>? otherTeams,
    bool? sportsNotifications,
    bool? matchAlerts,
    bool? scoreNotifications,
    String? profession,
    String? industry,
    String? careerLevel,
    bool? jobAlerts,
    bool? careerTips,
    Map<String, dynamic>? workSchedule,
    List<String>? musicGenres,
    List<String>? hobbies,
    List<String>? weekendActivities,
    Map<String, dynamic>? entertainmentPreferences,
    String? zodiacSign,
    bool? dailyHoroscope,
    bool? spiritualQuotes,
    Map<String, dynamic>? healthProfile,
    bool? healthReminders,
    bool? medicationAlerts,
    bool? exerciseTracking,
    List<String>? allergies,
    Map<String, dynamic>? dailyRoutine,
    String? morningBriefingTime,
    String? eveningBriefingTime,
    bool? weatherUpdates,
    bool? newsUpdates,
    bool? trafficUpdates,
    List<String>? newsCategories,
    double? speechSpeed,
    double? volume,
    bool? autoTranslate,
    bool? offlineMode,
    bool? useEmojis,
    bool? useProverbs,
    bool? useHumor,
    double? currentLatitude,
    double? currentLongitude,
    DateTime? lastLocationUpdate,
    int? dailyScreenLimitMinutes,
    bool? appUsageWarnings,
    bool? temperatureMonitoring,
    String? bedtime,
    String? wakeupTime,
    int? totalMessages,
    int? totalConversations,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    bool? isPremium,
    int? aiStrictnessLevel,
    bool? allowReproches,
    String? preferredMotivationStyle,
    bool? wellnessGoalsActive,
    bool? dailyCheckInEnabled,
    bool? stressMonitoringEnabled,
    String? relationshipMode,
    double? emotionalIntelligenceLevel,
    bool? adaptivePersonality,
  }) {
    return UserProfile(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      city: city ?? this.city,
      birthDate: birthDate ?? this.birthDate,
      relationshipType: relationshipType ?? this.relationshipType,
      personalityPreference:
          personalityPreference ?? this.personalityPreference,
      languagePreference: languagePreference ?? this.languagePreference,
      voicePreference: voicePreference ?? this.voicePreference,
      accentPreference: accentPreference ?? this.accentPreference,
      wakeWord: wakeWord ?? this.wakeWord,
      assistantName: assistantName ?? this.assistantName,
      favoriteFootballTeam: favoriteFootballTeam ?? this.favoriteFootballTeam,
      favoriteSport: favoriteSport ?? this.favoriteSport,
      otherTeams: otherTeams ?? this.otherTeams,
      sportsNotifications: sportsNotifications ?? this.sportsNotifications,
      matchAlerts: matchAlerts ?? this.matchAlerts,
      scoreNotifications: scoreNotifications ?? this.scoreNotifications,
      profession: profession ?? this.profession,
      industry: industry ?? this.industry,
      careerLevel: careerLevel ?? this.careerLevel,
      jobAlerts: jobAlerts ?? this.jobAlerts,
      careerTips: careerTips ?? this.careerTips,
      workSchedule: workSchedule ?? this.workSchedule,
      musicGenres: musicGenres ?? this.musicGenres,
      hobbies: hobbies ?? this.hobbies,
      weekendActivities: weekendActivities ?? this.weekendActivities,
      entertainmentPreferences:
          entertainmentPreferences ?? this.entertainmentPreferences,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      dailyHoroscope: dailyHoroscope ?? this.dailyHoroscope,
      spiritualQuotes: spiritualQuotes ?? this.spiritualQuotes,
      healthProfile: healthProfile ?? this.healthProfile,
      healthReminders: healthReminders ?? this.healthReminders,
      medicationAlerts: medicationAlerts ?? this.medicationAlerts,
      exerciseTracking: exerciseTracking ?? this.exerciseTracking,
      allergies: allergies ?? this.allergies,
      dailyRoutine: dailyRoutine ?? this.dailyRoutine,
      morningBriefingTime: morningBriefingTime ?? this.morningBriefingTime,
      eveningBriefingTime: eveningBriefingTime ?? this.eveningBriefingTime,
      weatherUpdates: weatherUpdates ?? this.weatherUpdates,
      newsUpdates: newsUpdates ?? this.newsUpdates,
      trafficUpdates: trafficUpdates ?? this.trafficUpdates,
      newsCategories: newsCategories ?? this.newsCategories,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      volume: volume ?? this.volume,
      autoTranslate: autoTranslate ?? this.autoTranslate,
      offlineMode: offlineMode ?? this.offlineMode,
      useEmojis: useEmojis ?? this.useEmojis,
      useProverbs: useProverbs ?? this.useProverbs,
      useHumor: useHumor ?? this.useHumor,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      dailyScreenLimitMinutes:
          dailyScreenLimitMinutes ?? this.dailyScreenLimitMinutes,
      appUsageWarnings: appUsageWarnings ?? this.appUsageWarnings,
      temperatureMonitoring:
          temperatureMonitoring ?? this.temperatureMonitoring,
      bedtime: bedtime ?? this.bedtime,
      wakeupTime: wakeupTime ?? this.wakeupTime,
      totalMessages: totalMessages ?? this.totalMessages,
      totalConversations: totalConversations ?? this.totalConversations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      isPremium: isPremium ?? this.isPremium,
      aiStrictnessLevel: aiStrictnessLevel ?? this.aiStrictnessLevel,
      allowReproches: allowReproches ?? this.allowReproches,
      preferredMotivationStyle:
          preferredMotivationStyle ?? this.preferredMotivationStyle,
      wellnessGoalsActive: wellnessGoalsActive ?? this.wellnessGoalsActive,
      dailyCheckInEnabled: dailyCheckInEnabled ?? this.dailyCheckInEnabled,
      stressMonitoringEnabled:
          stressMonitoringEnabled ?? this.stressMonitoringEnabled,
      relationshipMode: relationshipMode ?? this.relationshipMode,
      emotionalIntelligenceLevel:
          emotionalIntelligenceLevel ?? this.emotionalIntelligenceLevel,
      adaptivePersonality: adaptivePersonality ?? this.adaptivePersonality,
    );
  }
}
