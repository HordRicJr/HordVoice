import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'advanced_permission_manager.dart';
import 'azure_speech_service.dart';
import 'unified_hordvoice_service.dart';

/// Service vocal pour la gestion des permissions avec explications vocales
class VoicePermissionService {
  static final VoicePermissionService _instance =
      VoicePermissionService._internal();
  factory VoicePermissionService() => _instance;
  VoicePermissionService._internal();

  final AdvancedPermissionManager _permissionManager =
      AdvancedPermissionManager();
  AzureSpeechService? _speechService;
  UnifiedHordVoiceService? _hordVoiceService;

  bool _isInitialized = false;
  bool _isListening = false;

  /// Scripts vocaux pour chaque catégorie de permissions
  static const Map<String, Map<String, String>> _voiceScripts = {
    'essential': {
      'introduction':
          'Pour commencer, j\'ai besoin d\'accéder à votre microphone. C\'est essentiel pour que je puisse vous entendre et vous répondre.',
      'rationale':
          'Le microphone me permet de vous écouter quand vous me parlez, et la synthèse vocale me permet de vous répondre clairement. Sans ces permissions, je ne peux pas fonctionner comme assistant vocal.',
      'request':
          'Puis-je avoir accès à votre microphone maintenant ? Dites "oui" pour accepter ou "non" pour refuser.',
      'granted':
          'Parfait ! Je peux maintenant vous entendre et vous parler. C\'est la base de notre communication.',
      'denied':
          'Je comprends votre hésitation. Sachez que ces permissions sont nécessaires pour que je fonctionne. Vous pouvez les activer plus tard dans les paramètres.',
      'retry':
          'Voulez-vous réessayer d\'activer le microphone ? Dites "oui" pour réessayer ou "non" pour continuer.',
    },
    'core_features': {
      'introduction':
          'Maintenant, parlons des fonctionnalités principales. Pour vous aider au quotidien, j\'aimerais accéder à votre position, vos contacts, et pouvoir passer des appels.',
      'rationale':
          'Avec votre localisation, je peux vous donner la météo locale, vous guider en navigation, et trouver des services près de chez vous. L\'accès aux contacts me permet de vous appeler qui vous voulez juste en disant leur nom.',
      'request':
          'Puis-je avoir accès à votre position et vos contacts ? Cela rendra nos interactions beaucoup plus utiles.',
      'granted':
          'Excellent ! Je peux maintenant vous aider avec la navigation, la météo, et passer des appels pour vous.',
      'denied':
          'Pas de problème. Vous pourrez quand même utiliser HordVoice, mais certaines fonctionnalités comme la navigation vocale ne seront pas disponibles.',
      'retry':
          'Souhaitez-vous reconsidérer ces permissions ? Elles rendent vraiment HordVoice plus pratique au quotidien.',
    },
    'enhanced_experience': {
      'introduction':
          'Pour une expérience encore plus riche, je peux aussi accéder à votre agenda, vous envoyer des notifications, et me connecter à vos appareils Bluetooth.',
      'rationale':
          'Votre agenda me permet de vous rappeler vos rendez-vous. Les notifications m\'aident à vous alerter d\'informations importantes. Bluetooth me permet de fonctionner avec vos écouteurs ou votre voiture.',
      'request':
          'Voulez-vous activer ces fonctionnalités avancées ? Elles ne sont pas obligatoires mais enrichissent vraiment l\'expérience.',
      'granted':
          'Formidable ! HordVoice peut maintenant gérer votre agenda, vous notifier, et fonctionner avec vos appareils Bluetooth.',
      'denied':
          'C\'est tout à fait compréhensible. Ces fonctionnalités sont optionnelles et vous pourrez les activer plus tard si vous changez d\'avis.',
      'retry':
          'Ces fonctionnalités améliorent vraiment le quotidien. Voulez-vous les essayer maintenant ?',
    },
    'storage_system': {
      'introduction':
          'Enfin, pour personnaliser votre expérience, j\'aimerais pouvoir sauvegarder vos préférences et votre profil vocal.',
      'rationale':
          'Le stockage me permet de me souvenir de vos préférences, de votre voix calibrée, et de vos habitudes. Cela rend chaque interaction plus personnelle et efficace.',
      'request':
          'Puis-je sauvegarder vos données personnelles sur votre appareil ? Tout reste privé et local.',
      'granted':
          'Parfait ! Je vais maintenant pouvoir mémoriser vos préférences et m\'adapter à votre utilisation.',
      'denied':
          'Je comprends. Vos données restent importantes. Notez que sans stockage, je ne pourrai pas mémoriser vos préférences entre les sessions.',
      'retry':
          'Le stockage local améliore vraiment la personnalisation. Êtes-vous sûr de ne pas vouloir l\'activer ?',
    },
  };

