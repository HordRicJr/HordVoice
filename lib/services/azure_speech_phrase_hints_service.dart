import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service COMPLET pour envoyer les Phrase Hints au SDK Azure Speech natif Android
/// Couvre TOUTES les fonctionnalités de HordVoice pour une précision maximale
/// Envoie directement les phrases au SDK Azure Speech natif sur Android
/// pour améliorer drastiquement la précision de reconnaissance vocale
class AzureSpeechPhraseHintsService {
  /// ========== WAKE WORDS & ACTIVATION ==========
  /// Phrases wake word prédéfinies
  static const List<String> _wakeWordPhrases = [
    // Wake words principaux
    'Hey Ric',
    'Salut Ric',
    'Ric',
    'Hello Ric',
    'Bonjour Ric',
    'Salut Rick',
    'Hey Rick',
    'Bonjour Rick',
    'Rick',

    // Variations d'activation
    'Active toi',
    'Réveille toi',
    'Écoute moi',
    'Assistant',
    'HordVoice',
    'Hord Voice',
  ];

  /// ========== COMMANDES SYSTÈME ==========
  static const List<String> _systemCommandPhrases = [
    // Contrôles audio
    'Augmente le volume',
    'Diminue le volume',
    'Met en sourdine',
    'Active le son',
    'Volume maximum',
    'Volume minimum',

    // Contrôles système
    'Active le WiFi',
    'Désactive le WiFi',
    'Active le Bluetooth',
    'Désactive le Bluetooth',
    'Mode avion on',
    'Mode avion off',
    'Active la torche',
    'Éteins la torche',
    'Fais une capture d\'écran',
    'Redémarre le téléphone',
    'Éteins l\'écran',
    'Allume l\'écran',

    // Batterie
    'Niveau de batterie',
    'Combien de batterie',
    'Économie d\'énergie',
    'Mode économie',
    'État de la batterie',
  ];

  /// ========== NAVIGATION & LOCALISATION ==========
  static const List<String> _navigationPhrases = [
    // Navigation basique
    'Navigue vers',
    'Direction pour',
    'Comment aller à',
    'Itinéraire vers',
    'Route pour',
    'Emmène moi à',
    'Trouve le chemin vers',

    // Lieux courants
    'Navigue vers la maison',
    'Direction pour le travail',
    'Emmène moi au bureau',
    'Route vers l\'hôpital',
    'Direction de la pharmacie',
    'Où est le restaurant le plus proche',
    'Station service proche',
    'Distributeur près d\'ici',

    // Informations de localisation
    'Où suis je',
    'Ma position actuelle',
    'Adresse actuelle',
    'Coordonnées GPS',
    'Quelle ville',
    'Dans quel quartier',
  ];

  /// ========== MÉTÉO ==========
  static const List<String> _weatherPhrases = [
    // Météo actuelle
    'Quel temps fait il',
    'Météo aujourd\'hui',
    'Température actuelle',
    'Prévisions météo',
    'Il va pleuvoir',
    'Temps qu\'il fait',
    'Climat aujourd\'hui',

    // Prévisions
    'Météo demain',
    'Temps cette semaine',
    'Prévisions de la semaine',
    'Il va faire beau',
    'Risque de pluie',
    'Température demain',
    'Météo weekend',
  ];

  /// ========== APPELS & TÉLÉPHONIE ==========
  static const List<String> _telephonyPhrases = [
    // Appels
    'Appelle',
    'Téléphone à',
    'Compose le numéro',
    'Rappelle',
    'Appel manqué',
    'Dernier appel',
    'Historique des appels',
    'Journal d\'appels',

    // Contacts spécifiques
    'Appelle maman',
    'Téléphone à papa',
    'Appelle ma femme',
    'Appelle mon mari',
    'Appelle le bureau',
    'Appelle l\'urgence',
    'Appelle la police',
    'Compose le 112',
    'Compose le 15',
    'Compose le 18',
    'Compose le 17',

    // Gestion d'appel
    'Raccroche',
    'Termine l\'appel',
    'Réponds',
    'Décroche',
    'Rejette l\'appel',
    'Mets en attente',
  ];

