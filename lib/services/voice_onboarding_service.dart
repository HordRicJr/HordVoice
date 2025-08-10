import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/voice_management_service.dart';
import '../services/azure_speech_service.dart';

/// Étape 5: Service d'onboarding vocal complet
class VoiceOnboardingService {
  static final VoiceOnboardingService _instance =
      VoiceOnboardingService._internal();
  factory VoiceOnboardingService() => _instance;
  VoiceOnboardingService._internal();

  late UnifiedHordVoiceService _unifiedService;
  late VoiceManagementService _voiceService;
  late AzureSpeechService _speechService;

  bool _isInitialized = false;
  String _currentStep = 'welcome';
  Map<String, dynamic> _onboardingData = {};

  // Compteurs pour retry et timeouts
  int _micPermissionRetries = 0;
  int _voiceSelectionRetries = 0;
  final int _maxRetries = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _unifiedService = UnifiedHordVoiceService();
      _voiceService = VoiceManagementService();
      _speechService = AzureSpeechService();

      // UnifiedHordVoiceService est un singleton déjà initialisé - éviter la boucle infinie
      debugPrint('Service unifié récupéré depuis le singleton');

      await _voiceService.initialize().catchError((e) {
        debugPrint('Service vocal non disponible (continuer): $e');
      });

      await _speechService.initialize().catchError((e) {
        debugPrint('Service speech non disponible (continuer): $e');
      });