  /// Réponses vocales possibles de l'utilisateur
  static const Map<String, List<String>> _voiceResponses = {
    'yes': [
      'oui',
      'yes',
      'ok',
      'd\'accord',
      'accepte',
      'autoriser',
      'vas-y',
      'bien sûr',
      'parfait',
    ],
    'no': [
      'non',
      'no',
      'refuser',
      'pas maintenant',
      'plus tard',
      'jamais',
      'ça va',
    ],
    'retry': ['réessayer', 'essayer', 'retry', 'encore', 'reprendre'],
    'help': ['aide', 'help', 'expliquer', 'pourquoi', 'comment'],
    'skip': ['passer', 'skip', 'suivant', 'ignorer', 'continuer'],
  };

  /// Initialiser le service
  Future<void> initialize({
    required AzureSpeechService speechService,
    required UnifiedHordVoiceService hordVoiceService,
  }) async {
    debugPrint('Initialisation VoicePermissionService');

    _speechService = speechService;
    _hordVoiceService = hordVoiceService;

    await _permissionManager.initialize();

    _isInitialized = true;
    debugPrint('VoicePermissionService initialisé');
  }

  /// Demander permissions avec interface vocale complète
  Future<VoicePermissionResult> requestPermissionsWithVoice({
    required String category,
    required BuildContext context,
    bool allowRetry = true,
    int maxRetries = 2,
  }) async {
    if (!_isInitialized) {
      throw StateError('VoicePermissionService pas initialisé');
    }

    debugPrint('Demande permissions vocales: $category');

    try {
      // Phase 1: Introduction et explication
      await _speakScript(category, 'introduction');
      await Future.delayed(const Duration(milliseconds: 500));

      await _speakScript(category, 'rationale');
      await Future.delayed(const Duration(milliseconds: 800));

      // Phase 2: Demande avec écoute de réponse
      await _speakScript(category, 'request');

      final userResponse = await _listenForPermissionResponse();

      if (userResponse == 'help') {
        await _provideAdditionalHelp(category);
        return await requestPermissionsWithVoice(
          category: category,
          context: context,
          allowRetry: allowRetry,
          maxRetries: maxRetries - 1,
        );
      }

      if (userResponse == 'skip') {
        await _hordVoiceService?.speakText(
          'Très bien, nous passons cette étape.',
        );
        return VoicePermissionResult(
          category: category,
          userChoice: 'skip',
          permissionResult: null,
          voiceInteractionSuccess: true,
        );
      }

      // Phase 3: Traitement de la réponse
      if (userResponse == 'yes') {
        // Demander les permissions système
        final result = await _permissionManager.requestPermissionsByCategory(
          category,
          showRationale: false, // Déjà fait vocalement
          context: context,
        );

        if (result.success) {
          await _speakScript(category, 'granted');
          return VoicePermissionResult(
            category: category,
            userChoice: 'accepted',
            permissionResult: result,
            voiceInteractionSuccess: true,
          );
        } else {
          // Permissions refusées au niveau système
          await _handleSystemDenial(category, result);
          return VoicePermissionResult(
            category: category,
            userChoice: 'accepted_but_denied',
            permissionResult: result,
            voiceInteractionSuccess: true,
          );
        }
      } else if (userResponse == 'no') {
        await _speakScript(category, 'denied');

        // Proposer retry si autorisé
        if (allowRetry && maxRetries > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _speakScript(category, 'retry');

          final retryResponse = await _listenForPermissionResponse();
          if (retryResponse == 'yes') {
            return await requestPermissionsWithVoice(
              category: category,
              context: context,
              allowRetry: false,
              maxRetries: 0,
            );
          }
        }

        return VoicePermissionResult(
          category: category,
          userChoice: 'refused',
          permissionResult: null,
          voiceInteractionSuccess: true,
        );
      } else {
        // Réponse non comprise
        await _hordVoiceService?.speakText(
          'Je n\'ai pas bien compris. Pouvez-vous dire "oui" pour accepter ou "non" pour refuser ?',
        );

        if (maxRetries > 0) {
          return await requestPermissionsWithVoice(
            category: category,
            context: context,
            allowRetry: allowRetry,
            maxRetries: maxRetries - 1,
          );
        } else {
          return VoicePermissionResult(
            category: category,
            userChoice: 'unclear',
            permissionResult: null,
            voiceInteractionSuccess: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur permissions vocales $category: $e');
      await _hordVoiceService?.speakText(
        'Désolé, il y a eu un problème avec les permissions. Nous allons continuer.',
      );

      return VoicePermissionResult(
        category: category,
        userChoice: 'error',
        permissionResult: null,
        voiceInteractionSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Dire un script vocal pour une catégorie
  Future<void> _speakScript(String category, String scriptType) async {
    final script = _voiceScripts[category]?[scriptType];
    if (script != null && _hordVoiceService != null) {
      await _hordVoiceService!.speakText(script);
    }
  }

  /// Écouter la réponse de l'utilisateur pour les permissions
  Future<String> _listenForPermissionResponse() async {
    if (_speechService == null) return 'error';

    try {
      _isListening = true;
      debugPrint('Écoute réponse permission...');

      // Utiliser la reconnaissance simple avec timeout intégré
      final response = await _speechService!.startSimpleRecognition();

      _isListening = false;

      if (response == null || response.isEmpty) {
        debugPrint('Aucune réponse détectée');
        return 'timeout';
      }

      final normalizedResponse = response.toLowerCase().trim();
      debugPrint('Réponse reçue: "$normalizedResponse"');

      // Analyser la réponse
      for (final entry in _voiceResponses.entries) {
        final intent = entry.key;
        final patterns = entry.value;

        for (final pattern in patterns) {
          if (normalizedResponse.contains(pattern)) {
            debugPrint('Intent détecté: $intent');
            return intent;
          }
        }
      }

      debugPrint('Réponse non reconnue: "$normalizedResponse"');
      return 'unclear';
    } catch (e) {
      debugPrint('Erreur écoute permission: $e');
      _isListening = false;
      return 'error';
    }
  }

  /// Fournir aide supplémentaire
  Future<void> _provideAdditionalHelp(String category) async {
    final categoryData = AdvancedPermissionManager.getCategoryInfo(category);
    final name = categoryData['name'] ?? category;

    await _hordVoiceService?.speakText(
      'Les permissions $name sont utilisées pour améliorer votre expérience avec HordVoice. '
      'Vous gardez le contrôle total et pouvez les modifier à tout moment dans les paramètres. '
      'Souhaitez-vous les activer maintenant ?',
    );
  }

  /// Gérer refus au niveau système
  Future<void> _handleSystemDenial(
    String category,
    PermissionRequestResult result,
  ) async {
    final hasPermanentDenials = result.deniedPermissions.values.any(
      (status) => status == PermissionStatus.permanentlyDenied,
    );

    if (hasPermanentDenials) {
      await _hordVoiceService?.speakText(
        'Il semble que ces permissions soient bloquées dans vos paramètres système. '
        'Vous pouvez les activer manuellement dans les paramètres de l\'application si vous le souhaitez.',
      );
    } else {
      await _hordVoiceService?.speakText(
        'Ces permissions ont été refusées. Pas de problème, vous pourrez les activer plus tard si nécessaire.',
      );
    }
  }

  /// Traiter toutes les catégories de permissions avec voix
  Future<List<VoicePermissionResult>> requestAllPermissionsWithVoice({
    required BuildContext context,
    List<String>? categories,
  }) async {
    final categoriesToProcess =
        categories ?? AdvancedPermissionManager.availableCategories;

    final results = <VoicePermissionResult>[];

    await _hordVoiceService?.speakText(
      'Je vais maintenant vous demander quelques permissions pour améliorer votre expérience HordVoice. '
      'Pour chacune, je vous expliquerai pourquoi elle est utile.',
    );

    for (final category in categoriesToProcess) {
      debugPrint('Traitement vocal catégorie: $category');

      final result = await requestPermissionsWithVoice(
        category: category,
        context: context,
      );

      results.add(result);

      // Pause entre catégories
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Résumé final
    await _provideFinalSummary(results);

    return results;
  }

  /// Fournir résumé final des permissions
  Future<void> _provideFinalSummary(List<VoicePermissionResult> results) async {
    final accepted = results.where((r) => r.userChoice == 'accepted').length;
    final total = results.length;

    if (accepted == total) {
      await _hordVoiceService?.speakText(
        'Parfait ! Toutes les permissions sont activées. HordVoice est maintenant prêt à vous offrir la meilleure expérience possible.',
      );
    } else if (accepted > 0) {
      await _hordVoiceService?.speakText(
        'Merci ! J\'ai activé $accepted permissions sur $total. '
        'HordVoice fonctionne et vous pourrez activer les autres plus tard si vous le souhaitez.',
      );
    } else {
      await _hordVoiceService?.speakText(
        'Je comprends votre prudence avec les permissions. '
        'HordVoice fonctionnera avec les capacités de base et vous pourrez activer d\'autres fonctionnalités plus tard.',
      );
    }
  }

  /// Getters pour l'état
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  /// Arrêter l'écoute en cours
  Future<void> stopListening() async {
    if (_isListening && _speechService != null) {
      await _speechService!.stopListening();
      _isListening = false;
    }
  }
}

/// Résultat d'une interaction vocale de permission
class VoicePermissionResult {
  final String category;
  final String userChoice; // 'accepted', 'refused', 'skip', 'unclear', 'error'
  final PermissionRequestResult? permissionResult;
  final bool voiceInteractionSuccess;
  final String? error;

  VoicePermissionResult({
    required this.category,
    required this.userChoice,
    required this.permissionResult,
    required this.voiceInteractionSuccess,
    this.error,
  });

  bool get wasGranted => permissionResult?.success ?? false;
  bool get wasRefused =>
      userChoice == 'refused' || userChoice == 'accepted_but_denied';
  bool get wasSkipped => userChoice == 'skip';

  @override
  String toString() {
    return 'VoicePermissionResult(category: $category, choice: $userChoice, granted: $wasGranted)';
  }
}