  /// ========== MESSAGES & SMS ==========
  static const List<String> _messagingPhrases = [
    // SMS
    'Envoie un SMS',
    'Écris un message',
    'Nouveau message',
    'Lis mes messages',
    'Messages non lus',
    'Dernier SMS',
    'Réponds au message',

    // Contenu type
    'Message pour dire',
    'Écris je suis en route',
    'Envoie j\'arrive',
    'Écris appelle moi',
    'Message je suis occupé',
    'Envoie à plus tard',

    // Email
    'Envoie un email',
    'Nouveau mail',
    'Lis mes emails',
    'Boîte de réception',
    'Emails non lus',
    'Réponds à l\'email',
  ];

  /// ========== MUSIQUE & MÉDIA ==========
  static const List<String> _musicPhrases = [
    // Contrôles de base
    'Joue de la musique',
    'Lance la musique',
    'Démarre la playlist',
    'Mets de la musique',
    'Play musique',
    'Pause musique',
    'Arrête la musique',
    'Musique suivante',
    'Chanson précédente',
    'Prochaine chanson',

    // Spotify
    'Ouvre Spotify',
    'Lance Spotify',
    'Joue ma playlist Spotify',
    'Mes favoris Spotify',
    'Découverte Spotify',

    // Genres et artistes
    'Joue du rap',
    'Musique classique',
    'Joue du jazz',
    'Musique africaine',
    'Joue du reggae',
    'Musique relaxante',
    'Musique énergique',
    'Hits du moment',

    // Contrôles avancés
    'Augmente le volume musique',
    'Baisse le volume musique',
    'Répète cette chanson',
    'Mode aléatoire',
    'Shuffle on',
    'Shuffle off',
  ];

  /// ========== AGENDA & CALENDRIER ==========
  static const List<String> _calendarPhrases = [
    // Événements
    'Mes rendez vous aujourd\'hui',
    'Planning de la journée',
    'Agenda de demain',
    'Calendrier cette semaine',
    'Prochain rendez vous',
    'Événements à venir',

    // Création d'événements
    'Ajoute un rendez vous',
    'Crée un événement',
    'Planifie une réunion',
    'Rappel dans',
    'Programme un rappel',
    'Nouvelle note',

    // Gestion
    'Annule le rendez vous',
    'Reporte la réunion',
    'Modifie l\'événement',
    'Supprime le rappel',
  ];

  /// ========== SANTÉ & FITNESS ==========
  static const List<String> _healthPhrases = [
    // Mesures
    'Combien de pas aujourd\'hui',
    'Mes statistiques de santé',
    'Fréquence cardiaque',
    'Tension artérielle',
    'Poids actuel',
    'Calories brûlées',

    // Rappels santé
    'Rappel médicament',
    'Heure de prendre les pilules',
    'Rappel médecin',
    'Rendez vous docteur',
    'Boire de l\'eau',
    'Pause étirement',

    // Activité
    'Commence l\'entraînement',
    'Séance de sport',
    'Exercice physique',
    'Marche de santé',
    'Yoga méditation',
  ];

  /// ========== HEURE & TEMPOREL ==========
  static const List<String> _timePhrases = [
    // Heure
    'Quelle heure il est',
    'Dis moi l\'heure',
    'Heure actuelle',
    'Il est quelle heure',

    // Date
    'Quel jour on est',
    'Date d\'aujourd\'hui',
    'Jour de la semaine',
    'On est le combien',

    // Alarmes et minuteurs
    'Mets un réveil',
    'Alarme dans',
    'Réveil demain',
    'Minuteur 5 minutes',
    'Chronomètre',
    'Annule l\'alarme',
    'Snooze',
    'Répète l\'alarme',
  ];

  /// ========== IA & CONVERSATION ==========
  static const List<String> _aiConversationPhrases = [
    // Questions générales
    'Aide moi',
    'J\'ai besoin d\'aide',
    'Peux tu m\'aider',
    'Explique moi',
    'Comment faire',
    'Qu\'est ce que',
    'Raconte moi',
    'Parle moi de',

    // Conversation
    'Comment ça va',
    'Ça va bien',
    'Merci beaucoup',
    'De rien',
    'Au revoir',
    'À bientôt',
    'Bonne nuit',
    'Bonjour',
    'Salut',

    // Emotions
    'Je suis content',
    'Je suis triste',
    'Je suis fatigué',
    'Je suis stressé',
    'Ça me rend heureux',
    'Je suis énervé',
    'Je me sens bien',
  ];

