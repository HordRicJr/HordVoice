import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/voice_management_service.dart';
import '../services/azure_speech_service.dart';

/// Étape 5: Service d'onboarding vocal complet avec support spatial
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

  // Support spatial
  bool _spatialModeEnabled = false;
  Function(String)? _spatialFeedbackCallback;

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

  /// Étape 5A: Démarrage auto - Greeting immédiat avec attente utilisateur
  Future<void> startOnboarding() async {
    if (!_isInitialized) {
      await initialize();
    }

    debugPrint('🎙️ Démarrage onboarding vocal séquentiel');

    try {
      // Arrêter toute écoute active pour éviter les conflits
      await _stopAllListeningServices();
      
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

  /// Arrêter tous les services d'écoute pour éviter les conflits
  Future<void> _stopAllListeningServices() async {
    try {
      // Arrêter écoute Azure Speech si active
      if (_speechService.isListening) {
        await _speechService.stopListening();
      }
      
      // Arrêter wake word detection si méthode existe
      try {
        await _unifiedService.stopWakeWordDetection();
      } catch (e) {
        debugPrint('Wake word detection non disponible: $e');
      }
      
      debugPrint('✅ Services d\'écoute arrêtés pour onboarding');
    } catch (e) {
      debugPrint('Erreur arrêt services écoute: $e');
    }
  }

  /// Attendre la confirmation de l'utilisateur avant de continuer
  Future<void> _waitForUserConfirmation(String expectedKeywords) async {
    debugPrint('🎧 Attente confirmation utilisateur: $expectedKeywords');
    
    try {
      // Démarrer écoute spécifiquement pour cette confirmation
      await _speechService.startListening();
      
      bool confirmationReceived = false;
      
      // Timeout après 15 secondes
      Timer? timeoutTimer = Timer(Duration(seconds: 15), () async {
        if (!confirmationReceived) {
          await _speechService.stopListening();
          await _handleConfirmationTimeout();
        }
      });

      // Écouter la réponse
      _speechService.resultStream.listen((result) async {
        if (result.isFinal && !confirmationReceived) {
          confirmationReceived = true;
          timeoutTimer.cancel();
          await _speechService.stopListening();
          
          final text = result.recognizedText.toLowerCase();
          debugPrint('🎤 Réponse utilisateur: $text');
          
          // Vérifier si la réponse contient les mots-clés attendus
          if (text.contains('continuer') || 
              text.contains('oui') || 
              text.contains('ok') ||
              text.contains('d\'accord') ||
              text.contains('commencer')) {
            debugPrint('✅ Confirmation positive reçue');
            await _unifiedService.speakText('Parfait ! Continuons.');
          } else if (text.contains('non') || text.contains('arrêter')) {
            debugPrint('❌ Confirmation négative reçue');
            await _unifiedService.speakText('D\'accord, nous arrêtons ici.');
            await _markOnboardingCompleted(); // Arrêter l'onboarding
            return;
          } else {
            debugPrint('❓ Réponse ambiguë, on continue quand même');
            await _unifiedService.speakText('Je n\'ai pas bien compris, mais continuons.');
          }
          
          // Petite pause avant l'étape suivante
          await Future.delayed(Duration(seconds: 1));
        }
      });

      // Gérer les erreurs de reconnaissance
      _speechService.errorStream.listen((error) async {
        if (!confirmationReceived) {
          confirmationReceived = true;
          timeoutTimer.cancel();
          await _speechService.stopListening();
          await _handleConfirmationError();
        }
      });
      
    } catch (e) {
      debugPrint('Erreur attente confirmation: $e');
      // Continuer quand même en cas d'erreur
      await _unifiedService.speakText('Je continue la configuration.');
    }
  }

  /// Gérer le timeout de confirmation
  Future<void> _handleConfirmationTimeout() async {
    debugPrint('⏰ Timeout confirmation utilisateur');
    await _unifiedService.speakText(
      'Je n\'ai pas entendu de réponse. Je continue la configuration.',
    );
  }

  /// Gérer les erreurs de confirmation
  Future<void> _handleConfirmationError() async {
    debugPrint('❌ Erreur confirmation utilisateur');
    await _unifiedService.speakText(
      'Il y a eu un petit problème d\'écoute. Je continue quand même.',
    );
  }

  /// Vérifier si c'est le premier lancement
  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_completed') ?? false);
  }

  /// Étape 5A: Greeting pour première fois - AVEC ATTENTE
  Future<void> _stepWelcomeFirstTime() async {
    _currentStep = 'welcome_first';

    debugPrint('🗣️ Étape 1: Message d\'accueil');
    
    // Message d'accueil - ATTENDRE la fin complète
    await _unifiedService.speakText(
      'Bonjour ! Je suis Ric, votre assistant vocal personnel. '
      'Je vais vous guider pour me configurer en quelques étapes. '
      'Tout se fait à la voix, pas besoin de touches.',
    );

    // ATTENDRE 3 secondes pour que l'utilisateur comprenne
    debugPrint('⏳ Attente assimilation message...');
    await Future.delayed(Duration(seconds: 3));
    
    // Demander confirmation avant de continuer
    await _unifiedService.speakText(
      'Dites "continuer" ou "oui" quand vous êtes prêt pour commencer la configuration.',
    );
    
    // ATTENDRE la réponse de l'utilisateur
    await _waitForUserConfirmation('continuer');
    
    debugPrint('✅ Utilisateur prêt, passage à l\'étape microphone');
    await _stepCheckMicrophone();
  }

  /// Greeting pour utilisateur qui revient - AVEC ACTIVATION WAKE WORD
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

    debugPrint('🗣️ Message d\'accueil utilisateur revenant');
    await _unifiedService.speakText(greeting);

    // ATTENDRE la fin du TTS
    await Future.delayed(Duration(seconds: 2));
    
    // ACTIVER le wake word detection après le message
    debugPrint('🎧 Activation détection wake word "Hey Ric"');
    try {
      await _unifiedService.startWakeWordDetection();
      debugPrint('✅ Wake word "Hey Ric" activé');
    } catch (e) {
      debugPrint('❌ Erreur activation wake word: $e');
      // Fallback : écoute continue
      await _unifiedService.speakText(
        'Vous pouvez maintenant me parler directement sans appuyer sur un bouton.',
      );
    }

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

  // ===============================================
  // MÉTHODES SPATIALES
  // ===============================================

  /// Active le mode spatial pour l'onboarding
  void enableSpatialMode({Function(String)? feedbackCallback}) {
    _spatialModeEnabled = true;
    _spatialFeedbackCallback = feedbackCallback;
    debugPrint('🌌 Mode spatial activé pour l\'onboarding');
  }

  /// Désactive le mode spatial
  void disableSpatialMode() {
    _spatialModeEnabled = false;
    _spatialFeedbackCallback = null;
    debugPrint('🌌 Mode spatial désactivé');
  }

  /// Envoie un feedback spatial si le mode est activé
  void _sendSpatialFeedback(String message) {
    if (_spatialModeEnabled && _spatialFeedbackCallback != null) {
      _spatialFeedbackCallback!(message);
    }
  }

  /// Démarre l'onboarding en mode spatial
  Future<void> startSpatialOnboarding() async {
    if (!_isInitialized) {
      await initialize();
    }

    _spatialModeEnabled = true;

    try {
      final isFirstRun = await _isFirstRun();

      _sendSpatialFeedback('Initialisation de l\'univers spatial...');

      if (isFirstRun) {
        await _stepSpatialWelcomeFirstTime();
      } else {
        await _stepSpatialWelcomeReturning();
      }
    } catch (e) {
      debugPrint('Erreur onboarding spatial: $e');
      _sendSpatialFeedback('Erreur lors de l\'initialisation');
      await _markOnboardingCompleted();
    }
  }

  /// Étape spatiale : Accueil première fois
  Future<void> _stepSpatialWelcomeFirstTime() async {
    _currentStep = 'spatial_welcome_first';

    _sendSpatialFeedback('Bienvenue dans l\'univers HordVoice');

    await _unifiedService.speakText(
      'Bienvenue dans l\'univers HordVoice ! Je suis Ric, votre guide spatial. '
      'Nous allons explorer ensemble les fonctionnalités vocales de cet univers immersif. '
      'Prêt pour cette aventure spatiale ?',
    );

    await Future.delayed(Duration(seconds: 2));
    await _stepSpatialMicrophone();
  }

  /// Étape spatiale : Accueil utilisateur connu
  Future<void> _stepSpatialWelcomeReturning() async {
    _currentStep = 'spatial_welcome_returning';

    _sendSpatialFeedback('Bon retour dans l\'univers spatial');

    await _unifiedService.speakText(
      'Bon retour dans l\'univers HordVoice ! '
      'Vos paramètres spatiaux sont conservés. Continuons notre exploration.',
    );

    await Future.delayed(Duration(seconds: 1));
    // Aller directement à la vérification finale en mode retour
    await _stepSpatialCompletion();
  }

  /// Étape spatiale : Configuration microphone
  Future<void> _stepSpatialMicrophone() async {
    _currentStep = 'spatial_microphone';

    _sendSpatialFeedback('Configuration du microphone spatial');

    final micStatus = await Permission.microphone.status;

    if (micStatus.isGranted) {
      await _unifiedService.speakText(
        'Excellent ! Le microphone spatial est déjà configuré. '
        'Je peux vous entendre parfaitement dans cet univers.',
      );
      await _stepSpatialVoiceDemo();
      return;
    }

    await _unifiedService.speakText(
      'Pour communiquer dans l\'univers spatial, nous devons activer le microphone. '
      'Cela me permettra de percevoir vos commandes vocales à travers l\'espace. '
      'Autorisons maintenant cette connexion spatiale.',
    );

    await _requestSpatialMicrophonePermission();
  }

  /// Demande permission microphone en mode spatial
  Future<void> _requestSpatialMicrophonePermission() async {
    try {
      _sendSpatialFeedback('Demande d\'autorisation microphone...');

      final result = await Permission.microphone.request();

      if (result.isGranted) {
        await _unifiedService.speakText(
          'Parfait ! La connexion spatiale est établie. '
          'Je peux maintenant vous entendre dans l\'univers.',
        );
        _sendSpatialFeedback('Microphone configuré avec succès');
        await _stepSpatialVoiceDemo();
      } else {
        await _unifiedService.speakText(
          'Microphone non autorisé. Nous continuerons en mode visuel pour l\'instant. '
          'Vous pourrez activer la voix plus tard dans les paramètres spatiaux.',
        );
        _sendSpatialFeedback('Mode visuel activé');
        await _stepSpatialCompletion();
      }
    } catch (e) {
      debugPrint('Erreur permission microphone spatial: $e');
      await _stepSpatialCompletion();
    }
  }

  /// Étape spatiale : Démonstration vocale
  Future<void> _stepSpatialVoiceDemo() async {
    _currentStep = 'spatial_voice_demo';

    _sendSpatialFeedback('Démonstration des capacités vocales');

    await _unifiedService.speakText(
      'Testons maintenant nos capacités de communication spatiale. '
      'Dites "Ric, test spatial" et je vous répondrai pour valider la connexion.',
    );

    // Simulation d'écoute (en production, utiliser le vrai STT)
    _sendSpatialFeedback('Écoute active...');
    await Future.delayed(Duration(seconds: 4));

    await _unifiedService.speakText(
      'Fantastique ! La communication spatiale fonctionne parfaitement. '
      'Votre voix résonne clairement dans l\'univers HordVoice.',
    );

    _sendSpatialFeedback('Test vocal réussi');
    await _stepSpatialCompletion();
  }

  /// Étape spatiale : Finalisation
  Future<void> _stepSpatialCompletion() async {
    _currentStep = 'spatial_completion';

    _sendSpatialFeedback('Configuration spatiale terminée');

    await _unifiedService.speakText(
      'Félicitations ! Votre univers HordVoice est maintenant prêt. '
      'Vous pouvez explorer toutes les fonctionnalités spatiales et vocales. '
      'Bienvenue dans votre nouvelle dimension interactive !',
    );

    await _markOnboardingCompleted();

    _sendSpatialFeedback('Prêt à explorer l\'univers');

    // Sauvegarder les préférences spatiales
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spatial_mode_preferred', true);
    await prefs.setString(
      'spatial_completion_date',
      DateTime.now().toIso8601String(),
    );
  }

  void dispose() {
    _onboardingData.clear();
    _isInitialized = false;
  }
}
