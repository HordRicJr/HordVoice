import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/unified_hordvoice_service.dart';

/// Service pour gérer les Quick Settings Android avec contrôles vocaux
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
        await _startListening();
      } else if (!shouldBeActive && _isListening) {
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
      await _unifiedService.speakText("Assistant vocal activé");
      debugPrint('Écoute démarrée depuis Quick Settings');
    } catch (e) {
      debugPrint('Erreur démarrage écoute: $e');
    }
  }

  /// Arrêter l'écoute
  Future<void> _stopListening() async {
    try {
      await _unifiedService.stopListening();
      _isListening = false;
      await _unifiedService.speakText("Assistant vocal désactivé");
      debugPrint('Écoute arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt écoute: $e');
    }
  }

  /// Contrôle vocal de la luminosité
  Future<void> handleBrightnessVoiceCommand(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      if (lowerCommand.contains('luminosité') ||
          lowerCommand.contains('écran')) {
        if (lowerCommand.contains('augmente') ||
            lowerCommand.contains('plus forte')) {
          await _setBrightness(1.0);
          await _unifiedService.speakText("Luminosité au maximum");
        } else if (lowerCommand.contains('diminue') ||
            lowerCommand.contains('plus faible')) {
          await _setBrightness(0.2);
          await _unifiedService.speakText("Luminosité réduite");
        } else if (lowerCommand.contains('moyenne') ||
            lowerCommand.contains('normale')) {
          await _setBrightness(0.5);
          await _unifiedService.speakText("Luminosité normale");
        }
      }
    } catch (e) {
      debugPrint('Erreur contrôle vocal luminosité: $e');
      await _unifiedService.speakText("Erreur de contrôle de luminosité");
    }
  }

  /// Contrôle vocal du volume
  Future<void> handleVolumeVoiceCommand(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      if (lowerCommand.contains('volume') || lowerCommand.contains('son')) {
        if (lowerCommand.contains('augmente') ||
            lowerCommand.contains('plus fort')) {
          await _setVolume(1.0);
          await _unifiedService.speakText("Volume au maximum");
        } else if (lowerCommand.contains('diminue') ||
            lowerCommand.contains('plus faible')) {
          await _setVolume(0.3);
          await _unifiedService.speakText("Volume réduit");
        } else if (lowerCommand.contains('muet') ||
            lowerCommand.contains('silence')) {
          await _setVolume(0.0);
          await _unifiedService.speakText("Volume coupé");
        }
      }
    } catch (e) {
      debugPrint('Erreur contrôle vocal volume: $e');
      await _unifiedService.speakText("Erreur de contrôle du volume");
    }
  }

  /// Contrôle vocal du WiFi/Bluetooth
  Future<void> handleConnectivityVoiceCommand(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      if (lowerCommand.contains('wifi')) {
        if (lowerCommand.contains('active') ||
            lowerCommand.contains('allume')) {
          await _toggleWifi(true);
          await _unifiedService.speakText("WiFi activé");
        } else if (lowerCommand.contains('désactive') ||
            lowerCommand.contains('éteint')) {
          await _toggleWifi(false);
          await _unifiedService.speakText("WiFi désactivé");
        }
      } else if (lowerCommand.contains('bluetooth')) {
        if (lowerCommand.contains('active') ||
            lowerCommand.contains('allume')) {
          await _toggleBluetooth(true);
          await _unifiedService.speakText("Bluetooth activé");
        } else if (lowerCommand.contains('désactive') ||
            lowerCommand.contains('éteint')) {
          await _toggleBluetooth(false);
          await _unifiedService.speakText("Bluetooth désactivé");
        }
      }
    } catch (e) {
      debugPrint('Erreur contrôle vocal connectivité: $e');
      await _unifiedService.speakText("Erreur de contrôle de connectivité");
    }
  }

  /// Modifier la luminosité via platform channel
  Future<void> _setBrightness(double brightness) async {
    try {
      await _channel.invokeMethod('setBrightness', {
        'brightness': brightness.clamp(0.0, 1.0),
      });
    } catch (e) {
      debugPrint('Erreur modification luminosité: $e');
    }
  }

  /// Modifier le volume
  Future<void> _setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      debugPrint('Erreur modification volume: $e');
    }
  }

  /// Toggle WiFi
  Future<void> _toggleWifi(bool enable) async {
    try {
      await _channel.invokeMethod('toggleWifi', {'enable': enable});
    } catch (e) {
      debugPrint('Erreur toggle WiFi: $e');
    }
  }

  /// Toggle Bluetooth
  Future<void> _toggleBluetooth(bool enable) async {
    try {
      await _channel.invokeMethod('toggleBluetooth', {'enable': enable});
    } catch (e) {
      debugPrint('Erreur toggle Bluetooth: $e');
    }
  }

  /// Contrôle vocal des paramètres téléphone avancés
  Future<void> handlePhoneSettingsVoiceCommand(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      if (lowerCommand.contains('mode avion')) {
        if (lowerCommand.contains('active') ||
            lowerCommand.contains('allume')) {
          await _toggleAirplaneMode(true);
          await _unifiedService.speakText("Mode avion activé");
        } else if (lowerCommand.contains('désactive') ||
            lowerCommand.contains('éteint')) {
          await _toggleAirplaneMode(false);
          await _unifiedService.speakText("Mode avion désactivé");
        }
      } else if (lowerCommand.contains('données mobiles')) {
        if (lowerCommand.contains('active') ||
            lowerCommand.contains('allume')) {
          await _toggleMobileData(true);
          await _unifiedService.speakText("Données mobiles activées");
        } else if (lowerCommand.contains('désactive') ||
            lowerCommand.contains('éteint')) {
          await _toggleMobileData(false);
          await _unifiedService.speakText("Données mobiles désactivées");
        }
      } else if (lowerCommand.contains('rotation') ||
          lowerCommand.contains('orientation')) {
        if (lowerCommand.contains('active') ||
            lowerCommand.contains('allume')) {
          await _toggleAutoRotate(true);
          await _unifiedService.speakText("Rotation automatique activée");
        } else if (lowerCommand.contains('désactive') ||
            lowerCommand.contains('éteint')) {
          await _toggleAutoRotate(false);
          await _unifiedService.speakText("Rotation automatique désactivée");
        }
      }
    } catch (e) {
      debugPrint('Erreur contrôle vocal paramètres téléphone: $e');
      await _unifiedService.speakText("Erreur de contrôle des paramètres");
    }
  }

  /// Toggle mode avion
  Future<void> _toggleAirplaneMode(bool enable) async {
    try {
      await _channel.invokeMethod('toggleAirplaneMode', {'enable': enable});
    } catch (e) {
      debugPrint('Erreur toggle mode avion: $e');
    }
  }

  /// Toggle données mobiles
  Future<void> _toggleMobileData(bool enable) async {
    try {
      await _channel.invokeMethod('toggleMobileData', {'enable': enable});
    } catch (e) {
      debugPrint('Erreur toggle données mobiles: $e');
    }
  }

  /// Toggle rotation automatique
  Future<void> _toggleAutoRotate(bool enable) async {
    try {
      await _channel.invokeMethod('toggleAutoRotate', {'enable': enable});
    } catch (e) {
      debugPrint('Erreur toggle rotation auto: $e');
    }
  }

  bool _getListeningState() => _isListening;

  /// Méthodes utilitaires
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  void dispose() {
    _isInitialized = false;
    _isListening = false;
  }
}
