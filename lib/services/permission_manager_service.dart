import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service de gestion des permissions et de l'onboarding
/// Gère tous les aspects de sécurité et d'autorisation de l'app
class PermissionManagerService {
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _voiceCalibrationKey = 'voice_calibration_complete';
  static const String _permissionsGrantedKey = 'permissions_granted';

  // Permissions requises par fonctionnalité
  static const Map<String, List<Permission>> _featurePermissions = {
    'voice_core': [Permission.microphone, Permission.speech],
    'location_services': [Permission.location, Permission.locationWhenInUse],
    'phone_calls': [Permission.phone],
    'contacts': [Permission.contacts],
    'calendar': [Permission.calendar],
    'notifications': [Permission.notification],
    'bluetooth': [Permission.bluetooth, Permission.bluetoothConnect],
    'camera': [Permission.camera],
    'storage': [Permission.storage, Permission.manageExternalStorage],
  };

  /// Vérifie si l'onboarding est terminé
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Marque l'onboarding comme terminé
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  /// Vérifie si la calibration vocale est terminée
  static Future<bool> isVoiceCalibrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceCalibrationKey) ?? false;
  }

  /// Marque la calibration vocale comme terminée
  static Future<void> completeVoiceCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceCalibrationKey, true);
  }

  /// Vérifie l'état de toutes les permissions par fonctionnalité
  static Future<Map<String, PermissionStatus>> checkAllPermissions() async {
    final Map<String, PermissionStatus> results = {};

    for (final feature in _featurePermissions.keys) {
      final permissions = _featurePermissions[feature]!;
      final statuses = await permissions.request();

      // Une fonctionnalité est accordée si au moins une permission est accordée
      final hasGranted = statuses.values.any(
        (status) => status == PermissionStatus.granted,
      );

      results[feature] = hasGranted
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    }

    return results;
  }

  /// Demande les permissions essentielles pour la fonctionnalité vocale
  static Future<Map<Permission, PermissionStatus>>
  requestCoreVoicePermissions() async {
    final permissions = _featurePermissions['voice_core']!;
    return await permissions.request();
  }

  /// Demande les permissions pour une fonctionnalité spécifique
  static Future<Map<Permission, PermissionStatus>> requestFeaturePermissions(
    String feature,
  ) async {
    if (!_featurePermissions.containsKey(feature)) {
      throw ArgumentError('Feature $feature not found');
    }

    final permissions = _featurePermissions[feature]!;
    return await permissions.request();
  }

  /// Vérifie si les permissions essentielles sont accordées
  static Future<bool> hasEssentialPermissions() async {
    final microphoneStatus = await Permission.microphone.status;
    return microphoneStatus == PermissionStatus.granted;
  }

  /// Ouvre les paramètres de l'application
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Obtient un message explicatif pour une permission
  static String getPermissionExplanation(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'HordVoice a besoin d\'accéder au microphone pour entendre tes commandes vocales et te permettre d\'interagir naturellement avec l\'assistant.';

      case Permission.location:
        return 'L\'accès à ta position permet à HordVoice de te donner des informations météo locales, des directions de navigation et des suggestions personnalisées.';

      case Permission.phone:
        return 'HordVoice peut passer des appels pour toi en utilisant des commandes vocales comme "Appelle maman" ou "Compose le 911".';

      case Permission.contacts:
        return 'L\'accès aux contacts permet à HordVoice d\'identifier et d\'appeler tes proches par leur nom sans que tu aies à épeler leurs numéros.';

      case Permission.calendar:
        return 'HordVoice peut consulter ton agenda pour te rappeler tes rendez-vous et t\'aider à planifier ta journée.';

      case Permission.notification:
        return 'Les notifications permettent à HordVoice de t\'alerter de messages importants, d\'appels manqués ou de rappels même quand l\'app est fermée.';

      case Permission.bluetooth:
        return 'La connexion Bluetooth permet à HordVoice de fonctionner avec tes écouteurs, enceintes et autres appareils connectés.';

      case Permission.camera:
        return 'L\'accès à la caméra permet à HordVoice d\'identifier des objets, de lire des codes QR et d\'assister visuellement tes interactions.';

      case Permission.storage:
        return 'L\'accès au stockage permet à HordVoice de sauvegarder tes préférences, ton profil vocal et tes données personnalisées.';

      default:
        return 'Cette permission améliore l\'expérience HordVoice en permettant des fonctionnalités avancées.';
    }
  }

  /// Vérifie les permissions manquantes pour une fonctionnalité
  static Future<List<Permission>> getMissingPermissions(String feature) async {
    if (!_featurePermissions.containsKey(feature)) {
      return [];
    }

    final permissions = _featurePermissions[feature]!;
    final List<Permission> missing = [];

    for (final permission in permissions) {
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        missing.add(permission);
      }
    }

    return missing;
  }

  /// Obtient des informations sur l'appareil pour adapter les permissions
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'canRequestExactAlarm': androidInfo.version.sdkInt >= 31,
        'hasSystemAlertWindow': androidInfo.version.sdkInt >= 23,
      };
    } catch (e) {
      // Fallback pour autres plateformes
      return {
        'platform': 'unknown',
        'version': 'unknown',
        'sdkInt': 0,
        'manufacturer': 'unknown',
        'model': 'unknown',
        'canRequestExactAlarm': false,
        'hasSystemAlertWindow': false,
      };
    }
  }

  /// Sauvegarde l'état des permissions accordées
  static Future<void> savePermissionStates(
    Map<String, PermissionStatus> states,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> stateStrings = {};

    for (final entry in states.entries) {
      stateStrings[entry.key] = entry.value.toString();
    }

    await prefs.setString(_permissionsGrantedKey, stateStrings.toString());
  }

  /// Récupère l'état sauvegardé des permissions
  static Future<Map<String, PermissionStatus>>
  getSavedPermissionStates() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_permissionsGrantedKey);

    if (stateString == null) return {};

    // Parse basique - en production, utiliser JSON
    return {};
  }

  /// Vérifie si une permission peut être demandée (pas définitivement refusée)
  static Future<bool> canRequestPermission(Permission permission) async {
    final status = await permission.status;
    return status != PermissionStatus.permanentlyDenied;
  }

  /// Gère les permissions refusées définitivement
  static Future<void> handlePermanentlyDeniedPermission(
    BuildContext context,
    Permission permission,
  ) async {
    final explanation = getPermissionExplanation(permission);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(explanation),
            const SizedBox(height: 16),
            const Text(
              'Cette permission a été refusée définitivement. '
              'Tu peux l\'activer manuellement dans les paramètres.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Ouvrir paramètres'),
          ),
        ],
      ),
    );
  }

  /// Récupère le niveau de permission accordé (0-100%)
  static Future<double> getPermissionCompletionLevel() async {
    final allPermissions = _featurePermissions.values
        .expand((perms) => perms)
        .toSet()
        .toList();

    int grantedCount = 0;
    for (final permission in allPermissions) {
      final status = await permission.status;
      if (status == PermissionStatus.granted) {
        grantedCount++;
      }
    }

    return grantedCount / allPermissions.length;
  }

  /// Vérifie les permissions critiques manquantes
  static Future<List<String>> getCriticalMissingFeatures() async {
    final List<String> critical = [];
    final corePermissions = await checkAllPermissions();

    // Permissions critiques pour le fonctionnement de base
    if (corePermissions['voice_core'] != PermissionStatus.granted) {
      critical.add('Reconnaissance vocale');
    }

    return critical;
  }

  /// Planifie une vérification périodique des permissions
  static Future<void> schedulePermissionCheck() async {
    // TODO: Implémenter avec WorkManager ou similar
    // Vérifier les permissions toutes les 24h et notifier si révoquées
  }
}
