import 'package:flutter/foundation.dart';

// DEPRECATED - NE PLUS UTILISER
// Cette classe sera supprimée dans la prochaine version
// Utilisez EnvConfig avec .env à la place pour la sécurité
@Deprecated('Use EnvConfig with .env file for security')
class EnvLoader {
  // 🔴 CLÉS SUPPRIMÉES POUR SÉCURITÉ
  // Les clés ont été migrées vers .env et EnvConfig
  static const String _azureSpeechKey = '';
  static const String _azureSpeechRegion = 'eastus';
  static const String _azureSpeechEndpoint =
      'https://eastus.api.cognitive.microsoft.com/';
  static const String _azureTranslatorKey = '';
  static const String _azureTranslatorEndpoint =
      'https://api.cognitive.microsofttranslator.com/';
  static const String _azureOpenAIKey = '';
  static const String _azureOpenAIEndpoint =
      'https://assistancevocalintelligent.openai.azure.com/';
  static const String _azureOpenAIDeployment = 'chat';

  static const String _azureLanguageKey = '';
  static const String _azureLanguageEndpoint =
      'https://hordvoicelang.cognitiveservices.azure.com/';
  static const String _azureLanguageRegion = 'eastus';

  static const String _azureMLKey = '';
  static const String _azureMLEndpoint = 'https://hordai.vault.azure.net';

  static const String _azureFormRecognizerKey = '';
  static const String _azureFormRecognizerEndpoint =
      'https://reconnaissancedeformulaire.cognitiveservices.azure.com/';
  static const String _azureFormRecognizerRegion = 'eastus';

  static const String _supabaseUrl = 'https://glbzkbshvgiceiaqobzu.supabase.co';
  static const String _supabaseKey = '';

  static const String _azureMapsKey = '';
  static const String _azureMapsClientId = '';
  static const String _azureMapsEndpoint = 'https://atlas.microsoft.com';

  static const String _openWeatherApiKey = '';
  static const String _openWeatherEndpoint =
      "https://api.openweathermap.org/data/2.5";

  static Future<void> load() async {
    // 🔴 DEPRECATED: Utiliser EnvConfig.load() à la place
    debugPrint(
      'EnvLoader is deprecated. Use EnvConfig with .env file instead.',
    );

    if (!isConfigured) {
      throw Exception(
        '🔴 SÉCURITÉ: EnvLoader ne contient plus de clés pour des raisons de sécurité. '
        'Utilisez EnvConfig avec un fichier .env local.',
      );
    }

    debugPrint('Migration requise vers EnvConfig pour la sécurité des API');
  }

  static String get azureTranslatorKey => _azureTranslatorKey;
  static String get azureTranslatorEndpoint => _azureTranslatorEndpoint;
  static String get azureSpeechKey => _azureSpeechKey;
  static String get azureSpeechRegion => _azureSpeechRegion;
  static String get azureSpeechEndpoint => _azureSpeechEndpoint;
  static String get azureOpenAIKey => _azureOpenAIKey;
  static String get azureOpenAIEndpoint => _azureOpenAIEndpoint;
  static String get azureOpenAIDeployment => _azureOpenAIDeployment;

  static String get azureLanguageKey => _azureLanguageKey;
  static String get azureLanguageEndpoint => _azureLanguageEndpoint;
  static String get azureLanguageRegion => _azureLanguageRegion;

  static String get azureMLKey => _azureMLKey;
  static String get azureMLEndpoint => _azureMLEndpoint;

  static String get azureFormRecognizerKey => _azureFormRecognizerKey;
  static String get azureFormRecognizerEndpoint => _azureFormRecognizerEndpoint;
  static String get azureFormRecognizerRegion => _azureFormRecognizerRegion;

  static String get azureMapsKey => _azureMapsKey;
  static String get azureMapsClientId => _azureMapsClientId;
  static String get azureMapsEndpoint => _azureMapsEndpoint;

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseKey => _supabaseKey;

  static String get openWeatherApiKey => _openWeatherApiKey;
  static String get openWeatherEndpoint => _openWeatherEndpoint;

  static bool get isConfigured {
    // 🔴 TOUJOURS FALSE - Migration vers EnvConfig requise
    return false;
  }
}
