import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/azure_speech_service.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  static const _prefsKey = 'app_locale';

  LocaleNotifier() : super(null) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
        // Notify Azure speech service
        AzureSpeechService().setCurrentLanguage(_localeToAzure(code));
      }
    } catch (_) {
      // ignore
    }
  }

  void setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
        // Notify Azure speech service to switch language for STT
        AzureSpeechService().setCurrentLanguage(_localeToAzure(locale.languageCode));
      }
    } catch (_) {
      // ignore
    }
  }

  void clearLocale() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  String _localeToAzure(String code) {
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
}