      _isInitialized = true;
      debugPrint('VoiceOnboardingService initialisé (mode graceful)');
    } catch (e) {
      debugPrint('Erreur initialisation VoiceOnboardingService: $e');
      // Ne pas lancer d'exception - continuer en mode dégradé
      _isInitialized = true;
    }
  }

  /// Étape 5A: Démarrage auto - Greeting immédiat
  Future<void> startOnboarding() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final isFirstRun = await _isFirstRun();

      if (isFirstRun) {
        await _stepWelcomeFirstTime();
      } else {
        await _stepWelcomeReturning();
      }
    } catch (e) {
      debugPrint('Erreur démarrage onboarding: $e');
      // Fallback graceful
      try {
        await _unifiedService
            .speakText('Bienvenue dans HordVoice. Configuration en cours.')
            .catchError((e) {
              debugPrint('TTS non disponible: $e');
            });
      } catch (fallbackError) {
        debugPrint('Fallback TTS échoué: $fallbackError');
      }

      // Marquer comme terminé pour éviter les boucles d'erreur
      await _markOnboardingCompleted();
    }
  }

  /// Vérifier si c'est le premier lancement
  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_completed') ?? false);
  }

  /// Étape 5A: Greeting pour première fois
  Future<void> _stepWelcomeFirstTime() async {
    _currentStep = 'welcome_first';

    await _unifiedService.speakText(
      'Bonjour ! Je suis Ric, votre assistant vocal personnel. '
      'Je vais vous guider pour me configurer en quelques étapes. '
      'Tout se fait à la voix, pas besoin de touches.',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepCheckMicrophone();
  }

  /// Greeting pour utilisateur qui revient
  Future<void> _stepWelcomeReturning() async {
    _currentStep = 'welcome_returning';

    final now = DateTime.now();
    String greeting;

    if (now.hour < 12) {
      greeting =
          'Bonjour ! Ric à votre service. Dites "Hey Ric" pour commencer.';
    } else if (now.hour < 18) {
      greeting =
          'Bel après-midi ! Je suis prêt. Dites "Hey Ric" quand vous voulez.';
    } else {
      greeting = 'Bonsoir ! Ric est là. Réveillez-moi avec "Hey Ric".';
    }

    await _unifiedService.speakText(greeting);

    // Marquer l'onboarding comme terminé pour les prochaines fois
    await _markOnboardingCompleted();
  }

  /// Étape 5A: Vérification microphone avec rationale vocal
  Future<void> _stepCheckMicrophone() async {
    _currentStep = 'microphone_check';

    final micStatus = await Permission.microphone.status;

    if (micStatus.isGranted) {
      await _unifiedService.speakText(
        'Parfait, le microphone est autorisé. Continuons.',
      );
      await Future.delayed(Duration(seconds: 1));
      await _stepVoiceSelection();
      return;
    }

    // Rationale vocal avant demande permission
    await _unifiedService.speakText(
      'Pour m\'écouter et exécuter vos commandes à la voix, j\'ai besoin d\'accéder au microphone. '
      'Dites "oui" pour autoriser maintenant, ou "non" si vous préférez configurer manuellement.',
    );

    await _listenForMicrophonePermission();
  }

  /// Écouter réponse permission microphone
  Future<void> _listenForMicrophonePermission() async {
    try {
      await _speechService.startListening();

      // Timeout après 10 secondes
      Timer? timeoutTimer = Timer(Duration(seconds: 10), () async {
        await _speechService.stopListening();
        await _handleMicrophoneTimeout();
      });

      // Écouter résultat
      _speechService.resultStream.listen((result) async {
        if (result.isFinal) {
          timeoutTimer.cancel();
          await _speechService.stopListening();
          await _processMicrophoneResponse(result.recognizedText);
        }
      });

      // Écouter erreurs
      _speechService.errorStream.listen((error) async {
        timeoutTimer.cancel();
        debugPrint('Erreur STT permission micro: ${error.errorMessage}');
        await _handleMicrophoneError();
      });
    } catch (e) {
      debugPrint('Erreur écoute permission micro: $e');
      await _handleMicrophoneError();
    }
  }

  /// Traiter réponse permission microphone
  Future<void> _processMicrophoneResponse(String response) async {
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains(
      RegExp(r'\b(oui|ok|accord|autoriser?|accepte?r?)\b'),
    )) {
      await _requestMicrophonePermission();
    } else if (lowerResponse.contains(
      RegExp(r'\b(non|pas|refus[ez]?|jamais)\b'),
    )) {
      await _handleMicrophoneRefused();
    } else {
      // Réponse non comprise
      _micPermissionRetries++;
      if (_micPermissionRetries < _maxRetries) {
        await _unifiedService.speakText(
          'Désolé, je n\'ai pas compris. Dites "oui" pour autoriser ou "non" pour refuser.',
        );
        await _listenForMicrophonePermission();
      } else {
        await _handleMicrophoneTimeout();
      }
    }
  }

  /// Demander permission microphone système
  Future<void> _requestMicrophonePermission() async {
    try {
      await _unifiedService.speakText(
        'Je lance la demande d\'autorisation. Veuillez accepter dans la popup.',
      );

      final permission = await Permission.microphone.request();

      if (permission.isGranted) {
        await _unifiedService.speakText(
          'Merci ! Microphone activé. Continuons avec le choix de votre voix.',
        );
        await Future.delayed(Duration(seconds: 1));
        await _stepVoiceSelection();
      } else if (permission.isDenied) {
        await _handleMicrophoneRefused();
      } else if (permission.isPermanentlyDenied) {
        await _handleMicrophonePermanentlyDenied();
      }
    } catch (e) {
      debugPrint('Erreur demande permission: $e');
      await _handleMicrophoneError();
    }
  }

  /// Gérer refus permission microphone
  Future<void> _handleMicrophoneRefused() async {
    await _unifiedService.speakText(
      'D\'accord. Sans microphone, je ne pourrai pas écouter automatiquement. '
      'Vous pouvez l\'autoriser plus tard dans les paramètres de l\'application. '
      'Veux-tu que je t\'explique comment faire ?',
    );

    // Pour l'instant, continuer l'onboarding sans micro
    await Future.delayed(Duration(seconds: 3));
    await _stepVoiceSelection();
  }

  /// Gérer permission microphone bloquée définitivement
  Future<void> _handleMicrophonePermanentlyDenied() async {
    await _unifiedService.speakText(
      'Permission microphone bloquée. Pour m\'utiliser, veuillez aller dans Paramètres > Applications > HordVoice > Autorisations et activer le microphone. '
      'Je continue la configuration en attendant.',
    );

    await Future.delayed(Duration(seconds: 3));
    await _stepVoiceSelection();
  }

  /// Gérer timeout ou erreur microphone
  Future<void> _handleMicrophoneTimeout() async {
    await _unifiedService.speakText(
      'Je n\'ai pas entendu de réponse. Je continue avec la configuration. '
      'Vous pourrez autoriser le microphone plus tard.',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepVoiceSelection();
  }

  /// Gérer erreur microphone
  Future<void> _handleMicrophoneError() async {
    await _unifiedService.speakText(
      'Problème technique avec le microphone. Continuons la configuration. '
      'Vous pourrez configurer l\'audio plus tard.',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepVoiceSelection();
  }

  /// Étape 5B: Choix de voix voice-only
  Future<void> _stepVoiceSelection() async {
    _currentStep = 'voice_selection';

    await _unifiedService.speakText('Maintenant, choisissons ma voix.');
    await Future.delayed(Duration(seconds: 1));

    // Générer liste vocale
    final voiceListResponse = _voiceService.generateVoiceListResponse();
    await _unifiedService.speakText(voiceListResponse);

    await _listenForVoiceSelection();
  }

  /// Écouter sélection de voix
  Future<void> _listenForVoiceSelection() async {
    try {
      await _speechService.startListening();

      Timer? timeoutTimer = Timer(Duration(seconds: 15), () async {
        await _speechService.stopListening();
        await _handleVoiceSelectionTimeout();
      });

      _speechService.resultStream.listen((result) async {
        if (result.isFinal) {
          timeoutTimer.cancel();
          await _speechService.stopListening();
          await _processVoiceSelection(result.recognizedText);
        }
      });

      _speechService.errorStream.listen((error) async {
        timeoutTimer.cancel();
        await _handleVoiceSelectionError();
      });
    } catch (e) {
      await _handleVoiceSelectionError();
    }
  }

  /// Traiter sélection de voix
  Future<void> _processVoiceSelection(String response) async {
    final result = await _voiceService.selectVoiceByName(response);

    if (!result.contains('Désolé')) {
      // Succès - jouer aperçu dans nouvelle voix
      await _unifiedService.speakText(result);

      final selectedVoice = _voiceService.selectedVoice;
      if (selectedVoice != null) {
        final preview = await _voiceService.generateVoicePreview(selectedVoice);
        await _unifiedService.speakText(preview);
      }

      await Future.delayed(Duration(seconds: 2));
      await _stepPersonalitySelection();
    } else {
      // Échec
      _voiceSelectionRetries++;
      if (_voiceSelectionRetries < _maxRetries) {
        await _unifiedService.speakText(result);
        await _listenForVoiceSelection();
      } else {
        await _useDefaultVoice();
      }
    }
  }

  /// Utiliser voix par défaut
  Future<void> _useDefaultVoice() async {
    await _unifiedService.speakText(
      'Aucun problème, je garde ma voix par défaut. Vous pourrez la changer plus tard en disant "quelles voix".',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepPersonalitySelection();
  }

  /// Gérer timeout sélection voix
  Future<void> _handleVoiceSelectionTimeout() async {
    await _unifiedService.speakText(
      'Pas de réponse. Je garde ma voix actuelle. Dites "quelles voix" plus tard pour changer.',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepPersonalitySelection();
  }

  /// Gérer erreur sélection voix
  Future<void> _handleVoiceSelectionError() async {
    await _unifiedService.speakText(
      'Problème technique. Je garde ma voix par défaut. Continuons.',
    );

    await Future.delayed(Duration(seconds: 1));
    await _stepPersonalitySelection();
  }

  /// Étape 5C: Choix personnalité IA voice-only
  Future<void> _stepPersonalitySelection() async {
    _currentStep = 'personality_selection';

    await _unifiedService.speakText(
      'Maintenant, choisissez mon style de conversation. '
      'Dites "style mère" pour une approche bienveillante et protectrice, '
      '"style ami" pour un ton décontracté et complice, '
      'ou "style assistant" pour un comportement professionnel.',
    );

    await _listenForPersonalitySelection();
  }

  /// Écouter sélection personnalité
  Future<void> _listenForPersonalitySelection() async {
    try {
      await _speechService.startListening();

      Timer? timeoutTimer = Timer(Duration(seconds: 12), () async {
        await _speechService.stopListening();
        await _useDefaultPersonality();
      });

      _speechService.resultStream.listen((result) async {
        if (result.isFinal) {
          timeoutTimer.cancel();
          await _speechService.stopListening();
          await _processPersonalitySelection(result.recognizedText);
        }
      });
    } catch (e) {
      await _useDefaultPersonality();
    }
  }

  /// Traiter sélection personnalité
  Future<void> _processPersonalitySelection(String response) async {
    final lowerResponse = response.toLowerCase();
    String personality = 'ami'; // défaut
    String confirmationText = '';

    if (lowerResponse.contains('mère') || lowerResponse.contains('maman')) {
      personality = 'mere_africaine';
      confirmationText =
          'Style maternel activé. Je serai bienveillante et protectrice avec vous.';
    } else if (lowerResponse.contains('ami') ||
        lowerResponse.contains('complice')) {
      personality = 'ami';
      confirmationText = 'Style ami activé. On va bien s\'entendre !';
    } else if (lowerResponse.contains('assistant') ||
        lowerResponse.contains('professionnel')) {
      personality = 'assistant_pro';
      confirmationText =
          'Style professionnel activé. Je serai efficace et précise.';
    } else {
      // Pas compris - utiliser ami par défaut
      confirmationText =
          'Je n\'ai pas bien compris. J\'adopte un style amical par défaut.';
    }

    // Sauvegarder choix
    _onboardingData['personality'] = personality;
    await _savePersonalityChoice(personality);

    await _unifiedService.speakText(confirmationText);
    await Future.delayed(Duration(seconds: 2));
    await _stepFinalTest();
  }

  /// Utiliser personnalité par défaut
  Future<void> _useDefaultPersonality() async {
    _onboardingData['personality'] = 'ami';
    await _savePersonalityChoice('ami');

    await _unifiedService.speakText(
      'Aucune réponse. J\'adopte un style amical par défaut. Vous pourrez le changer plus tard.',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepFinalTest();
  }

  /// Étape 5D: Test interactif final
  Future<void> _stepFinalTest() async {
    _currentStep = 'final_test';

    await _unifiedService.speakText(
      'Parfait ! Configuration terminée. Faisons un test rapide. '
      'Dites "Bonjour Ric" pour voir comment je réagis.',
    );

    await _listenForFinalTest();
  }

  /// Écouter test final
  Future<void> _listenForFinalTest() async {
    try {
      await _speechService.startListening();

      Timer? timeoutTimer = Timer(Duration(seconds: 8), () async {
        await _speechService.stopListening();
        await _completeOnboardingWithoutTest();
      });

      _speechService.resultStream.listen((result) async {
        if (result.isFinal) {
          timeoutTimer.cancel();
          await _speechService.stopListening();
          await _processFinalTest(result.recognizedText);
        }
      });
    } catch (e) {
      await _completeOnboardingWithoutTest();
    }
  }

  /// Traiter test final
  Future<void> _processFinalTest(String response) async {
    // Simuler réponse interactive basée sur personnalité
    final personality = _onboardingData['personality'] ?? 'ami';
    String testResponse = '';

    switch (personality) {
      case 'mere_africaine':
        testResponse =
            'Bonjour mon enfant ! Je suis là pour veiller sur vous. Comment allez-vous aujourd\'hui ?';
        break;
      case 'assistant_pro':
        testResponse =
            'Bonjour. Je suis opérationnelle et prête à vous assister. Que puis-je faire pour vous ?';
        break;
      default: // ami
        testResponse =
            'Salut ! Content de te parler ! Alors, qu\'est-ce qu\'on fait ensemble aujourd\'hui ?';
    }

    await _unifiedService.speakText(testResponse);
    await Future.delayed(Duration(seconds: 3));
    await _completeOnboardingSuccessfully();
  }

  /// Finaliser onboarding sans test
  Future<void> _completeOnboardingWithoutTest() async {
    await _unifiedService.speakText(
      'Aucun problème ! Configuration terminée. Je suis maintenant prêt à vous assister. '
      'Dites "Hey Ric" pour me réveiller à tout moment.',
    );

    await _markOnboardingCompleted();
  }

  /// Finaliser onboarding avec succès
  Future<void> _completeOnboardingSuccessfully() async {
    await _unifiedService.speakText(
      'Excellent ! Je suis maintenant configuré et prêt. '
      'Pour me réveiller, dites simplement "Hey Ric". '
      'Bienvenue dans votre expérience vocale personnalisée !',
    );

    await _markOnboardingCompleted();
  }

  /// Sauvegarder choix personnalité
  Future<void> _savePersonalityChoice(String personality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_personality', personality);
      debugPrint('Personnalité sauvegardée: $personality');
    } catch (e) {
      debugPrint('Erreur sauvegarde personnalité: $e');
    }
  }

  /// Marquer onboarding comme terminé
  Future<void> _markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setString(
        'onboarding_completion_date',
        DateTime.now().toIso8601String(),
      );

      debugPrint('Onboarding vocal terminé avec succès');
    } catch (e) {
      debugPrint('Erreur marquage onboarding: $e');
    }
  }

  // Getters
  String get currentStep => _currentStep;
  Map<String, dynamic> get onboardingData => Map.unmodifiable(_onboardingData);
  bool get isInitialized => _isInitialized;

  /// Reset onboarding (pour dev/debug)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('onboarding_completion_date');
    await prefs.remove('selected_personality');
    _onboardingData.clear();
    _currentStep = 'welcome';
    debugPrint('Onboarding réinitialisé');
  }

  void dispose() {
    _onboardingData.clear();
    _isInitialized = false;
  }
}
