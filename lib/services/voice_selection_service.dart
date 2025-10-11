import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/voice_models.dart';
import 'azure_speech_service.dart';
import 'environment_config.dart';

final voiceSelectionServiceProvider = Provider<VoiceSelectionService>((ref) {
  return VoiceSelectionService();
});

final selectedVoiceProvider =
    StateNotifierProvider<SelectedVoiceNotifier, VoiceOption>((ref) {
      return SelectedVoiceNotifier();
    });

class SelectedVoiceNotifier extends StateNotifier<VoiceOption> {
  SelectedVoiceNotifier() : super(VoiceLibrary.getDefaultVoice()) {
    _loadSavedVoice();
  }

  final String _storageKey = 'selected_voice_id';

  Future<void> _loadSavedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoiceId = prefs.getString(_storageKey);

      if (savedVoiceId != null) {
        final voice = VoiceLibrary.getVoiceById(savedVoiceId);
        if (voice != null) {
          state = voice;
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement voix sauvegardée: $e');
    }
  }

  Future<void> selectVoice(VoiceOption voice) async {
    try {
      state = voice;

      // Sauvegarder la sélection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, voice.id);

      debugPrint('Voix sélectionnée: ${voice.name} (${voice.id})');
    } catch (e) {
      debugPrint('Erreur sélection voix: $e');
    }
  }
}

class VoiceSelectionService {
  static final VoiceSelectionService _instance =
      VoiceSelectionService._internal();
  factory VoiceSelectionService() => _instance;
  VoiceSelectionService._internal();

  late FlutterTts _tts;
  late AzureSpeechService _azureSpeech;
  final EnvironmentConfig _envConfig = EnvironmentConfig();
  bool _isInitialized = false;

  /// Initialise le service de sélection de voix
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _tts = FlutterTts();
      _azureSpeech = AzureSpeechService();
      await _envConfig.loadConfig();
      await _azureSpeech.initialize();

