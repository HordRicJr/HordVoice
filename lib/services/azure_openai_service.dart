import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'environment_config.dart';
import 'circuit_breaker.dart';

class AzureOpenAIService {
  late http.Client _client;
  bool _isInitialized = false;
  final EnvironmentConfig _envConfig = EnvironmentConfig();
  String? _lastResponse;
  late CircuitBreaker _azureCircuit;

  Future<void> initialize() async {
    _client = http.Client();

    // Initialiser le circuit breaker pour Azure OpenAI
    _azureCircuit = CircuitBreakerManager.instance.getCircuit(
      'azure-openai',
      failureThreshold: 3,
      timeout: Duration(seconds: 15),
      retryTimeout: Duration(minutes: 2),
    );

    // Charger la configuration
    await _envConfig.loadConfig();

    // Vérifier que les clés Azure OpenAI sont configurées
    if (!_envConfig.hasValidValue('AZURE_OPENAI_KEY') ||
        !_envConfig.hasValidValue('AZURE_OPENAI_ENDPOINT')) {
      throw Exception('Configuration Azure OpenAI manquante ou invalide');
    }

    _isInitialized = true;
    debugPrint('AzureOpenAIService initialisé avec configuration réelle');
    debugPrint('Endpoint: ${_envConfig.azureOpenAIEndpoint}');
    debugPrint('Deployment: ${_envConfig.azureOpenAIDeployment}');
    debugPrint('URL complète: ${_buildOpenAIUrl()}');
    debugPrint('🛡️ Circuit breaker Azure OpenAI configuré');
  }

  /// Construit l'URL pour les appels Azure OpenAI
  String _buildOpenAIUrl() {
    final endpoint = _envConfig.azureOpenAIEndpoint!;
    final deployment = _envConfig.azureOpenAIDeployment;

    // S'assurer que l'endpoint se termine par "/"
    final cleanEndpoint = endpoint.endsWith('/') ? endpoint : '$endpoint/';

    // URL complète au format Azure AI Foundry
    return '${cleanEndpoint}openai/deployments/$deployment/chat/completions?api-version=2024-02-15-preview';
  }

