import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion avancée des permissions pour HordVoice v2.0
class AdvancedPermissionManager {
  static final AdvancedPermissionManager _instance =
      AdvancedPermissionManager._internal();
  factory AdvancedPermissionManager() => _instance;
  AdvancedPermissionManager._internal();

  // Clés SharedPreferences
  static const String _permissionsAskedKey = 'permissions_asked_';
  static const String _permissionsDeniedCountKey = 'permissions_denied_count_';
  static const String _lastPermissionRequestKey = 'last_permission_request';

  /// Permissions par catégorie avec priorités
  static const Map<String, Map<String, dynamic>> _permissionCategories = {
    'essential': {
      'name': 'Essentielles',
      'description': 'Permissions requises pour le fonctionnement de base',
      'priority': 1,
      'permissions': [Permission.microphone, Permission.speech],
    },
    'core_features': {
      'name': 'Fonctionnalités principales',
      'description': 'Pour les fonctionnalités de navigation et communication',
      'priority': 2,
      'permissions': [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.phone,
        Permission.contacts,
      ],
    },
    'enhanced_experience': {
      'name': 'Expérience enrichie',
      'description': 'Pour les fonctionnalités avancées et personnalisation',
      'priority': 3,
      'permissions': [
        Permission.calendar,
        Permission.notification,
        Permission.camera,
        Permission.bluetooth,
        Permission.bluetoothConnect,
      ],
    },
    'storage_system': {
      'name': 'Stockage et système',
      'description': 'Pour la sauvegarde et les fonctionnalités système',
      'priority': 4,
      'permissions': [Permission.storage, Permission.manageExternalStorage],
    },
  };

  /// Initialiser le gestionnaire de permissions
  Future<void> initialize() async {
    debugPrint('🔐 Initialisation AdvancedPermissionManager');
    await _cleanupOldPermissionData();
  }

