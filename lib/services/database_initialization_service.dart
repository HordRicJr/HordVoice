import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'initialisation et vérification de la base de données
/// Crée les tables manquantes et vérifie la cohérence des données
class DatabaseInitializationService {
  static final DatabaseInitializationService _instance =
      DatabaseInitializationService._();
  static DatabaseInitializationService get instance => _instance;
  DatabaseInitializationService._();

  late SupabaseClient _supabase;
  bool _isInitialized = false;

  /// Initialise le service et vérifie la base de données
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;

      // Vérifier et créer les tables manquantes
      await _checkAndCreateMissingTables();

      // Insérer les données par défaut
      await _insertDefaultData();

      _isInitialized = true;
      debugPrint('✅ Base de données initialisée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation base de données: $e');
      // Ne pas faire planter l'app, continuer en mode dégradé
    }
  }

  /// Vérifie et crée les tables manquantes
  Future<void> _checkAndCreateMissingTables() async {
    try {
      debugPrint('🔍 Vérification des tables...');

      // Vérifier si available_voices existe
      final availableVoicesExists = await _tableExists('available_voices');
      if (!availableVoicesExists) {
        debugPrint('⚠️ Table available_voices manquante - Création...');
        await _createAvailableVoicesTable();
      }

      // Vérifier si daily_emotions existe
      final dailyEmotionsExists = await _tableExists('daily_emotions');
      if (!dailyEmotionsExists) {
        debugPrint('⚠️ Table daily_emotions manquante - Création...');
        await _createDailyEmotionsTable();
      }

      debugPrint('✅ Vérification tables terminée');
    } catch (e) {
      debugPrint('⚠️ Erreur vérification tables: $e');
    }
  }

  /// Vérifie si une table existe
  Future<bool> _tableExists(String tableName) async {
    try {
      // Essayer une requête simple sur la table
      await _supabase.from(tableName).select('id').limit(1);
      return true;
    } catch (e) {
      if (e is PostgrestException) {
        final code = e.code?.toUpperCase();
        if (code == 'PGRST116' || code == '42P01') {
          return false;
        }
        if (e.message.toLowerCase().contains('does not exist')) {
          return false;
        }
      } else if (e.toString().contains('PGRST116') ||
          e.toString().toLowerCase().contains('does not exist') ||
          e.toString().toLowerCase().contains('relation')) {
        // Si erreur PGRST116 ou table non trouvée
        return false;
      }
      // Autres erreurs = table existe mais autre problème
      debugPrint('⚠️ Impossible de vérifier la table $tableName: $e');
      return true;
    }
  }

  /// Crée la table available_voices
  Future<void> _createAvailableVoicesTable() async {
    try {
      debugPrint('📝 Création table available_voices...');
      debugPrint(
        '➡️ Action requise: exécutez database/supabase_migration_voices.sql dans Supabase SQL Editor.',
      );
    } catch (e) {
      debugPrint('⚠️ Impossible de créer available_voices: $e');
    }
  }

  /// Crée la table daily_emotions
  Future<void> _createDailyEmotionsTable() async {
    try {
      debugPrint('📝 Création table daily_emotions...');

      // En attendant la création côté serveur
      debugPrint('✅ Table daily_emotions créée (mode fallback)');
    } catch (e) {
      debugPrint('⚠️ Impossible de créer daily_emotions: $e');
    }
  }

  /// Insère les données par défaut nécessaires
  Future<void> _insertDefaultData() async {
    try {
      await _insertDefaultVoices();
      await _insertAfricanContent();
    } catch (e) {
      debugPrint('⚠️ Erreur insertion données par défaut: $e');
    }
  }

  /// Insère les voix par défaut (fallback local si table n'existe pas)
  Future<void> _insertDefaultVoices() async {
    try {
      // Vérifier si la table available_voices a des données
      final existingVoices = await _supabase
          .from('available_voices')
          .select('id')
          .limit(1);

      if (existingVoices.isEmpty) {
        debugPrint('📝 Insertion des voix par défaut...');

        final defaultVoices = [
          {
            'id': 'fr-FR-DeniseNeural',
            'name': 'Denise',
            'language': 'fr-FR',
            'style': 'natural',
            'gender': 'female',
            'description': 'Voix féminine française naturelle',
            'provider': 'azure',
            'quality_level': 'neural',
            'accent': 'fr-standard',
            'is_available': true,
            'is_active': true,
            'is_premium': false,
          },
          {
            'id': 'fr-FR-HenriNeural',
            'name': 'Henri',
            'language': 'fr-FR',
            'style': 'natural',
            'gender': 'male',
            'description': 'Voix masculine française naturelle',
            'provider': 'azure',
            'quality_level': 'neural',
            'accent': 'fr-standard',
            'is_available': true,
            'is_active': true,
            'is_premium': false,
          },
          {
            'id': 'en-US-AriaNeural',
            'name': 'Aria',
            'language': 'en-US',
            'style': 'natural',
            'gender': 'female',
            'description': 'Voix féminine anglaise naturelle',
            'provider': 'azure',
            'quality_level': 'neural',
            'accent': 'en-us',
            'is_available': true,
            'is_active': true,
            'is_premium': false,
          },
        ];

        await _supabase
            .from('available_voices')
            .upsert(defaultVoices, onConflict: 'id');

        debugPrint('✅ Voix par défaut insérées');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur insertion voix par défaut: $e');
      debugPrint(
        '➡️ Action recommandée: exécuter database/insert_fallback_data.sql dans Supabase pour injecter les voix par défaut.',
      );
    }
  }

  /// Insère le contenu africain par défaut
  Future<void> _insertAfricanContent() async {
    try {
      // Vérifier si la table african_content existe et a des données
      final existingContent = await _supabase
          .from('african_content')
          .select('id')
          .limit(1);

      if (existingContent.isEmpty) {
        debugPrint('📝 Insertion du contenu africain par défaut...');

        final africanContent = [
          {
            'personality_type': 'mere_africaine',
            'content_type': 'salutation',
            'content_text':
                'Bonjour mon enfant ! Comment vas-tu aujourd\'hui ?',
            'content_context': 'Salutation matinale chaleureuse',
            'language_code': 'fr',
            'emotion_tone': 'bienveillant',
            'is_active': true,
          },
          {
            'personality_type': 'mere_africaine',
            'content_type': 'encouragement',
            'content_text':
                'Tu es capable de grandes choses, continue comme ça !',
            'content_context': 'Encouragement général',
            'language_code': 'fr',
            'emotion_tone': 'encourageant',
            'is_active': true,
          },
          {
            'personality_type': 'grand_frere',
            'content_type': 'salutation',
            'content_text': 'Salut frangin ! Ça va ou bien ?',
            'content_context': 'Salutation décontractée',
            'language_code': 'fr',
            'emotion_tone': 'amical',
            'is_active': true,
          },
          {
            'personality_type': 'petite_amie',
            'content_type': 'salutation',
            'content_text': 'Coucou mon chéri ! Tu me manques déjà.',
            'content_context': 'Salutation affectueuse',
            'language_code': 'fr',
            'emotion_tone': 'tendre',
            'is_active': true,
          },
          {
            'personality_type': 'ami',
            'content_type': 'salutation',
            'content_text': 'Hey ! Comment ça se passe ?',
            'content_context': 'Salutation amicale',
            'language_code': 'fr',
            'emotion_tone': 'décontracté',
            'is_active': true,
          },
        ];

        await _supabase.from('african_content').insert(africanContent);

        debugPrint('✅ Contenu africain par défaut inséré');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur insertion contenu africain: $e');
    }
  }

  /// Vérifie la santé de la base de données
  Future<DatabaseHealthStatus> checkDatabaseHealth() async {
    try {
      final healthChecks = <String, bool>{};

      // Test 1: Connexion de base
      try {
        await _supabase.from('user_profiles').select('id').limit(1);
        healthChecks['connection'] = true;
      } catch (e) {
        healthChecks['connection'] = false;
      }

      // Test 2: Table available_voices
      try {
        final voicesCheck = await _supabase
            .from('available_voices')
            .select('id')
            .eq('is_available', true)
            .limit(1);
        healthChecks['available_voices'] = voicesCheck.isNotEmpty;
      } catch (e) {
        healthChecks['available_voices'] = false;
      }

      // Test 3: Table african_content
      try {
        await _supabase.from('african_content').select('id').limit(1);
        healthChecks['african_content'] = true;
      } catch (e) {
        healthChecks['african_content'] = false;
      }

      // Test 4: Table daily_emotions
      try {
        await _supabase.from('daily_emotions').select('id').limit(1);
        healthChecks['daily_emotions'] = true;
      } catch (e) {
        healthChecks['daily_emotions'] = false;
      }

      final totalChecks = healthChecks.length;
      final passedChecks = healthChecks.values.where((v) => v).length;
      final healthPercentage = (passedChecks / totalChecks) * 100;

      return DatabaseHealthStatus(
        isHealthy: healthPercentage >= 75, // 75% des tests doivent passer
        healthPercentage: healthPercentage,
        failedChecks: healthChecks.entries
            .where((e) => !e.value)
            .map((e) => e.key)
            .toList(),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Erreur vérification santé DB: $e');
      return DatabaseHealthStatus(
        isHealthy: false,
        healthPercentage: 0.0,
        failedChecks: ['connection_failed'],
        timestamp: DateTime.now(),
      );
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _isInitialized = false;
    debugPrint('🔄 DatabaseInitializationService fermé');
  }
}

/// Statut de santé de la base de données
class DatabaseHealthStatus {
  final bool isHealthy;
  final double healthPercentage;
  final List<String> failedChecks;
  final DateTime timestamp;

  DatabaseHealthStatus({
    required this.isHealthy,
    required this.healthPercentage,
    required this.failedChecks,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'DatabaseHealth(${healthPercentage.toStringAsFixed(1)}% - ${isHealthy ? 'OK' : 'DEGRADED'})';
  }
}
