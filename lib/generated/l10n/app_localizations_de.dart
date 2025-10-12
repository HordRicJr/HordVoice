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
  String get preparingInterface => 'Preparing interface...';

  @override
  String get readyInitializingBackground => 'Ready! Initializing in background...';

  @override
  String get interfaceReadyDegraded => 'Interface ready (degraded mode)';

  @override
  String get ricIsListening => 'Ric is listening from the spatial universe...';

  @override
  String get spatialProcessing => 'Processing in spatial universe...';

  @override
  String get spatialReady => 'Ready! Say \'Hey Ric\' in the spatial universe';

  @override
  String spatialListeningError(Object error) {
    return 'Spatial listening error: $error';
  }

  @override
  String stopError(Object error) {
    return 'Stop error: $error';
  }

  @override
  String get ricConnectedSpatial => 'Ric is connected in the spatial universe';

  @override
  String get spatialModeAvailable => 'Spatial mode available';

  @override
  String get listeningInSpatial => 'Listening in the spatial universe...';
}
