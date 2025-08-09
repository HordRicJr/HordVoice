import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de mode multilingue instantané pour HordVoice IA
/// Fonctionnalité 5: Mode Multilingue instantané
class MultilingualService {
  static final MultilingualService _instance = MultilingualService._internal();
  factory MultilingualService() => _instance;
  MultilingualService._internal();

  // Services et contrôleurs
  FlutterTts? _tts;

  // État du service
  bool _isInitialized = false;
  bool _multilingualModeActive = false;
  LanguageProfile _currentLanguage = LanguageProfile.french;
  bool _autoDetectionEnabled = true;
  bool _autoTranslationEnabled = false;

  // Configuration multilingue
  late Map<LanguageProfile, LanguageConfiguration> _languageConfigs;
  final List<LanguageDetectionResult> _detectionHistory = [];
  final Map<String, String> _translationCache = {};

  // Streams pour les événements
  final StreamController<MultilingualEvent> _multilingualController =
      StreamController.broadcast();
  final StreamController<LanguageDetectionResult> _detectionController =
      StreamController.broadcast();

  // Getters
  Stream<MultilingualEvent> get multilingualStream =>
      _multilingualController.stream;
  Stream<LanguageDetectionResult> get detectionStream =>
      _detectionController.stream;
  bool get isInitialized => _isInitialized;
  bool get multilingualModeActive => _multilingualModeActive;
  LanguageProfile get currentLanguage => _currentLanguage;
  bool get autoDetectionEnabled => _autoDetectionEnabled;

  /// Initialise le service multilingue
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('MultilingualService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation MultilingualService...');

      _tts = FlutterTts();
      await _initializeLanguageConfigurations();
      await _loadUserPreferences();
      await _configureTtsForCurrentLanguage();

      _isInitialized = true;
      debugPrint('MultilingualService initialisé avec succès');

