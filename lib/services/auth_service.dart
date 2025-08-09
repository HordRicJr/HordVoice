import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// Service d'authentification HordVoice avec intégration Supabase
/// Gère l'authentification, la création de profils et la synchronisation
class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _currentUser;
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Stream pour écouter les changements d'état d'authentification
  StreamSubscription<AuthState>? _authSubscription;

  AuthService() {
    _initializeAuth();
  }

  /// Initialise le service d'authentification
  void _initializeAuth() {
    _currentUser = _supabase.auth.currentUser;

    // Écouter les changements d'authentification
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;

      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _currentProfile = null;
      }

      notifyListeners();
    });

    // Charger le profil si déjà connecté
    if (_currentUser != null) {
      _loadUserProfile();
    }
  }

  /// Connexion avec email et mot de passe
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
        return true;
      }

      _setError('Erreur de connexion inattendue');
      return false;
    } on AuthException catch (e) {
      _setError(_getLocalizedAuthError(e.message));
      return false;
    } catch (e) {
      _setError('Erreur de connexion: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inscription avec email, mot de passe et données de profil
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? preferredLanguage = 'fr',
    String? culturalBackground = 'africain',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // 1. Créer le compte utilisateur
      final AuthResponse response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName, 'phone_number': phoneNumber},
      );

      if (response.user != null) {
        // 2. Créer le profil utilisateur dans la base de données
        await _createUserProfile(
          userId: response.user!.id,
          email: email.trim(),
          fullName: fullName,
          phoneNumber: phoneNumber,
          preferredLanguage: preferredLanguage!,
          culturalBackground: culturalBackground!,
        );

        _currentUser = response.user;
        await _loadUserProfile();

        return true;
      }

      _setError('Erreur lors de la création du compte');
      return false;
    } on AuthException catch (e) {
      _setError(_getLocalizedAuthError(e.message));
      return false;
    } catch (e) {
      _setError('Erreur d\'inscription: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabase.auth.signOut();
      _currentUser = null;
      _currentProfile = null;
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'https://hordvoice.com/reset-password',
      );

      return true;
    } on AuthException catch (e) {
      _setError(_getLocalizedAuthError(e.message));
      return false;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mise à jour du profil utilisateur
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? preferredLanguage,
    String? culturalBackground,
    String? voicePersonality,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentUser == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final Map<String, dynamic> updates = {};

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (preferredLanguage != null)
        updates['preferred_language'] = preferredLanguage;
      if (culturalBackground != null)
        updates['cultural_background'] = culturalBackground;
      if (voicePersonality != null)
        updates['voice_personality'] = voicePersonality;
      if (preferences != null) updates['user_preferences'] = preferences;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError('Erreur de mise à jour: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Charge le profil utilisateur depuis la base de données
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (response != null) {
        _currentProfile = UserProfile.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement du profil: $e');
      }
    }
  }

  /// Crée un nouveau profil utilisateur
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phoneNumber,
    required String preferredLanguage,
    required String culturalBackground,
  }) async {
    final profileData = {
      'id': userId,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'preferred_language': preferredLanguage,
      'cultural_background': culturalBackground,
      'voice_personality': 'ami', // Personnalité par défaut
      'ai_strictness_level': 3,
      'allow_reproches': true,
      'preferred_motivation_style': 'encourageant',
      'wellness_goals_active': true,
      'daily_check_in_enabled': true,
      'stress_monitoring_enabled': true,
      'relationship_mode': 'ami',
      'emotional_intelligence_level': 5.0,
      'adaptive_personality': true,
      'user_preferences': {
        'voice_speed': 1.0,
        'voice_pitch': 1.0,
        'notifications_enabled': true,
        'african_expressions': true,
        'cultural_content': true,
      },
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('user_profiles').insert(profileData);
  }

  /// Traduit les messages d'erreur d'authentification
  String _getLocalizedAuthError(String error) {
    switch (error.toLowerCase()) {
      case 'invalid login credentials':
        return 'Email ou mot de passe incorrect';
      case 'email already registered':
        return 'Cette adresse email est déjà utilisée';
      case 'email not confirmed':
        return 'Veuillez confirmer votre email avant de vous connecter';
      case 'invalid email':
        return 'Adresse email invalide';
      case 'password is too weak':
        return 'Le mot de passe est trop faible (minimum 6 caractères)';
      case 'signup disabled':
        return 'Les inscriptions sont temporairement désactivées';
      case 'email rate limit exceeded':
        return 'Trop de tentatives. Réessayez dans quelques minutes';
      default:
        return error;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validation de l'email
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validation du mot de passe
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    return null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