  /// ========== APPLICATIONS & CONTRÔLES ==========
  static const List<String> _appControlPhrases = [
    // Ouverture d'apps
    'Ouvre WhatsApp',
    'Lance Instagram',
    'Ouvre Facebook',
    'Démarre YouTube',
    'Lance Google Maps',
    'Ouvre la calculatrice',
    'Lance l\'appareil photo',
    'Ouvre la galerie',
    'Lance Chrome',
    'Ouvre Gmail',

    // Navigation dans les apps
    'Retour en arrière',
    'Page d\'accueil',
    'Ferme l\'application',
    'Change d\'application',
    'Applications récentes',
    'Menu principal',

    // Recherche
    'Recherche sur Google',
    'Cherche sur YouTube',
    'Trouve moi',
    'Recherche',
    'Google',
  ];

  /// ========== SÉCURITÉ & URGENCES ==========
  static const List<String> _emergencyPhrases = [
    // Urgences
    'Appel d\'urgence',
    'Aide urgente',
    'SOS',
    'Police secours',
    'Pompiers',
    'SAMU',
    'Urgence médicale',

    // Sécurité
    'Localise mon téléphone',
    'Verrouille l\'écran',
    'Mode sécurisé',
    'Efface mes données',
    'Sauvegarder',
    'Protection activée',
  ];

  /// ========== COMMANDES SECRÈTES & AVANCÉES ==========
  static const List<String> _secretCommandPhrases = [
    // Mode développeur
    'Mode debug',
    'Informations système',
    'Statut des services',
    'Cache clear',
    'Redémarre les services',

    // Personnalité
    'Change de personnalité',
    'Mode professionnel',
    'Mode amical',
    'Mode mère africaine',
    'Parle comme',

    // Tests
    'Test du microphone',
    'Test des haut parleurs',
    'Calibre ma voix',
    'Test de reconnaissance',
    'Diagnostic audio',
  ];

  /// ========== MÉTHODES PUBLIQUES ==========

  /// Configure uniquement les wake words
  static Future<bool> configureWakeWordHints() async {
    return await _configurePhraseHints(_wakeWordPhrases, 'wake_word');
  }

  /// Configure toutes les commandes système
  static Future<bool> configureSystemHints() async {
    return await _configurePhraseHints(_systemCommandPhrases, 'system');
  }

  /// Configure les commandes de navigation
  static Future<bool> configureNavigationHints() async {
    return await _configurePhraseHints(_navigationPhrases, 'navigation');
  }

  /// Configure les commandes météo
  static Future<bool> configureWeatherHints() async {
    return await _configurePhraseHints(_weatherPhrases, 'weather');
  }

  /// Configure les commandes téléphonie
  static Future<bool> configureTelephonyHints() async {
    return await _configurePhraseHints(_telephonyPhrases, 'telephony');
  }

  /// Configure les commandes de messagerie
  static Future<bool> configureMessagingHints() async {
    return await _configurePhraseHints(_messagingPhrases, 'messaging');
  }

  /// Configure les commandes musicales
  static Future<bool> configureMusicHints() async {
    return await _configurePhraseHints(_musicPhrases, 'music');
  }

  /// Configure les commandes d'agenda
  static Future<bool> configureCalendarHints() async {
    return await _configurePhraseHints(_calendarPhrases, 'calendar');
  }

  /// Configure les commandes de santé
  static Future<bool> configureHealthHints() async {
    return await _configurePhraseHints(_healthPhrases, 'health');
  }

  /// Configure les commandes temporelles
  static Future<bool> configureTimeHints() async {
    return await _configurePhraseHints(_timePhrases, 'time');
  }

  /// Configure les commandes d'IA et conversation
  static Future<bool> configureAIHints() async {
    return await _configurePhraseHints(_aiConversationPhrases, 'ai');
  }

  /// Configure les commandes d'applications
  static Future<bool> configureAppHints() async {
    return await _configurePhraseHints(_appControlPhrases, 'apps');
  }

  /// Configure les commandes d'urgence
  static Future<bool> configureEmergencyHints() async {
    return await _configurePhraseHints(_emergencyPhrases, 'emergency');
  }

  /// Configure les commandes secrètes
  static Future<bool> configureSecretHints() async {
    return await _configurePhraseHints(_secretCommandPhrases, 'secret');
  }