      _multilingualController.add(MultilingualEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation MultilingualService: $e');
      throw Exception('Impossible d\'initialiser le service multilingue: $e');
    }
  }

  /// Initialise les configurations de langues
  Future<void> _initializeLanguageConfigurations() async {
    _languageConfigs = {
      LanguageProfile.french: LanguageConfiguration(
        profile: LanguageProfile.french,
        name: 'Français',
        locale: 'fr-FR',
        ttsLanguage: 'fr-FR',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 1.0,
          speechRate: 1.0,
          volume: 0.8,
        ),
        commonPhrases: [
          'Bonjour',
          'Comment allez-vous?',
          'Merci beaucoup',
          'Au revoir',
          'Excusez-moi',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.polite,
          greetingStyle: GreetingStyle.formal,
          timeFormat: TimeFormat.h24,
        ),
      ),

      LanguageProfile.english: LanguageConfiguration(
        profile: LanguageProfile.english,
        name: 'English',
        locale: 'en-US',
        ttsLanguage: 'en-US',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 1.1,
          speechRate: 1.0,
          volume: 0.8,
        ),
        commonPhrases: [
          'Hello',
          'How are you?',
          'Thank you very much',
          'Goodbye',
          'Excuse me',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.casual,
          greetingStyle: GreetingStyle.friendly,
          timeFormat: TimeFormat.h12,
        ),
      ),

      LanguageProfile.spanish: LanguageConfiguration(
        profile: LanguageProfile.spanish,
        name: 'Español',
        locale: 'es-ES',
        ttsLanguage: 'es-ES',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 1.05,
          speechRate: 0.95,
          volume: 0.85,
        ),
        commonPhrases: [
          'Hola',
          '¿Cómo está usted?',
          'Muchas gracias',
          'Adiós',
          'Disculpe',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.polite,
          greetingStyle: GreetingStyle.warm,
          timeFormat: TimeFormat.h24,
        ),
      ),

      LanguageProfile.german: LanguageConfiguration(
        profile: LanguageProfile.german,
        name: 'Deutsch',
        locale: 'de-DE',
        ttsLanguage: 'de-DE',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 0.95,
          speechRate: 0.9,
          volume: 0.8,
        ),
        commonPhrases: [
          'Guten Tag',
          'Wie geht es Ihnen?',
          'Vielen Dank',
          'Auf Wiedersehen',
          'Entschuldigung',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.formal,
          greetingStyle: GreetingStyle.formal,
          timeFormat: TimeFormat.h24,
        ),
      ),

      LanguageProfile.italian: LanguageConfiguration(
        profile: LanguageProfile.italian,
        name: 'Italiano',
        locale: 'it-IT',
        ttsLanguage: 'it-IT',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 1.1,
          speechRate: 1.05,
          volume: 0.9,
        ),
        commonPhrases: [
          'Ciao',
          'Come sta?',
          'Grazie mille',
          'Arrivederci',
          'Mi scusi',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.polite,
          greetingStyle: GreetingStyle.warm,
          timeFormat: TimeFormat.h24,
        ),
      ),

      LanguageProfile.portuguese: LanguageConfiguration(
        profile: LanguageProfile.portuguese,
        name: 'Português',
        locale: 'pt-PT',
        ttsLanguage: 'pt-PT',
        voiceCharacteristics: VoiceCharacteristics(
          pitch: 1.0,
          speechRate: 0.95,
          volume: 0.85,
        ),
        commonPhrases: [
          'Olá',
          'Como está?',
          'Muito obrigado',
          'Tchau',
          'Desculpe',
        ],
        culturalContext: CulturalContext(
          formalityLevel: FormalityLevel.polite,
          greetingStyle: GreetingStyle.warm,
          timeFormat: TimeFormat.h24,
        ),
      ),
    };

    debugPrint('${_languageConfigs.length} configurations de langues chargées');
  }

  /// Active le mode multilingue
  Future<void> activateMultilingualMode({
    bool autoDetection = true,
    bool autoTranslation = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _multilingualModeActive = true;
      _autoDetectionEnabled = autoDetection;
      _autoTranslationEnabled = autoTranslation;

      await _saveUserPreferences();

      _multilingualController.add(
        MultilingualEvent.modeActivated(
          autoDetection: autoDetection,
          autoTranslation: autoTranslation,
        ),
      );

      debugPrint(
        'Mode multilingue activé (auto-détection: $autoDetection, traduction: $autoTranslation)',
      );
    } catch (e) {
      debugPrint('Erreur activation mode multilingue: $e');
      _multilingualController.add(
        MultilingualEvent.error('Erreur activation: $e'),
      );
    }
  }

  /// Détecte automatiquement la langue d'un texte
  Future<LanguageDetectionResult> detectLanguage(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final detectionResult = await _performLanguageDetection(text);

      _detectionHistory.add(detectionResult);

      // Garder seulement les 50 dernières détections
      if (_detectionHistory.length > 50) {
        _detectionHistory.removeAt(0);
      }

      _detectionController.add(detectionResult);

      // Changer automatiquement de langue si confidence élevée
      if (_autoDetectionEnabled &&
          detectionResult.confidence > 0.8 &&
          detectionResult.detectedLanguage != _currentLanguage) {
        await switchToLanguage(detectionResult.detectedLanguage);
      }

      return detectionResult;
    } catch (e) {
      debugPrint('Erreur détection langue: $e');

      final errorResult = LanguageDetectionResult(
        detectedLanguage: _currentLanguage,
        confidence: 0.0,
        text: text,
        alternativeLanguages: [],
      );

      _detectionController.add(errorResult);
      return errorResult;
    }
  }

  /// Change la langue active
  Future<void> switchToLanguage(LanguageProfile language) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final previousLanguage = _currentLanguage;
      _currentLanguage = language;

      await _configureTtsForCurrentLanguage();
      await _saveUserPreferences();

      _multilingualController.add(
        MultilingualEvent.languageChanged(from: previousLanguage, to: language),
      );

      debugPrint('Langue changée: ${previousLanguage.name} → ${language.name}');
    } catch (e) {
      debugPrint('Erreur changement langue: $e');
      _multilingualController.add(
        MultilingualEvent.error('Erreur changement langue: $e'),
      );
    }
  }

  /// Parle dans la langue spécifiée
  Future<void> speakInLanguage(String text, LanguageProfile language) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final config = _languageConfigs[language];
      if (config == null) {
        throw Exception('Configuration langue non trouvée: ${language.name}');
      }

      // Configurer TTS temporairement pour cette langue
      await _configureTtsForLanguage(config);

      // Adapter le texte selon le contexte culturel
      final adaptedText = _adaptTextForCulture(text, config);

      await _tts!.speak(adaptedText);

      _multilingualController.add(
        MultilingualEvent.speechStarted(text: adaptedText, language: language),
      );

      // Revenir à la langue actuelle après la synthèse
      Timer(const Duration(seconds: 2), () async {
        await _configureTtsForCurrentLanguage();
      });
    } catch (e) {
      debugPrint('Erreur speech multilingue: $e');
      _multilingualController.add(MultilingualEvent.error('Erreur speech: $e'));
    }
  }

  /// Traduit un texte (simulation simple)
  Future<String> translateText(
    String text, {
    LanguageProfile? fromLanguage,
    LanguageProfile? toLanguage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final from = fromLanguage ?? _currentLanguage;
    final to = toLanguage ?? LanguageProfile.english;

    // Vérifier le cache de traduction
    final cacheKey = '${from.name}_${to.name}_${text.hashCode}';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      // Simulation de traduction (en réalité, utiliserait une API)
      final translation = await _performTranslation(text, from, to);

      // Mettre en cache
      _translationCache[cacheKey] = translation;

      _multilingualController.add(
        MultilingualEvent.textTranslated(
          originalText: text,
          translatedText: translation,
          fromLanguage: from,
          toLanguage: to,
        ),
      );

      return translation;
    } catch (e) {
      debugPrint('Erreur traduction: $e');
      _multilingualController.add(
        MultilingualEvent.error('Erreur traduction: $e'),
      );
      return text; // Retourner le texte original en cas d'erreur
    }
  }

  /// Obtient les langues supportées
  List<LanguageConfiguration> getSupportedLanguages() {
    return _languageConfigs.values.toList();
  }

  /// Obtient les statistiques d'utilisation des langues
  LanguageUsageStats getLanguageStats() {
    final totalDetections = _detectionHistory.length;
    if (totalDetections == 0) {
      return LanguageUsageStats(
        totalDetections: 0,
        languageDistribution: {},
        averageConfidence: 0.0,
        mostUsedLanguage: _currentLanguage,
      );
    }

    final distribution = <LanguageProfile, int>{};
    double totalConfidence = 0.0;

    for (final detection in _detectionHistory) {
      distribution[detection.detectedLanguage] =
          (distribution[detection.detectedLanguage] ?? 0) + 1;
      totalConfidence += detection.confidence;
    }

    final mostUsed = distribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return LanguageUsageStats(
      totalDetections: totalDetections,
      languageDistribution: distribution,
      averageConfidence: totalConfidence / totalDetections,
      mostUsedLanguage: mostUsed,
    );
  }

  /// Configure un mélange de langues pour une conversation
  Future<void> configureLanguageMix(List<LanguageProfile> languages) async {
    if (!_multilingualModeActive) {
      await activateMultilingualMode();
    }

    _multilingualController.add(
      MultilingualEvent.languageMixConfigured(languages),
    );
    debugPrint(
      'Mélange de langues configuré: ${languages.map((l) => l.name).join(', ')}',
    );
  }

  // ==================== MÉTHODES PRIVÉES ====================

  Future<LanguageDetectionResult> _performLanguageDetection(String text) async {
    // Simulation de détection de langue basée sur des mots-clés
    final detectionScores = <LanguageProfile, double>{};

    for (final config in _languageConfigs.values) {
      double score = 0.0;
      final textLower = text.toLowerCase();

      // Analyser les phrases communes
      for (final phrase in config.commonPhrases) {
        if (textLower.contains(phrase.toLowerCase())) {
          score += 0.3;
        }
      }

      // Analyser les caractéristiques de la langue
      score += _analyzeLanguageCharacteristics(textLower, config.profile);

      detectionScores[config.profile] = score.clamp(0.0, 1.0);
    }

    // Trouver la langue avec le score le plus élevé
    final sortedResults = detectionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final detectedLanguage = sortedResults.first.key;
    final confidence = sortedResults.first.value;

    final alternatives = sortedResults
        .skip(1)
        .take(2)
        .map(
          (entry) =>
              LanguageAlternative(language: entry.key, confidence: entry.value),
        )
        .toList();

    return LanguageDetectionResult(
      detectedLanguage: detectedLanguage,
      confidence: confidence,
      text: text,
      alternativeLanguages: alternatives,
    );
  }

  double _analyzeLanguageCharacteristics(
    String text,
    LanguageProfile language,
  ) {
    double score = 0.0;

    switch (language) {
      case LanguageProfile.french:
        if (text.contains('le ') ||
            text.contains('la ') ||
            text.contains('les '))
          score += 0.2;
        if (text.contains('ç') || text.contains('è') || text.contains('é'))
          score += 0.3;
        break;

      case LanguageProfile.english:
        if (text.contains('the ') ||
            text.contains('and ') ||
            text.contains('you '))
          score += 0.2;
        if (!text.contains('ç') && !text.contains('ñ') && !text.contains('ü'))
          score += 0.1;
        break;

      case LanguageProfile.spanish:
        if (text.contains('el ') ||
            text.contains('la ') ||
            text.contains('los '))
          score += 0.2;
        if (text.contains('ñ') || text.contains('¿') || text.contains('¡'))
          score += 0.3;
        break;

      case LanguageProfile.german:
        if (text.contains('der ') ||
            text.contains('die ') ||
            text.contains('das '))
          score += 0.2;
        if (text.contains('ü') || text.contains('ö') || text.contains('ä'))
          score += 0.3;
        break;

      case LanguageProfile.italian:
        if (text.contains('il ') ||
            text.contains('la ') ||
            text.contains('gli '))
          score += 0.2;
        if (text.contains('zione') || text.contains('mente')) score += 0.2;
        break;

      case LanguageProfile.portuguese:
        if (text.contains('o ') || text.contains('a ') || text.contains('os '))
          score += 0.2;
        if (text.contains('ção') || text.contains('mente')) score += 0.2;
        break;
    }

    return score;
  }

  Future<String> _performTranslation(
    String text,
    LanguageProfile from,
    LanguageProfile to,
  ) async {
    // Simulation de traduction (en réalité utiliserait une API de traduction)
    await Future.delayed(const Duration(milliseconds: 500));

    // Traductions simulées pour phrases communes
    final translations = {
      'bonjour': {
        LanguageProfile.english: 'hello',
        LanguageProfile.spanish: 'hola',
        LanguageProfile.german: 'guten tag',
        LanguageProfile.italian: 'ciao',
        LanguageProfile.portuguese: 'olá',
      },
      'hello': {
        LanguageProfile.french: 'bonjour',
        LanguageProfile.spanish: 'hola',
        LanguageProfile.german: 'hallo',
        LanguageProfile.italian: 'ciao',
        LanguageProfile.portuguese: 'olá',
      },
      'merci': {
        LanguageProfile.english: 'thank you',
        LanguageProfile.spanish: 'gracias',
        LanguageProfile.german: 'danke',
        LanguageProfile.italian: 'grazie',
        LanguageProfile.portuguese: 'obrigado',
      },
    };

    final textLower = text.toLowerCase().trim();
    final translationMap = translations[textLower];

    if (translationMap != null && translationMap.containsKey(to)) {
      return translationMap[to]!;
    }

    // Traduction générique simulée
    return '[Traduction de "$text" de ${from.name} vers ${to.name}]';
  }

  Future<void> _configureTtsForCurrentLanguage() async {
    final config = _languageConfigs[_currentLanguage];
    if (config != null) {
      await _configureTtsForLanguage(config);
    }
  }

  Future<void> _configureTtsForLanguage(LanguageConfiguration config) async {
    if (_tts == null) return;

    await _tts!.setLanguage(config.ttsLanguage);
    await _tts!.setPitch(config.voiceCharacteristics.pitch);
    await _tts!.setSpeechRate(config.voiceCharacteristics.speechRate);
    await _tts!.setVolume(config.voiceCharacteristics.volume);
  }

  String _adaptTextForCulture(String text, LanguageConfiguration config) {
    // Adapter le texte selon le contexte culturel
    switch (config.culturalContext.formalityLevel) {
      case FormalityLevel.formal:
        // Ajouter des formules de politesse
        if (!text.toLowerCase().contains('veuillez')) {
          text = 'Veuillez noter que $text';
        }
        break;

      case FormalityLevel.casual:
        // Style plus décontracté
        text = text.replaceAll('Veuillez', 'S\'il vous plaît');
        break;

      default:
        break;
    }

    return text;
  }

  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'multilingual_current_language',
        _currentLanguage.name,
      );
      await prefs.setBool('multilingual_mode_active', _multilingualModeActive);
      await prefs.setBool('multilingual_auto_detection', _autoDetectionEnabled);
      await prefs.setBool(
        'multilingual_auto_translation',
        _autoTranslationEnabled,
      );
    } catch (e) {
      debugPrint('Erreur sauvegarde préférences multilingues: $e');
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final languageName = prefs.getString('multilingual_current_language');
      if (languageName != null) {
        _currentLanguage = LanguageProfile.values.firstWhere(
          (l) => l.name == languageName,
          orElse: () => LanguageProfile.french,
        );
      }

      _multilingualModeActive =
          prefs.getBool('multilingual_mode_active') ?? false;
      _autoDetectionEnabled =
          prefs.getBool('multilingual_auto_detection') ?? true;
      _autoTranslationEnabled =
          prefs.getBool('multilingual_auto_translation') ?? false;
    } catch (e) {
      debugPrint('Erreur chargement préférences multilingues: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _tts?.stop();
    _multilingualController.close();
    _detectionController.close();
    debugPrint('MultilingualService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class LanguageConfiguration {
  final LanguageProfile profile;
  final String name;
  final String locale;
  final String ttsLanguage;
  final VoiceCharacteristics voiceCharacteristics;
  final List<String> commonPhrases;
  final CulturalContext culturalContext;

  LanguageConfiguration({
    required this.profile,
    required this.name,
    required this.locale,
    required this.ttsLanguage,
    required this.voiceCharacteristics,
    required this.commonPhrases,
    required this.culturalContext,
  });
}

class VoiceCharacteristics {
  final double pitch;
  final double speechRate;
  final double volume;

  VoiceCharacteristics({
    required this.pitch,
    required this.speechRate,
    required this.volume,
  });
}

class CulturalContext {
  final FormalityLevel formalityLevel;
  final GreetingStyle greetingStyle;
  final TimeFormat timeFormat;

  CulturalContext({
    required this.formalityLevel,
    required this.greetingStyle,
    required this.timeFormat,
  });
}

class LanguageDetectionResult {
  final LanguageProfile detectedLanguage;
  final double confidence;
  final String text;
  final List<LanguageAlternative> alternativeLanguages;

  LanguageDetectionResult({
    required this.detectedLanguage,
    required this.confidence,
    required this.text,
    required this.alternativeLanguages,
  });
}

class LanguageAlternative {
  final LanguageProfile language;
  final double confidence;

  LanguageAlternative({required this.language, required this.confidence});
}

class LanguageUsageStats {
  final int totalDetections;
  final Map<LanguageProfile, int> languageDistribution;
  final double averageConfidence;
  final LanguageProfile mostUsedLanguage;

  LanguageUsageStats({
    required this.totalDetections,
    required this.languageDistribution,
    required this.averageConfidence,
    required this.mostUsedLanguage,
  });
}

class MultilingualEvent {
  final MultilingualEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MultilingualEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory MultilingualEvent.initialized() {
    return MultilingualEvent(
      type: MultilingualEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.modeActivated({
    required bool autoDetection,
    required bool autoTranslation,
  }) {
    return MultilingualEvent(
      type: MultilingualEventType.modeActivated,
      data: {
        'autoDetection': autoDetection,
        'autoTranslation': autoTranslation,
      },
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.languageChanged({
    required LanguageProfile from,
    required LanguageProfile to,
  }) {
    return MultilingualEvent(
      type: MultilingualEventType.languageChanged,
      data: {'from': from.name, 'to': to.name},
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.speechStarted({
    required String text,
    required LanguageProfile language,
  }) {
    return MultilingualEvent(
      type: MultilingualEventType.speechStarted,
      data: {'text': text, 'language': language.name},
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.textTranslated({
    required String originalText,
    required String translatedText,
    required LanguageProfile fromLanguage,
    required LanguageProfile toLanguage,
  }) {
    return MultilingualEvent(
      type: MultilingualEventType.textTranslated,
      data: {
        'originalText': originalText,
        'translatedText': translatedText,
        'fromLanguage': fromLanguage.name,
        'toLanguage': toLanguage.name,
      },
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.languageMixConfigured(
    List<LanguageProfile> languages,
  ) {
    return MultilingualEvent(
      type: MultilingualEventType.languageMixConfigured,
      data: {'languages': languages.map((l) => l.name).toList()},
      timestamp: DateTime.now(),
    );
  }

  factory MultilingualEvent.error(String message) {
    return MultilingualEvent(
      type: MultilingualEventType.error,
      data: {'message': message},
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS ====================

enum LanguageProfile { french, english, spanish, german, italian, portuguese }

enum FormalityLevel { casual, polite, formal }

enum GreetingStyle { formal, friendly, warm }

enum TimeFormat { h12, h24 }

enum MultilingualEventType {
  initialized,
  modeActivated,
  languageChanged,
  speechStarted,
  textTranslated,
  languageMixConfigured,
  error,
}
