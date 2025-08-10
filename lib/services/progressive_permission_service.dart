import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Service de gestion progressive des permissions - Évite les demandes en masse
/// Implemente le système de slot filling pour les permissions selon le guide
class ProgressivePermissionService {
  static final ProgressivePermissionService _instance =
      ProgressivePermissionService._internal();
  factory ProgressivePermissionService() => _instance;
  ProgressivePermissionService._internal();

  // États du processus de permissions
  bool _isRequestingPermissions = false;

  // Permissions par étapes avec explications contextuelles
  static const List<PermissionStep> _permissionSteps = [
    // ÉTAPE 1: Permission essentielle (micro)
    PermissionStep(
      permissions: [Permission.microphone],
      title: 'Accès au microphone',
      explanation:
          'Ric a besoin du microphone pour vous entendre et répondre à vos commandes vocales.',
      isEssential: true,
      canSkip: false,
    ),

    // ÉTAPE 2: Permissions communication
    PermissionStep(
      permissions: [Permission.phone, Permission.contacts],
      title: 'Appels et contacts',
      explanation:
          'Ric peut passer des appels et accéder à vos contacts pour vous aider avec "Appelle maman" ou "Envoie un message à Pierre".',
      isEssential: false,
      canSkip: true,
    ),

    // ÉTAPE 3: Localisation
    PermissionStep(
      permissions: [Permission.location],
      title: 'Localisation',
      explanation:
          'Ric peut vous donner la météo locale, des directions et des suggestions personnalisées selon votre position.',
      isEssential: false,
      canSkip: true,
    ),

    // ÉTAPE 4: Stockage et médias
    PermissionStep(
      permissions: [Permission.storage, Permission.camera],
      title: 'Stockage et caméra',
      explanation:
          'Ric peut sauvegarder vos préférences et identifier des objets avec la caméra.',
      isEssential: false,
      canSkip: true,
    ),

    // ÉTAPE 5: Notifications et système
    PermissionStep(
      permissions: [Permission.notification, Permission.systemAlertWindow],
      title: 'Notifications et système',
      explanation:
          'Ric peut vous alerter de messages importants et afficher des informations même quand l\'app est fermée.',
      isEssential: false,
      canSkip: true,
    ),
  ];

  /// Interface publique - Démarre le processus progressif
  Future<PermissionFlowResult> startProgressivePermissionFlow(
    BuildContext context,
  ) async {
    if (_isRequestingPermissions) {
      debugPrint('⚠️ Processus de permissions déjà en cours');
      return PermissionFlowResult.alreadyInProgress();
    }

    _isRequestingPermissions = true;

    try {
      debugPrint('🔐 Démarrage flux progressif permissions');

      final result = await _processAllSteps(context);

      debugPrint('✅ Flux permissions terminé: ${result.summary}');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur flux permissions: $e');
      return PermissionFlowResult.error(e.toString());
    } finally {
      _isRequestingPermissions = false;
    }
  }