  /// Nettoyer les anciennes données de permissions
  Future<void> _cleanupOldPermissionData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_permissionsAskedKey) ||
              key.startsWith(_permissionsDeniedCountKey),
        )
        .toList();

    for (final key in keys) {
      final timestamp = prefs.getInt('${key}_timestamp');
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        // Nettoyer les données de plus de 30 jours
        if (age > 30 * 24 * 60 * 60 * 1000) {
          await prefs.remove(key);
          await prefs.remove('${key}_timestamp');
        }
      }
    }
  }

  /// Demander permissions par catégorie avec logique intelligente
  Future<PermissionRequestResult> requestPermissionsByCategory(
    String category, {
    bool showRationale = true,
    BuildContext? context,
  }) async {
    if (!_permissionCategories.containsKey(category)) {
      return PermissionRequestResult(
        category: category,
        success: false,
        message: 'Catégorie de permission inconnue: $category',
        grantedPermissions: {},
        deniedPermissions: {},
      );
    }

    final categoryData = _permissionCategories[category]!;
    final permissions = List<Permission>.from(categoryData['permissions']);

    debugPrint('🔐 Demande permissions pour catégorie: $category');

    // Vérifier si déjà demandées récemment
    if (await _wasRecentlyRequested(category)) {
      debugPrint('⏱️ Permissions $category demandées récemment, skip');
      final currentStatuses = await _checkPermissionsStatus(permissions);
      return PermissionRequestResult(
        category: category,
        success: _allGranted(currentStatuses),
        message: 'Permissions vérifiées (demandées récemment)',
        grantedPermissions: _getGranted(currentStatuses),
        deniedPermissions: _getDenied(currentStatuses),
      );
    }

    // Afficher rationale si nécessaire
    if (showRationale && context != null) {
      final shouldProceed = await _showPermissionRationale(context, category);
      if (!shouldProceed) {
        return PermissionRequestResult(
          category: category,
          success: false,
          message: 'Utilisateur a refusé les explications',
          grantedPermissions: {},
          deniedPermissions: {},
        );
      }
    }

    // Demander les permissions
    final Map<Permission, PermissionStatus> results = {};

    for (final permission in permissions) {
      try {
        final status = await permission.status;

        if (status == PermissionStatus.granted) {
          results[permission] = status;
          continue;
        }

        // Vérifier si permission bloquée définitivement
        if (status == PermissionStatus.permanentlyDenied) {
          results[permission] = status;
          continue;
        }

        // Demander permission
        final newStatus = await permission.request();
        results[permission] = newStatus;

        // Enregistrer tentative
        await _recordPermissionAttempt(permission, newStatus);
      } catch (e) {
        debugPrint('❌ Erreur demande permission $permission: $e');
        results[permission] = PermissionStatus.denied;
      }
    }

    // Marquer catégorie comme demandée
    await _markCategoryRequested(category);

    final success = _allGranted(results);
    final message = _generateResultMessage(category, results);

    return PermissionRequestResult(
      category: category,
      success: success,
      message: message,
      grantedPermissions: _getGranted(results),
      deniedPermissions: _getDenied(results),
    );
  }

  /// Vérifier statut de toutes les permissions
  Future<Map<Permission, PermissionStatus>> _checkPermissionsStatus(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in permissions) {
      try {
        statuses[permission] = await permission.status;
      } catch (e) {
        debugPrint('❌ Erreur vérification $permission: $e');
        statuses[permission] = PermissionStatus.denied;
      }
    }

    return statuses;
  }

  /// Vérifier si permissions récemment demandées
  Future<bool> _wasRecentlyRequested(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRequest = prefs.getInt('${_lastPermissionRequestKey}_$category');

    if (lastRequest == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDiff = now - lastRequest;

    // Considérer comme récent si moins de 24h
    return timeDiff < 24 * 60 * 60 * 1000;
  }

  /// Marquer catégorie comme demandée
  Future<void> _markCategoryRequested(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '${_lastPermissionRequestKey}_$category',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Enregistrer tentative de permission
  Future<void> _recordPermissionAttempt(
    Permission permission,
    PermissionStatus status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_permissionsAskedKey}${permission.toString()}';

    // Incrémenter compteur de demandes
    final asked = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, asked + 1);

    // Compteur de refus
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      final deniedKey = '${_permissionsDeniedCountKey}${permission.toString()}';
      final denied = prefs.getInt(deniedKey) ?? 0;
      await prefs.setInt(deniedKey, denied + 1);
    }

    // Timestamp
    await prefs.setInt(
      '${key}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Afficher explication rationale
  Future<bool> _showPermissionRationale(
    BuildContext context,
    String category,
  ) async {
    final categoryData = _permissionCategories[category]!;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: Text(
              'Permissions ${categoryData['name']}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryData['description'],
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ces permissions permettent à HordVoice de :',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_getPermissionBenefits(category).map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.blue)),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Plus tard',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Autoriser',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Obtenir bénéfices des permissions par catégorie
  List<String> _getPermissionBenefits(String category) {
    switch (category) {
      case 'essential':
        return [
          'Vous écouter et comprendre vos commandes vocales',
          'Répondre avec une voix naturelle et expressive',
          'Fonctionner comme assistant vocal personnel',
        ];
      case 'core_features':
        return [
          'Vous guider avec navigation GPS vocale',
          'Passer des appels en disant "Appelle [nom]"',
          'Consulter vos contacts par la voix',
          'Donner des infos météo de votre position',
        ];
      case 'enhanced_experience':
        return [
          'Consulter votre agenda et rendez-vous',
          'Envoyer des notifications importantes',
          'Scanner des QR codes et analyser des images',
          'Se connecter à vos appareils Bluetooth',
        ];
      case 'storage_system':
        return [
          'Sauvegarder vos préférences personnelles',
          'Stocker votre profil vocal calibré',
          'Conserver l\'historique des conversations',
        ];
      default:
        return ['Améliorer votre expérience HordVoice'];
    }
  }

  /// Générer message de résultat
  String _generateResultMessage(
    String category,
    Map<Permission, PermissionStatus> results,
  ) {
    final granted = _getGranted(results).length;
    final total = results.length;
    final denied = _getDenied(results).length;
    final permanentlyDenied = results.values
        .where((status) => status == PermissionStatus.permanentlyDenied)
        .length;

    if (granted == total) {
      return '✅ Toutes les permissions $category accordées ($granted/$total)';
    } else if (granted > 0) {
      return '⚠️ Permissions $category partielles ($granted/$total accordées)';
    } else if (permanentlyDenied > 0) {
      return '🔒 Permissions $category bloquées. Veuillez les activer dans les paramètres.';
    } else {
      return '❌ Permissions $category refusées ($denied/$total)';
    }
  }

  /// Helpers pour filtrer les résultats
  bool _allGranted(Map<Permission, PermissionStatus> results) {
    return results.values.every((status) => status == PermissionStatus.granted);
  }

  Map<Permission, PermissionStatus> _getGranted(
    Map<Permission, PermissionStatus> results,
  ) {
    return Map.fromEntries(
      results.entries.where((entry) => entry.value == PermissionStatus.granted),
    );
  }

  Map<Permission, PermissionStatus> _getDenied(
    Map<Permission, PermissionStatus> results,
  ) {
    return Map.fromEntries(
      results.entries.where((entry) => entry.value != PermissionStatus.granted),
    );
  }

  /// Demander toutes les permissions par ordre de priorité
  Future<List<PermissionRequestResult>> requestAllPermissionsByPriority({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    final results = <PermissionRequestResult>[];

    // Trier par priorité
    final sortedCategories = _permissionCategories.entries.toList()
      ..sort((a, b) => a.value['priority'].compareTo(b.value['priority']));

    for (final entry in sortedCategories) {
      final category = entry.key;
      debugPrint(
        '🔐 Traitement catégorie $category (priorité ${entry.value['priority']})',
      );

      final result = await requestPermissionsByCategory(
        category,
        context: context,
        showRationale: showRationale,
      );

      results.add(result);

      // Pause entre catégories pour éviter spam
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  /// Ouvrir paramètres système pour permissions bloquées
  Future<bool> openSystemSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('Erreur ouverture paramètres: $e');
      return false;
    }
  }

  /// Obtenir résumé de l'état des permissions
  Future<PermissionSummary> getPermissionSummary() async {
    final summary = PermissionSummary();

    for (final category in _permissionCategories.keys) {
      final permissions = List<Permission>.from(
        _permissionCategories[category]!['permissions'],
      );
      final statuses = await _checkPermissionsStatus(permissions);

      summary.categories[category] = CategoryStatus(
        name: _permissionCategories[category]!['name'],
        allGranted: _allGranted(statuses),
        grantedCount: _getGranted(statuses).length,
        totalCount: statuses.length,
        permissions: statuses,
      );
    }

    return summary;
  }

  /// Getters pour les catégories
  static List<String> get availableCategories =>
      _permissionCategories.keys.toList();
  static Map<String, dynamic> getCategoryInfo(String category) {
    return _permissionCategories[category] ?? {};
  }
}

/// Résultat d'une demande de permissions
class PermissionRequestResult {
  final String category;
  final bool success;
  final String message;
  final Map<Permission, PermissionStatus> grantedPermissions;
  final Map<Permission, PermissionStatus> deniedPermissions;

  PermissionRequestResult({
    required this.category,
    required this.success,
    required this.message,
    required this.grantedPermissions,
    required this.deniedPermissions,
  });

  @override
  String toString() {
    return 'PermissionRequestResult(category: $category, success: $success, message: $message)';
  }
}

/// Résumé de l'état des permissions
class PermissionSummary {
  final Map<String, CategoryStatus> categories = {};

  bool get allEssentialGranted {
    final essential = categories['essential'];
    return essential?.allGranted ?? false;
  }

  double get overallCompletionRate {
    if (categories.isEmpty) return 0.0;

    int totalGranted = 0;
    int totalPermissions = 0;

    for (final category in categories.values) {
      totalGranted += category.grantedCount;
      totalPermissions += category.totalCount;
    }

    return totalPermissions > 0 ? totalGranted / totalPermissions : 0.0;
  }
}

/// Statut d'une catégorie de permissions
class CategoryStatus {
  final String name;
  final bool allGranted;
  final int grantedCount;
  final int totalCount;
  final Map<Permission, PermissionStatus> permissions;

  CategoryStatus({
    required this.name,
    required this.allGranted,
    required this.grantedCount,
    required this.totalCount,
    required this.permissions,
  });
}
