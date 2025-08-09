import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Service pour gérer l'accès aux paramètres du téléphone
class PhoneSettingsService {
  static final PhoneSettingsService _instance =
      PhoneSettingsService._internal();
  factory PhoneSettingsService() => _instance;
  PhoneSettingsService._internal();

  /// Ouvrir les paramètres généraux de l'application
  Future<bool> openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres app: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres de permissions spécifiques
  Future<bool> openPermissionSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres permissions: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres de notification
  Future<bool> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres notifications: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres de localisation
  Future<bool> openLocationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.location);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres localisation: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres de sécurité
  Future<bool> openSecuritySettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.security);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres sécurité: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres Bluetooth
  Future<bool> openBluetoothSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres Bluetooth: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres WiFi
  Future<bool> openWifiSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres WiFi: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres son
  Future<bool> openSoundSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.sound);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres son: $e');
      return false;
    }
  }

  /// Ouvrir les paramètres d'accessibilité
  Future<bool> openAccessibilitySettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
      return true;
    } catch (e) {
      debugPrint('Erreur ouverture paramètres accessibilité: $e');
      return false;
    }
  }

  /// Vérifier si une permission spécifique peut être accordée
  Future<bool> canRequestPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status != PermissionStatus.permanentlyDenied;
    } catch (e) {
      debugPrint('Erreur vérification permission: $e');
      return false;
    }
  }

  /// Obtenir le statut d'une permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      debugPrint('Erreur statut permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Demander une permission avec gestion des erreurs
  Future<PermissionRequestResult> requestPermissionSafely(
    Permission permission,
  ) async {
    try {
      final initialStatus = await permission.status;

      if (initialStatus == PermissionStatus.granted) {
        return PermissionRequestResult(
          permission: permission,
          status: initialStatus,
          success: true,
          canOpenSettings: false,
        );
      }

      if (initialStatus == PermissionStatus.permanentlyDenied) {
        return PermissionRequestResult(
          permission: permission,
          status: initialStatus,
          success: false,
          canOpenSettings: true,
        );
      }

      // Demander la permission
      final newStatus = await permission.request();

      return PermissionRequestResult(
        permission: permission,
        status: newStatus,
        success: newStatus == PermissionStatus.granted,
        canOpenSettings: newStatus == PermissionStatus.permanentlyDenied,
      );
    } catch (e) {
      debugPrint('Erreur demande permission: $e');
      return PermissionRequestResult(
        permission: permission,
        status: PermissionStatus.denied,
        success: false,
        canOpenSettings: true,
        error: e.toString(),
      );
    }
  }

  /// Ouvrir les paramètres appropriés pour une permission
  Future<bool> openSettingsForPermission(Permission permission) async {
    try {
      switch (permission) {
        case Permission.location:
        case Permission.locationWhenInUse:
        case Permission.locationAlways:
          return await openLocationSettings();

        case Permission.notification:
          return await openNotificationSettings();

        case Permission.bluetooth:
        case Permission.bluetoothAdvertise:
        case Permission.bluetoothConnect:
        case Permission.bluetoothScan:
          return await openBluetoothSettings();

        case Permission.microphone:
        case Permission.speech:
          return await openSoundSettings();

        default:
          return await openAppSettings();
      }
    } catch (e) {
      debugPrint('Erreur ouverture paramètres pour permission: $e');
      return await openAppSettings();
    }
  }

  /// Vérifier si les paramètres sont accessibles
  Future<bool> areSettingsAccessible() async {
    try {
      // Test simple pour vérifier l'accès aux paramètres
      await AppSettings.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('Paramètres non accessibles: $e');
      return false;
    }
  }

  /// Obtenir la liste des paramètres disponibles
  List<SettingsOption> getAvailableSettings() {
    return [
      SettingsOption(
        type: AppSettingsType.settings,
        title: 'Paramètres généraux',
        description: 'Paramètres généraux de l\'application',
        icon: Icons.settings,
      ),
      SettingsOption(
        type: AppSettingsType.notification,
        title: 'Notifications',
        description: 'Gérer les notifications',
        icon: Icons.notifications,
      ),
      SettingsOption(
        type: AppSettingsType.location,
        title: 'Localisation',
        description: 'Paramètres de géolocalisation',
        icon: Icons.location_on,
      ),
      SettingsOption(
        type: AppSettingsType.bluetooth,
        title: 'Bluetooth',
        description: 'Paramètres Bluetooth',
        icon: Icons.bluetooth,
      ),
      SettingsOption(
        type: AppSettingsType.wifi,
        title: 'WiFi',
        description: 'Paramètres réseau WiFi',
        icon: Icons.wifi,
      ),
      SettingsOption(
        type: AppSettingsType.sound,
        title: 'Son et micro',
        description: 'Paramètres audio',
        icon: Icons.volume_up,
      ),
      SettingsOption(
        type: AppSettingsType.accessibility,
        title: 'Accessibilité',
        description: 'Options d\'accessibilité',
        icon: Icons.accessibility,
      ),
    ];
  }
}

/// Résultat d'une demande de permission
class PermissionRequestResult {
  final Permission permission;
  final PermissionStatus status;
  final bool success;
  final bool canOpenSettings;
  final String? error;

  PermissionRequestResult({
    required this.permission,
    required this.status,
    required this.success,
    required this.canOpenSettings,
    this.error,
  });

  @override
  String toString() {
    return 'PermissionRequestResult(permission: $permission, status: $status, success: $success)';
  }
}

/// Option de paramètres disponible
class SettingsOption {
  final AppSettingsType type;
  final String title;
  final String description;
  final IconData icon;

  SettingsOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}
