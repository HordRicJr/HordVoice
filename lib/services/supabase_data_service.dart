import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de gestion des données Supabase pour HordVoice v2.0 - Version Corrigée
/// Synchronise les données locales avec la base de données complète
class SupabaseDataService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ===== GESTION DES PROFILS UTILISATEUR =====

  /// Récupère le profil utilisateur complet
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('user_profiles')
          .select('''
            *,
            user_preferences(*),
            user_sports_teams(*),
            user_music_genres(*),
            african_cultural_preferences(*)
          ''')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      _setError('Erreur lors du chargement du profil: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour le profil utilisateur
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DU CONTENU AFRICAIN =====

  /// Récupère le contenu africain personnalisé
  Future<List<Map<String, dynamic>>> getAfricanContent({
    String? category,
    String? language,
    int limit = 20,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase.from('african_content').select('*');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (language != null) {
        query = query.eq('language', language);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement du contenu: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute du contenu africain
  Future<bool> addAfricanContent(Map<String, dynamic> content) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('african_content').insert(content);
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES ÉQUIPES SPORTIVES =====

  /// Récupère les équipes sportives globales
  Future<List<Map<String, dynamic>>> getGlobalSportsTeams({
    String? sport,
    String? country,
    String? continent,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase.from('global_sports_teams').select('*');

      if (sport != null) {
        query = query.eq('sport', sport);
      }

      if (country != null) {
        query = query.eq('country', country);
      }

      if (continent != null) {
        query = query.eq('continent', continent);
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des équipes: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute une équipe sportive aux favoris de l'utilisateur
  Future<bool> addUserSportsTeam(String userId, int teamId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('user_sports_teams').insert({
        'user_id': userId,
        'team_id': teamId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de l\'équipe: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DE LA MUSIQUE =====

  /// Récupère les genres musicaux disponibles
  Future<List<Map<String, dynamic>>> getMusicGenres({
    String? category,
    String? origin,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase.from('music_genres').select('*');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (origin != null) {
        query = query.eq('origin', origin);
      }

      final response = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des genres: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un genre musical aux préférences utilisateur
  Future<bool> addUserMusicGenre(String userId, int genreId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('user_music_genres').insert({
        'user_id': userId,
        'genre_id': genreId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout du genre: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES ÉVÈNEMENTS =====

  /// Récupère les événements calendrier de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserCalendarEvents(
    String userId,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('calendar_events')
          .select('*')
          .eq('user_id', userId)
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des événements: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un événement au calendrier
  Future<bool> addCalendarEvent(Map<String, dynamic> event) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('calendar_events').insert(event);
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de l\'événement: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DU MONITORING COMPORTEMENTAL =====

  /// Enregistre le comportement utilisateur
  Future<bool> recordBehaviorData(Map<String, dynamic> behaviorData) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('behavior_monitoring').insert({
        ...behaviorData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère les données comportementales avec filtres
  Future<List<Map<String, dynamic>>> getBehaviorData(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? action,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase
          .from('behavior_monitoring')
          .select('*')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      if (action != null) {
        query = query.eq('action', action);
      }

      final response = await query.order('timestamp', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des données: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES OPPORTUNITÉS D'EMPLOI =====

  /// Récupère les opportunités d'emploi avec filtres
  Future<List<Map<String, dynamic>>> getJobOpportunities({
    String? location,
    String? industry,
    String? experienceLevel,
    int limit = 20,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase
          .from('job_opportunities')
          .select('*')
          .eq('is_active', true);

      if (location != null) {
        query = query.ilike('location', '%$location%');
      }

      if (industry != null) {
        query = query.eq('industry', industry);
      }

      if (experienceLevel != null) {
        query = query.eq('experience_level', experienceLevel);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des emplois: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== NOUVELLES FONCTIONNALITÉS V2.0 =====

  /// ===== GESTION DE LA SURVEILLANCE TÉLÉPHONE =====

  /// Enregistre une session d'utilisation du téléphone
  Future<bool> recordPhoneUsageSession(Map<String, dynamic> usageData) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('phone_usage_monitoring').insert({
        ...usageData,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement d\'usage: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère les données d'usage du téléphone
  Future<List<Map<String, dynamic>>> getPhoneUsageData(
    String userId, {
    int days = 7,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('phone_usage_monitoring')
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError(
        'Erreur lors du chargement des données d\'usage: ${e.toString()}',
      );
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DE LA SURVEILLANCE BATTERIE =====

  /// Enregistre l'état de la batterie
  Future<bool> recordBatteryStatus(Map<String, dynamic> batteryData) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('battery_health_monitoring').insert({
        ...batteryData,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement batterie: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère l'historique de la batterie
  Future<List<Map<String, dynamic>>> getBatteryHistory(
    String userId, {
    int hours = 24,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('battery_health_monitoring')
          .select('*')
          .eq('user_id', userId)
          .gte('recorded_at', startDate.toIso8601String())
          .order('recorded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError(
        'Erreur lors du chargement historique batterie: ${e.toString()}',
      );
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES RÉPONSES IA PERSONNALISÉES =====

  /// Récupère les réponses IA selon le contexte
  Future<List<Map<String, dynamic>>> getAIResponses({
    String? responseType,
    String? triggerContext,
    String? personalityType,
    String? language = 'fr',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase
          .from('ai_personality_responses')
          .select('*')
          .eq('is_active', true);

      if (responseType != null) {
        query = query.eq('response_type', responseType);
      }

      if (triggerContext != null) {
        query = query.eq('trigger_context', triggerContext);
      }

      if (personalityType != null) {
        query = query.eq('personality_type', personalityType);
      }

      if (language != null) {
        query = query.eq('language_code', language);
      }

      final response = await query.order('usage_count', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des réponses IA: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Incrémente l'utilisation d'une réponse IA
  Future<bool> incrementAIResponseUsage(
    String responseId,
    bool userReactionPositive,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final Map<String, dynamic> updates = {
        'usage_count': _supabase.rpc(
          'increment_usage_count',
          params: {'response_id': responseId},
        ),
      };

      if (userReactionPositive) {
        updates['user_reaction_positive'] = _supabase.rpc(
          'increment_positive_reaction',
          params: {'response_id': responseId},
        );
      } else {
        updates['user_reaction_negative'] = _supabase.rpc(
          'increment_negative_reaction',
          params: {'response_id': responseId},
        );
      }

      await _supabase
          .from('ai_personality_responses')
          .update(updates)
          .eq('id', responseId);

      return true;
    } catch (e) {
      // Fallback si les fonctions RPC n'existent pas
      try {
        final response = await _supabase
            .from('ai_personality_responses')
            .select(
              'usage_count, user_reaction_positive, user_reaction_negative',
            )
            .eq('id', responseId)
            .single();

        final updates = {
          'usage_count': (response['usage_count'] as int) + 1,
          if (userReactionPositive)
            'user_reaction_positive':
                (response['user_reaction_positive'] as int) + 1
          else
            'user_reaction_negative':
                (response['user_reaction_negative'] as int) + 1,
        };

        await _supabase
            .from('ai_personality_responses')
            .update(updates)
            .eq('id', responseId);

        return true;
      } catch (fallbackError) {
        _setError('Erreur lors de la mise à jour: ${fallbackError.toString()}');
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES OBJECTIFS DE BIEN-ÊTRE =====

  /// Récupère les objectifs de bien-être actifs
  Future<List<Map<String, dynamic>>> getWellnessGoals(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('wellness_goals_tracking')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des objectifs: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Met à jour la progression d'un objectif
  Future<bool> updateGoalProgress(String goalId, double currentValue) async {
    try {
      _setLoading(true);
      _clearError();

      // Récupérer l'objectif actuel
      final goal = await _supabase
          .from('wellness_goals_tracking')
          .select('target_value, streak_days, best_streak')
          .eq('id', goalId)
          .single();

      final targetValue = goal['target_value'] as double;
      final streakDays = goal['streak_days'] as int;
      final bestStreak = goal['best_streak'] as int;

      final achievementPercentage = (currentValue / targetValue * 100).clamp(
        0,
        100,
      );
      final isAchieved = currentValue >= targetValue;

      final updates = {
        'current_value': currentValue,
        'achievement_percentage': achievementPercentage,
        'is_achieved': isAchieved,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isAchieved) {
        final newStreak = streakDays + 1;
        updates['streak_days'] = newStreak;
        updates['best_streak'] = newStreak > bestStreak
            ? newStreak
            : bestStreak;
      }

      await _supabase
          .from('wellness_goals_tracking')
          .update(updates)
          .eq('id', goalId);

      return true;
    } catch (e) {
      _setError(
        'Erreur lors de la mise à jour de l\'objectif: ${e.toString()}',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DE LA MÉMOIRE ÉMOTIONNELLE IA =====

  /// Enregistre une interaction émotionnelle
  Future<bool> recordEmotionalInteraction(
    Map<String, dynamic> interactionData,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('ai_emotional_memory').insert({
        ...interactionData,
        'interaction_date': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement émotionnel: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère l'historique émotionnel pour personnalisation
  Future<List<Map<String, dynamic>>> getEmotionalHistory(
    String userId, {
    int days = 30,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabase
          .from('ai_emotional_memory')
          .select('*')
          .eq('user_id', userId)
          .gte('interaction_date', startDate.toIso8601String())
          .order('interaction_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError(
        'Erreur lors du chargement historique émotionnel: ${e.toString()}',
      );
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES PRÉFÉRENCES CULTURELLES =====

  /// Met à jour les préférences culturelles africaines
  Future<bool> updateAfricanCulturalPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      // Vérifier si les préférences existent déjà
      final existing = await _supabase
          .from('african_cultural_preferences')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Mettre à jour
        await _supabase
            .from('african_cultural_preferences')
            .update(preferences)
            .eq('user_id', userId);
      } else {
        // Créer
        await _supabase.from('african_cultural_preferences').insert({
          ...preferences,
          'user_id': userId,
        });
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour culturelle: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ===== GESTION DES NOUVELLES =====

  /// Récupère les nouvelles personnalisées
  Future<List<Map<String, dynamic>>> getPersonalizedNews(
    String userId, {
    String? category,
    String? language,
    int limit = 10,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      var query = _supabase
          .from('news_articles')
          .select('*')
          .eq('is_published', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (language != null) {
        query = query.eq('language', language);
      }

      final response = await query
          .order('published_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setError('Erreur lors du chargement des nouvelles: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// ===== MÉTHODES UTILITAIRES =====

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Synchronise toutes les données utilisateur
  Future<Map<String, dynamic>?> syncAllUserData(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Récupération en parallèle de toutes les données principales
      final results = await Future.wait([
        getUserProfile(userId),
        getUserCalendarEvents(userId),
        getBehaviorData(userId),
        getPersonalizedNews(userId),
        getWellnessGoals(userId),
        getPhoneUsageData(userId),
        getBatteryHistory(userId),
        getEmotionalHistory(userId),
      ]);

      return {
        'profile': results[0],
        'calendar_events': results[1],
        'behavior_data': results[2],
        'news': results[3],
        'wellness_goals': results[4],
        'phone_usage': results[5],
        'battery_history': results[6],
        'emotional_history': results[7],
        'sync_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _setError('Erreur lors de la synchronisation complète: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Calcule le score de bien-être utilisateur
  Future<double> calculateWellnessScore(String userId) async {
    try {
      final goals = await getWellnessGoals(userId);
      if (goals.isEmpty) return 5.0;

      double totalScore = 0;
      for (final goal in goals) {
        final achievement = goal['achievement_percentage'] as double? ?? 0;
        totalScore += achievement;
      }

      return (totalScore / goals.length / 100 * 10).clamp(0, 10);
    } catch (e) {
      return 5.0; // Score neutre en cas d'erreur
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
