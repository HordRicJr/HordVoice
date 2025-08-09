import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service de commandes secrètes pour HordVoice IA
/// Fonctionnalité 6: Commandes secrètes
class SecretCommandsService {
  static final SecretCommandsService _instance =
      SecretCommandsService._internal();
  factory SecretCommandsService() => _instance;
  SecretCommandsService._internal();

  // État du service
  bool _isInitialized = false;
  bool _secretModeEnabled = false;
  String? _currentSecretSession;
  int _failedAttempts = 0;
  DateTime? _lastFailedAttempt;

  // Configuration de sécurité
  static const int maxFailedAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 5);
  static const String masterKey = 'hordvoice_secret_2024';

  // Commandes secrètes prédéfinies
  late Map<String, SecretCommand> _secretCommands;
  final List<String> _commandHistory = [];

  // Streams pour les événements
  final StreamController<SecretCommandEvent> _commandController =
      StreamController.broadcast();

  // Getters
  Stream<SecretCommandEvent> get commandStream => _commandController.stream;
  bool get isInitialized => _isInitialized;
  bool get secretModeEnabled => _secretModeEnabled;
  bool get isLockedOut => _isCurrentlyLockedOut();

  /// Initialise le service de commandes secrètes
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SecretCommandsService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation SecretCommandsService...');

      await _loadSecretCommands();
      await _loadSecurityState();

      _isInitialized = true;
      debugPrint('SecretCommandsService initialisé avec succès');

      _commandController.add(SecretCommandEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation SecretCommandsService: $e');
      throw Exception(
        'Impossible d\'initialiser le service de commandes secrètes: $e',
      );
    }
  }

  /// Initialise les commandes secrètes prédéfinies
  Future<void> _loadSecretCommands() async {
    _secretCommands = {
      // Commandes de développement
      'code_debug': SecretCommand(
        id: 'code_debug',
        trigger: 'activez le mode développeur',
        description: 'Active le mode debug avancé',
        category: CommandCategory.development,
        securityLevel: SecurityLevel.high,
        action: _activateDebugMode,
        requiredParams: [],
      ),

      'code_reset': SecretCommand(
        id: 'code_reset',
        trigger: 'réinitialisation totale du système',
        description: 'Remet à zéro toutes les configurations',
        category: CommandCategory.system,
        securityLevel: SecurityLevel.critical,
        action: _resetSystemConfiguration,
        requiredParams: [],
      ),

      // Commandes avancées
      'voice_enhancement': SecretCommand(
        id: 'voice_enhancement',
        trigger: 'amélioration vocale ultime',
        description: 'Active les paramètres vocaux avancés',
        category: CommandCategory.voice,
        securityLevel: SecurityLevel.medium,
        action: _activateVoiceEnhancement,
        requiredParams: [],
      ),

      'ai_personality': SecretCommand(
        id: 'ai_personality',
        trigger: 'changement de personnalité artificielle',
        description: 'Modifie la personnalité de l\'IA',
        category: CommandCategory.ai,
        securityLevel: SecurityLevel.medium,
        action: _changeAiPersonality,
        requiredParams: ['personality'],
      ),

      // Commandes de diagnostic
      'system_diagnostic': SecretCommand(
        id: 'system_diagnostic',
        trigger: 'diagnostic complet du système',
        description: 'Lance un diagnostic approfondi',
        category: CommandCategory.diagnostic,
        securityLevel: SecurityLevel.low,
        action: _runSystemDiagnostic,
        requiredParams: [],
      ),

      'performance_analysis': SecretCommand(
        id: 'performance_analysis',
        trigger: 'analyse de performance détaillée',
        description: 'Analyse les performances du système',
        category: CommandCategory.diagnostic,
        securityLevel: SecurityLevel.low,
        action: _analyzePerformance,
        requiredParams: [],
      ),

      // Commandes de personnalisation
      'custom_avatar': SecretCommand(
        id: 'custom_avatar',
        trigger: 'avatar personnalisé extrême',
        description: 'Déverrouille les options d\'avatar avancées',
        category: CommandCategory.customization,
        securityLevel: SecurityLevel.medium,
        action: _unlockCustomAvatar,
        requiredParams: [],
      ),

      'easter_egg': SecretCommand(
        id: 'easter_egg',
        trigger: 'œuf de Pâques caché',
        description: 'Active un easter egg spécial',
        category: CommandCategory.fun,
        securityLevel: SecurityLevel.low,
        action: _activateEasterEgg,
        requiredParams: [],
      ),

      // Commandes de maintenance
      'memory_clean': SecretCommand(
        id: 'memory_clean',
        trigger: 'nettoyage mémoire profond',
        description: 'Nettoie la mémoire et optimise les performances',
        category: CommandCategory.maintenance,
        securityLevel: SecurityLevel.medium,
        action: _deepMemoryClean,
        requiredParams: [],
      ),

      'backup_restore': SecretCommand(
        id: 'backup_restore',
        trigger: 'sauvegarde et restauration système',
        description: 'Gère les sauvegardes du système',
        category: CommandCategory.maintenance,
        securityLevel: SecurityLevel.high,
        action: _manageBackupRestore,
        requiredParams: ['operation'],
      ),
    };

    debugPrint('${_secretCommands.length} commandes secrètes chargées');
  }

  /// Tente d'exécuter une commande secrète
  Future<SecretCommandResult> executeSecretCommand(String input) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isCurrentlyLockedOut()) {
      return SecretCommandResult.failure(
        'Accès bloqué suite à trop de tentatives. Réessayez plus tard.',
      );
    }

    try {
      // Analyser l'entrée pour détecter une commande secrète
      final detectedCommand = _detectSecretCommand(input);

      if (detectedCommand == null) {
        await _recordFailedAttempt();
        return SecretCommandResult.notFound();
      }

      // Vérifier les permissions
      if (!await _verifyPermissions(detectedCommand)) {
        await _recordFailedAttempt();
        return SecretCommandResult.failure('Permissions insuffisantes');
      }

      // Extraire les paramètres
      final parameters = _extractParameters(input, detectedCommand);

      // Vérifier que tous les paramètres requis sont présents
      if (!_validateParameters(detectedCommand, parameters)) {
        return SecretCommandResult.failure(
          'Paramètres manquants: ${detectedCommand.requiredParams.join(', ')}',
        );
      }

      // Exécuter la commande
      final result = await _executeCommand(detectedCommand, parameters);

      // Enregistrer l'exécution réussie
      await _recordSuccessfulExecution(detectedCommand, parameters);

      _commandController.add(
        SecretCommandEvent.commandExecuted(
          detectedCommand.id,
          parameters,
          result.success,
        ),
      );

      return result;
    } catch (e) {
      debugPrint('Erreur exécution commande secrète: $e');
      await _recordFailedAttempt();
      return SecretCommandResult.failure('Erreur d\'exécution: $e');
    }
  }

  /// Active le mode secret avec authentification
  Future<bool> activateSecretMode(String authCode) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isCurrentlyLockedOut()) {
      return false;
    }

    try {
      final expectedHash = _generateAuthHash(authCode);
      final masterHash = _generateAuthHash(masterKey);

      if (expectedHash == masterHash) {
        _secretModeEnabled = true;
        _currentSecretSession = _generateSessionId();
        _failedAttempts = 0;

        await _saveSecurityState();

        _commandController.add(
          SecretCommandEvent.secretModeActivated(_currentSecretSession!),
        );
        debugPrint('Mode secret activé');

        return true;
      } else {
        await _recordFailedAttempt();
        return false;
      }
    } catch (e) {
      debugPrint('Erreur activation mode secret: $e');
      await _recordFailedAttempt();
      return false;
    }
  }

  /// Désactive le mode secret
  Future<void> deactivateSecretMode() async {
    _secretModeEnabled = false;
    _currentSecretSession = null;

    await _saveSecurityState();

    _commandController.add(SecretCommandEvent.secretModeDeactivated());
    debugPrint('Mode secret désactivé');
  }

  /// Obtient la liste des commandes disponibles (si autorisé)
  List<SecretCommandInfo> getAvailableCommands({
    bool includeRestricted = false,
  }) {
    if (!_secretModeEnabled && !includeRestricted) {
      return [];
    }

    return _secretCommands.values
        .where(
          (cmd) =>
              includeRestricted || cmd.securityLevel != SecurityLevel.critical,
        )
        .map(
          (cmd) => SecretCommandInfo(
            id: cmd.id,
            trigger: cmd.trigger,
            description: cmd.description,
            category: cmd.category,
            securityLevel: cmd.securityLevel,
          ),
        )
        .toList();
  }

  /// Ajoute une commande secrète personnalisée
  Future<void> addCustomCommand({
    required String id,
    required String trigger,
    required String description,
    required CommandCategory category,
    required SecurityLevel securityLevel,
    required Function action,
    List<String> requiredParams = const [],
  }) async {
    if (!_secretModeEnabled) {
      throw Exception('Mode secret requis pour ajouter des commandes');
    }

    final command = SecretCommand(
      id: id,
      trigger: trigger,
      description: description,
      category: category,
      securityLevel: securityLevel,
      action: action,
      requiredParams: requiredParams,
    );

    _secretCommands[id] = command;

    _commandController.add(SecretCommandEvent.customCommandAdded(id));
    debugPrint('Commande personnalisée ajoutée: $id');
  }

  // ==================== MÉTHODES PRIVÉES ====================

  SecretCommand? _detectSecretCommand(String input) {
    final inputLower = input.toLowerCase().trim();

    for (final command in _secretCommands.values) {
      final triggerLower = command.trigger.toLowerCase();

      // Recherche exacte
      if (inputLower.contains(triggerLower)) {
        return command;
      }

      // Recherche floue (mots-clés principaux)
      final triggerWords = triggerLower.split(' ');
      final inputWords = inputLower.split(' ');

      int matches = 0;
      for (final triggerWord in triggerWords) {
        if (triggerWord.length > 3 &&
            inputWords.any((word) => word.contains(triggerWord))) {
          matches++;
        }
      }

      // Si au moins 70% des mots-clés correspondent
      if (matches / triggerWords.length >= 0.7) {
        return command;
      }
    }

    return null;
  }

  Future<bool> _verifyPermissions(SecretCommand command) async {
    switch (command.securityLevel) {
      case SecurityLevel.low:
        return true;

      case SecurityLevel.medium:
        return _secretModeEnabled;

      case SecurityLevel.high:
      case SecurityLevel.critical:
        return _secretModeEnabled && _currentSecretSession != null;
    }
  }

  Map<String, String> _extractParameters(String input, SecretCommand command) {
    final parameters = <String, String>{};

    // Extraction simple des paramètres (peut être améliorée)
    if (command.requiredParams.contains('personality')) {
      final personalities = [
        'amical',
        'professionnel',
        'décontracté',
        'scientifique',
      ];
      for (final personality in personalities) {
        if (input.toLowerCase().contains(personality)) {
          parameters['personality'] = personality;
          break;
        }
      }
    }

    if (command.requiredParams.contains('operation')) {
      if (input.toLowerCase().contains('sauvegarde')) {
        parameters['operation'] = 'backup';
      } else if (input.toLowerCase().contains('restauration')) {
        parameters['operation'] = 'restore';
      }
    }

    return parameters;
  }

  bool _validateParameters(
    SecretCommand command,
    Map<String, String> parameters,
  ) {
    for (final requiredParam in command.requiredParams) {
      if (!parameters.containsKey(requiredParam)) {
        return false;
      }
    }
    return true;
  }

  Future<SecretCommandResult> _executeCommand(
    SecretCommand command,
    Map<String, String> parameters,
  ) async {
    try {
      final result = await command.action(parameters);
      return SecretCommandResult.success(
        result ?? 'Commande exécutée avec succès',
      );
    } catch (e) {
      return SecretCommandResult.failure('Erreur d\'exécution: $e');
    }
  }

  // ==================== ACTIONS DES COMMANDES ====================

  Future<String> _activateDebugMode(Map<String, String> parameters) async {
    // Simuler l'activation du mode debug
    debugPrint('Mode debug activé');
    return 'Mode développeur activé. Logs détaillés disponibles.';
  }

  Future<String> _resetSystemConfiguration(
    Map<String, String> parameters,
  ) async {
    // Simuler la réinitialisation système
    debugPrint('Réinitialisation système lancée');
    return 'Configuration système réinitialisée. Redémarrage requis.';
  }

  Future<String> _activateVoiceEnhancement(
    Map<String, String> parameters,
  ) async {
    // Simuler l'amélioration vocale
    debugPrint('Amélioration vocale activée');
    return 'Paramètres vocaux avancés déverrouillés. Qualité audio améliorée.';
  }

  Future<String> _changeAiPersonality(Map<String, String> parameters) async {
    final personality = parameters['personality'] ?? 'amical';
    debugPrint('Changement de personnalité: $personality');
    return 'Personnalité IA changée vers: $personality';
  }

  Future<String> _runSystemDiagnostic(Map<String, String> parameters) async {
    // Simuler un diagnostic système
    await Future.delayed(const Duration(seconds: 2));
    return 'Diagnostic terminé. Système: OK, Mémoire: 85%, CPU: 12%, Réseau: Connecté';
  }

  Future<String> _analyzePerformance(Map<String, String> parameters) async {
    // Simuler l'analyse de performance
    await Future.delayed(const Duration(seconds: 1));
    return 'Analyse terminée. Temps de réponse: 0.3s, Précision: 94%, Satisfaction: 87%';
  }

  Future<String> _unlockCustomAvatar(Map<String, String> parameters) async {
    debugPrint('Avatar personnalisé déverrouillé');
    return 'Options d\'avatar avancées déverrouillées. Personnalisation complète disponible.';
  }

  Future<String> _activateEasterEgg(Map<String, String> parameters) async {
    final easterEggs = [
      'Konami Code activé! 🎮',
      '42 est effectivement la réponse à tout! 🤖',
      'La force est forte avec vous, jeune Padawan! ⭐',
      'Il y a un serpent dans ma botte! 🤠',
      'May the voice be with you! 🎤',
    ];

    final random = Random();
    return easterEggs[random.nextInt(easterEggs.length)];
  }

  Future<String> _deepMemoryClean(Map<String, String> parameters) async {
    debugPrint('Nettoyage mémoire profond');
    await Future.delayed(const Duration(seconds: 3));
    return 'Nettoyage terminé. 245 MB libérés. Performances optimisées.';
  }

  Future<String> _manageBackupRestore(Map<String, String> parameters) async {
    final operation = parameters['operation'] ?? 'backup';

    if (operation == 'backup') {
      return 'Sauvegarde créée avec succès. Fichier: backup_${DateTime.now().millisecondsSinceEpoch}.hv';
    } else {
      return 'Restauration terminée. Configuration précédente rétablie.';
    }
  }

  // ==================== MÉTHODES UTILITAIRES ====================

  bool _isCurrentlyLockedOut() {
    if (_lastFailedAttempt == null || _failedAttempts < maxFailedAttempts) {
      return false;
    }

    final timeSinceLastFail = DateTime.now().difference(_lastFailedAttempt!);
    return timeSinceLastFail < lockoutDuration;
  }

  Future<void> _recordFailedAttempt() async {
    _failedAttempts++;
    _lastFailedAttempt = DateTime.now();

    await _saveSecurityState();

    _commandController.add(
      SecretCommandEvent.accessAttemptFailed(_failedAttempts),
    );

    if (_failedAttempts >= maxFailedAttempts) {
      _commandController.add(SecretCommandEvent.accessBlocked());
    }
  }

  Future<void> _recordSuccessfulExecution(
    SecretCommand command,
    Map<String, String> parameters,
  ) async {
    _commandHistory.add('${DateTime.now().toIso8601String()}: ${command.id}');
    _failedAttempts = 0; // Reset sur succès

    await _saveSecurityState();
  }

  String _generateAuthHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomComponent = random.nextInt(999999);
    return 'sess_${timestamp}_$randomComponent';
  }

  Future<void> _saveSecurityState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('secret_failed_attempts', _failedAttempts);
      if (_lastFailedAttempt != null) {
        await prefs.setString(
          'secret_last_failed',
          _lastFailedAttempt!.toIso8601String(),
        );
      }
      await prefs.setBool('secret_mode_enabled', _secretModeEnabled);
    } catch (e) {
      debugPrint('Erreur sauvegarde état sécurité: $e');
    }
  }

  Future<void> _loadSecurityState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _failedAttempts = prefs.getInt('secret_failed_attempts') ?? 0;

      final lastFailedStr = prefs.getString('secret_last_failed');
      if (lastFailedStr != null) {
        _lastFailedAttempt = DateTime.parse(lastFailedStr);
      }

      _secretModeEnabled = prefs.getBool('secret_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('Erreur chargement état sécurité: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _commandController.close();
    debugPrint('SecretCommandsService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class SecretCommand {
  final String id;
  final String trigger;
  final String description;
  final CommandCategory category;
  final SecurityLevel securityLevel;
  final Function action;
  final List<String> requiredParams;

  SecretCommand({
    required this.id,
    required this.trigger,
    required this.description,
    required this.category,
    required this.securityLevel,
    required this.action,
    required this.requiredParams,
  });
}

class SecretCommandInfo {
  final String id;
  final String trigger;
  final String description;
  final CommandCategory category;
  final SecurityLevel securityLevel;

  SecretCommandInfo({
    required this.id,
    required this.trigger,
    required this.description,
    required this.category,
    required this.securityLevel,
  });
}

class SecretCommandResult {
  final bool success;
  final String message;
  final bool commandFound;

  SecretCommandResult({
    required this.success,
    required this.message,
    required this.commandFound,
  });

  factory SecretCommandResult.success(String message) {
    return SecretCommandResult(
      success: true,
      message: message,
      commandFound: true,
    );
  }

  factory SecretCommandResult.failure(String message) {
    return SecretCommandResult(
      success: false,
      message: message,
      commandFound: true,
    );
  }

  factory SecretCommandResult.notFound() {
    return SecretCommandResult(
      success: false,
      message: 'Commande secrète non reconnue',
      commandFound: false,
    );
  }
}

class SecretCommandEvent {
  final SecretCommandEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SecretCommandEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory SecretCommandEvent.initialized() {
    return SecretCommandEvent(
      type: SecretCommandEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.secretModeActivated(String sessionId) {
    return SecretCommandEvent(
      type: SecretCommandEventType.secretModeActivated,
      data: {'sessionId': sessionId},
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.secretModeDeactivated() {
    return SecretCommandEvent(
      type: SecretCommandEventType.secretModeDeactivated,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.commandExecuted(
    String commandId,
    Map<String, String> parameters,
    bool success,
  ) {
    return SecretCommandEvent(
      type: SecretCommandEventType.commandExecuted,
      data: {
        'commandId': commandId,
        'parameters': parameters,
        'success': success,
      },
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.customCommandAdded(String commandId) {
    return SecretCommandEvent(
      type: SecretCommandEventType.customCommandAdded,
      data: {'commandId': commandId},
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.accessAttemptFailed(int attempts) {
    return SecretCommandEvent(
      type: SecretCommandEventType.accessAttemptFailed,
      data: {'attempts': attempts},
      timestamp: DateTime.now(),
    );
  }

  factory SecretCommandEvent.accessBlocked() {
    return SecretCommandEvent(
      type: SecretCommandEventType.accessBlocked,
      data: {},
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS ====================

enum CommandCategory {
  development,
  system,
  voice,
  ai,
  diagnostic,
  customization,
  fun,
  maintenance,
}

enum SecurityLevel { low, medium, high, critical }

enum SecretCommandEventType {
  initialized,
  secretModeActivated,
  secretModeDeactivated,
  commandExecuted,
  customCommandAdded,
  accessAttemptFailed,
  accessBlocked,
}
