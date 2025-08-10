import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
import 'services/environment_config.dart';
import 'services/permission_manager_service.dart';
import 'services/unified_hordvoice_service.dart';
import 'services/auth_service.dart';

// Theme
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';

// Views
import 'views/voice_onboarding_view.dart';
import 'views/home_view.dart';
import 'views/permissions_view.dart';
import 'views/register_view.dart';

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'écran
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: DesignTokens.lightBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Configuration d'erreur globale
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  // Activer WakeLock pour les sessions vocales
  try {
    await WakelockPlus.enable();
  } catch (e) {
    debugPrint('WakeLock non disponible: $e');
  }

  runApp(ProviderScope(child: HordVoiceApp()));
}

class HordVoiceApp extends ConsumerWidget {
  const HordVoiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'HordVoice v2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
      builder: (context, child) {
        // Gestion des erreurs UI globales
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return HordVoiceErrorWidget(errorDetails: errorDetails);
        };
        return child!;
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;

  bool _hasError = false;
  String _statusMessage = 'Initialisation de HordVoice...';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Étape 1: Configuration de l'environnement
      setState(() {
        _statusMessage = 'Configuration de l\'environnement...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final envConfig = EnvironmentConfig();
      await envConfig.loadConfig();

      // Étape 2: Initialisation de Supabase
      setState(() {
        _statusMessage = 'Initialisation de la base de données...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final supabaseUrl = envConfig.supabaseUrl;
      final supabaseKey = envConfig.supabaseAnonKey;

      if (supabaseUrl != null && supabaseKey != null) {
        try {
          await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
          debugPrint('***** Supabase init completed *****');
          // Délai pour s'assurer que l'initialisation est complète
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint('Erreur initialisation Supabase: $e');
          debugPrint('Continuons en mode déconnecté...');
        }
      } else {
        debugPrint('Supabase non configuré - fonctionnement en mode local');
      }

      // Étape 3: Vérification de l'authentification
      setState(() {
        _statusMessage = 'Vérification de l\'authentification...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final authService = AuthService();
      final isAuthenticated = await authService.isUserLoggedIn();

      if (!isAuthenticated) {
        // Redirection vers l'authentification
        setState(() {
          _statusMessage = 'Connexion requise...';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        await _fadeController.forward();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => FadeTransition(
                opacity: animation,
                child: const RegisterView(),
              ),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
        return;
      }

      // Étape 4: Vérification des permissions essentielles
      setState(() {
        _statusMessage = 'Vérification des permissions...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      final hasEssentialPermissions =
          await PermissionManagerService.hasEssentialPermissions();

      if (!hasEssentialPermissions) {
        // Redirection vers les permissions
        setState(() {
          _statusMessage = 'Configuration des permissions requise...';
        });
        await Future.delayed(const Duration(milliseconds: 800));
        await _fadeController.forward();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => FadeTransition(
                opacity: animation,
                child: const PermissionsView(),
              ),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
        return;
      }

      // Étape 3: Initialisation des services principaux
      setState(() {
        _statusMessage = 'Initialisation de l\'IA vocale...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Pré-initialisation des services critiques
      try {
        UnifiedHordVoiceService();
        // Service déjà singleton, pas besoin de pré-initialisation
      } catch (e) {
        debugPrint('Service Unity: $e');
        // Continuer même si l'initialisation échoue
      }

      // Étape 4: Configuration de l'avatar
      setState(() {
        _statusMessage = 'Configuration de l\'avatar...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        // Configuration avatar - service géré automatiquement
        debugPrint('Avatar prêt');
      } catch (e) {
        debugPrint('Avatar service: $e');
      }

      // Étape 5: Finalisation
      setState(() {
        _statusMessage = 'Finalisation...';
      });
      await Future.delayed(const Duration(milliseconds: 800));

      // Vérifier si l'onboarding vocal est nécessaire
      final needsOnboarding = await _checkNeedsOnboarding();

      await _fadeController.forward();

      // Navigation vers la vue appropriée
      if (mounted) {
        if (needsOnboarding) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => FadeTransition(
                opacity: animation,
                child: const VoiceOnboardingView(),
              ),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: const HomeView(),
              ),
              transitionDuration: const Duration(milliseconds: 1000),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur d\'initialisation: $e');
      debugPrint('Stack: $stackTrace');

      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'initialisation: ${e.toString()}';
      });
    }
  }

  Future<bool> _checkNeedsOnboarding() async {
    // CORRECTION: Ne plus afficher l'onboarding, démarrer automatiquement
    // L'IA va démarrer automatiquement et demander les paramètres vocalement
    return false; // Toujours false - l'onboarding se fait automatiquement
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return HordVoiceErrorScreen(
        errorMessage: _errorMessage,
        onRetry: () {
          setState(() {
            _hasError = false;
            _errorMessage = '';
          });
          _initializeApp();
        },
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.lightBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DesignTokens.lightBackground, Color(0xFFF0F0F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo HordVoice animé
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                DesignTokens.primaryBlue,
                                DesignTokens.accentOrange,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.primaryBlue.withOpacity(
                                  0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.record_voice_over,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Titre
              const Text(
                'HordVoice',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Assistant Vocal Intelligent',
                style: TextStyle(
                  fontSize: 16,
                  color: DesignTokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),

              // Indicateur de progression
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Barre de progression animée
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Container(
                            width: 200 * _logoAnimation.value,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  DesignTokens.primaryBlue,
                                  DesignTokens.accentOrange,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Message de statut
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey(_statusMessage),
                        style: const TextStyle(
                          fontSize: 14,
                          color: DesignTokens.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HordVoiceErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const HordVoiceErrorScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône d'erreur
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.errorRed.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: DesignTokens.errorRed,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Erreur d\'initialisation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: DesignTokens.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Bouton de retry
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HordVoiceErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const HordVoiceErrorWidget({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: DesignTokens.errorRed.withOpacity(0.1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: DesignTokens.errorRed),
                const SizedBox(height: 16),
                const Text(
                  'Une erreur est survenue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.errorRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorDetails.exception.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
