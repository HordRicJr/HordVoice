import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_resolver.dart';

/// Service d'effets vocaux en sortie pour HordVoice IA
/// Fonctionnalité 7: Effets vocaux en sortie
class VoiceEffectsService {
  static final VoiceEffectsService _instance = VoiceEffectsService._internal();
  factory VoiceEffectsService() => _instance;
  VoiceEffectsService._internal();

  // Services et contrôleurs
  FlutterTts? _tts;

  // État du service
  bool _isInitialized = false;
  VoiceEffect _currentEffect = VoiceEffect.none;
  Map<String, dynamic> _effectParameters = {};

  // Streams pour les événements
  final StreamController<VoiceEffectEvent> _effectController =
      StreamController.broadcast();

  // Getters
  Stream<VoiceEffectEvent> get effectStream => _effectController.stream;
  bool get isInitialized => _isInitialized;
  VoiceEffect get currentEffect => _currentEffect;

  /// Initialise le service d'effets vocaux
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('VoiceEffectsService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation VoiceEffectsService...');

      _tts = FlutterTts();
      await _configureTts();

      _isInitialized = true;
      debugPrint('VoiceEffectsService initialisé avec succès');

      _effectController.add(VoiceEffectEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation VoiceEffectsService: $e');
      throw Exception(
        'Impossible d\'initialiser le service d\'effets vocaux: $e',
      );
    }
  }

  /// Configure le TTS avec les paramètres par défaut
  Future<void> _configureTts() async {
    if (_tts == null) return;

    final ttsLang = await LanguageResolver.getTtsLanguage();
    await _tts!.setLanguage(ttsLang);
    await _tts!.setSpeechRate(1.0);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
  }

  /// Applique un effet vocal spécifique
  Future<void> applyVoiceEffect(
    VoiceEffect effect, [
    Map<String, dynamic>? parameters,
  ]) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _currentEffect = effect;
      _effectParameters = parameters ?? {};

      await _configureEffectSettings(effect, _effectParameters);

      _effectController.add(
        VoiceEffectEvent.effectApplied(effect, _effectParameters),
      );
      debugPrint('Effet vocal appliqué: ${effect.name}');
    } catch (e) {
      debugPrint('Erreur application effet vocal: $e');
      _effectController.add(
        VoiceEffectEvent.error('Erreur application effet: $e'),
      );
    }
  }

  /// Parle avec l'effet vocal actuel
  Future<void> speakWithEffect(
    String text, {
    VoiceEffect? temporaryEffect,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final effectToUse = temporaryEffect ?? _currentEffect;

      if (effectToUse != VoiceEffect.none) {
        await _applyTemporaryEffect(effectToUse);
      }

      // Appliquer les transformations de texte selon l'effet
      final transformedText = _transformText(text, effectToUse);

      await _tts!.speak(transformedText);

      _effectController.add(VoiceEffectEvent.speechStarted(text, effectToUse));
    } catch (e) {
      debugPrint('Erreur speech avec effet: $e');
      _effectController.add(VoiceEffectEvent.error('Erreur speech: $e'));
    }
  }

  /// Configure les paramètres TTS selon l'effet
  Future<void> _configureEffectSettings(
    VoiceEffect effect,
    Map<String, dynamic> parameters,
  ) async {
    if (_tts == null) return;

    switch (effect) {
      case VoiceEffect.none:
        await _resetToDefault();
        break;

      case VoiceEffect.robot:
        await _tts!.setPitch(0.5);
        await _tts!.setSpeechRate(0.8);
        break;

      case VoiceEffect.chipmunk:
        await _tts!.setPitch(2.0);
        await _tts!.setSpeechRate(1.3);
        break;

      case VoiceEffect.darth:
        await _tts!.setPitch(0.3);
        await _tts!.setSpeechRate(0.7);
        break;

      case VoiceEffect.echo:
        // L'écho sera simulé par répétition de phrases
        await _tts!.setPitch(1.0);
        await _tts!.setSpeechRate(0.9);
        break;

      case VoiceEffect.whisper:
        await _tts!.setVolume(0.3);
        await _tts!.setPitch(0.8);
        await _tts!.setSpeechRate(0.8);
        break;

      case VoiceEffect.narrator:
        await _tts!.setPitch(0.9);
        await _tts!.setSpeechRate(0.85);
        await _tts!.setVolume(0.8);
        break;

      case VoiceEffect.excited:
        await _tts!.setPitch(1.3);
        await _tts!.setSpeechRate(1.2);
        await _tts!.setVolume(1.0);
        break;

      case VoiceEffect.sleepy:
        await _tts!.setPitch(0.7);
        await _tts!.setSpeechRate(0.6);
        await _tts!.setVolume(0.7);
        break;

      case VoiceEffect.emotional:
        final emotion = parameters['emotion'] ?? 'neutral';
        await _applyEmotionalEffect(emotion);
        break;

      case VoiceEffect.multilingual:
        final language = parameters['language'] ?? 'fr-FR';
        await _tts!.setLanguage(language);
        await _adjustForLanguage(language);
        break;

      case VoiceEffect.dynamic:
        // Effet dynamique basé sur le contenu
        await _applyDynamicEffect(parameters['content'] ?? '');
        break;

      case VoiceEffect.custom:
        // Effet personnalisé avec paramètres utilisateur
        await _applyCustomEffect(parameters);
        break;
    }
  }

  /// Applique un effet émotionnel spécifique
  Future<void> _applyEmotionalEffect(String emotion) async {
    if (_tts == null) return;

    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'joie':
        await _tts!.setPitch(1.2);
        await _tts!.setSpeechRate(1.1);
        break;

      case 'sadness':
      case 'tristesse':
        await _tts!.setPitch(0.8);
        await _tts!.setSpeechRate(0.8);
        break;

      case 'anger':
      case 'colère':
        await _tts!.setPitch(1.1);
        await _tts!.setSpeechRate(1.3);
        await _tts!.setVolume(0.9);
        break;

      case 'fear':
      case 'peur':
        await _tts!.setPitch(1.4);
        await _tts!.setSpeechRate(1.2);
        break;

      case 'surprise':
        await _tts!.setPitch(1.3);
        await _tts!.setSpeechRate(1.0);
        break;

      case 'calm':
      case 'calme':
        await _tts!.setPitch(0.9);
        await _tts!.setSpeechRate(0.85);
        break;

      default:
        await _resetToDefault();
    }
  }

  /// Ajuste les paramètres selon la langue
  Future<void> _adjustForLanguage(String language) async {
    if (_tts == null) return;

    switch (language) {
      case 'en-US':
      case 'en-GB':
        await _tts!.setPitch(1.0);
        await _tts!.setSpeechRate(1.0);
        break;

      case 'es-ES':
      case 'es-MX':
        await _tts!.setPitch(1.1);
        await _tts!.setSpeechRate(0.95);
        break;

      case 'de-DE':
        await _tts!.setPitch(0.9);
        await _tts!.setSpeechRate(0.9);
        break;

      case 'it-IT':
        await _tts!.setPitch(1.05);
        await _tts!.setSpeechRate(1.0);
        break;

      default: // fr-FR
        await _tts!.setPitch(1.0);
        await _tts!.setSpeechRate(1.0);
    }
  }

  /// Applique un effet dynamique basé sur le contenu
  Future<void> _applyDynamicEffect(String content) async {
    if (_tts == null) return;

    final contentLower = content.toLowerCase();

    // Analyser le contenu pour choisir l'effet approprié
    if (contentLower.contains('urgent') || contentLower.contains('important')) {
      await _tts!.setPitch(1.2);
      await _tts!.setSpeechRate(1.1);
    } else if (contentLower.contains('secret') ||
        contentLower.contains('confidentiel')) {
      await _tts!.setVolume(0.6);
      await _tts!.setPitch(0.9);
    } else if (contentLower.contains('drôle') ||
        contentLower.contains('blague')) {
      await _tts!.setPitch(1.3);
      await _tts!.setSpeechRate(1.1);
    } else if (contentLower.contains('triste') ||
        contentLower.contains('désolé')) {
      await _tts!.setPitch(0.8);
      await _tts!.setSpeechRate(0.8);
    } else {
      await _resetToDefault();
    }
  }

  /// Applique un effet personnalisé avec paramètres utilisateur
  Future<void> _applyCustomEffect(Map<String, dynamic> parameters) async {
    if (_tts == null) return;

    // Appliquer les paramètres personnalisés
    if (parameters.containsKey('pitch')) {
      final pitch = (parameters['pitch'] as num?)?.toDouble() ?? 1.0;
      await _tts!.setPitch(pitch.clamp(0.1, 2.0));
    }

    if (parameters.containsKey('speechRate')) {
      final rate = (parameters['speechRate'] as num?)?.toDouble() ?? 1.0;
      await _tts!.setSpeechRate(rate.clamp(0.1, 2.0));
    }

    if (parameters.containsKey('volume')) {
      final volume = (parameters['volume'] as num?)?.toDouble() ?? 1.0;
      await _tts!.setVolume(volume.clamp(0.0, 1.0));
    }

    if (parameters.containsKey('language')) {
      final language = parameters['language'] as String? ?? 'fr-FR';
      await _tts!.setLanguage(language);
    }
  }

  /// Transforme le texte selon l'effet vocal
  String _transformText(String text, VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.robot:
        return _addRobotText(text);

      case VoiceEffect.echo:
        return _addEchoText(text);

      case VoiceEffect.whisper:
        return _addWhisperText(text);

      case VoiceEffect.narrator:
        return _addNarratorText(text);

      case VoiceEffect.darth:
        return _addDarthText(text);

      default:
        return text;
    }
  }

  String _addRobotText(String text) {
    // Ajouter des pauses pour simuler un robot
    return text.replaceAllMapped(RegExp(r'\.'), (match) => '... ');
  }

  String _addEchoText(String text) {
    // Simuler un écho en répétant certains mots
    final words = text.split(' ');
    if (words.length > 3) {
      final lastWord = words.last;
      return '$text... $lastWord';
    }
    return text;
  }

  String _addWhisperText(String text) {
    // Ajouter des pauses pour un effet chuchoté
    return text.replaceAll(' ', '... ');
  }

  String _addNarratorText(String text) {
    // Style narrateur
    return 'Et alors... $text';
  }

  String _addDarthText(String text) {
    // Style Darth Vader
    final darthPhrases = [
      'Je trouve votre manque de foi... perturbant.',
      'Le côté obscur vous appelle.',
      'Votre destin vous attend.',
    ];

    if (text.length < 20) {
      final random = Random();
      final phrase = darthPhrases[random.nextInt(darthPhrases.length)];
      return '$phrase $text';
    }
    return text;
  }

  /// Applique temporairement un effet
  Future<void> _applyTemporaryEffect(VoiceEffect effect) async {
    final originalEffect = _currentEffect;
    final originalParameters = Map<String, dynamic>.from(_effectParameters);

    await applyVoiceEffect(effect);

    // Programmer la restauration de l'effet original
    Timer(const Duration(seconds: 5), () async {
      await applyVoiceEffect(originalEffect, originalParameters);
    });
  }

  /// Remet les paramètres par défaut
  Future<void> _resetToDefault() async {
    if (_tts == null) return;

  final ttsLang = await LanguageResolver.getTtsLanguage();
  await _tts!.setLanguage(ttsLang);
    await _tts!.setSpeechRate(1.0);
    await _tts!.setVolume(1.0);
    await _tts!.setPitch(1.0);
  }

  /// Arrête la synthèse vocale
  Future<void> stop() async {
    if (_tts != null) {
      await _tts!.stop();
    }
  }

  /// Crée un effet vocal personnalisé
  Future<void> createCustomEffect({
    required String name,
    required double pitch,
    required double speechRate,
    required double volume,
    String? language,
    Map<String, dynamic>? additionalParams,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_tts == null) return;

      await _tts!.setPitch(pitch.clamp(0.1, 3.0));
      await _tts!.setSpeechRate(speechRate.clamp(0.1, 3.0));
      await _tts!.setVolume(volume.clamp(0.0, 1.0));

      if (language != null) {
        await _tts!.setLanguage(language);
      }

      _currentEffect = VoiceEffect.custom;
      _effectParameters = {
        'name': name,
        'pitch': pitch,
        'speechRate': speechRate,
        'volume': volume,
        'language': language,
        ...?additionalParams,
      };

      _effectController.add(
        VoiceEffectEvent.customEffectCreated(name, _effectParameters),
      );
      debugPrint('Effet vocal personnalisé créé: $name');
    } catch (e) {
      debugPrint('Erreur création effet personnalisé: $e');
      _effectController.add(
        VoiceEffectEvent.error('Erreur création effet: $e'),
      );
    }
  }

  /// Obtient la liste des effets disponibles
  List<VoiceEffectInfo> getAvailableEffects() {
    return [
      VoiceEffectInfo(
        VoiceEffect.none,
        'Aucun effet',
        'Voix normale sans effet',
      ),
      VoiceEffectInfo(
        VoiceEffect.robot,
        'Robot',
        'Voix robotique avec pitch bas',
      ),
      VoiceEffectInfo(VoiceEffect.chipmunk, 'Écureuil', 'Voix aiguë et rapide'),
      VoiceEffectInfo(
        VoiceEffect.darth,
        'Darth Vader',
        'Voix grave et imposante',
      ),
      VoiceEffectInfo(
        VoiceEffect.echo,
        'Écho',
        'Effet d\'écho et de réverbération',
      ),
      VoiceEffectInfo(
        VoiceEffect.whisper,
        'Chuchotement',
        'Voix chuchotée et douce',
      ),
      VoiceEffectInfo(
        VoiceEffect.narrator,
        'Narrateur',
        'Style narrateur professionnel',
      ),
      VoiceEffectInfo(
        VoiceEffect.excited,
        'Excité',
        'Voix enthousiaste et énergique',
      ),
      VoiceEffectInfo(
        VoiceEffect.sleepy,
        'Endormi',
        'Voix lente et somnolente',
      ),
      VoiceEffectInfo(
        VoiceEffect.emotional,
        'Émotionnel',
        'Adapte selon l\'émotion',
      ),
      VoiceEffectInfo(
        VoiceEffect.multilingual,
        'Multilingue',
        'Adapte selon la langue',
      ),
      VoiceEffectInfo(
        VoiceEffect.dynamic,
        'Dynamique',
        'Adapte selon le contenu',
      ),
    ];
  }

  /// Teste un effet vocal avec un texte d'exemple
  Future<void> testVoiceEffect(VoiceEffect effect) async {
    const testTexts = {
      VoiceEffect.robot:
          'Bonjour. Je suis un robot. Comment puis-je vous aider?',
      VoiceEffect.chipmunk: 'Salut! Je parle très vite et très aigu!',
      VoiceEffect.darth: 'Je suis votre père... Luke.',
      VoiceEffect.echo: 'Cette voix a un écho... écho... écho...',
      VoiceEffect.whisper: 'Je vous parle en secret, très doucement.',
      VoiceEffect.narrator: 'Il était une fois, dans une galaxie lointaine...',
      VoiceEffect.excited: 'Wow! C\'est fantastique! Je suis si content!',
      VoiceEffect.sleepy: 'Je suis... si fatigué... je vais... dormir...',
    };

    final testText = testTexts[effect] ?? 'Ceci est un test de l\'effet vocal.';
    await speakWithEffect(testText, temporaryEffect: effect);
  }

  /// Nettoie les ressources
  void dispose() {
    _tts?.stop();
    _effectController.close();
    debugPrint('VoiceEffectsService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class VoiceEffectEvent {
  final VoiceEffectEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VoiceEffectEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory VoiceEffectEvent.initialized() {
    return VoiceEffectEvent(
      type: VoiceEffectEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceEffectEvent.effectApplied(
    VoiceEffect effect,
    Map<String, dynamic> parameters,
  ) {
    return VoiceEffectEvent(
      type: VoiceEffectEventType.effectApplied,
      data: {'effect': effect.name, 'parameters': parameters},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceEffectEvent.speechStarted(String text, VoiceEffect effect) {
    return VoiceEffectEvent(
      type: VoiceEffectEventType.speechStarted,
      data: {'text': text, 'effect': effect.name},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceEffectEvent.customEffectCreated(
    String name,
    Map<String, dynamic> parameters,
  ) {
    return VoiceEffectEvent(
      type: VoiceEffectEventType.customEffectCreated,
      data: {'name': name, 'parameters': parameters},
      timestamp: DateTime.now(),
    );
  }

  factory VoiceEffectEvent.error(String message) {
    return VoiceEffectEvent(
      type: VoiceEffectEventType.error,
      data: {'message': message},
      timestamp: DateTime.now(),
    );
  }
}

class VoiceEffectInfo {
  final VoiceEffect effect;
  final String name;
  final String description;

  VoiceEffectInfo(this.effect, this.name, this.description);
}

// ==================== ENUMS ====================

enum VoiceEffect {
  none,
  robot,
  chipmunk,
  darth,
  echo,
  whisper,
  narrator,
  excited,
  sleepy,
  emotional,
  multilingual,
  dynamic,
  custom,
}

enum VoiceEffectEventType {
  initialized,
  effectApplied,
  speechStarted,
  customEffectCreated,
  error,
}
