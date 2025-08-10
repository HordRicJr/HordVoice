import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// Service d'authentification HordVoice avec intégration Supabase
/// Gère l'authentification, la création de profils et la synchronisation
class AuthService extends ChangeNotifier {
  SupabaseClient? _supabase;
  bool _isSupabaseInitialized = false;

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

  /// Initialise et récupère le client Supabase de manière sécurisée
  SupabaseClient? get client {
    try {
      if (!_isSupabaseInitialized) {
        // Vérifier si Supabase est disponible
        try {
          _supabase = Supabase.instance.client;
          _isSupabaseInitialized = true;
        } catch (e) {
          debugPrint('Supabase instance non disponible: $e');
          return null;
        }
      }
      return _supabase;
    } catch (e) {
      debugPrint('Erreur récupération client Supabase: $e');
      return null;
    }
  }

  /// Vérifie si Supabase est disponible
  bool get isSupabaseAvailable => client != null;

  /// Vérifie si un utilisateur est connecté
  Future<bool> isUserLoggedIn() async {
    try {
      // Vérifier si Supabase est disponible
      if (!isSupabaseAvailable) {
        debugPrint('Supabase non disponible - mode déconnecté');
        return false;
      }

      // Vérifier d'abord la session locale
      final session = client!.auth.currentSession;
      final user = client!.auth.currentUser;

      if (session != null && user != null) {
        // Vérifier si la session est encore valide
        if (session.expiresAt != null &&
            DateTime.now().isBefore(
              DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
            )) {
          _currentUser = user;
          return true;
        }
      }

      // Essayer de renouveler la session
      try {
        await client!.auth.refreshSession();
        final refreshedUser = client!.auth.currentUser;
        if (refreshedUser != null) {
          _currentUser = refreshedUser;
          return true;
        }
      } catch (refreshError) {
        debugPrint('Erreur renouvellement session: $refreshError');
      }

      return false;
    } catch (e) {
      debugPrint('Erreur vérification connexion: $e');
      return false;
    }
  }

  // Stream pour écouter les changements d'état d'authentification
  StreamSubscription<AuthState>? _authSubscription;

  AuthService() {
    _initializeAuth();
  }

  /// Initialise le service d'authentification
  void _initializeAuth() {
    try {
      if (isSupabaseAvailable) {
        _currentUser = client!.auth.currentUser;

        // Écouter les changements d'authentification
        _authSubscription = client!.auth.onAuthStateChange.listen((data) {
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
      } else {
        debugPrint('Supabase non disponible - mode déconnecté');
      }
    } catch (e) {
      debugPrint('Erreur initialisation auth: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isSupabaseAvailable) {
      _errorMessage = 'Service d\'authentification non disponible';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      final AuthResponse response = await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _errorMessage = null;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Échec de la connexion';
        _setLoading(false);
        return false;
      }
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  /// Inscription avec email et mot de passe
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!isSupabaseAvailable) {
      _errorMessage = 'Service d\'authentification non disponible';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      final AuthResponse response = await client!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'email': email},
      );

      if (response.user != null) {
        _currentUser = response.user;
        _errorMessage = null;

        // Créer le profil utilisateur
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );

        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Échec de l\'inscription';
        _setLoading(false);
        return false;
      }
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    if (!isSupabaseAvailable) {
      _currentUser = null;
      _currentProfile = null;
      notifyListeners();
      return;
    }

    try {
      await client!.auth.signOut();
      _currentUser = null;
      _currentProfile = null;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    if (!isSupabaseAvailable) {
      _errorMessage = 'Service d\'authentification non disponible';
      notifyListeners();
      return false;
    }

    try {
      await client!.auth.resetPasswordForEmail(
        email,
        redirectTo: 'hordvoice://reset-password',
      );
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  /// Met à jour le profil utilisateur
  Future<bool> updateProfile({
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (!isSupabaseAvailable || _currentUser == null) return false;

    try {
      await client!
          .from('user_profiles')
          .update({
            if (fullName != null) 'full_name': fullName,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (preferences != null) 'preferences': preferences,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      await _loadUserProfile();
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  /// Charge le profil de l'utilisateur connecté
  Future<void> _loadUserProfile() async {
    if (!isSupabaseAvailable || _currentUser == null) return;

    try {
      final response = await client!
          .from('user_profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single();

      _currentProfile = UserProfile.fromJson(response);
      notifyListeners();
    } catch (error) {
      debugPrint('Erreur chargement profil: $error');
      // Ne pas affecter _errorMessage pour éviter d'afficher une erreur
      // si le profil n'existe pas encore
    }
  }

  /// Crée un nouveau profil utilisateur
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    if (!isSupabaseAvailable) return;

    try {
      final profileData = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'preferences': <String, dynamic>{},
      };

      await client!.from('user_profiles').insert(profileData);
      await _loadUserProfile();
    } catch (error) {
      debugPrint('Erreur création profil: $error');
    }
  }

  /// Définit l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Convertit une erreur en message lisible
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Email ou mot de passe incorrect';
        case 'Email not confirmed':
          return 'Email non confirmé. Vérifiez votre boîte mail.';
        case 'User already registered':
          return 'Un compte existe déjà avec cet email';
        case 'Password should be at least 6 characters':
          return 'Le mot de passe doit contenir au moins 6 caractères';
        default:
          return error.message;
      }
    }
    return 'Une erreur est survenue: ${error.toString()}';
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Méthodes de validation
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }
}
