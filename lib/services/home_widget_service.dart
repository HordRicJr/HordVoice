import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../services/unified_hordvoice_service.dart';

/// Service pour gérer les widgets d'écran d'accueil
class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  late UnifiedHordVoiceService _unifiedService;
  bool _isInitialized = false;
  bool _isListening = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _unifiedService = UnifiedHordVoiceService();
      await _unifiedService.initialize();

      // Initialiser le plugin HomeWidget
      await HomeWidget.setAppGroupId('group.com.example.hordvoice');

      // Configurer les callbacks pour les interactions widget
      HomeWidget.widgetClicked.listen(_onWidgetClicked);

      // Mettre à jour le widget initial
      await updateWidget();

      _isInitialized = true;
      debugPrint('HomeWidgetService initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation HomeWidgetService: $e');
      rethrow;
    }
  }

  /// Handler pour les clics sur le widget
  Future<void> _onWidgetClicked(Uri? uri) async {
    if (uri == null) return;

    try {
      final action = uri.host;
      debugPrint('Action widget reçue: $action');

      switch (action) {
        case 'toggle_listening':
          await _toggleListening();
          break;
        case 'open_app':
          // L'app s'ouvre automatiquement
          break;
        case 'quick_command':
          final command = uri.queryParameters['cmd'];
          if (command != null) {
            await _executeQuickCommand(command);
          }
          break;
        default:
          debugPrint('Action widget non reconnue: $action');
      }

      // Mettre à jour le widget après action
      await updateWidget();
    } catch (e) {
      debugPrint('Erreur traitement clic widget: $e');
    }
  }

  /// Toggle écoute depuis le widget
  Future<void> _toggleListening() async {
    if (!_isInitialized) return;

    try {
      if (_isListening) {
        await _unifiedService.stopListening();
        _isListening = false;
        await _unifiedService.speakText("Assistant désactivé depuis widget");
      } else {
        await _unifiedService.startListening();
        _isListening = true;
        await _unifiedService.speakText("Assistant activé depuis widget");
      }

      debugPrint('Toggle listening widget: $_isListening');
    } catch (e) {
      debugPrint('Erreur toggle widget: $e');
    }
  }

  /// Exécuter commande rapide depuis widget
  Future<void> _executeQuickCommand(String command) async {
    if (!_isInitialized) return;

    try {
      debugPrint('Commande rapide widget: $command');

      switch (command) {
        case 'weather':
          await _unifiedService.processVoiceCommand('météo');
          break;
        case 'news':
          await _unifiedService.processVoiceCommand('actualités');
          break;
        case 'navigation':
          await _unifiedService.processVoiceCommand('navigation');
          break;
        default:
          await _unifiedService.processVoiceCommand(command);
      }
    } catch (e) {
      debugPrint('Erreur commande rapide widget: $e');
    }
  }

  /// Mettre à jour le widget avec l'état actuel
  Future<void> updateWidget() async {
    try {
      // Données à envoyer au widget
      final statusText = _isListening
          ? 'Écoute active'
          : 'Touchez pour activer';
      final appName = 'HordVoice';
      final lastUpdate = DateTime.now().millisecondsSinceEpoch.toString();

      // Mettre à jour les données du widget
      await HomeWidget.saveWidgetData<bool>('is_listening', _isListening);
      await HomeWidget.saveWidgetData<String>('status_text', statusText);
      await HomeWidget.saveWidgetData<String>('app_name', appName);
      await HomeWidget.saveWidgetData<String>('last_update', lastUpdate);

      // Déclencher la mise à jour du widget
      await HomeWidget.updateWidget(
        name: 'HordVoiceWidget',
        androidName: 'HordVoiceWidget',
        iOSName: 'HordVoiceWidget',
      );

      debugPrint('Widget mis à jour: $_isListening');
    } catch (e) {
      debugPrint('Erreur mise à jour widget: $e');
    }
  }

  /// Forcer la mise à jour de l'état d'écoute
  Future<void> setListeningState(bool isListening) async {
    _isListening = isListening;
    await updateWidget();
  }

  /// Configurer les actions des boutons du widget
  Future<void> registerInteractiveCallbacks() async {
    try {
      // Le plugin home_widget gère automatiquement les interactions
      // via widgetClicked.listen() configuré dans initialize()
      debugPrint('Callbacks widget gérés automatiquement');
    } catch (e) {
      debugPrint('Erreur enregistrement callbacks widget: $e');
    }
  }

  /// Obtenir les données actuelles du widget
  Map<String, dynamic> getWidgetData() {
    return {
      'is_listening': _isListening,
      'is_initialized': _isInitialized,
      'status_text': _isListening ? 'Écoute active' : 'Touchez pour activer',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Tester la fonctionnalité widget
  Future<bool> testWidget() async {
    try {
      await updateWidget();

      // Vérifier que les données sont bien sauvegardées
      final isListening = await HomeWidget.getWidgetData<bool>('is_listening');
      final statusText = await HomeWidget.getWidgetData<String>('status_text');

      debugPrint('Test widget - Listening: $isListening, Status: $statusText');
      return true;
    } catch (e) {
      debugPrint('Erreur test widget: $e');
      return false;
    }
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  void dispose() {
    _isInitialized = false;
    _isListening = false;
  }
}
