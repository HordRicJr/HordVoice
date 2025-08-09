import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'azure_speech_service.dart';
import 'environment_config.dart';

/// Service de détection de mots déclencheurs utilisant Azure Speech NBest
/// Implémente l'algorithme complet de détection avec gestion des confidences
/// et confirmation des détections incertaines
class AzureWakeWordService {
  static final AzureWakeWordService _instance =
      AzureWakeWordService._internal();
  factory AzureWakeWordService() => _instance;
  AzureWakeWordService._internal();

  // Configuration
  final EnvironmentConfig _envConfig = EnvironmentConfig();
  late AzureSpeechService _speechService;

  // État de détection
  bool _isInitialized = false;
  bool _isListening = false;
  DateTime _lastDetectionTime = DateTime(1970);

  // Configuration de détection
  static const List<String> _wakeWords = [
    'salut rick',
    'salut ric',
    'rick',
    'ric',
    'hey rick',
    'bonjour rick',
  ];

  // Seuils de confiance (recommandés selon votre algorithme)
  static const double _acceptThreshold = 0.65; // ACCEPTER immédiatement
  static const double _alternativeThreshold = 0.50; // ACCEPTER avec cooldown
  static const double _uncertainThreshold = 0.35; // ATTENDRE renforcement
  static const Duration _cooldownDuration = Duration(seconds: 3);
  static const Duration _reinforcementTimeout = Duration(seconds: 2);

  // Phrase hints pour améliorer la reconnaissance
  static const List<String> _phraseHints = [
    'salut rick',
    'salut ric',
    'rick',
    'ric',
    'hey rick',
    'bonjour rick',
    'salut r',
    'hey ric',
  ];

  // Controllers pour les streams
  final StreamController<WakeWordDetectionResult> _detectionController =
      StreamController.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController.broadcast();
  final StreamController<WakeWordConfirmationRequest> _confirmationController =
      StreamController.broadcast();

  // Streams publics
  Stream<WakeWordDetectionResult> get detectionStream =>
      _detectionController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<WakeWordConfirmationRequest> get confirmationStream =>
      _confirmationController.stream;

  // État public
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  /// Initialise le service Azure Wake Word
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _envConfig.loadConfig();
      _speechService = AzureSpeechService();
      await _speechService.initialize();

      // Configuration des phrase hints pour améliorer la reconnaissance
      await _configurePhraseHints();