      _isInitialized = true;
      debugPrint('Service de sélection de voix initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation service voix: $e');
      rethrow;
    }
  }

  /// Obtient toutes les voix disponibles avec leurs catégories
  Map<String, List<VoiceOption>> getVoicesByCategory() {
    final allVoices = VoiceLibrary.getAllVoices();
    final categories = <String, List<VoiceOption>>{};

    for (final voice in allVoices) {
      final category = _getCategoryForVoice(voice);
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(voice);
    }

    return categories;
  }

  /// Détermine la catégorie d'une voix
  String _getCategoryForVoice(VoiceOption voice) {
    if (voice.style == 'Chaleureux' || voice.style == 'Multiculturel') {
      return 'Voix Africaines & Multiculturelles';
    } else if (voice.style == 'Sage') {
      return '👴 Voix Sages (Grand-parent)';
    } else if (voice.style == 'Romantique') {
      return '💕 Voix Romantiques';
    } else if (voice.style == 'Jeune') {
      return '👶 Voix Jeunes (Frère/Sœur)';
    } else if (voice.style == 'Professionnel') {
      return '💼 Voix Professionnelles';
    } else if (voice.language == 'fr') {
      return '🇫🇷 Voix Françaises Classiques';
    } else if (voice.language == 'en') {
      return '🇬🇧 Voix Anglaises';
    } else {
      return 'Autres Voix';
    }
  }

  /// Teste une voix avec un échantillon audio
  Future<void> previewVoice(VoiceOption voice, {String? customText}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final sampleTexts = {
      'Sage':
          'Bonjour mon enfant, je suis ${voice.name}. Laisse-moi te raconter une histoire...',
      'Romantique':
          'Bonsoir chéri, je suis ${voice.name}. Ta voix me fait battre le cœur...',
      'Jeune':
          'Salut ! Moi c\'est ${voice.name} ! On va bien s\'amuser ensemble !',
      'Professionnel':
          'Bonjour, je suis ${voice.name}, votre assistante professionnelle.',
      'Chaleureux':
          'Salut mon frère ! Je suis ${voice.name}. Comment ça va aujourd\'hui ?',
      'Multiculturel':
          'Hello my friend! I\'m ${voice.name}. How are you doing today?',
    };

    final text =
        customText ??
        sampleTexts[voice.style] ??
        'Bonjour, je suis ${voice.name}. Enchanté de faire votre connaissance !';

    try {
      // Utiliser TTS natif pour l'aperçu
      await _configureNativeTts(voice);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Erreur preview voix ${voice.name}: $e');
      rethrow;
    }
  }

  /// Configure le TTS natif pour une voix donnée
  Future<void> _configureNativeTts(VoiceOption voice) async {
    // If voice.language is a short code like 'fr', map to BCP-47; otherwise assume it's already BCP-47
    final code = voice.language.length == 2 ? voice.language : null;
    final lang = code != null ? LanguageResolver.toBcp47(code) : voice.language;
    await _tts.setLanguage(lang);

    // Adapter les paramètres selon le style
    switch (voice.style) {
      case 'Sage':
        await _tts.setSpeechRate(0.7); // Plus lent
        await _tts.setPitch(0.9); // Plus grave
        break;
      case 'Jeune':
        await _tts.setSpeechRate(1.1); // Plus rapide
        await _tts.setPitch(1.2); // Plus aigu
        break;
      case 'Romantique':
        await _tts.setSpeechRate(0.8); // Lent et sensuel
        await _tts.setPitch(1.0);
        break;
      case 'Professionnel':
        await _tts.setSpeechRate(0.9); // Mesuré
        await _tts.setPitch(1.0); // Neutre
        break;
      default:
        await _tts.setSpeechRate(0.9);
        await _tts.setPitch(1.0);
    }

    await _tts.setVolume(1.0);
  }

  /// Arrête l'aperçu vocal en cours
  Future<void> stopPreview() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Erreur arrêt preview: $e');
    }
  }

  /// Obtient les voix favorites de l'utilisateur
  Future<List<VoiceOption>> getFavoriteVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_voice_ids') ?? [];

      return favoriteIds
          .map((id) => VoiceLibrary.getVoiceById(id))
          .where((voice) => voice != null)
          .cast<VoiceOption>()
          .toList();
    } catch (e) {
      debugPrint('Erreur chargement voix favorites: $e');
      return [];
    }
  }

  /// Ajoute une voix aux favoris
  Future<void> addToFavorites(VoiceOption voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_voice_ids') ?? [];

      if (!favoriteIds.contains(voice.id)) {
        favoriteIds.add(voice.id);
        await prefs.setStringList('favorite_voice_ids', favoriteIds);
        debugPrint('Voix ${voice.name} ajoutée aux favoris');
      }
    } catch (e) {
      debugPrint('Erreur ajout favoris: $e');
    }
  }

  /// Retire une voix des favoris
  Future<void> removeFromFavorites(VoiceOption voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_voice_ids') ?? [];

      favoriteIds.remove(voice.id);
      await prefs.setStringList('favorite_voice_ids', favoriteIds);
      debugPrint('Voix ${voice.name} retirée des favoris');
    } catch (e) {
      debugPrint('Erreur suppression favoris: $e');
    }
  }

  /// Vérifie si une voix est dans les favoris
  Future<bool> isFavorite(VoiceOption voice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_voice_ids') ?? [];
      return favoriteIds.contains(voice.id);
    } catch (e) {
      debugPrint('Erreur vérification favoris: $e');
      return false;
    }
  }

  /// Obtient des recommandations de voix basées sur les préférences
  List<VoiceOption> getRecommendedVoices(VoiceOption currentVoice) {
    final allVoices = VoiceLibrary.getAllVoices();
    final recommendations = <VoiceOption>[];

    // Recommander des voix du même style
    recommendations.addAll(
      allVoices.where(
        (v) => v.style == currentVoice.style && v.id != currentVoice.id,
      ),
    );

    // Recommander des voix de la même langue
    recommendations.addAll(
      allVoices.where(
        (v) =>
            v.language == currentVoice.language &&
            v.style != currentVoice.style &&
            !recommendations.contains(v),
      ),
    );

    // Ajouter quelques voix premium populaires
    recommendations.addAll(
      allVoices
          .where((v) => v.isPremium && !recommendations.contains(v))
          .take(2),
    );

    return recommendations.take(6).toList();
  }

  /// Nettoie les ressources
  void dispose() {
    _tts.stop();
  }
}
