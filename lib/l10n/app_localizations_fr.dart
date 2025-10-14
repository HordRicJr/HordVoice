// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'HordVoice';

  @override
  String get initializing => 'Initialisation de HordVoice...';

  @override
  String get environmentConfig => 'Configuration de l\'environnement...';

  @override
  String get dbInitializing => 'Initialisation de la base de données...';

  @override
  String get authChecking => 'Vérification de l\'authentification...';

  @override
  String get permissionsChecking => 'Vérification des permissions...';

  @override
  String get finalizing => 'Finalisation...';

  @override
  String get homeWelcome => 'Bienvenue sur HordVoice';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionnez la langue';

  @override
  String get langEnglish => 'Anglais';

  @override
  String get langFrench => 'Français';

  @override
  String get langSpanish => 'Espagnol';

  @override
  String get langGerman => 'Allemand';

  @override
  String get langArabic => 'Arabe';

  @override
  String get listenHint => 'Dites \'Hey Ric\' pour commencer à écouter';

  @override
  String errorInitialization(Object error) {
    return 'Erreur lors de l\'initialisation : $error';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String get preparingInterface => 'Préparation de l\'interface...';

  @override
  String get readyInitializingBackground =>
      'Prêt! Initialisation en arrière-plan...';

  @override
  String get interfaceReadyDegraded => 'Interface prête (mode dégradé)';

  @override
  String get ricIsListening => 'Ric vous écoute depuis l\'univers spatial...';

  @override
  String get spatialProcessing => 'Traitement dans l\'univers spatial...';

  @override
  String get spatialReady => 'Prêt ! Dites \'Hey Ric\' dans l\'univers spatial';

  @override
  String spatialListeningError(Object error) {
    return 'Erreur d\'écoute spatiale : $error';
  }

  @override
  String stopError(Object error) {
    return 'Erreur d\'arrêt : $error';
  }

  @override
  String get ricConnectedSpatial => 'Ric est connecté dans l\'univers spatial';

  @override
  String get spatialModeAvailable => 'Mode spatial disponible';

  @override
  String get listeningInSpatial => 'En écoute dans l\'univers spatial...';
}
