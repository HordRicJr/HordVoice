import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/unified_hordvoice_service.dart';
import '../services/emotional_avatar_service.dart';
import '../widgets/spacial_avatar_view.dart';

final spatialOverlayServiceProvider = Provider<SpatialOverlayService>((ref) {
  return SpatialOverlayService();
});

/// Service pour l'avatar spatial persistant avec overlay système
/// Permet à l'IA d'apparaître en superposition sur tout le système Android
@pragma('vm:entry-point')
class SpatialOverlayService {
  static final SpatialOverlayService _instance =
      SpatialOverlayService._internal();
  factory SpatialOverlayService() => _instance;
  SpatialOverlayService._internal();

  // Services connectés
  late UnifiedHordVoiceService _unifiedService;
  late EmotionalAvatarService _emotionalAvatarService;

  // État du service
  bool _isInitialized = false;
  bool _isOverlayActive = false;
  bool _isPersistentMode = false;
  bool _isBackgroundServiceRunning = false;
  bool _isSpeaking = false; // État local pour le speaking

  // Configuration overlay
  late OverlayEntry? _overlayEntry;
  late GlobalKey<NavigatorState> _navigatorKey;
  OverlayState? _overlayState;

  // Streams pour communication
  final StreamController<OverlayEvent> _overlayEventController =
      StreamController<OverlayEvent>.broadcast();
  final StreamController<SpatialContext> _spatialContextController =
      StreamController<SpatialContext>.broadcast();

  // Timers pour gestion arrière-plan
  Timer? _heartbeatTimer;
  Timer? _contextUpdateTimer;
  Timer? _wakeWordListenerTimer;

  // Getters
  Stream<OverlayEvent> get overlayEventStream => _overlayEventController.stream;
  Stream<SpatialContext> get spatialContextStream =>
      _spatialContextController.stream;
  bool get isInitialized => _isInitialized;
  bool get isOverlayActive => _isOverlayActive;
  bool get isPersistentMode => _isPersistentMode;

  /// Initialise le service d'overlay spatial
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SpatialOverlayService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation SpatialOverlayService...');

      // Vérifier et demander les permissions système
      await _requestSystemPermissions();

      // Initialiser les services dépendants
      _unifiedService = UnifiedHordVoiceService();
      _emotionalAvatarService = EmotionalAvatarService();

      // Écouter les changements d'état speaking
      _unifiedService.isSpeakingStream.listen((speaking) {
        _isSpeaking = speaking;
      });

      // Configurer le service d'arrière-plan
      await _initializeBackgroundService();

      // Configurer l'overlay système
      await _setupSystemOverlay();

      // Démarrer l'écoute des événements
      _startEventListeners();

