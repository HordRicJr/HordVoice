// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'HordVoice';

  @override
  String get initializing => 'Initialisiere HordVoice...';

  @override
  String get environmentConfig => 'Umgebung wird konfiguriert...';

  @override
  String get dbInitializing => 'Datenbank wird initialisiert...';

  @override
  String get authChecking => 'Überprüfe Authentifizierung...';

  @override
  String get permissionsChecking => 'Überprüfe Berechtigungen...';

  @override
  String get finalizing => 'Abschluss...';

  @override
  String get homeWelcome => 'Willkommen bei HordVoice';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get langEnglish => 'Englisch';

  @override
  String get langFrench => 'Französisch';

  @override
  String get langSpanish => 'Spanisch';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langArabic => 'Arabisch';

  @override
  String get listenHint => 'Sagen Sie \'Hey Ric\', um das Zuhören zu starten';

  @override
  String errorInitialization(Object error) {
    return 'Fehler bei der Initialisierung: $error';
  }

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get preparingInterface => 'Vorbereitung der Benutzeroberfläche...';

  @override
  String get readyInitializingBackground =>
      'Bereit! Initialisierung im Hintergrund...';

  @override
  String get interfaceReadyDegraded =>
      'Benutzeroberfläche bereit (eingeschränkter Modus)';

  @override
  String get ricIsListening => 'Ric hört aus dem räumlichen Universum zu...';

  @override
  String get spatialProcessing => 'Verarbeitung im räumlichen Universum...';

  @override
  String get spatialReady =>
      'Bereit! Sagen Sie \'Hey Ric\' im räumlichen Universum';

  @override
  String spatialListeningError(Object error) {
    return 'Räumlicher Hörfehler: $error';
  }

  @override
  String stopError(Object error) {
    return 'Stopp-Fehler: $error';
  }

  @override
  String get ricConnectedSpatial => 'Ric ist im räumlichen Universum verbunden';

  @override
  String get spatialModeAvailable => 'Räumlicher Modus verfügbar';

  @override
  String get listeningInSpatial => 'Hören im räumlichen Universum...';
}
