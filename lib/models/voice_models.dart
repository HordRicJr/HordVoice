/// Modèle pour les options de voix disponibles
class VoiceOption {
  final String id;
  final String name;
  final String language;
  final String style;
  final String gender;
  final String description;
  final bool isAvailable;
  final bool isPremium;

  const VoiceOption({
    required this.id,
    required this.name,
    required this.language,
    required this.style,
    required this.gender,
    required this.description,
    this.isAvailable = true,
    this.isPremium = false,
  });

  factory VoiceOption.fromJson(Map<String, dynamic> json) {
    return VoiceOption(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      style: json['style'] as String,
      gender: json['gender'] as String,
      description: json['description'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'style': style,
      'gender': gender,
      'description': description,
      'is_available': isAvailable,
      'is_premium': isPremium,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Liste des voix prédéfinies disponibles
class VoiceLibrary {
  static const List<VoiceOption> predefinedVoices = [
    // Voix françaises
    VoiceOption(
      id: 'voice_fr_smooth_f',
      name: 'Clara',
      language: 'fr',
      style: 'Doux',
      gender: 'Féminin',
      description: 'Voix française féminine douce et apaisante',
    ),
    VoiceOption(
      id: 'voice_fr_smooth_m',
      name: 'Hugo',
      language: 'fr',
      style: 'Doux',
      gender: 'Masculin',
      description: 'Voix française masculine douce et rassurante',
    ),
    VoiceOption(
      id: 'voice_fr_expressive_f',
      name: 'Emma',
      language: 'fr',
      style: 'Expressif',
      gender: 'Féminin',
      description: 'Voix française féminine expressive et dynamique',
    ),
    VoiceOption(
      id: 'voice_fr_expressive_m',
      name: 'Lucas',
      language: 'fr',
      style: 'Expressif',
      gender: 'Masculin',
      description: 'Voix française masculine expressive et énergique',
    ),

    // Voix anglaises
    VoiceOption(
      id: 'voice_en_calm_f',
      name: 'Sophie',
      language: 'en',
      style: 'Calme',
      gender: 'Féminin',
      description: 'Voix anglaise féminine calme et professionnelle',
    ),
    VoiceOption(
      id: 'voice_en_calm_m',
      name: 'James',
      language: 'en',
      style: 'Calme',
      gender: 'Masculin',
      description: 'Voix anglaise masculine calme et posée',
    ),
    VoiceOption(
      id: 'voice_en_vibrant_f',
      name: 'Mia',
      language: 'en',
      style: 'Énergique',
      gender: 'Féminin',
      description: 'Voix anglaise féminine énergique et enjouée',
    ),
    VoiceOption(
      id: 'voice_en_vibrant_m',
      name: 'Leo',
      language: 'en',
      style: 'Énergique',
      gender: 'Masculin',
      description: 'Voix anglaise masculine énergique et motivante',
    ),

    // Nouvelles voix africaines/multiculturelles
    VoiceOption(
      id: 'voice_fr_african_f',
      name: 'Aminata',
      language: 'fr',
      style: 'Chaleureux',
      gender: 'Féminin',
      description: 'Voix française féminine avec accent africain chaleureux',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_african_m',
      name: 'Kwame',
      language: 'fr',
      style: 'Chaleureux',
      gender: 'Masculin',
      description: 'Voix française masculine avec accent africain authentique',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_wise_f',
      name: 'Mariam',
      language: 'fr',
      style: 'Sage',
      gender: 'Féminin',
      description:
          'Voix française féminine sage et maternelle, style grand-mère',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_wise_m',
      name: 'Amadou',
      language: 'fr',
      style: 'Sage',
      gender: 'Masculin',
      description:
          'Voix française masculine sage et paternelle, style grand-père',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_romantic_f',
      name: 'Aïcha',
      language: 'fr',
      style: 'Romantique',
      gender: 'Féminin',
      description: 'Voix française féminine tendre et romantique',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_romantic_m',
      name: 'Malik',
      language: 'fr',
      style: 'Romantique',
      gender: 'Masculin',
      description: 'Voix française masculine charmante et séduisante',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_fr_young_f',
      name: 'Kadia',
      language: 'fr',
      style: 'Jeune',
      gender: 'Féminin',
      description:
          'Voix française féminine jeune et dynamique, style petite sœur',
    ),
    VoiceOption(
      id: 'voice_fr_young_m',
      name: 'Sekou',
      language: 'fr',
      style: 'Jeune',
      gender: 'Masculin',
      description:
          'Voix française masculine jeune et énergique, style petit frère',
    ),
    VoiceOption(
      id: 'voice_fr_professional_f',
      name: 'Fatou',
      language: 'fr',
      style: 'Professionnel',
      gender: 'Féminin',
      description: 'Voix française féminine professionnelle et assurée',
    ),
    VoiceOption(
      id: 'voice_fr_professional_m',
      name: 'Omar',
      language: 'fr',
      style: 'Professionnel',
      gender: 'Masculin',
      description: 'Voix française masculine professionnelle et confiante',
    ),

    // Voix anglaises additionnelles
    VoiceOption(
      id: 'voice_en_african_f',
      name: 'Zara',
      language: 'en',
      style: 'Multiculturel',
      gender: 'Féminin',
      description: 'Voix anglaise féminine avec influence africaine',
      isPremium: true,
    ),
    VoiceOption(
      id: 'voice_en_african_m',
      name: 'Kofi',
      language: 'en',
      style: 'Multiculturel',
      gender: 'Masculin',
      description: 'Voix anglaise masculine avec influence africaine',
      isPremium: true,
    ),
  ];

  /// Obtenir toutes les voix disponibles
  static List<VoiceOption> getAllVoices() {
    return List.from(predefinedVoices);
  }

  /// Obtenir les voix par langue
  static List<VoiceOption> getVoicesByLanguage(String language) {
    return predefinedVoices
        .where((voice) => voice.language == language)
        .toList();
  }

  /// Obtenir les voix par style
  static List<VoiceOption> getVoicesByStyle(String style) {
    return predefinedVoices.where((voice) => voice.style == style).toList();
  }

  /// Obtenir les voix par genre
  static List<VoiceOption> getVoicesByGender(String gender) {
    return predefinedVoices.where((voice) => voice.gender == gender).toList();
  }

  /// Obtenir une voix par ID
  static VoiceOption? getVoiceById(String id) {
    try {
      return predefinedVoices.firstWhere((voice) => voice.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir la voix par défaut
  static VoiceOption getDefaultVoice() {
    return predefinedVoices.first;
  }

  /// Vérifier si une voix existe
  static bool hasVoice(String id) {
    return predefinedVoices.any((voice) => voice.id == id);
  }
}

/// Modèle pour les paramètres vocaux
class VoiceSettings {
  final String selectedVoiceId;
  final double speechSpeed;
  final double volume;
  final double pitch;
  final bool useEmotionalTone;
  final bool useAfricanAccent;
  final bool useProverbs;
  final bool autoTranslate;

  const VoiceSettings({
    required this.selectedVoiceId,
    this.speechSpeed = 1.0,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.useEmotionalTone = true,
    this.useAfricanAccent = false,
    this.useProverbs = true,
    this.autoTranslate = false,
  });

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      selectedVoiceId: json['selected_voice_id'] as String,
      speechSpeed: (json['speech_speed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
      useEmotionalTone: json['use_emotional_tone'] as bool? ?? true,
      useAfricanAccent: json['use_african_accent'] as bool? ?? false,
      useProverbs: json['use_proverbs'] as bool? ?? true,
      autoTranslate: json['auto_translate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selected_voice_id': selectedVoiceId,
      'speech_speed': speechSpeed,
      'volume': volume,
      'pitch': pitch,
      'use_emotional_tone': useEmotionalTone,
      'use_african_accent': useAfricanAccent,
      'use_proverbs': useProverbs,
      'auto_translate': autoTranslate,
    };
  }

  VoiceSettings copyWith({
    String? selectedVoiceId,
    double? speechSpeed,
    double? volume,
    double? pitch,
    bool? useEmotionalTone,
    bool? useAfricanAccent,
    bool? useProverbs,
    bool? autoTranslate,
  }) {
    return VoiceSettings(
      selectedVoiceId: selectedVoiceId ?? this.selectedVoiceId,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      useEmotionalTone: useEmotionalTone ?? this.useEmotionalTone,
      useAfricanAccent: useAfricanAccent ?? this.useAfricanAccent,
      useProverbs: useProverbs ?? this.useProverbs,
      autoTranslate: autoTranslate ?? this.autoTranslate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceSettings &&
          runtimeType == other.runtimeType &&
          selectedVoiceId == other.selectedVoiceId &&
          speechSpeed == other.speechSpeed &&
          volume == other.volume &&
          pitch == other.pitch &&
          useEmotionalTone == other.useEmotionalTone &&
          useAfricanAccent == other.useAfricanAccent &&
          useProverbs == other.useProverbs &&
          autoTranslate == other.autoTranslate;

  @override
  int get hashCode => Object.hash(
    selectedVoiceId,
    speechSpeed,
    volume,
    pitch,
    useEmotionalTone,
    useAfricanAccent,
    useProverbs,
    autoTranslate,
  );
}