  /// Traite toutes les étapes séquentiellement (slot filling)
  Future<PermissionFlowResult> _processAllSteps(BuildContext context) async {
    final Map<Permission, PermissionStatus> results = {};
    final List<String> skippedSteps = [];
    final List<String> errors = [];

    for (int i = 0; i < _permissionSteps.length; i++) {
      final step = _permissionSteps[i];

      debugPrint('📋 Étape ${i + 1}/${_permissionSteps.length}: ${step.title}');

      // Vérifier si permissions déjà accordées
      final alreadyGranted = await _checkStepAlreadyGranted(step);
      if (alreadyGranted) {
        debugPrint('✅ Étape ${step.title} - déjà accordées');
        for (final permission in step.permissions) {
          results[permission] = PermissionStatus.granted;
        }
        continue;
      }

      // Interface utilisateur pour cette étape
      if (!context.mounted) {
        debugPrint('⚠️ Context non monté, arrêt du processus');
        return PermissionFlowResult.error('Interface fermée');
      }

      final stepResult = await _showPermissionStepDialog(context, step, i + 1);

      if (stepResult.action == PermissionStepAction.skip) {
        debugPrint('⏩ Étape ${step.title} - ignorée par l\'utilisateur');
        skippedSteps.add(step.title);
        continue;
      }

      if (stepResult.action == PermissionStepAction.deny) {
        if (step.isEssential) {
          debugPrint('❌ Permission essentielle refusée: ${step.title}');
          return PermissionFlowResult.essentialDenied(step.title);
        } else {
          debugPrint('⚠️ Permission optionnelle refusée: ${step.title}');
          skippedSteps.add(step.title);
          continue;
        }
      }

      // Demander les permissions de cette étape
      try {
        final stepPermissionResults = await _requestStepPermissions(step);
        results.addAll(stepPermissionResults);

        // Vérifier si au moins une permission essentielle a été accordée
        if (step.isEssential) {
          final hasEssentialGranted = stepPermissionResults.values.any(
            (status) => status == PermissionStatus.granted,
          );

          if (!hasEssentialGranted) {
            debugPrint(
              '❌ Aucune permission essentielle accordée pour: ${step.title}',
            );
            return PermissionFlowResult.essentialDenied(step.title);
          }
        }
      } catch (e) {
        errors.add('Erreur ${step.title}: $e');
        debugPrint('❌ Erreur étape ${step.title}: $e');
      }

      // Délai entre les étapes pour éviter la surcharge
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return PermissionFlowResult.success(
      grantedPermissions: results,
      skippedSteps: skippedSteps,
      errors: errors,
    );
  }

  /// Vérifie si les permissions d'une étape sont déjà accordées
  Future<bool> _checkStepAlreadyGranted(PermissionStep step) async {
    for (final permission in step.permissions) {
      final status = await permission.status;
      if (status == PermissionStatus.granted) {
        return true; // Au moins une permission accordée
      }
    }
    return false;
  }

  /// Interface utilisateur pour une étape de permission
  Future<PermissionStepResult> _showPermissionStepDialog(
    BuildContext context,
    PermissionStep step,
    int stepNumber,
  ) async {
    final completer = Completer<PermissionStepResult>();

    showDialog(
      context: context,
      barrierDismissible: !step.isEssential,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                step.isEssential ? Icons.security : Icons.info_outline,
                color: step.isEssential ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${step.title} ${step.isEssential ? "(Requis)" : "(Optionnel)"}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Étape $stepNumber sur ${_permissionSteps.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Text(step.explanation, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Text(
                'Permissions demandées:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              ...step.permissions.map(
                (permission) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• ${_getPermissionDisplayName(permission)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (step.canSkip)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  completer.complete(PermissionStepResult.skip());
                },
                child: const Text('Plus tard'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                completer.complete(PermissionStepResult.deny());
              },
              child: Text(step.isEssential ? 'Quitter l\'app' : 'Non merci'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                completer.complete(PermissionStepResult.grant());
              },
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  /// Demande les permissions pour une étape donnée
  Future<Map<Permission, PermissionStatus>> _requestStepPermissions(
    PermissionStep step,
  ) async {
    debugPrint(
      '🔑 Demande permissions: ${step.permissions.map((p) => _getPermissionDisplayName(p)).join(", ")}',
    );

    final Map<Permission, PermissionStatus> results = {};

    for (final permission in step.permissions) {
      try {
        final status = await permission.request();
        results[permission] = status;

        debugPrint('${_getPermissionDisplayName(permission)}: ${status.name}');
      } catch (e) {
        debugPrint(
          '❌ Erreur permission ${_getPermissionDisplayName(permission)}: $e',
        );
        results[permission] = PermissionStatus.denied;
      }
    }

    return results;
  }

  /// Interface publique - Vérification permissions manquantes
  Future<List<Permission>> getMissingEssentialPermissions() async {
    final missing = <Permission>[];

    for (final step in _permissionSteps) {
      if (step.isEssential) {
        for (final permission in step.permissions) {
          final status = await permission.status;
          if (status != PermissionStatus.granted) {
            missing.add(permission);
          }
        }
      }
    }

    return missing;
  }

  /// Interface publique - Ouvre les paramètres pour une permission
  Future<bool> openSettingsForPermission(Permission permission) async {
    try {
      debugPrint(
        '🔧 Ouverture paramètres pour: ${_getPermissionDisplayName(permission)}',
      );

      switch (permission) {
        case Permission.microphone:
        case Permission.speech:
          await AppSettings.openAppSettings(type: AppSettingsType.settings);
          return true;
        case Permission.location:
          await AppSettings.openAppSettings(type: AppSettingsType.location);
          return true;
        case Permission.notification:
          await AppSettings.openAppSettings(type: AppSettingsType.notification);
          return true;
        default:
          await AppSettings.openAppSettings();
          return true;
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture paramètres: $e');
      return false;
    }
  }

  /// Utilitaire - Nom d'affichage pour une permission
  String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Microphone';
      case Permission.camera:
        return 'Caméra';
      case Permission.location:
        return 'Localisation';
      case Permission.contacts:
        return 'Contacts';
      case Permission.phone:
        return 'Téléphone';
      case Permission.storage:
        return 'Stockage';
      case Permission.notification:
        return 'Notifications';
      case Permission.systemAlertWindow:
        return 'Superposition d\'écran';
      default:
        return permission.toString().split('.').last;
    }
  }
}

/// Modèle d'une étape de permission
class PermissionStep {
  final List<Permission> permissions;
  final String title;
  final String explanation;
  final bool isEssential;
  final bool canSkip;

  const PermissionStep({
    required this.permissions,
    required this.title,
    required this.explanation,
    required this.isEssential,
    required this.canSkip,
  });
}

/// Résultat d'une étape de permission
class PermissionStepResult {
  final PermissionStepAction action;

  const PermissionStepResult._(this.action);

  factory PermissionStepResult.grant() =>
      const PermissionStepResult._(PermissionStepAction.grant);
  factory PermissionStepResult.deny() =>
      const PermissionStepResult._(PermissionStepAction.deny);
  factory PermissionStepResult.skip() =>
      const PermissionStepResult._(PermissionStepAction.skip);
}

enum PermissionStepAction { grant, deny, skip }

/// Résultat complet du flux de permissions
class PermissionFlowResult {
  final PermissionFlowStatus status;
  final Map<Permission, PermissionStatus> grantedPermissions;
  final List<String> skippedSteps;
  final List<String> errors;
  final String? errorMessage;
  final String? essentialPermissionDenied;

  const PermissionFlowResult._({
    required this.status,
    this.grantedPermissions = const {},
    this.skippedSteps = const [],
    this.errors = const [],
    this.errorMessage,
    this.essentialPermissionDenied,
  });

  factory PermissionFlowResult.success({
    required Map<Permission, PermissionStatus> grantedPermissions,
    List<String> skippedSteps = const [],
    List<String> errors = const [],
  }) => PermissionFlowResult._(
    status: PermissionFlowStatus.success,
    grantedPermissions: grantedPermissions,
    skippedSteps: skippedSteps,
    errors: errors,
  );

  factory PermissionFlowResult.essentialDenied(String permissionName) =>
      PermissionFlowResult._(
        status: PermissionFlowStatus.essentialDenied,
        essentialPermissionDenied: permissionName,
      );

  factory PermissionFlowResult.error(String message) => PermissionFlowResult._(
    status: PermissionFlowStatus.error,
    errorMessage: message,
  );

  factory PermissionFlowResult.alreadyInProgress() =>
      const PermissionFlowResult._(
        status: PermissionFlowStatus.alreadyInProgress,
      );

  /// Résumé textuel du résultat
  String get summary {
    switch (status) {
      case PermissionFlowStatus.success:
        final granted = grantedPermissions.values
            .where((s) => s == PermissionStatus.granted)
            .length;
        return 'Succès: $granted permissions accordées, ${skippedSteps.length} ignorées';
      case PermissionFlowStatus.essentialDenied:
        return 'Échec: Permission essentielle refusée ($essentialPermissionDenied)';
      case PermissionFlowStatus.error:
        return 'Erreur: $errorMessage';
      case PermissionFlowStatus.alreadyInProgress:
        return 'Processus déjà en cours';
    }
  }
}

enum PermissionFlowStatus { success, essentialDenied, error, alreadyInProgress }
