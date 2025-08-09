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
        // En production, utiliser les variables d'environnement système
        _loadFromSystemEnv();
      }

      _isLoaded = true;
      debugPrint('Configuration environnement chargée avec succès');
    } catch (e) {
      debugPrint('Erreur chargement configuration: $e');
      throw Exception('Impossible de charger la configuration: $e');
    }
  }

  /// Charge depuis le fichier .env local
  Future<void> _loadFromEnvFile() async {
    try {
      final envFile = File('.env');
      if (!await envFile.exists()) {
        throw Exception(
          'Fichier .env introuvable. Créez un fichier .env à la racine du projet.',
        );
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
    } catch (e) {
      debugPrint('Erreur lecture fichier .env: $e');
      rethrow;
    }
  }

  /// Charge depuis les variables d'environnement système
  void _loadFromSystemEnv() {
    final requiredKeys = [
      'AZURE_SPEECH_KEY',
      'AZURE_SPEECH_REGION',
      'AZURE_OPENAI_KEY',
      'AZURE_OPENAI_ENDPOINT',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ];

    for (String key in requiredKeys) {
      final value = Platform.environment[key];
      if (value != null && value.isNotEmpty) {
        _config[key] = value;
      }
    }
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
    ];

    return requiredKeys.every((key) => hasValidValue(key));
  }

  /// Getters pour les configurations spécifiques

  // Azure Speech
  String? get azureSpeechKey => getValue('AZURE_SPEECH_KEY');
  String? get azureSpeechRegion => getValue('AZURE_SPEECH_REGION');

  // Azure OpenAI
  String? get azureOpenAIKey => getValue('AZURE_OPENAI_KEY');
  String? get azureOpenAIEndpoint => getValue('AZURE_OPENAI_ENDPOINT');
  String get azureOpenAIDeployment =>
      getValueOrDefault('AZURE_OPENAI_DEPLOYMENT_NAME', 'gpt-4');

  // Azure Language Services
  String? get azureLanguageKey => getValue('AZURE_LANGUAGE_KEY');
  String? get azureLanguageEndpoint => getValue('AZURE_LANGUAGE_ENDPOINT');
  String? get azureLanguageRegion => getValue('AZURE_LANGUAGE_REGION');

  // Supabase
  String? get supabaseUrl => getValue('SUPABASE_URL');
  String? get supabaseAnonKey => getValue('SUPABASE_ANON_KEY');

  // APIs externes
  String? get googleMapsApiKey => getValue('GOOGLE_MAPS_API_KEY');
  String? get openWeatherMapApiKey => getValue('OPENWEATHERMAP_API_KEY');
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

    // Validation Supabase
    if (!hasValidValue('SUPABASE_URL')) {
      errors.add('SUPABASE_URL manquante ou invalide');
    }
    if (!hasValidValue('SUPABASE_ANON_KEY')) {
      errors.add('SUPABASE_ANON_KEY manquante ou invalide');
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
