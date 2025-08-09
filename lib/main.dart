import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'services/environment_config.dart';
import 'services/permission_manager_service.dart';
import 'services/unified_hordvoice_service.dart';
import 'services/quick_settings_service.dart';
import 'services/home_widget_service.dart';
import 'services/auth_service.dart';
import 'views/voice_onboarding_view.dart';
import 'views/home_view.dart';
import 'views/permissions_view.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration système
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Chargement des variables d'environnement
  final envConfig = EnvironmentConfig();
  try {
    await envConfig.loadConfig();
    envConfig.printConfigStatus();
    debugPrint('Configuration API chargée avec succès');
  } catch (e) {
    debugPrint('Erreur lors du chargement de la configuration: $e');
    // Continuer même en cas d'erreur de configuration
  }

  // Initialiser Supabase avec les vraies clés
  try {
    final supabaseUrl = envConfig.supabaseUrl;
    final supabaseKey = envConfig.supabaseAnonKey;

    if (supabaseUrl != null && supabaseKey != null) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      debugPrint('Supabase initialisé avec succès');
    } else {
      debugPrint('Configuration Supabase manquante - mode hors ligne');
    }
  } catch (e) {
    debugPrint('Erreur initialisation Supabase: $e');
  }

  // Initialiser Quick Settings Service
  try {
    final quickSettingsService = QuickSettingsService();
    await quickSettingsService.initialize();
    debugPrint('Quick Settings Service initialisé');
  } catch (e) {
    debugPrint('Erreur initialisation Quick Settings: $e');
  }

  // Initialiser Home Widget Service
  try {
    final homeWidgetService = HomeWidgetService();
    await homeWidgetService.initialize();
    debugPrint('Home Widget Service initialisé');
  } catch (e) {
    debugPrint('Erreur initialisation Home Widget: $e');
  }

  runApp(const ProviderScope(child: HordVoiceApp()));
}

class HordVoiceApp extends StatelessWidget {
  const HordVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HordVoice v2.0',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Interface voice-first préfère le dark
      debugShowCheckedModeBanner: false,
      home: const AppInitializer(),
      routes: {
        '/voice_onboarding': (context) => const VoiceOnboardingView(),
        '/home': (context) => const HomeView(),
        '/permissions': (context) => const PermissionsView(),
      },
    );
  }
}

/// Widget d'initialisation qui détermine l'écran de démarrage
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  String _statusMessage = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Étape 1: Vérifier l'état de l'onboarding
      setState(() => _statusMessage = 'Vérification du profil...');
      await Future.delayed(const Duration(milliseconds: 500));

      final onboardingComplete =
          await PermissionManagerService.isOnboardingComplete();

      if (onboardingComplete) {
        // Étape 2: Initialiser les services pour utilisateur existant
        setState(() => _statusMessage = 'Chargement des services...');
        await _initializeServices();

        setState(() => _statusMessage = 'Prêt !');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Nouveau utilisateur - onboarding vocal
        setState(
          () => _statusMessage = 'Préparation de la configuration vocale...',
        );
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/voice_onboarding');
        }
      }
    } catch (e) {
      debugPrint('Erreur initialisation: $e');
      setState(() => _statusMessage = 'Erreur - Redémarrage...');

      // En cas d'erreur, aller à l'onboarding vocal par sécurité
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/voice_onboarding');
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialisation du service principal
      final unifiedService = UnifiedHordVoiceService();
      await unifiedService.initialize();

      debugPrint('Services HordVoice initialisés avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des services: $e');
      // Ne pas bloquer l'app si les services échouent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo central
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.mic, size: 60, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // Titre
              const Text(
                'HordVoice',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Sous-titre
              Text(
                'Assistant vocal intelligent',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(),

              // Indicateur de progression
              Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