      _isInitialized = true;
      debugPrint('Azure Wake Word Service initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur initialisation Azure Wake Word Service: $e');
      rethrow;
    }
  }

  /// Configure les phrase hints pour Azure Speech
  Future<void> _configurePhraseHints() async {
    try {
      // Ajouter les phrase hints pour améliorer la reconnaissance
      // Note: Cette fonctionnalité dépend de l'implémentation du SDK Azure Speech
      debugPrint('Configuration des phrase hints: $_phraseHints');
    } catch (e) {
      debugPrint('Erreur configuration phrase hints: $e');
    }
  }

  /// Démarre l'écoute continue pour la détection de mots déclencheurs
  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    try {
      _isListening = true;

      // Écouter les résultats de reconnaissance avec NBest
      _speechService.resultStream.listen(_processRecognitionResult);
      _speechService.errorStream.listen(_handleError);

      // Démarrer la reconnaissance continue
      await _speechService.startListening();

      debugPrint('Écoute de mots déclencheurs démarrée');
    } catch (e) {
      _isListening = false;
      debugPrint('Erreur démarrage écoute: $e');
      rethrow;
    }
  }

  /// Arrête l'écoute de mots déclencheurs
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechService.stopListening();
      _isListening = false;
      debugPrint('Écoute de mots déclencheurs arrêtée');
    } catch (e) {
      debugPrint('Erreur arrêt écoute: $e');
    }
  }

  /// Traite les résultats de reconnaissance selon l'algorithme NBest
  void _processRecognitionResult(SpeechRecognitionResult result) {
    if (!result.isFinal) return;

    try {
      // Simuler la structure NBest d'Azure (en attendant l'implémentation réelle)
      final nbestData = _parseRecognitionResult(result);

      // Appliquer l'algorithme de détection
      final detection = _analyzeNBestForWakeWord(nbestData);

      if (detection != null) {
        _handleWakeWordDetection(detection);
      }

      // Émettre la transcription pour debug
      _transcriptionController.add(result.recognizedText);
    } catch (e) {
      debugPrint('Erreur traitement résultat: $e');
    }
  }

  /// Parse le résultat de reconnaissance pour extraire les données NBest
  /// Note: Cette fonction simule la structure NBest en attendant l'API réelle
  Map<String, dynamic> _parseRecognitionResult(SpeechRecognitionResult result) {
    // Simulation de la structure NBest d'Azure Speech
    // Dans la réalité, cette structure viendrait directement d'Azure
    return {
      'DisplayText': result.recognizedText,
      'NBest': [
        {
          'Lexical': _normalize(result.recognizedText),
          'Confidence': result.confidence,
          'Display': result.recognizedText,
          'ITN': result.recognizedText,
          'MaskedITN': result.recognizedText,
        },
      ],
      'Offset': 0,
      'Duration': 0,
    };
  }

  /// Algorithme principal d'analyse NBest pour détecter les mots déclencheurs
  WakeWordDetectionCandidate? _analyzeNBestForWakeWord(
    Map<String, dynamic> nbestData,
  ) {
    final List<dynamic> nbestList = nbestData['NBest'] ?? [];
    if (nbestList.isEmpty) return null;

    double bestWakeConf = 0.0;
    String? matchedText;
    String? originalHypothesis;

    // 1. Examiner chaque hypothèse NBest
    for (final hypothesis in nbestList) {
      final String text = _normalize(hypothesis['Lexical'] ?? '');
      final double confidence = (hypothesis['Confidence'] ?? 0.0).toDouble();

      // 2. Détecter le wake-word dans cette hypothèse
      final wakeWordMatch = _detectWakeWordInText(text);

      if (wakeWordMatch.isMatch) {
        if (confidence > bestWakeConf) {
          bestWakeConf = confidence;
          matchedText = wakeWordMatch.matchedWord;
          originalHypothesis = hypothesis['Display'] ?? text;
        }
      }
    }

    // 3. Si aucun wake-word détecté, vérifier avec fuzzy matching
    if (bestWakeConf == 0.0) {
      for (final hypothesis in nbestList) {
        final String text = _normalize(hypothesis['Lexical'] ?? '');
        final double confidence = (hypothesis['Confidence'] ?? 0.0).toDouble();

        final fuzzyMatch = _fuzzyMatchWakeWord(text);
        if (fuzzyMatch.isMatch && confidence >= 0.30) {
          bestWakeConf = confidence * 0.8; // Réduire confiance pour fuzzy match
          matchedText = fuzzyMatch.matchedWord;
          originalHypothesis = hypothesis['Display'] ?? text;
          break;
        }
      }
    }

    if (bestWakeConf == 0.0) return null;

    // 4. Vérifier la confiance de la meilleure hypothèse globale
    final double topConf = (nbestList[0]['Confidence'] ?? 0.0).toDouble();
    final String topText = _normalize(nbestList[0]['Lexical'] ?? '');

    // Si la meilleure hypothèse est très confiante mais ne contient pas le wake-word, ignorer
    if (topConf > 0.9 && !_detectWakeWordInText(topText).isMatch) {
      debugPrint('Hypothèse principale très confiante sans wake-word, ignoré');
      return null;
    }

    // 5. Calculer l'action selon les seuils
    WakeWordAction action;
    if (bestWakeConf >= _acceptThreshold) {
      action = WakeWordAction.accept;
    } else if (bestWakeConf >= _alternativeThreshold) {
      action = WakeWordAction.acceptWithCooldown;
    } else if (bestWakeConf >= _uncertainThreshold) {
      action = WakeWordAction.requestConfirmation;
    } else {
      action = WakeWordAction.ignore;
    }

    return WakeWordDetectionCandidate(
      confidence: bestWakeConf,
      matchedText: matchedText ?? '',
      originalText: originalHypothesis ?? '',
      topConfidence: topConf,
      action: action,
      timestamp: DateTime.now(),
    );
  }

  /// Détecte la présence exacte d'un wake-word dans le texte
  WakeWordMatch _detectWakeWordInText(String text) {
    for (final wakeWord in _wakeWords) {
      if (text.contains(wakeWord)) {
        return WakeWordMatch(isMatch: true, matchedWord: wakeWord);
      }
    }
    return WakeWordMatch(isMatch: false, matchedWord: '');
  }

  /// Effectue une correspondance floue (fuzzy matching) pour les wake-words
  WakeWordMatch _fuzzyMatchWakeWord(String text) {
    final words = text.split(' ');

    for (final word in words) {
      for (final wakeWord in _wakeWords) {
        // Pour les mots courts (3-5 lettres), tolérance = 1
        // Pour les mots plus longs, tolérance = 2
        final tolerance = wakeWord.length <= 5 ? 1 : 2;

        if (_levenshteinDistance(word, wakeWord) <= tolerance) {
          return WakeWordMatch(isMatch: true, matchedWord: wakeWord);
        }
      }
    }

    return WakeWordMatch(isMatch: false, matchedWord: '');
  }

  /// Calcule la distance de Levenshtein entre deux chaînes
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Normalise le texte (minuscules, suppression ponctuation, trim)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Gère la détection d'un mot déclencheur selon l'action déterminée
  void _handleWakeWordDetection(WakeWordDetectionCandidate candidate) {
    final now = DateTime.now();

    // Vérifier le cooldown
    if (now.difference(_lastDetectionTime) < _cooldownDuration) {
      debugPrint('Détection ignorée - cooldown actif');
      return;
    }

    switch (candidate.action) {
      case WakeWordAction.accept:
        _acceptWakeWord(candidate);
        break;

      case WakeWordAction.acceptWithCooldown:
        _acceptWakeWordWithCooldown(candidate);
        break;

      case WakeWordAction.requestConfirmation:
        _requestConfirmation(candidate);
        break;

      case WakeWordAction.ignore:
        debugPrint(
          'Wake-word détecté mais confiance trop faible: ${candidate.confidence}',
        );
        break;
    }
  }

  /// Accepte immédiatement le wake-word (confiance élevée)
  void _acceptWakeWord(WakeWordDetectionCandidate candidate) {
    debugPrint(
      'Wake-word accepté: ${candidate.matchedText} (conf: ${candidate.confidence})',
    );

    _lastDetectionTime = DateTime.now();
    HapticFeedback.lightImpact();

    _detectionController.add(
      WakeWordDetectionResult(
        isDetected: true,
        confidence: candidate.confidence,
        matchedText: candidate.matchedText,
        originalText: candidate.originalText,
        needsConfirmation: false,
        timestamp: candidate.timestamp,
      ),
    );
  }

  /// Accepte le wake-word avec cooldown court (confiance moyenne)
  void _acceptWakeWordWithCooldown(WakeWordDetectionCandidate candidate) {
    debugPrint(
      'Wake-word accepté avec cooldown: ${candidate.matchedText} (conf: ${candidate.confidence})',
    );

    _lastDetectionTime = DateTime.now();
    HapticFeedback.lightImpact();

    _detectionController.add(
      WakeWordDetectionResult(
        isDetected: true,
        confidence: candidate.confidence,
        matchedText: candidate.matchedText,
        originalText: candidate.originalText,
        needsConfirmation: false,
        timestamp: candidate.timestamp,
      ),
    );
  }

  /// Demande une confirmation vocale (confiance incertaine)
  void _requestConfirmation(WakeWordDetectionCandidate candidate) {
    debugPrint(
      'Demande de confirmation: ${candidate.matchedText} (conf: ${candidate.confidence})',
    );

    final confirmationRequest = WakeWordConfirmationRequest(
      candidate: candidate,
      question: 'Tu m\'as appelé \'Rick\' ?',
      timeout: _reinforcementTimeout,
    );

    _confirmationController.add(confirmationRequest);
  }

  /// Confirme un wake-word après validation utilisateur
  void confirmWakeWord(WakeWordDetectionCandidate candidate, bool confirmed) {
    if (confirmed) {
      debugPrint(
        'Wake-word confirmé par utilisateur: ${candidate.matchedText}',
      );

      _lastDetectionTime = DateTime.now();
      HapticFeedback.lightImpact();

      _detectionController.add(
        WakeWordDetectionResult(
          isDetected: true,
          confidence: candidate.confidence,
          matchedText: candidate.matchedText,
          originalText: candidate.originalText,
          needsConfirmation: false,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      debugPrint('Wake-word rejeté par utilisateur: ${candidate.matchedText}');
    }
  }

  /// Gère les erreurs de reconnaissance
  void _handleError(SpeechRecognitionError error) {
    debugPrint('Erreur reconnaissance wake-word: ${error.errorMessage}');

    _detectionController.add(
      WakeWordDetectionResult(
        isDetected: false,
        confidence: 0.0,
        matchedText: '',
        originalText: '',
        needsConfirmation: false,
        timestamp: DateTime.now(),
        error: error.errorMessage,
      ),
    );
  }

  /// Force la détection d'un wake-word (pour tests/debug)
  void forceDetection() {
    _detectionController.add(
      WakeWordDetectionResult(
        isDetected: true,
        confidence: 1.0,
        matchedText: 'rick',
        originalText: 'Force detection',
        needsConfirmation: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Nettoie les ressources
  void dispose() {
    _detectionController.close();
    _transcriptionController.close();
    _confirmationController.close();
  }
}

// Modèles de données

class WakeWordDetectionResult {
  final bool isDetected;
  final double confidence;
  final String matchedText;
  final String originalText;
  final bool needsConfirmation;
  final DateTime timestamp;
  final String? error;

  const WakeWordDetectionResult({
    required this.isDetected,
    required this.confidence,
    required this.matchedText,
    required this.originalText,
    required this.needsConfirmation,
    required this.timestamp,
    this.error,
  });
}

class WakeWordDetectionCandidate {
  final double confidence;
  final String matchedText;
  final String originalText;
  final double topConfidence;
  final WakeWordAction action;
  final DateTime timestamp;

  const WakeWordDetectionCandidate({
    required this.confidence,
    required this.matchedText,
    required this.originalText,
    required this.topConfidence,
    required this.action,
    required this.timestamp,
  });
}

class WakeWordConfirmationRequest {
  final WakeWordDetectionCandidate candidate;
  final String question;
  final Duration timeout;

  const WakeWordConfirmationRequest({
    required this.candidate,
    required this.question,
    required this.timeout,
  });
}

class WakeWordMatch {
  final bool isMatch;
  final String matchedWord;

  const WakeWordMatch({required this.isMatch, required this.matchedWord});
}

enum WakeWordAction { accept, acceptWithCooldown, requestConfirmation, ignore }