  /// Configure des hints personnalisés
  static Future<bool> configureCustomHints(
    List<String> phrases, {
    String context = 'custom',
  }) async {
    return await _configurePhraseHints(phrases, context);
  }

  /// Configure TOUTES les phrases de TOUTES les catégories - RECOMMANDÉ
  static Future<bool> configureAllHints() async {
    final allPhrases = [
      ..._wakeWordPhrases,
      ..._systemCommandPhrases,
      ..._navigationPhrases,
      ..._weatherPhrases,
      ..._telephonyPhrases,
      ..._messagingPhrases,
      ..._musicPhrases,
      ..._calendarPhrases,
      ..._healthPhrases,
      ..._timePhrases,
      ..._aiConversationPhrases,
      ..._appControlPhrases,
      ..._emergencyPhrases,
      ..._secretCommandPhrases,
    ];

    debugPrint('🎯 Configuration COMPLÈTE: ${allPhrases.length} phrases hints');
    return await _configurePhraseHints(allPhrases, 'complete_hordvoice');
  }

  /// Efface toutes les phrases configurées
  static Future<bool> clearAllHints() async {
    try {
      debugPrint('AzureSpeechPhraseHints: Effacement de toutes les phrases');

      final result = await _platformChannel.invokeMethod('clearPhraseHints');
      if (result == true) {
        debugPrint('AzureSpeechPhraseHints: Phrases effacées avec succès');
        return true;
      } else {
        debugPrint(
          'AzureSpeechPhraseHints: Échec de l\'effacement des phrases',
        );
        return false;
      }
    } catch (e) {
      debugPrint('AzureSpeechPhraseHints: Erreur lors de l\'effacement: $e');
      return false;
    }
  }

  /// ========== IMPLÉMENTATION INTERNE ==========

  /// Platform Channel pour communiquer avec Android
  static const MethodChannel _platformChannel = MethodChannel(
    'azure_speech_custom',
  );

  /// Méthode interne pour configurer les phrases
  static Future<bool> _configurePhraseHints(
    List<String> phrases,
    String context,
  ) async {
    try {
      debugPrint(
        '🔊 AzureSpeechPhraseHints: Configuration de ${phrases.length} phrases pour [$context]',
      );

      // Envoyer les phrases au code Android natif via Platform Channel
      final result = await _platformChannel.invokeMethod(
        'configurePhraseHints',
        {'phrases': phrases, 'context': context},
      );

      if (result == true) {
        debugPrint(
          '✅ Azure Speech - Phrase Hints configurées avec succès: ${phrases.length} phrases',
        );
        return true;
      } else {
        debugPrint(
          '❌ Azure Speech - Échec de la configuration des Phrase Hints',
        );
        return false;
      }
    } catch (e) {
      debugPrint('🚨 AzureSpeechPhraseHints: Erreur Platform Channel: $e');
      return false;
    }
  }

  /// Obtient le nombre total de phrases disponibles
  static int getTotalPhrasesCount() {
    return _wakeWordPhrases.length +
        _systemCommandPhrases.length +
        _navigationPhrases.length +
        _weatherPhrases.length +
        _telephonyPhrases.length +
        _messagingPhrases.length +
        _musicPhrases.length +
        _calendarPhrases.length +
        _healthPhrases.length +
        _timePhrases.length +
        _aiConversationPhrases.length +
        _appControlPhrases.length +
        _emergencyPhrases.length +
        _secretCommandPhrases.length;
  }

  /// Obtient des statistiques sur les phrases
  static Map<String, int> getPhrasesStats() {
    return {
      'wake_words': _wakeWordPhrases.length,
      'system': _systemCommandPhrases.length,
      'navigation': _navigationPhrases.length,
      'weather': _weatherPhrases.length,
      'telephony': _telephonyPhrases.length,
      'messaging': _messagingPhrases.length,
      'music': _musicPhrases.length,
      'calendar': _calendarPhrases.length,
      'health': _healthPhrases.length,
      'time': _timePhrases.length,
      'ai_conversation': _aiConversationPhrases.length,
      'app_control': _appControlPhrases.length,
      'emergency': _emergencyPhrases.length,
      'secret': _secretCommandPhrases.length,
      'TOTAL': getTotalPhrasesCount(),
    };
  }
}
