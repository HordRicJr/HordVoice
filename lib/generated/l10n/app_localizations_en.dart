// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HordVoice';

  @override
  String get initializing => 'Initializing HordVoice...';

  @override
  String get environmentConfig => 'Configuring environment...';

  @override
  String get dbInitializing => 'Initializing database...';

  @override
  String get authChecking => 'Checking authentication...';

  @override
  String get permissionsChecking => 'Checking permissions...';

  @override
  String get finalizing => 'Finalizing...';

  @override
  String get homeWelcome => 'Welcome to HordVoice';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get langEnglish => 'English';

  @override
  String get langFrench => 'French';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get langGerman => 'German';

  @override
  String get langArabic => 'Arabic';

  @override
  String get listenHint => 'Say \'Hey Ric\' to start listening';

  @override
  String errorInitialization(Object error) {
    return 'Error during initialization: $error';
  }

  @override
  String get retry => 'Retry';

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
