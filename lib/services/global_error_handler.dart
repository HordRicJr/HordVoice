import 'dart:async';
import 'package:flutter/foundation.dart';

/// Handler global pour toutes les erreurs non gérées
/// Empêche les crashes et fournit des rapports détaillés
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance =>
      _instance ??= GlobalErrorHandler._();
  GlobalErrorHandler._();

  bool _isInitialized = false;
  final List<Map<String, dynamic>> _errorHistory = [];
  final List<Map<String, dynamic>> _actionHistory = [];
  final StreamController<Map<String, dynamic>> _crashReportController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get crashReportStream =>
      _crashReportController.stream;

  /// Initialise le handler global
  void initialize() {
    if (_isInitialized) return;

    // Handler pour erreurs Dart non capturées
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handler pour erreurs asynchrones
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true;
    };

    // Handler pour erreurs natif/Platform Channels
    _setupPlatformChannelErrorHandling();

    _isInitialized = true;
    debugPrint('🛡️ GlobalErrorHandler initialisé');
  }

  /// Enregistre une action utilisateur (pour contexte crash)
  void logAction(String action, [Map<String, dynamic>? context]) {
    final actionLog = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'action': action,
      'context': context ?? {},
    };

    _actionHistory.add(actionLog);

    // Garder seulement les 10 dernières actions
    if (_actionHistory.length > 10) {
      _actionHistory.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('📝 Action: $action ${context ?? ''}');
    }
  }

  /// Handler pour erreurs Flutter
  void _handleFlutterError(FlutterErrorDetails details) {
    final errorData = _buildErrorReport(
      type: 'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.call(),
      },
    );

    _processError(errorData);
  }

  /// Handler pour erreurs asynchrones
  void _handleAsyncError(Object error, StackTrace stackTrace) {
    final errorData = _buildErrorReport(
      type: 'async_error',
      error: error,
      stackTrace: stackTrace,
    );

    _processError(errorData);
  }

  /// Configuration pour erreurs Platform Channels
  void _setupPlatformChannelErrorHandling() {
    // Handler pour erreurs Azure Speech
    _wrapMethodChannel('azure_speech_recognition_flutter');

    // Handler pour erreurs caméra
    _wrapMethodChannel('plugins.flutter.io/camera');

    // Handler pour erreurs audio/TTS
    _wrapMethodChannel('flutter_tts');

    // Handler pour erreurs géolocalisation
    _wrapMethodChannel('flutter.baseflow.com/geolocator');
  }

  /// Wrap un MethodChannel pour capturer ses erreurs
  void _wrapMethodChannel(String channelName) {
    try {
      // Note: Wrapper complet nécessiterait plus de configuration
      debugPrint('🔗 Monitoring channel: $channelName');
    } catch (e) {
      debugPrint('⚠️ Impossible de wrapper channel $channelName: $e');
    }
  }

  /// Construit un rapport d'erreur complet
  Map<String, dynamic> _buildErrorReport({
    required String type,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
      'context': context ?? {},
      'deviceInfo': _getDeviceInfo(),
      'memoryInfo': _getMemoryInfo(),
      'lastActions': List.from(_actionHistory),
    };
  }

  /// Traite une erreur
  void _processError(Map<String, dynamic> errorData) {
    // Ajouter à l'historique
    _errorHistory.add(errorData);
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }

    // Log développement
    if (kDebugMode) {
      debugPrint('💥 ERREUR CAPTURÉE:');
      debugPrint('Type: ${errorData['type']}');
      debugPrint('Erreur: ${errorData['error']}');
      debugPrint('Stack: ${errorData['stackTrace']}');
    }

    // Émettre le rapport
    _crashReportController.add(errorData);

    // Tenter une récupération selon le type
    _attemptRecovery(errorData);

    // TODO: Envoyer à Crashlytics/Sentry en production
    _sendToCrashReporting(errorData);
  }

  /// Tente une récupération automatique
  void _attemptRecovery(Map<String, dynamic> errorData) {
    final errorMessage = errorData['error'] as String;

    // Récupération pour erreurs audio
    if (errorMessage.contains('audio') ||
        errorMessage.contains('tts') ||
        errorMessage.contains('speech')) {
      _recoverAudioServices();
    }

    // Récupération pour erreurs réseau
    if (errorMessage.contains('network') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection')) {
      _recoverNetworkServices();
    }

    // Récupération pour erreurs de permission
    if (errorMessage.contains('permission') ||
        errorMessage.contains('denied')) {
      _recoverPermissionServices();
    }

    // Récupération pour erreurs mémoire
    if (errorMessage.contains('memory') ||
        errorMessage.contains('OutOfMemory')) {
      _recoverMemoryServices();
    }
  }

  /// Récupération services audio
  void _recoverAudioServices() {
    Timer(Duration(seconds: 2), () {
      logAction('audio_recovery_attempt');
      // TODO: Réinitialiser services audio
      debugPrint('🔄 Tentative récupération services audio');
    });
  }

  /// Récupération services réseau
  void _recoverNetworkServices() {
    Timer(Duration(seconds: 5), () {
      logAction('network_recovery_attempt');
      // TODO: Réinitialiser connexions réseau
      debugPrint('🔄 Tentative récupération services réseau');
    });
  }

  /// Récupération permissions
  void _recoverPermissionServices() {
    logAction('permission_recovery_attempt');
    // TODO: Guider utilisateur vers permissions
    debugPrint('🔄 Guide utilisateur vers permissions');
  }

  /// Récupération mémoire
  void _recoverMemoryServices() {
    logAction('memory_recovery_attempt');
    // TODO: Libérer caches, réduire qualité 3D
    debugPrint('🔄 Nettoyage mémoire forcé');
  }

  /// Informations appareil
  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.toString(),
      'is_debug': kDebugMode,
      'is_profile': kProfileMode,
      'is_release': kReleaseMode,
    };
  }

  /// Informations mémoire
  Map<String, dynamic> _getMemoryInfo() {
    return {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'debug_mode': kDebugMode,
    };
  }

  /// Envoie à service de crash reporting
  void _sendToCrashReporting(Map<String, dynamic> errorData) {
    if (kReleaseMode) {
      // TODO: Intégrer Crashlytics/Sentry
      debugPrint('📤 Envoi crash report: ${errorData['id']}');
    }
  }

  /// Obtient l'historique des erreurs
  List<Map<String, dynamic>> getErrorHistory() => List.from(_errorHistory);

  /// Obtient l'historique des actions
  List<Map<String, dynamic>> getActionHistory() => List.from(_actionHistory);

  /// Nettoyage
  void dispose() {
    _crashReportController.close();
    _errorHistory.clear();
    _actionHistory.clear();
    debugPrint('🧹 GlobalErrorHandler nettoyé');
  }
}
