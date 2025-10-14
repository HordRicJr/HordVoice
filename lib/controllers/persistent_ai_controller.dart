import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/unified_hordvoice_service.dart';
import '../services/spatial_overlay_service.dart';

final persistentAIControllerProvider = Provider<PersistentAIController>((ref) {
  return PersistentAIController();
});

/// Contrôleur pour gérer l'IA persistante et l'avatar spatial
/// Gère l'activation/désactivation, les transitions et la cohérence
class PersistentAIController {
  static final PersistentAIController _instance =
      PersistentAIController._internal();
  factory PersistentAIController() => _instance;
  PersistentAIController._internal();

  // Services
  late UnifiedHordVoiceService _unifiedService;
  SpatialOverlayService? _spatialOverlayService;

  // État du contrôleur
  bool _isInitialized = false;
  bool _isPersistentModeActive = false;
  SpatialContext _currentContext = SpatialContextExtension.unknown();

  // Callbacks pour les événements UI
  VoidCallback? _onAvatarShown;
  VoidCallback? _onAvatarHidden;
  Function(String)? _onContextChanged;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPersistentModeActive => _isPersistentModeActive;
  SpatialContext get currentContext => _currentContext;

  /// Initialise le contrôleur d'IA persistante
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PersistentAIController déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation PersistentAIController...');

      // Obtenir les services
      _unifiedService = UnifiedHordVoiceService();

      // S'assurer que UnifiedHordVoiceService est initialisé
      if (!_unifiedService.isInitialized) {
        debugPrint(
          '⚠️ UnifiedHordVoiceService non initialisé - Initialisation en cours...',
        );
        await _unifiedService.initialize();
      }

      // S'assurer que les services secondaires sont initialisés
      await _unifiedService.initializeSecondary();

      _spatialOverlayService = _unifiedService.spatialOverlayService;

      // Écouter les événements de l'overlay
      _spatialOverlayService?.overlayEventStream.listen(_handleOverlayEvent);

      // Ignorer temporairement le spatial context stream pour éviter conflit de types
      // _spatialOverlayService.spatialContextStream.listen((context) {
      //   _handleContextChange(context);
      // });

