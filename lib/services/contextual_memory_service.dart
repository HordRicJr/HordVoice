import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de mémoire contextuelle courte pour HordVoice IA
/// Fonctionnalité 2: Mémoire contextuelle courte
class ContextualMemoryService {
  static final ContextualMemoryService _instance =
      ContextualMemoryService._internal();
  factory ContextualMemoryService() => _instance;
  ContextualMemoryService._internal();

  // Configuration
  static const int maxConversationHistory = 20; // Derniers 20 échanges
  static const int maxContextDurationMinutes = 30; // 30 minutes de contexte
  static const String storageKey = 'hordvoice_contextual_memory';

  // État du service
  bool _isInitialized = false;
  List<ConversationMemory> _conversationHistory = [];
  Map<String, UserPreference> _userPreferences = {};
  Map<String, ContextualTopic> _topicMemory = {};

  // Streams pour les événements
  final StreamController<MemoryEvent> _memoryController =
      StreamController.broadcast();

  // Getters
  Stream<MemoryEvent> get memoryStream => _memoryController.stream;
  bool get isInitialized => _isInitialized;
  List<ConversationMemory> get recentHistory => _getRecentHistory();
  Map<String, UserPreference> get userPreferences => Map.from(_userPreferences);

  /// Initialise le service de mémoire contextuelle
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ContextualMemoryService déjà initialisé');
      return;
    }

    try {
      debugPrint('Initialisation ContextualMemoryService...');

      await _loadMemoryFromStorage();
      await _cleanOldMemories();

      _isInitialized = true;
      debugPrint('ContextualMemoryService initialisé avec succès');

      _memoryController.add(MemoryEvent.initialized());
    } catch (e) {
      debugPrint('Erreur initialisation ContextualMemoryService: $e');
      throw Exception('Impossible d\'initialiser le service de mémoire: $e');
    }
  }

  /// Ajoute un nouvel échange conversationnel en mémoire
  Future<void> addConversationMemory({
    required String userInput,
    required String assistantResponse,
    required ConversationType type,
    Map<String, dynamic>? context,
    EmotionDetected? emotion,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final memory = ConversationMemory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userInput: userInput,
        assistantResponse: assistantResponse,
        type: type,
        timestamp: DateTime.now(),
        context: context ?? {},
        emotion: emotion,
      );

      _conversationHistory.add(memory);

      // Maintenir la limite de l'historique
      if (_conversationHistory.length > maxConversationHistory) {
        _conversationHistory.removeAt(0);
      }

      // Extraire les préférences utilisateur
      await _extractUserPreferences(memory);

      // Analyser les sujets de conversation
      await _analyzeConversationTopics(memory);

      // Sauvegarder en storage
      await _saveMemoryToStorage();

      _memoryController.add(MemoryEvent.conversationAdded(memory));

      debugPrint('Mémoire conversationnelle ajoutée: ${memory.id}');
    } catch (e) {
      debugPrint('Erreur ajout mémoire: $e');
    }
  }

  /// Récupère le contexte pertinent pour une nouvelle conversation
  Future<ConversationContext> getConversationContext({
    required String currentInput,
    ConversationType? type,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final recentHistory = _getRecentHistory();
      final relevantPreferences = _getRelevantPreferences(currentInput);
      final relatedTopics = _getRelatedTopics(currentInput);
      final emotionalContext = _getEmotionalContext();

      return ConversationContext(
        recentHistory: recentHistory,
        userPreferences: relevantPreferences,
        relatedTopics: relatedTopics,
        emotionalContext: emotionalContext,
        contextScore: _calculateContextScore(currentInput),
      );
    } catch (e) {
      debugPrint('Erreur récupération contexte: $e');
      return ConversationContext.empty();
    }
  }

  /// Ajoute ou met à jour une préférence utilisateur
  Future<void> updateUserPreference({
    required String key,
    required dynamic value,
    required PreferenceType type,
    double confidence = 0.8,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final preference = UserPreference(
        key: key,
        value: value,
        type: type,
        confidence: confidence,
        timestamp: DateTime.now(),
      );

      _userPreferences[key] = preference;
      await _saveMemoryToStorage();

      _memoryController.add(MemoryEvent.preferenceUpdated(preference));
      debugPrint('Préférence utilisateur mise à jour: $key = $value');
    } catch (e) {
      debugPrint('Erreur mise à jour préférence: $e');
    }
  }

  /// Obtient une préférence utilisateur spécifique
  UserPreference? getUserPreference(String key) {
    return _userPreferences[key];
  }

  /// Analyse si l'utilisateur change de sujet de conversation
  bool isTopicChange(String newInput) {
    if (_conversationHistory.isEmpty) return false;

    final lastTopic = _getLastTopic();
    final newTopic = _extractTopic(newInput);

    return lastTopic != null && newTopic != lastTopic.name;
  }

  /// Obtient le résumé de la conversation courante
  String getConversationSummary() {
    if (_conversationHistory.isEmpty) {
      return "Aucune conversation récente";
    }

    final recentHistory = _getRecentHistory();
    final mainTopics = _getMainTopics();
    final dominantEmotion = _getDominantEmotion();

    return "Conversation récente: ${recentHistory.length} échanges sur "
        "${mainTopics.join(', ')}. Émotion dominante: ${dominantEmotion?.name ?? 'neutre'}.";
  }

  /// Nettoie les mémoires anciennes
  Future<void> cleanOldMemories() async {
    await _cleanOldMemories();
    await _saveMemoryToStorage();
    _memoryController.add(MemoryEvent.memoriesCleaned());
  }

  /// Exporte l'historique de conversation (pour debug/backup)
  Map<String, dynamic> exportMemory() {
    return {
      'conversationHistory': _conversationHistory
          .map((m) => m.toJson())
          .toList(),
      'userPreferences': _userPreferences.map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'topicMemory': _topicMemory.map((k, v) => MapEntry(k, v.toJson())),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  // ==================== MÉTHODES PRIVÉES ====================

  List<ConversationMemory> _getRecentHistory() {
    final cutoffTime = DateTime.now().subtract(
      const Duration(minutes: maxContextDurationMinutes),
    );

    return _conversationHistory
        .where((memory) => memory.timestamp.isAfter(cutoffTime))
        .toList();
  }

  Map<String, UserPreference> _getRelevantPreferences(String input) {
    // Analyse simple par mots-clés pour l'instant
    final keywords = input.toLowerCase().split(' ');
    final relevantPrefs = <String, UserPreference>{};

    for (final entry in _userPreferences.entries) {
      final key = entry.key.toLowerCase();
      if (keywords.any((keyword) => key.contains(keyword))) {
        relevantPrefs[entry.key] = entry.value;
      }
    }

    return relevantPrefs;
  }

  List<ContextualTopic> _getRelatedTopics(String input) {
    final inputWords = input.toLowerCase().split(' ');
    final relatedTopics = <ContextualTopic>[];

    for (final topic in _topicMemory.values) {
      final topicWords = topic.keywords;
      final relevanceScore = _calculateTopicRelevance(inputWords, topicWords);

      if (relevanceScore > 0.3) {
        relatedTopics.add(topic);
      }
    }

    relatedTopics.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return relatedTopics;
  }

  EmotionalContext _getEmotionalContext() {
    final recentHistory = _getRecentHistory();
    final emotions = recentHistory
        .where((m) => m.emotion != null)
        .map((m) => m.emotion!)
        .toList();

    if (emotions.isEmpty) {
      return EmotionalContext.neutral();
    }

    final dominantEmotion = _getDominantEmotion();
    final averageIntensity =
        emotions.map((e) => e.intensity).reduce((a, b) => a + b) /
        emotions.length;

    return EmotionalContext(
      dominantEmotion: dominantEmotion?.name ?? 'neutre',
      averageIntensity: averageIntensity,
      emotionHistory: emotions,
    );
  }

  double _calculateContextScore(String input) {
    double score = 0.0;

    // Score basé sur l'historique récent
    final recentHistory = _getRecentHistory();
    score += recentHistory.length * 0.1;

    // Score basé sur les préférences
    score += _getRelevantPreferences(input).length * 0.2;

    // Score basé sur les sujets
    score += _getRelatedTopics(input).length * 0.15;

    return score.clamp(0.0, 1.0);
  }

  Future<void> _extractUserPreferences(ConversationMemory memory) async {
    // Analyse simple des préférences basée sur le contenu
    final input = memory.userInput.toLowerCase();

    // Préférences musicales
    if (input.contains('musique') || input.contains('chanson')) {
      final genres = ['rock', 'pop', 'jazz', 'classique', 'rap'];
      for (final genre in genres) {
        if (input.contains(genre)) {
          await updateUserPreference(
            key: 'genre_musical_prefere',
            value: genre,
            type: PreferenceType.musicGenre,
            confidence: 0.7,
          );
        }
      }
    }

    // Préférences linguistiques
    if (input.contains('langue') || input.contains('language')) {
      final languages = ['français', 'anglais', 'espagnol', 'allemand'];
      for (final lang in languages) {
        if (input.contains(lang)) {
          await updateUserPreference(
            key: 'langue_preferee',
            value: lang,
            type: PreferenceType.language,
            confidence: 0.8,
          );
        }
      }
    }

    // Préférences temporelles
    final now = DateTime.now();
    await updateUserPreference(
      key: 'heure_interaction',
      value: now.hour,
      type: PreferenceType.timePreference,
      confidence: 0.6,
    );
  }

  Future<void> _analyzeConversationTopics(ConversationMemory memory) async {
    final topic = _extractTopic(memory.userInput);
    if (topic.isNotEmpty) {
      final existing = _topicMemory[topic];

      if (existing != null) {
        existing.frequency++;
        existing.lastMentioned = DateTime.now();
        existing.relevanceScore = _calculateTopicRelevance(
          memory.userInput.toLowerCase().split(' '),
          existing.keywords,
        );
      } else {
        _topicMemory[topic] = ContextualTopic(
          name: topic,
          keywords: _extractKeywords(memory.userInput),
          frequency: 1,
          firstMentioned: DateTime.now(),
          lastMentioned: DateTime.now(),
          relevanceScore: 0.8,
        );
      }
    }
  }

  String _extractTopic(String input) {
    // Analyse simple des sujets par mots-clés
    final topics = {
      'musique': ['musique', 'chanson', 'audio', 'son', 'écouter'],
      'météo': ['météo', 'temps', 'pluie', 'soleil', 'température'],
      'actualités': ['actualités', 'news', 'information', 'journal'],
      'calendrier': ['calendrier', 'rendez-vous', 'planning', 'agenda'],
      'sport': ['sport', 'football', 'tennis', 'course', 'exercice'],
    };

    final inputLower = input.toLowerCase();
    for (final entry in topics.entries) {
      if (entry.value.any((keyword) => inputLower.contains(keyword))) {
        return entry.key;
      }
    }

    return 'général';
  }

  List<String> _extractKeywords(String input) {
    final words = input.toLowerCase().split(' ');
    final stopWords = [
      'le',
      'la',
      'les',
      'un',
      'une',
      'de',
      'du',
      'des',
      'et',
      'ou',
      'mais',
    ];

    return words
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();
  }

  double _calculateTopicRelevance(
    List<String> inputWords,
    List<String> topicKeywords,
  ) {
    if (inputWords.isEmpty || topicKeywords.isEmpty) return 0.0;

    int matches = 0;
    for (final word in inputWords) {
      if (topicKeywords.contains(word)) {
        matches++;
      }
    }

    return matches / topicKeywords.length;
  }

  ContextualTopic? _getLastTopic() {
    if (_topicMemory.isEmpty) return null;

    return _topicMemory.values.reduce(
      (a, b) => a.lastMentioned.isAfter(b.lastMentioned) ? a : b,
    );
  }

  List<String> _getMainTopics() {
    final sortedTopics = _topicMemory.values.toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));

    return sortedTopics.take(3).map((t) => t.name).toList();
  }

  EmotionDetected? _getDominantEmotion() {
    final recentHistory = _getRecentHistory();
    final emotions = recentHistory
        .where((m) => m.emotion != null)
        .map((m) => m.emotion!)
        .toList();

    if (emotions.isEmpty) return null;

    final emotionCounts = <String, int>{};
    for (final emotion in emotions) {
      emotionCounts[emotion.name] = (emotionCounts[emotion.name] ?? 0) + 1;
    }

    final dominantEmotionName = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return emotions.firstWhere((e) => e.name == dominantEmotionName);
  }

  Future<void> _cleanOldMemories() async {
    final cutoffTime = DateTime.now().subtract(
      const Duration(minutes: maxContextDurationMinutes),
    );

    _conversationHistory.removeWhere(
      (memory) => memory.timestamp.isBefore(cutoffTime),
    );

    // Nettoyer les sujets anciens
    _topicMemory.removeWhere(
      (key, topic) => topic.lastMentioned.isBefore(cutoffTime),
    );

    debugPrint('Mémoires anciennes nettoyées');
  }

  Future<void> _saveMemoryToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryData = exportMemory();
      await prefs.setString(storageKey, jsonEncode(memoryData));
    } catch (e) {
      debugPrint('Erreur sauvegarde mémoire: $e');
    }
  }

  Future<void> _loadMemoryFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = prefs.getString(storageKey);

      if (memoryJson != null) {
        final memoryData = jsonDecode(memoryJson) as Map<String, dynamic>;

        // Charger l'historique de conversation
        if (memoryData['conversationHistory'] != null) {
          _conversationHistory = (memoryData['conversationHistory'] as List)
              .map((item) => ConversationMemory.fromJson(item))
              .toList();
        }

        // Charger les préférences utilisateur
        if (memoryData['userPreferences'] != null) {
          _userPreferences =
              (memoryData['userPreferences'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, UserPreference.fromJson(value)),
              );
        }

        // Charger la mémoire des sujets
        if (memoryData['topicMemory'] != null) {
          _topicMemory = (memoryData['topicMemory'] as Map<String, dynamic>)
              .map(
                (key, value) => MapEntry(key, ContextualTopic.fromJson(value)),
              );
        }

        debugPrint('Mémoire chargée depuis le storage');
      }
    } catch (e) {
      debugPrint('Erreur chargement mémoire: $e');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _memoryController.close();
    debugPrint('ContextualMemoryService disposé');
  }
}

