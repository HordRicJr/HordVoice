import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'environment_config.dart';
import 'camera_emotion_analysis_service.dart';

class EmotionAnalysisService {
  late http.Client _client;
  bool _isInitialized = false;
  final EnvironmentConfig _envConfig = EnvironmentConfig();

  // Service caméra pour analyse visuelle
  final CameraEmotionAnalysisService _cameraService =
      CameraEmotionAnalysisService();

  // Étape 7: Smoothing et cache d'émotion
  String _lastEmotion = 'neutral';
  double _lastConfidence = 0.0;
  DateTime _lastAnalysis = DateTime.now();
  final double _smoothingThreshold = 0.6; // Seuil de changement
  final Duration _cacheTimeout = Duration(seconds: 30);

  // Stream combiné audio + visuel
  final StreamController<Map<String, dynamic>> _emotionController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get emotionStream => _emotionController.stream;

  Future<void> initialize() async {
    _client = http.Client();
    _isInitialized = true;
    debugPrint('EmotionAnalysisService initialisé avec analyse multimodale');

    // Initialiser le service caméra (optionnel)
    try {
      await _cameraService.initialize();
      debugPrint('Service caméra intégré pour analyse émotionnelle');
    } catch (e) {
      debugPrint('Service caméra non disponible: $e');
    }
  }

  /// Analyse émotionnelle par texte (existant)
  Future<String> analyzeEmotion(String text) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    // Étape 7: Vérifier le cache pour éviter trop d'appels
    if (DateTime.now().difference(_lastAnalysis) < _cacheTimeout &&
        text.length < 20) {
      return _lastEmotion;
    }

