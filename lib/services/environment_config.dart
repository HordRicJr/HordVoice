import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service de configuration environnement avec chargement sécurisé depuis .env
class EnvironmentConfig {
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  factory EnvironmentConfig() => _instance;
  EnvironmentConfig._internal();

  Map<String, String> _config = {};
  bool _isLoaded = false;

  /// Charge la configuration depuis le fichier .env
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      // En développement, charger depuis .env
      if (kDebugMode) {
        await _loadFromEnvFile();
      } else {
        // En production, utiliser directement les clés hardcodées
        // car les variables d'environnement système ne sont pas disponibles
        _loadHardcodedKeys();
      }

      _isLoaded = true;
      if (kDebugMode) {
        debugPrint('Configuration environnement chargée avec succès');
      }
    } catch (e) {
      // En cas d'erreur, utiliser les clés hardcodées
      if (kDebugMode) {
        debugPrint(
          'Erreur chargement configuration, utilisation des clés de fallback: $e',
        );
      }
      _loadHardcodedKeys();
      _isLoaded = true; // Marquer comme chargé même avec fallback
    }
  }

  /// Charge depuis le fichier .env local
  Future<void> _loadFromEnvFile() async {
    try {
      final envFile = File('.env');
      if (!await envFile.exists()) {
        // Si le fichier .env n'existe pas, utiliser les clés hardcodées
        _loadHardcodedKeys();
        return;
      }

      final contents = await envFile.readAsString();
      final lines = contents.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          _config[key] = value;
        }
      }

      // Vérifier si les clés importantes sont chargées, sinon utiliser hardcodées
      if (!_hasEssentialKeys()) {
        _loadHardcodedKeys();
      }
    } catch (e) {
      // En cas d'erreur, utiliser les clés hardcodées
      _loadHardcodedKeys();
    }
  }

  /// Charge les clés hardcodées pour HordVoice
  void _loadHardcodedKeys() {
    _config.addAll({
      'AZURE_SPEECH_KEY':
          'BWkbBCvtCTaZB6ijvlJsYgFgSCSLxo3ARJp8835NL3fE24vrDcRIJQQJ99BHACYeBjFXJ3w3AAAYACOGFcSl',
      'AZURE_SPEECH_REGION': 'eastus',
      'AZURE_SPEECH_ENDPOINT': 'https://eastus.api.cognitive.microsoft.com/',
      'AZURE_TRANSLATOR_KEY':
          'C6Uv167mxzRIjxRIVhxk3T0Bl7FmeMWqALl8zSOeAoYpBgchHnq6JQQJ99BHAC5RqLJXJ3w3AAAbACOGHNU2',
      'AZURE_TRANSLATOR_ENDPOINT':
          'https://api.cognitive.microsofttranslator.com/',
      'AZURE_OPENAI_KEY':
          'ARHFmyisJHz76YW6ZHaRsiyZ8ZgXTFwNGhyLZ8rTiic1t1VE17g8JQQJ99BHACYeBjFXJ3w3AAABACOGKax4',
      'AZURE_OPENAI_ENDPOINT':
          'https://assistancevocalintelligent.openai.azure.com/',
      'AZURE_OPENAI_DEPLOYMENT': 'chat',
      'AZURE_LANGUAGE_KEY':
          'DiaAEgjah3gPN5A5eN1HvUIP8a8ZtJrAzcQe24CnCv99ha5vgqzfJQQJ99BHACYeBjFXJ3w3AAAaACOGgiAQ',
      'AZURE_LANGUAGE_ENDPOINT':
          'https://hordvoicelang.cognitiveservices.azure.com/',
      'AZURE_LANGUAGE_REGION': 'eastus',
      'AZURE_ML_KEY':
          'https://hordai.vault.azure.net/keys/HordVoice/7844c139da8c42c4886f3883b9d072fa',
      'AZURE_ML_ENDPOINT': 'https://hordai.vault.azure.net',
      'AZURE_FORM_RECOGNIZER_KEY':
          'C9870i6q0a5zGWEAaGXlGtq9CvvahmPSITZBtaSN1oLvAN7fB6VUJQQJ99BHACYeBjFXJ3w3AAALACOGLMLT',
      'AZURE_FORM_RECOGNIZER_ENDPOINT':
          'https://reconnaissancedeformulaire.cognitiveservices.azure.com/',
      'AZURE_FORM_RECOGNIZER_REGION': 'eastus',
      'AZURE_MAPS_KEY':
          '4aXO1Ab6kcdOVw6LYsKfTMKUwcW3iGJWeUGuBNwxJGkpEicubgseJQQJ99BHACi5YpzPDDZUAAAgAZMP3FDa',
      'AZURE_MAPS_CLIENT_ID': 'c9ca8eae-a04c-4150-bcba-b4fc44ebbffc',
      'AZURE_MAPS_ENDPOINT': 'https://atlas.microsoft.com',
      'SUPABASE_URL': 'https://glbzkbshvgiceiaqobzu.supabase.co',
      'SUPABASE_ANON_KEY':
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsYnprYnNodmdpY2VpYXFvYnp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1MjkyMjgsImV4cCI6MjA3MDEwNTIyOH0.NWeZnbRP6wYS-TNPzoelGt-6FBwj2b4c4SywW3QRSbE',
      'OPENWEATHERMAP_API_KEY': 'cdcff205ac95a50040813b0464d87d5a',
      'OPENWEATHERMAP_ENDPOINT': 'https://api.openweathermap.org/data/2.5',
      'DEBUG_MODE': 'false',
      'LOG_LEVEL': 'info',
    });
  }

  /// Vérifie si les clés essentielles sont présentes
  bool _hasEssentialKeys() {
    final essentialKeys = [
      'AZURE_SPEECH_KEY',
      'AZURE_OPENAI_KEY',
      'SUPABASE_URL',
      'OPENWEATHERMAP_API_KEY',
    ];

    return essentialKeys.every(
      (key) =>
          _config.containsKey(key) &&
          _config[key]?.isNotEmpty == true &&
          !_config[key]!.contains('your_'),
    );
  }

  /// Obtient une valeur de configuration
  String? getValue(String key) {
    if (!_isLoaded) {
      throw Exception(
        'Configuration non chargée. Appelez loadConfig() d\'abord.',
      );
    }
    return _config[key];
  }

  /// Obtient une valeur de configuration avec valeur par défaut
  String getValueOrDefault(String key, String defaultValue) {
    final value = getValue(key);
    return value?.isNotEmpty == true ? value! : defaultValue;
  }

  /// Vérifie si une clé existe et n'est pas vide
  bool hasValidValue(String key) {
    final value = getValue(key);
    return value != null &&
        value.isNotEmpty &&
        value != 'your_${key.toLowerCase()}_here';
  }

  /// Vérifie si la configuration est complète
  bool get isConfigured {
    final requiredKeys = [
      'AZURE_SPEECH_KEY',
      'AZURE_SPEECH_REGION',
      'AZURE_OPENAI_KEY',
      'AZURE_OPENAI_ENDPOINT',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'OPENWEATHERMAP_API_KEY',
    ];

    return requiredKeys.every((key) => hasValidValue(key));
  }

  /// Getters pour les configurations spécifiques

  // Azure Speech
  String? get azureSpeechKey => getValue('AZURE_SPEECH_KEY');
  String? get azureSpeechRegion => getValue('AZURE_SPEECH_REGION');
  String? get azureSpeechEndpoint => getValue('AZURE_SPEECH_ENDPOINT');

  // Azure OpenAI
  String? get azureOpenAIKey => getValue('AZURE_OPENAI_KEY');
  String? get azureOpenAIEndpoint => getValue('AZURE_OPENAI_ENDPOINT');
  String get azureOpenAIDeployment =>
      getValueOrDefault('AZURE_OPENAI_DEPLOYMENT', 'chat');

  // Azure Translator
  String? get azureTranslatorKey => getValue('AZURE_TRANSLATOR_KEY');
  String? get azureTranslatorEndpoint => getValue('AZURE_TRANSLATOR_ENDPOINT');

  // Azure Language Services
  String? get azureLanguageKey => getValue('AZURE_LANGUAGE_KEY');
  String? get azureLanguageEndpoint => getValue('AZURE_LANGUAGE_ENDPOINT');
  String? get azureLanguageRegion => getValue('AZURE_LANGUAGE_REGION');

  // Azure Machine Learning
  String? get azureMLKey => getValue('AZURE_ML_KEY');
  String? get azureMLEndpoint => getValue('AZURE_ML_ENDPOINT');

  // Azure Form Recognizer
  String? get azureFormRecognizerKey => getValue('AZURE_FORM_RECOGNIZER_KEY');
  String? get azureFormRecognizerEndpoint =>
      getValue('AZURE_FORM_RECOGNIZER_ENDPOINT');
  String? get azureFormRecognizerRegion =>
      getValue('AZURE_FORM_RECOGNIZER_REGION');

  // Azure Maps
  String? get azureMapsKey => getValue('AZURE_MAPS_KEY');
  String? get azureMapsClientId => getValue('AZURE_MAPS_CLIENT_ID');
  String? get azureMapsEndpoint => getValue('AZURE_MAPS_ENDPOINT');

  // Supabase
  String? get supabaseUrl => getValue('SUPABASE_URL');
  String? get supabaseAnonKey => getValue('SUPABASE_ANON_KEY');

  // APIs externes
  String? get googleMapsApiKey => getValue('GOOGLE_MAPS_API_KEY');
  String? get openWeatherMapApiKey => getValue('OPENWEATHERMAP_API_KEY');
  String? get openWeatherMapEndpoint => getValue('OPENWEATHERMAP_ENDPOINT');
  String? get spotifyClientId => getValue('SPOTIFY_CLIENT_ID');
  String? get spotifyClientSecret => getValue('SPOTIFY_CLIENT_SECRET');

  // Configuration debug
  bool get debugMode =>
      getValueOrDefault('DEBUG_MODE', 'false').toLowerCase() == 'true';
  String get logLevel => getValueOrDefault('LOG_LEVEL', 'info');

  /// Validation de la configuration
  List<String> validateConfiguration() {
    List<String> errors = [];

    // Validation Azure Speech
    if (!hasValidValue('AZURE_SPEECH_KEY')) {
      errors.add('AZURE_SPEECH_KEY manquante ou invalide');
    }
    if (!hasValidValue('AZURE_SPEECH_REGION')) {
      errors.add('AZURE_SPEECH_REGION manquante ou invalide');
    }

    // Validation Azure OpenAI
    if (!hasValidValue('AZURE_OPENAI_KEY')) {
      errors.add('AZURE_OPENAI_KEY manquante ou invalide');
    }
    if (!hasValidValue('AZURE_OPENAI_ENDPOINT')) {
      errors.add('AZURE_OPENAI_ENDPOINT manquante ou invalide');
    }

    // Validation Azure Translator
    if (!hasValidValue('AZURE_TRANSLATOR_KEY')) {
      errors.add('AZURE_TRANSLATOR_KEY manquante ou invalide');
    }

    // Validation Azure Language
    if (!hasValidValue('AZURE_LANGUAGE_KEY')) {
      errors.add('AZURE_LANGUAGE_KEY manquante ou invalide');
    }

    // Validation Azure Maps
    if (!hasValidValue('AZURE_MAPS_KEY')) {
      errors.add('AZURE_MAPS_KEY manquante ou invalide');
    }

    // Validation Supabase
    if (!hasValidValue('SUPABASE_URL')) {
      errors.add('SUPABASE_URL manquante ou invalide');
    }
    if (!hasValidValue('SUPABASE_ANON_KEY')) {
      errors.add('SUPABASE_ANON_KEY manquante ou invalide');
    }

    // Validation APIs externes
    if (!hasValidValue('OPENWEATHERMAP_API_KEY')) {
      errors.add('OPENWEATHERMAP_API_KEY manquante ou invalide');
    }

    return errors;
  }

  /// Affiche le statut de la configuration
  void printConfigStatus() {
    debugPrint('=== Status Configuration ===');
    debugPrint('Chargée: $_isLoaded');
    debugPrint('Configurée: $isConfigured');

    if (debugMode) {
      debugPrint(
        'Azure Speech: ${hasValidValue('AZURE_SPEECH_KEY') ? '✓' : '✗'}',
      );
      debugPrint(
        'Azure OpenAI: ${hasValidValue('AZURE_OPENAI_KEY') ? '✓' : '✗'}',
      );
      debugPrint(
        'Azure Translator: ${hasValidValue('AZURE_TRANSLATOR_KEY') ? '✓' : '✗'}',
      );
      debugPrint(
        'Azure Language: ${hasValidValue('AZURE_LANGUAGE_KEY') ? '✓' : '✗'}',
      );
      debugPrint('Azure ML: ${hasValidValue('AZURE_ML_KEY') ? '✓' : '✗'}');
      debugPrint(
        'Azure Form Recognizer: ${hasValidValue('AZURE_FORM_RECOGNIZER_KEY') ? '✓' : '✗'}',
      );
      debugPrint('Azure Maps: ${hasValidValue('AZURE_MAPS_KEY') ? '✓' : '✗'}');
      debugPrint('Supabase: ${hasValidValue('SUPABASE_URL') ? '✓' : '✗'}');
      debugPrint(
        'Google Maps: ${hasValidValue('GOOGLE_MAPS_API_KEY') ? '✓' : '✗'}',
      );
      debugPrint(
        'Weather: ${hasValidValue('OPENWEATHERMAP_API_KEY') ? '✓' : '✗'}',
      );
    }

    final errors = validateConfiguration();
    if (errors.isNotEmpty) {
      debugPrint('Erreurs de configuration:');
      for (String error in errors) {
        debugPrint('- $error');
      }
    }
  }
}