// ==================== CLASSES DE DONNÉES ====================

class ConversationMemory {
  final String id;
  final String userInput;
  final String assistantResponse;
  final ConversationType type;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final EmotionDetected? emotion;

  ConversationMemory({
    required this.id,
    required this.userInput,
    required this.assistantResponse,
    required this.type,
    required this.timestamp,
    required this.context,
    this.emotion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userInput': userInput,
    'assistantResponse': assistantResponse,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
    'emotion': emotion?.toJson(),
  };

  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    return ConversationMemory(
      id: json['id'],
      userInput: json['userInput'],
      assistantResponse: json['assistantResponse'],
      type: ConversationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConversationType.general,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      emotion: json['emotion'] != null
          ? EmotionDetected.fromJson(json['emotion'])
          : null,
    );
  }
}

class UserPreference {
  final String key;
  final dynamic value;
  final PreferenceType type;
  final double confidence;
  final DateTime timestamp;

  UserPreference({
    required this.key,
    required this.value,
    required this.type,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'type': type.name,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
  };

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      key: json['key'],
      value: json['value'],
      type: PreferenceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PreferenceType.general,
      ),
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ContextualTopic {
  final String name;
  final List<String> keywords;
  int frequency;
  final DateTime firstMentioned;
  DateTime lastMentioned;
  double relevanceScore;

  ContextualTopic({
    required this.name,
    required this.keywords,
    required this.frequency,
    required this.firstMentioned,
    required this.lastMentioned,
    required this.relevanceScore,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'keywords': keywords,
    'frequency': frequency,
    'firstMentioned': firstMentioned.toIso8601String(),
    'lastMentioned': lastMentioned.toIso8601String(),
    'relevanceScore': relevanceScore,
  };

  factory ContextualTopic.fromJson(Map<String, dynamic> json) {
    return ContextualTopic(
      name: json['name'],
      keywords: List<String>.from(json['keywords']),
      frequency: json['frequency'],
      firstMentioned: DateTime.parse(json['firstMentioned']),
      lastMentioned: DateTime.parse(json['lastMentioned']),
      relevanceScore: json['relevanceScore'],
    );
  }
}

class ConversationContext {
  final List<ConversationMemory> recentHistory;
  final Map<String, UserPreference> userPreferences;
  final List<ContextualTopic> relatedTopics;
  final EmotionalContext emotionalContext;
  final double contextScore;

  ConversationContext({
    required this.recentHistory,
    required this.userPreferences,
    required this.relatedTopics,
    required this.emotionalContext,
    required this.contextScore,
  });

  factory ConversationContext.empty() {
    return ConversationContext(
      recentHistory: [],
      userPreferences: {},
      relatedTopics: [],
      emotionalContext: EmotionalContext.neutral(),
      contextScore: 0.0,
    );
  }
}

class EmotionalContext {
  final String dominantEmotion;
  final double averageIntensity;
  final List<EmotionDetected> emotionHistory;

  EmotionalContext({
    required this.dominantEmotion,
    required this.averageIntensity,
    required this.emotionHistory,
  });

  factory EmotionalContext.neutral() {
    return EmotionalContext(
      dominantEmotion: 'neutre',
      averageIntensity: 0.5,
      emotionHistory: [],
    );
  }
}

class EmotionDetected {
  final String name;
  final double intensity;
  final DateTime timestamp;

  EmotionDetected({
    required this.name,
    required this.intensity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'intensity': intensity,
    'timestamp': timestamp.toIso8601String(),
  };

  factory EmotionDetected.fromJson(Map<String, dynamic> json) {
    return EmotionDetected(
      name: json['name'],
      intensity: json['intensity'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MemoryEvent {
  final MemoryEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MemoryEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory MemoryEvent.initialized() {
    return MemoryEvent(
      type: MemoryEventType.initialized,
      data: {},
      timestamp: DateTime.now(),
    );
  }

  factory MemoryEvent.conversationAdded(ConversationMemory memory) {
    return MemoryEvent(
      type: MemoryEventType.conversationAdded,
      data: {'memory': memory.toJson()},
      timestamp: DateTime.now(),
    );
  }

  factory MemoryEvent.preferenceUpdated(UserPreference preference) {
    return MemoryEvent(
      type: MemoryEventType.preferenceUpdated,
      data: {'preference': preference.toJson()},
      timestamp: DateTime.now(),
    );
  }

  factory MemoryEvent.memoriesCleaned() {
    return MemoryEvent(
      type: MemoryEventType.memoriesCleaned,
      data: {},
      timestamp: DateTime.now(),
    );
  }
}

// ==================== ENUMS ====================

enum ConversationType {
  general,
  command,
  question,
  music,
  weather,
  news,
  calendar,
  phone,
  settings,
}

enum PreferenceType {
  general,
  musicGenre,
  language,
  timePreference,
  voiceType,
  responseStyle,
}

enum MemoryEventType {
  initialized,
  conversationAdded,
  preferenceUpdated,
  memoriesCleaned,
}