      _isInitialized = true;
      debugPrint('PersistentAIController initialisé');
    } catch (e) {
      debugPrint('Erreur initialisation PersistentAIController: $e');
      rethrow;
    }
  }

  /// Active l'IA persistante avec l'univers spatial
  Future<void> enablePersistentAI({
    bool showWelcomeAnimation = true,
    SpatialTransitionConfig? transitionConfig,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ PersistentAIController non initialisé - Initialisation...');
      await initialize();
    }

    if (_isPersistentModeActive) {
      debugPrint('IA persistante déjà active');
      return;
    }

    debugPrint('Activation IA persistante avec univers spatial...');

    try {
      // Vérification supplémentaire des services
      if (!_unifiedService.isInitialized) {
        debugPrint('⚠️ UnifiedHordVoiceService non prêt - Attente...');
        await _unifiedService.initialize();
        await _unifiedService.initializeSecondary();
      }

      // Haptic feedback pour indiquer l'activation
      HapticFeedback.mediumImpact();

      // Animation de bienvenue si demandée
      if (showWelcomeAnimation) {
        await _playWelcomeSequence(transitionConfig);
      }

      // Activer le mode persistant
      debugPrint('Activation mode persistant');
      await _unifiedService.enablePersistentAI();
      
      // Vérifier que le service spatial est disponible
      if (_spatialOverlayService == null) {
        debugPrint('⚠️ Service spatial non disponible');
        return;
      }

      _isPersistentModeActive = true;
      _updateContext(SpatialContextExtension.persistentActive());

      debugPrint('✅ IA persistante activée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur activation IA persistante: $e');
      // Ne pas rethrow pour éviter les crashes
    }
  }

  /// Désactive l'IA persistante
  Future<void> disablePersistentAI({bool showGoodbyeAnimation = true}) async {
    if (!_isPersistentModeActive) {
      debugPrint('IA persistante déjà désactivée');
      return;
    }

    debugPrint('Désactivation IA persistante...');

    try {
      // Animation d'au revoir si demandée
      if (showGoodbyeAnimation) {
        await _playGoodbyeSequence();
      }

      // Désactiver le mode persistant
      await _unifiedService.disablePersistentAI();

      _isPersistentModeActive = false;
      _updateContext(SpatialContextExtension.inactive());

      // Haptic feedback pour indiquer la désactivation
      HapticFeedback.lightImpact();

      debugPrint('IA persistante désactivée');
    } catch (e) {
      debugPrint('Erreur désactivation IA persistante: $e');
    }
  }

  /// Affiche l'avatar pour une interaction contextuelle
  Future<void> showContextualAvatar({
    required SpatialInteractionContext context,
    Duration? autoHideDelay,
  }) async {
    debugPrint('Affichage avatar contextuel: ${context.type}');

    if (_spatialOverlayService == null) {
      debugPrint('Service spatial non disponible');
      return;
    }

    try {
      // Choisir le mode d'affichage selon le contexte
      final mode = _getOverlayModeForContext(context);

      final config = SpatialOverlayConfig(
        autoHide: autoHideDelay != null,
        hideDelay: autoHideDelay,
        initialPosition: _getPositionForContext(context),
      );

      // Afficher l'avatar avec animation contextuelle
      await _unifiedService.showSpatialAvatar(mode: mode, config: config);

      _updateContext(SpatialContextExtension.interacting(context));
    } catch (e) {
      debugPrint('Erreur affichage avatar contextuel: $e');
    }
  }

  /// Gère les notifications et interventions spontanées
  Future<void> showSpontaneousIntervention({
    required SpontaneousInterventionType type,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    debugPrint('Intervention spontanée: $type');

    try {
      // Animation d'apparition selon le type
      await _showInterventionAnimation(type);

      // Afficher l'avatar en mode miniature
      await _unifiedService.showSpatialAvatar(
        mode: SpatialOverlayMode.miniature,
        config: SpatialOverlayConfig(
          autoHide: true,
          hideDelay: const Duration(seconds: 8),
          initialPosition: _getInterventionPosition(type),
        ),
      );

      // Jouer le message avec synchronisation audio-visuelle
      await _playMessageWithSync(message, data);

      _updateContext(SpatialContextExtension.intervening(type, message));
    } catch (e) {
      debugPrint('Erreur intervention spontanée: $e');
    }
  }

  /// Joue la séquence de bienvenue spatiale
  Future<void> _playWelcomeSequence(SpatialTransitionConfig? config) async {
    debugPrint('Séquence de bienvenue spatiale...');

    // Animation d'entrée dans l'univers spatial
    await _unifiedService.showSpatialAvatar(
      mode: SpatialOverlayMode.fullscreen,
      config: SpatialOverlayConfig(
        autoHide: true,
        hideDelay: const Duration(seconds: 5),
      ),
    );

    // Message de bienvenue avec voix
    await _unifiedService.speakWithEmotion(
      'Bienvenue dans mon univers spatial. Je suis maintenant disponible partout sur votre appareil.',
      emotion: 'welcome',
    );

    // Transition vers mode arrière-plan
    await Future.delayed(const Duration(seconds: 2));
    await _unifiedService.hideSpatialAvatar();

    debugPrint('Séquence de bienvenue terminée');
  }

  /// Joue la séquence d'au revoir
  Future<void> _playGoodbyeSequence() async {
    debugPrint('Séquence d\'au revoir...');

    // Apparition pour dire au revoir
    await _unifiedService.showSpatialAvatar(
      mode: SpatialOverlayMode.overlay,
      config: SpatialOverlayConfig(
        autoHide: true,
        hideDelay: const Duration(seconds: 4),
      ),
    );

    // Message d'au revoir
    await _unifiedService.speakWithEmotion(
      'À bientôt dans l\'espace !',
      emotion: 'goodbye',
    );

    await Future.delayed(const Duration(seconds: 2));
    await _unifiedService.hideSpatialAvatar();

    debugPrint('Séquence d\'au revoir terminée');
  }

  /// Affiche l'animation d'intervention
  Future<void> _showInterventionAnimation(
    SpontaneousInterventionType type,
  ) async {
    switch (type) {
      case SpontaneousInterventionType.weatherAlert:
        // Animation météo avec effets de nuages/soleil
        break;
      case SpontaneousInterventionType.calendarReminder:
        // Animation horloge avec temps qui clignote
        break;
      case SpontaneousInterventionType.messageReceived:
        // Animation cube lumineux qui s'ouvre
        break;
      case SpontaneousInterventionType.batteryLow:
        // Animation indicateur batterie rouge
        break;
      case SpontaneousInterventionType.suggestion:
        // Animation idée avec ampoule
        break;
    }

    // Animation générique de portail spatial
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Joue un message avec synchronisation audio-visuelle
  Future<void> _playMessageWithSync(
    String message,
    Map<String, dynamic>? data,
  ) async {
    // Phase intro visuelle
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase de parole avec lumière pulsée
    await _unifiedService.speakWithEmotion(message);

    // Phase conclusion avec geste
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Obtient le mode d'overlay pour un contexte donné
  SpatialOverlayMode _getOverlayModeForContext(
    SpatialInteractionContext context,
  ) {
    switch (context.type) {
      case SpatialInteractionType.wakeWord:
        return SpatialOverlayMode.overlay;
      case SpatialInteractionType.notification:
        return SpatialOverlayMode.miniature;
      case SpatialInteractionType.conversation:
        return SpatialOverlayMode.fullscreen;
      case SpatialInteractionType.assistance:
        return SpatialOverlayMode.overlay;
    }
  }

  /// Obtient la position pour un contexte donné
  Offset _getPositionForContext(SpatialInteractionContext context) {
    switch (context.type) {
      case SpatialInteractionType.wakeWord:
        return const Offset(50, 200);
      case SpatialInteractionType.notification:
        return const Offset(20, 100);
      case SpatialInteractionType.conversation:
        return const Offset(0, 150);
      case SpatialInteractionType.assistance:
        return const Offset(30, 180);
    }
  }

  /// Obtient la position pour une intervention spontanée
  Offset _getInterventionPosition(SpontaneousInterventionType type) {
    switch (type) {
      case SpontaneousInterventionType.weatherAlert:
        return const Offset(20, 80);
      case SpontaneousInterventionType.calendarReminder:
        return const Offset(20, 120);
      case SpontaneousInterventionType.messageReceived:
        return const Offset(20, 160);
      case SpontaneousInterventionType.batteryLow:
        return const Offset(20, 200);
      case SpontaneousInterventionType.suggestion:
        return const Offset(20, 240);
    }
  }

  /// Gère les événements de l'overlay
  void _handleOverlayEvent(OverlayEvent event) {
    debugPrint('Événement overlay: ${event.type}');

    switch (event.type) {
      case OverlayEventType.shown:
        _onAvatarShown?.call();
        break;
      case OverlayEventType.hidden:
        _onAvatarHidden?.call();
        break;
      case OverlayEventType.interacted:
        // Gérer les interactions
        break;
      case OverlayEventType.moved:
        // Gérer les déplacements
        break;
    }
  }

  /// Met à jour le contexte spatial
  void _updateContext(SpatialContext context) {
    _currentContext = context;
    _onContextChanged?.call(context.currentActivity);
  }

  /// Configure les callbacks d'événements UI
  void setEventCallbacks({
    VoidCallback? onAvatarShown,
    VoidCallback? onAvatarHidden,
    Function(String)? onContextChanged,
  }) {
    _onAvatarShown = onAvatarShown;
    _onAvatarHidden = onAvatarHidden;
    _onContextChanged = onContextChanged;
  }

  /// Libère les ressources
  void dispose() {
    debugPrint('Libération PersistentAIController');
    _isInitialized = false;
    _isPersistentModeActive = false;
  }
}

// Classes de support pour le contexte spatial

// Extension de SpatialContext pour ajouter des factory methods
extension SpatialContextExtension on SpatialContext {
  static SpatialContext unknown() => SpatialContext(
    timestamp: DateTime.now(),
    currentActivity: 'unknown',
    isAppInForeground: true,
    interactionMode: SpatialInteractionMode.idle,
    emotionalState: 'neutral',
  );

  static SpatialContext persistentActive() => SpatialContext(
    timestamp: DateTime.now(),
    currentActivity: 'persistent_active',
    isAppInForeground: false,
    interactionMode: SpatialInteractionMode.idle,
    emotionalState: 'neutral',
  );

  static SpatialContext inactive() => SpatialContext(
    timestamp: DateTime.now(),
    currentActivity: 'inactive',
    isAppInForeground: true,
    interactionMode: SpatialInteractionMode.idle,
    emotionalState: 'neutral',
  );

  static SpatialContext interacting(SpatialInteractionContext context) =>
      SpatialContext(
        timestamp: DateTime.now(),
        currentActivity: 'interacting_${context.type.toString()}',
        isAppInForeground: false,
        interactionMode: SpatialInteractionMode.listening,
        emotionalState: 'engaged',
      );

  static SpatialContext intervening(
    SpontaneousInterventionType type,
    String message,
  ) => SpatialContext(
    timestamp: DateTime.now(),
    currentActivity: 'intervening_${type.toString()}',
    isAppInForeground: false,
    interactionMode: SpatialInteractionMode.speaking,
    emotionalState: 'active',
  );
}

class SpatialTransitionConfig {
  final Duration duration;
  final Curve curve;
  final bool withSound;
  final bool withHaptic;

  SpatialTransitionConfig({
    this.duration = const Duration(seconds: 3),
    this.curve = Curves.easeInOut,
    this.withSound = true,
    this.withHaptic = true,
  });
}

class SpatialInteractionContext {
  final SpatialInteractionType type;
  final String trigger;
  final Map<String, dynamic> data;

  SpatialInteractionContext({
    required this.type,
    required this.trigger,
    this.data = const {},
  });
}

enum SpatialInteractionType {
  wakeWord, // Déclenchement par wake word
  notification, // Notification système
  conversation, // Conversation longue
  assistance, // Aide contextuelle
}

enum SpontaneousInterventionType {
  weatherAlert, // Alerte météo
  calendarReminder, // Rappel agenda
  messageReceived, // Message reçu
  batteryLow, // Batterie faible
  suggestion, // Suggestion intelligente
}
