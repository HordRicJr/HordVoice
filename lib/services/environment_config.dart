import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de configuration environnement avec chargement sécurisé depuis .env
class EnvironmentConfig {
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  factory EnvironmentConfig() => _instance;
  EnvironmentConfig._internal();

  bool _isLoaded = false;

  /// Charge la configuration depuis le fichier .env
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      await dotenv.load(fileName: ".env");
      _isLoaded = true;
      
      if (kDebugMode) {
        debugPrint('Configuration environnement chargée avec succès depuis .env');
      }
      
      // Vérifier si les clés essentielles sont présentes
      if (!_hasEssentialKeys()) {
        throw Exception('Clés essentielles manquantes dans le fichier .env');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erreur chargement .env');
        debugPrint('Assurez-vous d\'avoir un fichier .env avec toutes les clés requises');
      }
      throw Exception('Configuration environnement impossible à charger. Vérifiez votre fichier .env.');
    }
  }

  /// Vérifie si les clés essentielles sont présentes
  bool _hasEssentialKeys() {
    final essentialKeys = [
      'AZURE_SPEECH_KEY',
      'AZURE_SPEECH_REGION',
      'AZURE_OPENAI_KEY',
      'AZURE_OPENAI_ENDPOINT',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ];

    for (String key in essentialKeys) {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty || value.contains('your_')) {
        if (kDebugMode) {
          debugPrint('Clé manquante ou invalide');
        }
        return false;
      }
    }
    return true;
  }

  /// Obtient une valeur de configuration
  String? getValue(String key) {
    if (!_isLoaded) {
      throw Exception('Configuration non chargée. Appelez loadConfig() d\'abord.');
    }
    return dotenv.env[key];
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

  // Azure OpenAI / AI Foundry
  String? get azureOpenAIKey => getValue('AZURE_OPENAI_KEY');
  String? get azureOpenAIEndpoint => getValue('AZURE_OPENAI_ENDPOINT');
  String get azureOpenAIDeployment =>
      getValueOrDefault('AZURE_OPENAI_DEPLOYMENT', 'gpt-4');
  String? get azureAIFoundryProject => getValue('AZURE_AI_FOUNDRY_PROJECT');
  String get azureOpenAIApiVersion =>
      getValueOrDefault('AZURE_OPENAI_API_VERSION', '2024-05-01-preview');

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
  
  // Clés de sécurité
  String? get masterSecretKey => getValue('MASTER_SECRET_KEY');
  String? get jwtSecret => getValue('JWT_SECRET');
  String? get encryptionKey => getValue('ENCRYPTION_KEY');

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
        'Azure Speech: ${hasValidValue('AZURE_SPEECH_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint(
        'Azure OpenAI: ${hasValidValue('AZURE_OPENAI_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint(
        'Azure Translator: ${hasValidValue('AZURE_TRANSLATOR_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint(
        'Azure Language: ${hasValidValue('AZURE_LANGUAGE_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint('Azure ML: ${hasValidValue('AZURE_ML_KEY') ? 'OK' : 'MANQUANT'}');
      debugPrint(
        'Azure Form Recognizer: ${hasValidValue('AZURE_FORM_RECOGNIZER_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint('Azure Maps: ${hasValidValue('AZURE_MAPS_KEY') ? 'OK' : 'MANQUANT'}');
      debugPrint('Supabase: ${hasValidValue('SUPABASE_URL') ? 'OK' : 'MANQUANT'}');
      debugPrint(
        'Google Maps: ${hasValidValue('GOOGLE_MAPS_API_KEY') ? 'OK' : 'MANQUANT'}',
      );
      debugPrint(
        'Weather: ${hasValidValue('OPENWEATHERMAP_API_KEY') ? 'OK' : 'MANQUANT'}',
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