  /// Obtient les headers pour les appels Azure OpenAI
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'api-key': _envConfig.azureOpenAIKey!,
    };
  }

  /// Analyse l'intention de l'utilisateur
  Future<String> analyzeIntent(String userInput) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    debugPrint(
      '🤖 Azure OpenAI - Analyse intention: ${userInput.length} chars',
    );

    return await _azureCircuit.executeWithFallback(
      () async {
        final response = await _client
            .post(
              Uri.parse(_buildOpenAIUrl()),
              headers: _buildHeaders(),
              body: jsonEncode({
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        '''Tu es un assistant vocal africain qui analyse les intentions des utilisateurs.
                Analyse cette phrase et retourne une seule catégorie d'intention parmi:
                - weather (météo)
                - news (actualités)
                - music (musique)
                - navigation (direction, route)
                - calendar (calendrier, rendez-vous)
                - health (santé, forme)
                - system (système, batterie, paramètres)
                - general (conversation générale)
                
                Réponds uniquement par la catégorie, sans explication.''',
                  },
                  {'role': 'user', 'content': userInput},
                ],
                'max_tokens': 50,
                'temperature': 0.3,
              }),
            )
            .timeout(Duration(seconds: 15)); // Timeout de sécurité

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'] as String;
          final result = content.trim().toLowerCase();
          _lastResponse = result;
          debugPrint('✅ Azure OpenAI - Intention détectée: $result');
          return result;
        } else {
          debugPrint(
            '❌ Erreur API Azure OpenAI: ${response.statusCode} - ${response.body}',
          );
          throw Exception('Erreur API: ${response.statusCode}');
        }
      },
      () {
        debugPrint('🔄 Fallback - Utilisation de l\'analyse locale');
        return _analyzeIntentLocally(userInput);
      },
    );
  }

  /// Analyse locale d'intention en cas de fallback
  String _analyzeIntentLocally(String userInput) {
    final input = userInput.toLowerCase();

    // Patterns simples pour classification locale
    if (input.contains('météo') ||
        input.contains('temps') ||
        input.contains('pluie')) {
      return 'weather';
    } else if (input.contains('musique') ||
        input.contains('chanson') ||
        input.contains('jouer')) {
      return 'music';
    } else if (input.contains('nouvelle') ||
        input.contains('info') ||
        input.contains('actualité')) {
      return 'news';
    } else if (input.contains('route') ||
        input.contains('direction') ||
        input.contains('aller')) {
      return 'navigation';
    } else if (input.contains('rendez-vous') ||
        input.contains('calendrier') ||
        input.contains('agenda')) {
      return 'calendar';
    } else if (input.contains('santé') ||
        input.contains('forme') ||
        input.contains('exercice')) {
      return 'health';
    } else if (input.contains('batterie') ||
        input.contains('système') ||
        input.contains('paramètre')) {
      return 'system';
    }

    return 'general';
  }

  /// Génère une réponse personnalisée selon le profil utilisateur
  Future<String> generatePersonalizedResponse(
    String userInput,
    String assistantType,
    String userId,
    List<String> conversationHistory,
  ) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final messages = [
        {
          'role': 'system',
          'content':
              '''Tu es un assistant vocal africain bienveillant et chaleureux.
          Réponds de manière naturelle et personnalisée.
          Utilise un ton amical et professionnel.
          Garde tes réponses courtes (maximum 2 phrases) pour la synthèse vocale.
          Si tu ne peux pas aider, propose des alternatives.''',
        },
        ...conversationHistory.map((msg) => {'role': 'user', 'content': msg}),
        {'role': 'user', 'content': userInput},
      ];

      final response = await _client.post(
        Uri.parse(_buildOpenAIUrl()),
        headers: _buildHeaders(),
        body: jsonEncode({
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        debugPrint('Erreur API Azure OpenAI: ${response.statusCode}');
        return 'Je suis désolé, je rencontre des difficultés techniques en ce moment.';
      }
    } catch (e) {
      debugPrint('Erreur génération réponse: $e');
      return 'Je suis désolé, je ne peux pas répondre à cette question pour le moment.';
    }
  }

  /// Génère une réponse contextuelle avec données externes
  Future<String> generateContextualResponse(
    String userInput,
    String intent,
    Map<String, dynamic> contextData,
  ) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      String systemPrompt =
          '''Tu es un assistant vocal africain qui fournit des informations précises.
      L'utilisateur a une intention: $intent
      Utilise les données contextuelles fournies pour donner une réponse pertinente et naturelle.
      Garde ta réponse courte (maximum 2 phrases) pour la synthèse vocale.''';

      if (contextData.isNotEmpty) {
        systemPrompt += '\nDonnées contextuelles: ${jsonEncode(contextData)}';
      }

      final response = await _client.post(
        Uri.parse(_buildOpenAIUrl()),
        headers: _buildHeaders(),
        body: jsonEncode({
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userInput},
          ],
          'max_tokens': 150,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        debugPrint('Erreur API Azure OpenAI: ${response.statusCode}');
        return 'Je ne peux pas accéder aux informations demandées en ce moment.';
      }
    } catch (e) {
      debugPrint('Erreur génération réponse contextuelle: $e');
      return 'Je rencontre des difficultés pour traiter votre demande.';
    }
  }

  /// Analyse les émotions dans le texte
  Future<Map<String, dynamic>> analyzeEmotions(String text) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final response = await _client.post(
        Uri.parse(_buildOpenAIUrl()),
        headers: _buildHeaders(),
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': '''Analyse les émotions dans ce texte.
              Retourne un JSON avec:
              - emotion: l'émotion principale (joie, tristesse, colère, peur, surprise, neutre)
              - intensity: intensité de 0.0 à 1.0
              - confidence: confiance de l'analyse de 0.0 à 1.0
              
              Réponds uniquement avec le JSON, sans texte supplémentaire.''',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 100,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        try {
          return jsonDecode(content.trim());
        } catch (e) {
          return {'emotion': 'neutre', 'intensity': 0.5, 'confidence': 0.5};
        }
      } else {
        debugPrint('Erreur API Azure OpenAI: ${response.statusCode}');
        return {'emotion': 'neutre', 'intensity': 0.5, 'confidence': 0.0};
      }
    } catch (e) {
      debugPrint('Erreur analyse émotions: $e');
      return {'emotion': 'neutre', 'intensity': 0.5, 'confidence': 0.0};
    }
  }

  /// Optimise le texte pour la synthèse vocale
  Future<String> optimizeForSpeech(String text) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final response = await _client.post(
        Uri.parse(_buildOpenAIUrl()),
        headers: _buildHeaders(),
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': '''Optimise ce texte pour la synthèse vocale:
              - Remplace les abréviations par les mots complets
              - Écris les nombres en toutes lettres
              - Ajoute la ponctuation appropriée pour les pauses
              - Simplifie les phrases trop complexes
              - Garde le sens original
              
              Retourne uniquement le texte optimisé.''',
            },
            {'role': 'user', 'content': text},
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        debugPrint('Erreur API Azure OpenAI: ${response.statusCode}');
        return text; // Retourner le texte original en cas d'erreur
      }
    } catch (e) {
      debugPrint('Erreur optimisation pour speech: $e');
      return text; // Retourner le texte original en cas d'erreur
    }
  }

  /// Obtient la dernière réponse générée
  String getLastResponse() {
    return _lastResponse ??
        "Je suis désolé, je n'ai pas de réponse disponible.";
  }

  /// Efface la dernière réponse mise en cache
  void clearLastResponse() {
    _lastResponse = null;
    debugPrint('🧹 Cache Azure OpenAI vidé');
  }

  void dispose() {
    try {
      _client.close();
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la fermeture du client HTTP: $e');
    }
    _isInitialized = false;
    _lastResponse = null;
    debugPrint('🔄 AzureOpenAIService fermé et nettoyé');
  }
}
