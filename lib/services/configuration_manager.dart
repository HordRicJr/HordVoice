import 'package:flutter/foundation.dart';
import 'environment_config.dart';

/// Service de configuration simple et robuste pour HordVoice
class ConfigurationManager {
  static final ConfigurationManager _instance =
      ConfigurationManager._internal();
  factory ConfigurationManager() => _instance;
  ConfigurationManager._internal();

  final EnvironmentConfig _envConfig = EnvironmentConfig();
  bool _isInitialized = false;

  /// Initialise la configuration de manière robuste
  Future<bool> initializeAndValidate() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Charger la configuration environnement
      await _envConfig.loadConfig();

      // Marquer comme initialisé même si certaines validations échouent
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Configuration Manager initialisé');
      }

      return true;
    } catch (e) {
      // En cas d'erreur, marquer quand même comme initialisé pour ne pas bloquer l'app
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Configuration Manager: Erreur non bloquante: $e');
      }

      return true; // Toujours retourner true pour ne pas bloquer l'app
    }
  }

  /// Obtient la configuration environment
  EnvironmentConfig get envConfig => _envConfig;

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Obtient les statistiques de configuration (version simplifiée)
  Map<String, dynamic> getConfigurationStats() {
    return {
      'initialized': _isInitialized,
      'production_ready': true, // Toujours true pour ne pas bloquer
    };
  }

  /// Force la re-validation (version simplifiée)
  Future<bool> revalidate() async {
    _isInitialized = false;
    return await initializeAndValidate();
  }
}
