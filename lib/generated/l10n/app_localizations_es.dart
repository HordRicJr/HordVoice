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
  String get preparingInterface => 'Preparando la interfaz...';

  @override
  String get readyInitializingBackground => '¡Listo! Inicializando en segundo plano...';

  @override
  String get interfaceReadyDegraded => 'Interfaz lista (modo degradado)';

  @override
  String get ricIsListening => 'Ric está escuchando desde el universo espacial...';

  @override
  String get spatialProcessing => 'Procesando en el universo espacial...';

  @override
  String get spatialReady => '¡Listo! Di \'Hey Ric\' en el universo espacial';

  @override
  String spatialListeningError(Object error) {
    return 'Error de escucha espacial: $error';
  }

  @override
  String stopError(Object error) {
    return 'Error de parada: $error';
  }

  @override
  String get ricConnectedSpatial => 'Ric está conectado en el universo espacial';

  @override
  String get spatialModeAvailable => 'Modo espacial disponible';

  @override
  String get listeningInSpatial => 'Escuchando en el universo espacial...';
}
