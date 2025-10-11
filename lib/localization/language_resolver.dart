import 'package:shared_preferences/shared_preferences.dart';

/// Utility to resolve the app's saved locale into platform language codes
/// used by Azure Speech (STT) and Flutter TTS.
class LanguageResolver {
  static const String _prefsKey = 'app_locale';

  /// Returns the saved language code (e.g., 'en', 'fr'). Defaults to 'en'.
  static Future<String> getSavedLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) return code;
    } catch (_) {}
    return 'en';
  }

  /// Maps a short code (en, fr, es, de, ar) to a BCP-47 language tag.
  static String toBcp47(String code) {
    switch (code) {
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'de':
        return 'de-DE';
      case 'ar':
        return 'ar-SA';
      default:
        return 'en-US';
    }
  }

  /// Returns the BCP-47 language tag to use for TTS.
  static Future<String> getTtsLanguage() async {
    final code = await getSavedLanguageCode();
    return toBcp47(code);
    }

  /// Returns the BCP-47 language tag to use for Azure STT.
  static Future<String> getAzureLanguage() async {
    final code = await getSavedLanguageCode();
    return toBcp47(code);
  }
}