    try {
      await _envConfig.loadConfig();

      final response = await _client.post(
        Uri.parse(
          '${_envConfig.azureLanguageEndpoint}text/analytics/v3.1/sentiment',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Ocp-Apim-Subscription-Key': _envConfig.azureLanguageKey ?? '',
        },
        body: jsonEncode({
          'documents': [
            {'id': '1', 'language': 'fr', 'text': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sentiment = data['documents'][0]['sentiment'];
        final confidence = data['documents'][0]['confidenceScores'];

        String newEmotion;
        double newConfidence = 0.5;

        switch (sentiment) {
          case 'positive':
            newEmotion = _getPositiveEmotion(text);
            newConfidence = confidence['positive'] ?? 0.5;
            break;
          case 'negative':
            newEmotion = _getNegativeEmotion(text);
            newConfidence = confidence['negative'] ?? 0.5;
            break;
          default:
            newEmotion = 'neutral';
            newConfidence = confidence['neutral'] ?? 0.5;
        }

        // Étape 7: Appliquer le smoothing
        return _applyEmotionSmoothing(newEmotion, newConfidence);
      } else {
        debugPrint('Erreur API Azure Language: ${response.statusCode}');
        return _analyzeFallbackEmotion(text);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'analyse d\'émotion: $e');
      return _analyzeFallbackEmotion(text);
    }
  }

  /// Étape 7: Fusion texte + audio (placeholder pour Azure ML endpoint)
  Future<Map<String, dynamic>> analyzeEmotionMultimodal({
    required String text,
    List<double>? audioFeatures,
  }) async {
    try {
      // Pour l'instant, analyse texte seulement
      // TODO: Ajouter appel Azure ML endpoint pour fusion audio
      final textEmotion = await analyzeEmotion(text);

      return {
        'emotion': textEmotion,
        'confidence': _lastConfidence,
        'source': audioFeatures != null ? 'multimodal' : 'text_only',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur analyse multimodale: $e');
      return {
        'emotion': 'neutral',
        'confidence': 0.3,
        'source': 'fallback',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Étape 7: Smoothing pour éviter flicker d'émotion
  String _applyEmotionSmoothing(String newEmotion, double newConfidence) {
    // Si confidence trop faible, garder l'émotion précédente
    if (newConfidence < _smoothingThreshold) {
      return _lastEmotion;
    }

    // Si même émotion, pas de changement
    if (newEmotion == _lastEmotion) {
      _lastConfidence = newConfidence;
      _lastAnalysis = DateTime.now();
      return newEmotion;
    }

    // Changement d'émotion avec confidence suffisante
    _lastEmotion = newEmotion;
    _lastConfidence = newConfidence;
    _lastAnalysis = DateTime.now();

    debugPrint(
      'Émotion changée: $_lastEmotion (conf: ${newConfidence.toStringAsFixed(2)})',
    );
    return newEmotion;
  }

  String _getPositiveEmotion(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains(
      RegExp(r'\b(super|génial|fantastique|excellent|parfait|magnifique)\b'),
    )) {
      return 'joie';
    }
    if (lowerText.contains(
      RegExp(r'\b(merci|reconnaissance|gratitude|reconnaissant)\b'),
    )) {
      return 'reconnaissance';
    }
    if (lowerText.contains(RegExp(r'\b(amour|aime|adore|chéri|bébé)\b'))) {
      return 'amour';
    }
    if (lowerText.contains(
      RegExp(r'\b(fier|fierté|réussi|accompli|victoire)\b'),
    )) {
      return 'fierté';
    }
    if (lowerText.contains(RegExp(r'\b(excité|impatient|hâte|motivé)\b'))) {
      return 'excitation';
    }

    return 'contentement';
  }

  String _getNegativeEmotion(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains(RegExp(r'\b(furieux|énervé|colère|rage|agacé)\b'))) {
      return 'colere';
    }
    if (lowerText.contains(
      RegExp(r'\b(triste|déprimé|malheureux|chagrin|pleure)\b'),
    )) {
      return 'tristesse';
    }
    if (lowerText.contains(
      RegExp(r'\b(peur|angoisse|stress|inquiet|anxieux)\b'),
    )) {
      return 'anxiete';
    }
    if (lowerText.contains(
      RegExp(r'\b(déçu|déception|frustré|frustration)\b'),
    )) {
      return 'deception';
    }
    if (lowerText.contains(RegExp(r'\b(fatigué|épuisé|crevé|las)\b'))) {
      return 'fatigue';
    }
    if (lowerText.contains(RegExp(r'\b(seul|solitaire|isolé|abandonné)\b'))) {
      return 'solitude';
    }

    return 'melancolie';
  }

  String _analyzeFallbackEmotion(String text) {
    final lowerText = text.toLowerCase();

    final positiveWords = [
      'bien',
      'bon',
      'oui',
      'merci',
      'super',
      'cool',
      'génial',
    ];
    final negativeWords = [
      'non',
      'mal',
      'pas',
      'jamais',
      'rien',
      'problème',
      'erreur',
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (String word in positiveWords) {
      if (lowerText.contains(word)) positiveCount++;
    }

    for (String word in negativeWords) {
      if (lowerText.contains(word)) negativeCount++;
    }

    if (positiveCount > negativeCount) {
      return 'contentement';
    } else if (negativeCount > positiveCount) {
      return 'inquietude';
    } else {
      return 'neutral';
    }
  }

  Future<Map<String, dynamic>> getDetailedAnalysis(String text) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final emotion = await analyzeEmotion(text);
      final confidence = _calculateConfidence(text, emotion);

      return {
        'emotion': emotion,
        'confidence': confidence,
        'intensity': _calculateIntensity(text),
        'suggestions': _getEmotionSuggestions(emotion),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur lors de l\'analyse détaillée: $e');
      return {
        'emotion': 'neutral',
        'confidence': 0.5,
        'intensity': 1.0,
        'suggestions': [],
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  double _calculateConfidence(String text, String emotion) {
    final textLength = text.length;
    if (textLength < 10) return 0.3;
    if (textLength < 50) return 0.6;
    return 0.8;
  }

  double _calculateIntensity(String text) {
    final lowerText = text.toLowerCase();

    final intensityWords = [
      'très',
      'vraiment',
      'extrêmement',
      'énormément',
      'beaucoup',
      'trop',
    ];
    int intensityCount = 0;

    for (String word in intensityWords) {
      intensityCount += lowerText.split(word).length - 1;
    }

    if (lowerText.contains('!')) intensityCount++;
    if (lowerText.contains('!!!')) intensityCount += 2;

    return (1.0 + (intensityCount * 0.3)).clamp(0.5, 3.0);
  }

  List<String> _getEmotionSuggestions(String emotion) {
    switch (emotion) {
      case 'joie':
        return [
          'Profitez de ce moment positif !',
          'Partagez votre joie avec vos proches',
        ];
      case 'colere':
        return [
          'Prenez une grande respiration',
          'Essayez de vous calmer avant de réagir',
        ];
      case 'tristesse':
        return [
          'Parlez à quelqu\'un de confiance',
          'Accordez-vous du temps pour vous',
        ];
      case 'anxiete':
        return [
          'Pratiquez des exercices de respiration',
          'Identifiez la source de votre stress',
        ];
      case 'fatigue':
        return ['Prenez une pause bien méritée', 'Assurez-vous de bien dormir'];
      default:
        return ['Restez à l\'écoute de vos émotions'];
    }
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _client.close();
  }
}
