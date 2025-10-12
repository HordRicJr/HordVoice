// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'HordVoice';

  @override
  String get initializing => 'Inicializando HordVoice...';

  @override
  String get environmentConfig => 'Configurando el entorno...';

  @override
  String get dbInitializing => 'Inicializando la base de datos...';

  @override
  String get authChecking => 'Verificando autenticación...';

  @override
  String get permissionsChecking => 'Verificando permisos...';

  @override
  String get finalizing => 'Finalizando...';

  @override
  String get homeWelcome => 'Bienvenido a HordVoice';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecciona el idioma';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langFrench => 'Francés';

  @override
  String get langSpanish => 'Español';

  @override
  String get langGerman => 'Alemán';

  @override
  String get langArabic => 'Árabe';

  @override
  String get listenHint => 'Diga \'Hey Ric\' para comenzar a escuchar';

  @override
  String errorInitialization(Object error) {
    return 'Error durante la inicialización: $error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get preparingInterface => 'Preparing interface...';

  @override
  String get readyInitializingBackground =>
      'Ready! Initializing in background...';

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