      _isInitialized = true;
      debugPrint('SpatialOverlayService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur initialisation SpatialOverlayService: $e');
      rethrow;
    }
  }

  /// Demande les permissions système nécessaires
  Future<void> _requestSystemPermissions() async {
    debugPrint('Vérification des permissions système...');

    // Permission overlay système
    if (!await Permission.systemAlertWindow.isGranted) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) {
        throw Exception(
          'Permission SYSTEM_ALERT_WINDOW requise pour l\'overlay',
        );
      }
    }

    // Permission microphone
    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Permission microphone requise pour l\'écoute vocale');
      }
    }

    // Permission notifications
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    debugPrint('Permissions système accordées');
  }

  /// Initialise le service d'arrière-plan Flutter
  Future<void> _initializeBackgroundService() async {
    debugPrint('Configuration du service d\'arrière-plan...');

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'hordvoice_spatial_channel',
        initialNotificationTitle: 'HordVoice IA Spatiale',
        initialNotificationContent: 'Ric se connecte à l\'univers spatial...',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: false, // Changé à false pour éviter les problèmes
        foregroundServiceTypes: [AndroidForegroundType.microphone],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onBackgroundServiceStart,
      ),
    );

    _isBackgroundServiceRunning = true;
    debugPrint('Service d\'arrière-plan configuré');
  }

  /// Callback du service d'arrière-plan
  @pragma('vm:entry-point')
  static void _onBackgroundServiceStart(ServiceInstance service) async {
    debugPrint('Service d\'arrière-plan HordVoice démarré');

    // Maintenir le service actif avec un heartbeat simple
    Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('Service d\'arrière-plan HordVoice actif');

      service.invoke('update', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'active',
      });
    });

    // Écouter les commandes depuis l'application principale
    service.on('show_avatar').listen((event) {
      debugPrint('Commande reçue: show_avatar');
      // Activer l'overlay avatar
    });

    service.on('hide_avatar').listen((event) {
      debugPrint('Commande reçue: hide_avatar');
      // Masquer l'overlay avatar
    });

    service.on('hey_ric').listen((event) {
      debugPrint('Wake word détecté: Hey Ric');
      // Déclencher l'activation de l'avatar spatial
    });

    service.on('stop_service').listen((event) {
      debugPrint('Arrêt du service demandé');
      service.stopSelf();
    });
  }

  /// Configure l'overlay système pour l'avatar
  Future<void> _setupSystemOverlay() async {
    debugPrint('Configuration de l\'overlay système...');

    // L'overlay sera créé quand nécessaire
    _overlayEntry = null;

    debugPrint('Overlay système configuré');
  }

  /// Démarre l'écoute des événements système
  void _startEventListeners() {
    debugPrint('Démarrage des listeners d\'événements...');

    // Timer de heartbeat pour maintenir la connexion
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendHeartbeat();
    });

    // Timer de mise à jour du contexte spatial
    _contextUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateSpatialContext();
    });

    // Écouter les commandes vocales wake word
    _wakeWordListenerTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      _checkWakeWordTrigger();
    });

    debugPrint('Listeners d\'événements démarrés');
  }

  /// Active le mode overlay avatar
  Future<void> showSpatialOverlay({
    required SpatialOverlayMode mode,
    SpatialOverlayConfig? config,
  }) async {
    if (_isOverlayActive) {
      debugPrint('Overlay déjà actif');
      return;
    }

    debugPrint('Activation overlay spatial mode: $mode');

    try {
      // Créer l'entry overlay
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildSpatialOverlay(mode, config),
      );

      // Obtenir l'overlay state
      _overlayState = Overlay.of(_navigatorKey.currentContext!);
      _overlayState?.insert(_overlayEntry!);

      _isOverlayActive = true;

      // Envoyer l'événement
      _overlayEventController.add(
        OverlayEvent(
          type: OverlayEventType.shown,
          mode: mode,
          timestamp: DateTime.now(),
        ),
      );

      debugPrint('Overlay spatial activé');
    } catch (e) {
      debugPrint('Erreur activation overlay: $e');
      rethrow;
    }
  }

  /// Construit le widget overlay spatial
  Widget _buildSpatialOverlay(
    SpatialOverlayMode mode,
    SpatialOverlayConfig? config,
  ) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Arrière-plan spatial translucide
          if (mode != SpatialOverlayMode.miniature)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.deepPurple.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

          // Avatar spatial positionné
          Positioned(
            top: _getAvatarPosition(mode).dy,
            left: _getAvatarPosition(mode).dx,
            child: GestureDetector(
              onTap: () => _handleAvatarInteraction(),
              onPanUpdate: (details) => _handleAvatarDrag(details),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _getAvatarSize(mode),
                height: _getAvatarSize(mode),
                child: _buildAvatarWidget(mode),
              ),
            ),
          ),

          // Indicateur vocal si en écoute
          if (_unifiedService.isListening)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildVoiceIndicator(),
            ),

          // Bouton de fermeture si mode plein écran
          if (mode == SpatialOverlayMode.fullscreen)
            Positioned(top: 50, right: 20, child: _buildCloseButton()),
        ],
      ),
    );
  }

  /// Retourne la position de l'avatar selon le mode
  Offset _getAvatarPosition(SpatialOverlayMode mode) {
    switch (mode) {
      case SpatialOverlayMode.fullscreen:
        return const Offset(0, 200);
      case SpatialOverlayMode.overlay:
        return const Offset(50, 150);
      case SpatialOverlayMode.miniature:
        return const Offset(20, 100);
    }
  }

  /// Retourne la taille de l'avatar selon le mode
  double _getAvatarSize(SpatialOverlayMode mode) {
    switch (mode) {
      case SpatialOverlayMode.fullscreen:
        return 300;
      case SpatialOverlayMode.overlay:
        return 200;
      case SpatialOverlayMode.miniature:
        return 80;
    }
  }

  /// Construit le widget avatar
  Widget _buildAvatarWidget(SpatialOverlayMode mode) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const SpacialAvatarView(),
    );
  }

  /// Construit l'indicateur vocal
  Widget _buildVoiceIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, color: Colors.blue, size: 20),
          SizedBox(width: 10),
          Text(
            'Ric vous écoute...',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Construit le bouton de fermeture
  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: hideSpatialOverlay,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
    );
  }

  /// Gère l'interaction avec l'avatar
  void _handleAvatarInteraction() {
    debugPrint('Interaction avec l\'avatar spatial');

    // Démarrer ou arrêter l'écoute
    if (_unifiedService.isListening) {
      _unifiedService.stopListening();
    } else {
      _unifiedService.startListening();
    }
  }

  /// Gère le glissement de l'avatar
  void _handleAvatarDrag(DragUpdateDetails details) {
    // Implémenter le déplacement de l'avatar
    debugPrint('Avatar déplacé: ${details.delta}');
  }

  /// Masque l'overlay spatial
  Future<void> hideSpatialOverlay() async {
    if (!_isOverlayActive) {
      debugPrint('Aucun overlay actif');
      return;
    }

    debugPrint('Masquage overlay spatial');

    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOverlayActive = false;

      // Envoyer l'événement
      _overlayEventController.add(
        OverlayEvent(
          type: OverlayEventType.hidden,
          mode: null,
          timestamp: DateTime.now(),
        ),
      );

      debugPrint('Overlay spatial masqué');
    } catch (e) {
      debugPrint('Erreur masquage overlay: $e');
    }
  }

  /// Active le mode persistant
  Future<void> enablePersistentMode() async {
    if (_isPersistentMode) return;

    debugPrint('Activation mode persistant');

    _isPersistentMode = true;

    // Démarrer le service d'arrière-plan
    if (!_isBackgroundServiceRunning) {
      await FlutterBackgroundService().startService();
      _isBackgroundServiceRunning = true;
    }

    // Configurer l'écoute wake word
    await _enableWakeWordDetection();

    debugPrint('Mode persistant activé');
  }

  /// Désactive le mode persistant
  Future<void> disablePersistentMode() async {
    if (!_isPersistentMode) return;

    debugPrint('Désactivation mode persistant');

    _isPersistentMode = false;

    // Arrêter le service d'arrière-plan
    if (_isBackgroundServiceRunning) {
      FlutterBackgroundService().invoke('stopService');
      _isBackgroundServiceRunning = false;
    }

    // Masquer l'overlay s'il est actif
    if (_isOverlayActive) {
      await hideSpatialOverlay();
    }

    debugPrint('Mode persistant désactivé');
  }

  /// Configure l'écoute du wake word
  Future<void> _enableWakeWordDetection() async {
    debugPrint('Configuration détection wake word...');

    // Configuration avec le service unifié - utiliser les streams existants
    _unifiedService.wakeWordStream.listen((wakeWordDetected) {
      if (wakeWordDetected && _isPersistentMode && !_isOverlayActive) {
        debugPrint('Wake word détecté - Activation overlay');

        showSpatialOverlay(
          mode: SpatialOverlayMode.overlay,
          config: SpatialOverlayConfig(
            autoHide: true,
            hideDelay: const Duration(seconds: 10),
          ),
        );
      }
    });

    debugPrint('Détection wake word configurée');
  }

  /// Vérifie les déclencheurs wake word
  void _checkWakeWordTrigger() {
    // Cette méthode est maintenant gérée par le stream listener
    // Conservée pour compatibilité
  }

  /// Envoie un heartbeat pour maintenir le service
  void _sendHeartbeat() {
    if (!_isBackgroundServiceRunning) return;

    FlutterBackgroundService().invoke('heartbeat', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'overlayActive': _isOverlayActive,
      'persistentMode': _isPersistentMode,
    });
  }

  /// Met à jour le contexte spatial
  void _updateSpatialContext() {
    final context = SpatialContext(
      timestamp: DateTime.now(),
      isAppInForeground: true, // À implémenter
      currentActivity: _getCurrentActivity(),
      emotionalState: _emotionalAvatarService.getCurrentEmotion().toString(),
      interactionMode: _getCurrentInteractionMode(),
    );

    _spatialContextController.add(context);
  }

  /// Obtient l'activité actuelle de l'utilisateur
  String _getCurrentActivity() {
    // À implémenter avec AppState
    return 'unknown';
  }

  /// Obtient le mode d'interaction actuel
  SpatialInteractionMode _getCurrentInteractionMode() {
    if (_unifiedService.isListening) {
      return SpatialInteractionMode.listening;
    } else if (_isSpeaking) {
      return SpatialInteractionMode.speaking;
    } else {
      return SpatialInteractionMode.idle;
    }
  }

  /// Configure le navigateur key pour overlay
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Libère les ressources
  void dispose() {
    debugPrint('Libération SpatialOverlayService');

    _heartbeatTimer?.cancel();
    _contextUpdateTimer?.cancel();
    _wakeWordListenerTimer?.cancel();

    _overlayEventController.close();
    _spatialContextController.close();

    if (_isOverlayActive) {
      hideSpatialOverlay();
    }

    if (_isBackgroundServiceRunning) {
      FlutterBackgroundService().invoke('stopService');
    }

    _isInitialized = false;
  }
}

// Enums et classes de support

enum SpatialOverlayMode {
  fullscreen, // Plein écran avec arrière-plan spatial
  overlay, // Overlay translucide sur l'écran actuel
  miniature, // Miniature flottante
}

enum OverlayEventType { shown, hidden, interacted, moved }

enum SpatialInteractionMode { idle, listening, speaking, thinking }

class OverlayEvent {
  final OverlayEventType type;
  final SpatialOverlayMode? mode;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  OverlayEvent({
    required this.type,
    this.mode,
    required this.timestamp,
    this.data,
  });
}

class SpatialOverlayConfig {
  final bool autoHide;
  final Duration? hideDelay;
  final bool draggable;
  final Offset? initialPosition;
  final double? size;

  SpatialOverlayConfig({
    this.autoHide = false,
    this.hideDelay,
    this.draggable = true,
    this.initialPosition,
    this.size,
  });
}

class SpatialContext {
  final DateTime timestamp;
  final bool isAppInForeground;
  final String currentActivity;
  final String emotionalState;
  final SpatialInteractionMode interactionMode;

  SpatialContext({
    required this.timestamp,
    required this.isAppInForeground,
    required this.currentActivity,
    required this.emotionalState,
    required this.interactionMode,
  });
}
