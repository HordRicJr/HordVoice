import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les Phrase Hints Azure Speech via Platform Channel
/// Envoie directement les phrases au SDK Azure Speech natif sur Android
class AzureSpeechPhraseHintsService {
  static const MethodChannel _channel = MethodChannel('azure_speech_custom');

  /// Phrases wake word prédéfinies
  static const List<String> _defaultWakeWordPhrases = [
    'Hey Ric',
    'Salut Ric', 
    'Ric',
    'Hello Ric',
    'Bonjour Ric',
    'Rick',
    'Salut Rick',
    'Hey Rick',
    'Bonjour Rick',
  ];

  /// Phrases de commandes courantes
  static const List<String> _defaultCommandPhrases = [
    'Quel temps fait-il',
    'Quelle heure est-il',
    'Appelle',
    'Envoie un message',
    'Lance la musique',
    'Navigation vers',
    'Rappel',
    'Agenda',
    'Météo',
    'Actualités',
  ];

  /// Configure les Phrase Hints pour Wake Word
  static Future<bool> configureWakeWordHints() async {
    return await _configurePhraseHints(_defaultWakeWordPhrases, 'wake_word');
  }

  /// Configure les Phrase Hints pour les commandes
  static Future<bool> configureCommandHints() async {
    return await _configurePhraseHints(_defaultCommandPhrases, 'commands');
  }

  /// Configure des Phrase Hints personnalisées
  static Future<bool> configureCustomHints(List<String> phrases, {String context = 'custom'}) async {
    return await _configurePhraseHints(phrases, context);
  }

  /// Configure toutes les Phrase Hints (wake word + commandes)
  static Future<bool> configureAllHints() async {
    final allPhrases = [..._defaultWakeWordPhrases, ..._defaultCommandPhrases];
    return await _configurePhraseHints(allPhrases, 'all');
  }

  /// Efface toutes les Phrase Hints
  static Future<bool> clearAllHints() async {
    try {
      debugPrint('AzureSpeechPhraseHints: Effacement de toutes les phrases');
      
      final result = await _channel.invokeMethod('clearPhraseHints');
      
      if (result == true) {
        debugPrint('AzureSpeechPhraseHints: Phrases effacées avec succès');
        return true;
      } else {
        debugPrint('AzureSpeechPhraseHints: Échec de l\'effacement des phrases');
        return false;
      }
    } catch (e) {
      debugPrint('AzureSpeechPhraseHints: Erreur lors de l\'effacement: $e');
      return false;
    }
  }

  /// Méthode interne pour configurer les phrases
  static Future<bool> _configurePhraseHints(List<String> phrases, String context) async {
    try {
      debugPrint('AzureSpeechPhraseHints: Configuration de ${phrases.length} phrases pour $context');
      debugPrint('AzureSpeechPhraseHints: Phrases = $phrases');

      final result = await _channel.invokeMethod('configurePhraseHints', {
        'phrases': phrases,
        'context': context,
      });

      if (result == true) {
        debugPrint('AzureSpeechPhraseHints: Configuration réussie pour $context');
        return true;
      } else {
        debugPrint('AzureSpeechPhraseHints: Échec de la configuration pour $context');
        return false;
      }
    } catch (e) {
      debugPrint('AzureSpeechPhraseHints: Erreur lors de la configuration: $e');
      
      // Sur iOS ou Desktop, les Platform Channels ne sont pas supportés
      if (e is MissingPluginException) {
        debugPrint('AzureSpeechPhraseHints: Platform Channel non supporté (iOS/Desktop)');
        return true; // Continuer silencieusement
      }
      
      return false;
    }
  }

  /// Teste la connexion avec le Platform Channel
  static Future<bool> testConnection() async {
    try {
      final result = await _channel.invokeMethod('testConnection');
      debugPrint('AzureSpeechPhraseHints: Test de connexion = $result');
      return result == true;
    } catch (e) {
      debugPrint('AzureSpeechPhraseHints: Erreur test de connexion: $e');
      return false;
    }
  }

  /// Obtient des statistiques sur les phrases configurées
  static Future<Map<String, dynamic>?> getHintsStatistics() async {
    try {
      final result = await _channel.invokeMethod('getHintsStatistics');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      debugPrint('AzureSpeechPhraseHints: Erreur récupération statistiques: $e');
      return null;
    }
  }
}
