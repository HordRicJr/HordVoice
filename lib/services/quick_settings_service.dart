import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/unified_hordvoice_service.dart';

/// Service pour gérer les Quick Settings Android
class QuickSettingsService {
  static final QuickSettingsService _instance =
      QuickSettingsService._internal();
  factory QuickSettingsService() => _instance;
  QuickSettingsService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.hordvoice/quick_settings',
  );

  late UnifiedHordVoiceService _unifiedService;
  bool _isInitialized = false;
  bool _isListening = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _unifiedService = UnifiedHordVoiceService();
      await _unifiedService.initialize();

      // Configurer les handlers pour les appels depuis Android
      _channel.setMethodCallHandler(_handleMethodCall);

      _isInitialized = true;
      debugPrint('QuickSettingsService initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation QuickSettingsService: $e');
      rethrow;
    }
  }

  /// Handler pour les appels depuis le Quick Settings Android
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'toggleListening':
          return await _handleToggleListening(call.arguments);

        case 'getListeningState':
          return _getListeningState();

        default:
          debugPrint('Méthode non reconnue: ${call.method}');
          return null;
      }
    } catch (e) {
      debugPrint('Erreur dans _handleMethodCall: $e');
      return null;
    }
  }

  /// Gérer le toggle on/off depuis Quick Settings
  Future<bool> _handleToggleListening(dynamic arguments) async {
    if (!_isInitialized) {
      debugPrint('Service non initialisé');
      return false;
    }

    try {
      final Map<String, dynamic> args = Map<String, dynamic>.from(
        arguments ?? {},
      );
      final bool shouldBeActive = args['isActive'] ?? false;
      final String source = args['source'] ?? 'unknown';

      debugPrint('Toggle listening depuis $source: $shouldBeActive');

      if (shouldBeActive && !_isListening) {
        // Démarrer l'écoute
        await _startListening();
      } else if (!shouldBeActive && _isListening) {
        // Arrêter l'écoute
        await _stopListening();
      }

      return _isListening;
    } catch (e) {
      debugPrint('Erreur toggle listening: $e');
      return false;
    }
  }

  /// Démarrer l'écoute voice
  Future<void> _startListening() async {
    try {
      await _unifiedService.startListening();
      _isListening = true;

      // Optionnel: jouer un son de confirmation
      await _unifiedService.speakText("Assistant vocal activé");

      debugPrint('Écoute démarrée depuis Quick Settings');
    } catch (e) {
      debugPrint('Erreur démarrage écoute: $e');
      _isListening = false;
    }
  }

  /// Arrêter l'écoute
  Future<void> _stopListening() async {
    try {
      await _unifiedService.stopListening();
      _isListening = false;

      // Optionnel: jouer un son de confirmation
      await _unifiedService.speakText("Assistant vocal désactivé");

      debugPrint('Écoute arrêtée depuis Quick Settings');
    } catch (e) {
      debugPrint('Erreur arrêt écoute: $e');
    }
  }

  /// Obtenir l'état actuel d'écoute
  bool _getListeningState() {
    return _isListening;
  }

  /// Mettre à jour l'état du Quick Settings depuis Flutter
  Future<void> updateQuickSettingsState(bool isListening) async {
    try {
      _isListening = isListening;

      // Notifier Android du changement d'état
      await _channel.invokeMethod('updateTileState', {
        'isListening': isListening,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Erreur mise à jour Quick Settings: $e');
    }
  }

  /// Tester la communication Quick Settings
  Future<bool> testQuickSettingsConnection() async {
    try {
      final result = await _channel.invokeMethod('test', {'ping': 'flutter'});
      debugPrint('Test Quick Settings: $result');
      return true;
    } catch (e) {
      debugPrint('Erreur test Quick Settings: $e');
      return false;
    }
  }

  /// Alias pour testQuickSettingsConnection
  Future<bool> testQuickSettings() async {
    return await testQuickSettingsConnection();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  void dispose() {
    _isInitialized = false;
    _isListening = false;
  }
}
