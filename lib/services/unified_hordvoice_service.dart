import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/user_profile.dart';
import '../models/ai_models.dart';
import 'azure_openai_service.dart';
import 'azure_speech_service.dart';
import 'emotion_analysis_service.dart';
import 'weather_service.dart';
import 'news_service.dart';
import 'spotify_service.dart';
import 'navigation_service.dart';
import 'calendar_service.dart';
import 'health_monitoring_service.dart';
import 'phone_monitoring_service.dart';
import 'battery_monitoring_service.dart';
import 'voice_management_service.dart'; // Étape 11: Gestion des voix
import 'quick_settings_service.dart'; // Contrôles vocaux système
import 'transition_animation_service.dart'; // Transitions avatar

final unifiedHordVoiceServiceProvider = Provider<UnifiedHordVoiceService>((
  ref,
) {
  return UnifiedHordVoiceService();
});

class UnifiedHordVoiceService {
  static final UnifiedHordVoiceService _instance =
      UnifiedHordVoiceService._internal();
  factory UnifiedHordVoiceService() => _instance;
  UnifiedHordVoiceService._internal();

  late SupabaseClient _supabase;
  late FlutterTts _tts;
  late Battery _battery;
  late FlutterLocalNotificationsPlugin _notifications;

  UserProfile? _currentUser;
  Timer? _monitoringTimer;
  Timer? _batteryTimer;
  Timer? _wakeWordTimer;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _wakeWordActive = false;
  String _currentMood = 'neutral';

  late AzureOpenAIService _aiService;
  late AzureSpeechService _azureSpeechService;
  late EmotionAnalysisService _emotionAnalysisService;
  late WeatherService _weatherService;
  late NewsService _newsService;
  late SpotifyService _spotifyService;
  late NavigationService _navigationService;
  late CalendarService _calendarService;
  late HealthMonitoringService _healthService;
  late PhoneMonitoringService _phoneMonitoringService;
  late BatteryMonitoringService _batteryMonitoringService;
  late VoiceManagementService
  _voiceManagementService; // Étape 11: Gestion des voix
  late QuickSettingsService _quickSettingsService; // Contrôles vocaux système
  late TransitionAnimationService _transitionService; // Transitions avatar

  final StreamController<String> _aiResponseController =
      StreamController<String>.broadcast();
  final StreamController<String> _moodController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _systemStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Nouveaux streams pour pipeline audio (Étape 6)
  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _emotionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _wakeWordController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _isSpeakingController =
      StreamController<bool>.broadcast();

  Stream<String> get aiResponseStream => _aiResponseController.stream;
  Stream<String> get moodStream => _moodController.stream;
  Stream<Map<String, dynamic>> get systemStatusStream =>
      _systemStatusController.stream;

  // Getters pour nouveaux streams (Étape 6)
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<Map<String, dynamic>> get emotionStream => _emotionController.stream;
  Stream<bool> get wakeWordStream => _wakeWordController.stream;
  Stream<bool> get isSpeakingStream => _isSpeakingController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // L'initialisation Supabase est maintenant fait dans main.dart
      _supabase = Supabase.instance.client;

      _tts = FlutterTts();
      _battery = Battery();
      _notifications = FlutterLocalNotificationsPlugin();

      await _initializeNotifications();
      await _initializeTTS();
      await _initializeServices();

      _isInitialized = true;

      await _startSystemMonitoring();
      await _startWakeWordDetection(); // Démarrer la détection automatique

      debugPrint('UnifiedHordVoiceService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service: $e');
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    _aiService = AzureOpenAIService();
    _azureSpeechService = AzureSpeechService();
    _emotionAnalysisService = EmotionAnalysisService();
    _weatherService = WeatherService();
    _newsService = NewsService();
    _spotifyService = SpotifyService();
    _navigationService = NavigationService();
    _calendarService = CalendarService();
    _healthService = HealthMonitoringService();
    _phoneMonitoringService = PhoneMonitoringService();
    _batteryMonitoringService = BatteryMonitoringService();
    _voiceManagementService = VoiceManagementService(); // Étape 11
    _quickSettingsService = QuickSettingsService(); // Contrôles vocaux
    _transitionService = TransitionAnimationService(); // Transitions avatar

    await _aiService.initialize();
    await _azureSpeechService.initialize();
    await _emotionAnalysisService.initialize();
    await _weatherService.initialize();
    await _newsService.initialize();
    await _spotifyService.initialize();
    await _navigationService.initialize();
    await _calendarService.initialize();
    await _healthService.initialize();
    await _phoneMonitoringService.initialize();
    await _batteryMonitoringService.initialize();
    await _voiceManagementService.initialize(); // Étape 11
    await _quickSettingsService.initialize(); // Contrôles vocaux
    await _transitionService.initialize(); // Transitions avatar
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> _initializeTTS() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);
  }

  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      if (deviceId == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('device_id', deviceId)
          .single();

      _currentUser = UserProfile.fromJson(response);
      return _currentUser;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Future<UserProfile> createUser({
    required String firstName,
    String? lastName,
    String? nickname,
    String personalityType = 'mere_africaine',
    String relationshipMode = 'ami',
  }) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else {
        deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final userData = {
        'device_id': deviceId,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'personality_preference': personalityType,
        'relationship_mode': relationshipMode,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .insert(userData)
          .select()
          .single();

      _currentUser = UserProfile.fromJson(response);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_id', deviceId);

      await _speakWelcomeMessage();

      return _currentUser!;
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  Future<void> _speakWelcomeMessage() async {
    if (_currentUser == null) return;

    final responses = await _getPersonalityResponses(
      'felicitation',
      'premiere_utilisation',
    );
    if (responses.isNotEmpty) {
      final welcomeMessage = responses.first.responseText;
      await speakText(welcomeMessage);
    }
  }

  Future<void> speakText(String text, {String? emotion}) async {
    try {
      // Étape 6: Signaler qu'on commence à parler
      _isSpeakingController.add(true);

      if (_currentUser != null) {
        await _tts.setSpeechRate(_currentUser!.speechSpeed);
        await _tts.setVolume(_currentUser!.volume);
      }

      await _tts.speak(text);
      _aiResponseController.add(text);

      // Signaler qu'on a fini de parler
      _isSpeakingController.add(false);
    } catch (e) {
      _isSpeakingController.add(false);
      debugPrint('Erreur lors de la synthèse vocale: $e');
    }
  }

  /// Étape 6: Interrompre TTS si l'utilisateur parle
  Future<void> interruptSpeech() async {
    try {
      await _tts.stop();
      _isSpeakingController.add(false);
      debugPrint('TTS interrompu par l\'utilisateur');
    } catch (e) {
      debugPrint('Erreur lors de l\'interruption TTS: $e');
    }
  }

  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;

    // Étape 6: Pipeline audio streaming avec Azure Speech
    await _azureSpeechService.startListening();

    // Écouter les résultats de transcription en streaming
    _azureSpeechService.resultStream.listen((result) {
      _transcriptionController.add(result.recognizedText);
      if (result.isFinal) {
        _processVoiceCommandWithEmotion(result.recognizedText);
      }
    });

    // Écouter les erreurs
    _azureSpeechService.errorStream.listen((error) {
      debugPrint('Erreur STT: ${error.errorMessage}');
      speakText('Désolé, je n\'ai pas bien entendu.');
    });
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _azureSpeechService.stopListening();
  }

  /// Étape 6: Pipeline audio avec analyse parallèle (texte + émotion)
  Future<void> _processVoiceCommandWithEmotion(String command) async {
    try {
      // Parallélisation: text analytics + emotion analysis
      final Future<String> emotionFuture = _emotionAnalysisService
          .analyzeEmotion(command);
      final Future<String> intentFuture = _aiService.analyzeIntent(command);

      // Attendre les deux analyses en parallèle
      final results = await Future.wait([emotionFuture, intentFuture]);
      final emotion = results[0];
      final intent = results[1];

      // Publier l'émotion dans le stream
      _emotionController.add({
        'emotion': emotion,
        'text': command,
        'timestamp': DateTime.now().toIso8601String(),
        'confidence': 0.85, // TODO: récupérer vraie confidence
      });

      // Mettre à jour l'humeur et exécuter l'intention
      await _updateMood(emotion);
      await _executeIntent(intent, command);
    } catch (e) {
      debugPrint('Erreur lors du traitement avec émotion: $e');
      await speakText('Désolé, je n\'ai pas compris votre demande.');
    }
  }

  Future<void> _executeIntent(String intent, String originalCommand) async {
    switch (intent.toLowerCase()) {
      case 'weather':
        await _handleWeatherRequest(originalCommand);
        break;
      case 'news':
        await _handleNewsRequest(originalCommand);
        break;
      case 'music':
        await _handleMusicRequest(originalCommand);
        break;
      case 'navigation':
        await _handleNavigationRequest(originalCommand);
        break;
      case 'calendar':
        await _handleCalendarRequest(originalCommand);
        break;
      case 'health':
        await _handleHealthRequest(originalCommand);
        break;
      case 'system':
        await _handleSystemRequest(originalCommand);
        break;
      // Étape 11: Gestion des voix voice-only
      case 'voice':
      case 'voix':
        await _handleVoiceRequest(originalCommand);
        break;
      default:
        await _handleGeneralConversation(originalCommand);
    }
  }

  Future<void> _handleWeatherRequest(String command) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final weather = await _weatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      final response = await _aiService.generateContextualResponse(
        'Donne-moi la météo',
        'weather',
        {'weather': weather},
      );
      await speakText(response);
    } catch (e) {
      await speakText(
        'Je ne peux pas accéder aux informations météo pour le moment.',
      );
    }
  }

  Future<void> _handleNewsRequest(String command) async {
    try {
      final news = await _newsService.getLatestNews();
      final response = await _aiService.generateContextualResponse(
        command,
        'news',
        {'news': news},
      );
      await speakText(response);
    } catch (e) {
      await speakText('Je ne peux pas accéder aux actualités pour le moment.');
    }
  }

  Future<void> _handleMusicRequest(String command) async {
    try {
      if (command.toLowerCase().contains('spotify')) {
        await _spotifyService.playMusic(command);
      } else {
        await _spotifyService.searchAndPlay(command);
      }
      await speakText('Je lance votre musique !');
    } catch (e) {
      await speakText('Je ne peux pas lancer la musique pour le moment.');
    }
  }

  Future<void> _handleNavigationRequest(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      // Étape 8: Recherche POI voice-only
      final poiKeywords = [
        'trouve',
        'cherche',
        'restaurant',
        'pharmacie',
        'magasin',
        'hôpital',
        'banque',
      ];
      final hasPOISearch = poiKeywords.any(
        (keyword) => lowerCommand.contains(keyword),
      );

      if (hasPOISearch) {
        // Extraire le type de POI recherché
        String poiQuery = '';
        if (lowerCommand.contains('restaurant'))
          poiQuery = 'restaurant';
        else if (lowerCommand.contains('pharmacie'))
          poiQuery = 'pharmacie';
        else if (lowerCommand.contains('magasin'))
          poiQuery = 'magasin';
        else if (lowerCommand.contains('hôpital'))
          poiQuery = 'hôpital';
        else if (lowerCommand.contains('banque'))
          poiQuery = 'banque';
        else {
          // Fallback: extraire mot-clé du texte
          final words = lowerCommand.split(' ');
          poiQuery = words.firstWhere(
            (word) =>
                word.length > 3 &&
                !['trouve', 'cherche', 'près', 'dans'].contains(word),
            orElse: () => 'lieu',
          );
        }

        // Demander permission si nécessaire
        if (!await _navigationService.isLocationAvailable()) {
          final permissionResponse = await _navigationService
              .requestLocationPermissionVoiceOnly();
          await speakText(permissionResponse);
          if (permissionResponse.contains('refusée') ||
              permissionResponse.contains('bloquée')) {
            return;
          }
        }

        // Rechercher POI
        final searchResult = await _navigationService.searchPOIVoiceOnly(
          poiQuery,
        );
        final voiceResponse = _navigationService.generateVoiceResponseForPOI(
          searchResult,
        );
        await speakText(voiceResponse);
        return;
      }

      // Navigation classique vers destination
      // Utiliser Azure OpenAI pour extraire la destination
      final extractResponse = await _aiService.generatePersonalizedResponse(
        'Extrait uniquement le nom de la destination de cette phrase: $command',
        'navigation_assistant',
        _currentUser?.id ?? 'anonymous',
        [],
      );

      if (extractResponse.isNotEmpty && extractResponse.length > 3) {
        try {
          final directions = await _navigationService.getDirections(
            extractResponse,
          );
          final response = await _aiService.generateContextualResponse(
            command,
            'navigation',
            {'directions': directions, 'destination': extractResponse},
          );
          await speakText(response);
        } catch (e) {
          await speakText(
            'Je ne peux pas calculer l\'itinéraire vers $extractResponse.',
          );
        }
      } else {
        await speakText(
          'Je n\'ai pas compris la destination. Pouvez-vous répéter ?',
        );
      }
    } catch (e) {
      debugPrint('Erreur navigation: $e');
      await speakText('Je ne peux pas démarrer la navigation pour le moment.');
    }
  }

  Future<void> _handleCalendarRequest(String command) async {
    try {
      final events = await _calendarService.getTodayEvents();
      final eventsMap = events
          .map(
            (event) => {
              'title': event.title,
              'description': event.description,
              'start': event.start?.toIso8601String(),
              'end': event.end?.toIso8601String(),
              'location': event.location,
            },
          )
          .toList();

      final response = await _aiService.generateContextualResponse(
        command,
        'calendar',
        {'events': eventsMap},
      );
      await speakText(response);
    } catch (e) {
      await speakText(
        'Je ne peux pas accéder à votre calendrier pour le moment.',
      );
    }
  }

  Future<void> _handleHealthRequest(String command) async {
    try {
      final healthData = await _healthService.getHealthSummary();
      final response = await _aiService.generateContextualResponse(
        command,
        'health',
        {'healthData': healthData},
      );
      await speakText(response);
    } catch (e) {
      await speakText(
        'Je ne peux pas accéder à vos données de santé pour le moment.',
      );
    }
  }

  Future<void> _handleSystemRequest(String command) async {
    try {
      final systemInfo = await _getSystemStatus();
      final response = await _aiService.generateContextualResponse(
        command,
        'system',
        systemInfo,
      );
      await speakText(response);
    } catch (e) {
      await speakText(
        'Je ne peux pas accéder aux informations système pour le moment.',
      );
    }
  }

  Future<void> _handleGeneralConversation(String command) async {
    try {
      final response = await _aiService.generatePersonalizedResponse(
        command,
        'assistant_vocal',
        _currentUser?.id ?? 'anonymous',
        [],
      );
      await speakText(response);
    } catch (e) {
      await speakText('Je ne comprends pas bien. Pouvez-vous reformuler ?');
    }
  }

  /// Étape 11: Orchestration complète de la gestion des voix
  Future<void> _handleVoiceRequest(String command) async {
    try {
      final lowerCommand = command.toLowerCase();

      // Lister les voix disponibles
      if (lowerCommand.contains(
        RegExp(r'\b(quelles? voix|liste voix|voix disponibles?)\b'),
      )) {
        final response = _voiceManagementService.generateVoiceListResponse();
        await speakText(response);
        return;
      }

      // Sélectionner une voix par nom
      final chooseMatch = RegExp(
        r'\b(?:choisis|sélectionne|utilise)\s+(\w+)\b',
      ).firstMatch(lowerCommand);
      if (chooseMatch != null) {
        final voiceName = chooseMatch.group(1)!;
        final response = await _voiceManagementService.selectVoiceByName(
          voiceName,
        );

        // Aperçu dans la nouvelle voix si sélection réussie
        if (!response.contains('Désolé')) {
          await speakText(response);
          // TODO: Changer la voix TTS ici pour l'aperçu
          final selectedVoice = _voiceManagementService.selectedVoice;
          if (selectedVoice != null) {
            final preview = await _voiceManagementService.generateVoicePreview(
              selectedVoice,
            );
            await speakText(preview);
          }
        } else {
          await speakText(response);
        }
        return;
      }

      // Rafraîchir les voix
      if (lowerCommand.contains(
        RegExp(r'\b(actualise|rafraîchis|recharge)\s+(les\s+)?voix\b'),
      )) {
        await _voiceManagementService.refreshVoices();
        await speakText(
          'Liste des voix mise à jour. Dites "quelles voix" pour entendre les nouvelles options.',
        );
        return;
      }

      // Commande vocale non reconnue
      await speakText(
        'Pour les voix, dites "quelles voix" pour la liste ou "choisis" suivi du nom.',
      );
    } catch (e) {
      debugPrint('Erreur gestion voix: $e');
      await speakText(
        'Problème avec la gestion des voix. Réessayez plus tard.',
      );
    }
  }

  Future<void> _updateMood(String emotion) async {
    _currentMood = emotion;
    _moodController.add(emotion);

    if (_currentUser != null) {
      await _supabase.from('emotion_logs').insert({
        'user_id': _currentUser!.id,
        'emotion_type': emotion,
        'detection_method': 'voice_analysis',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _startSystemMonitoring() async {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) async {
      await _checkPhoneUsage();
      await _checkSystemHealth();
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkBatteryStatus();
    });
  }

  Future<void> _checkPhoneUsage() async {
    try {
      final usage = await _phoneMonitoringService.getCurrentUsage();
      if (usage.isExcessiveUsage && _currentUser?.allowReproches == true) {
        await _sendUsageWarning(usage);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'utilisation: $e');
    }
  }

  Future<void> _checkBatteryStatus() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      if (batteryLevel <= 15 && batteryState != BatteryState.charging) {
        await _sendBatteryWarning(batteryLevel);
      }

      final batteryInfo = await _batteryMonitoringService
          .getCurrentBatteryHealth();
      if (batteryInfo.batteryTemperatureCelsius != null &&
          batteryInfo.batteryTemperatureCelsius! > 45.0) {
        await _sendOverheatingWarning(batteryInfo.batteryTemperatureCelsius!);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la batterie: $e');
    }
  }

  Future<void> _sendUsageWarning(PhoneUsageMonitoring usage) async {
    final responses = await _getPersonalityResponses(
      'reproches',
      'usage_excessif',
    );
    if (responses.isNotEmpty) {
      final warning = responses[Random().nextInt(responses.length)];
      await speakText(warning.responseText);
      await _showNotification(
        'Attention à votre utilisation !',
        'Vous avez déjà passé ${(usage.totalScreenTimeSeconds / 3600).toStringAsFixed(1)} heures sur votre téléphone aujourd\'hui.',
      );
    }
  }

  Future<void> _sendBatteryWarning(int batteryLevel) async {
    final responses = await _getPersonalityResponses(
      'reproches',
      'batterie_faible',
    );
    if (responses.isNotEmpty) {
      final warning = responses[Random().nextInt(responses.length)];
      await speakText(warning.responseText);
      await _showNotification(
        'Batterie faible !',
        'Il ne reste que $batteryLevel% de batterie. Pensez à recharger votre téléphone.',
      );
    }
  }

  Future<void> _sendOverheatingWarning(double temperature) async {
    final responses = await _getPersonalityResponses('reproches', 'surchauffe');
    if (responses.isNotEmpty) {
      final warning = responses[Random().nextInt(responses.length)];
      await speakText(warning.responseText);
      await _showNotification(
        'Téléphone surchauffé !',
        'Votre téléphone est à ${temperature.toStringAsFixed(1)}°C. Laissez-le refroidir.',
      );
    }
  }

  Future<List<AIPersonalityResponse>> _getPersonalityResponses(
    String responseType,
    String context,
  ) async {
    try {
      final response = await _supabase
          .from('ai_personality_responses')
          .select()
          .eq('response_type', responseType)
          .eq('trigger_context', context)
          .eq(
            'personality_type',
            _currentUser?.personalityPreference ?? 'mere_africaine',
          )
          .eq('is_active', true);

      return (response as List)
          .map((json) => AIPersonalityResponse.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des réponses: $e');
      return [];
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'hordvoice_channel',
      'HordVoice Notifications',
      channelDescription: 'Notifications de l\'assistant vocal HordVoice',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  Future<Map<String, dynamic>> _getSystemStatus() async {
    final batteryLevel = await _battery.batteryLevel;
    final position = await Geolocator.getCurrentPosition();

    return {
      'battery_level': batteryLevel,
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'mood': _currentMood,
      'is_listening': _isListening,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _checkSystemHealth() async {
    final systemStatus = await _getSystemStatus();
    _systemStatusController.add(systemStatus);
  }

  String get currentMood => _currentMood;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  UserProfile? get currentUser => _currentUser;

  // Méthodes pour l'interface vocale
  Future<void> startVoiceRecognition() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      _isListening = true;

      // Utiliser le nouveau pipeline streaming (Étape 6)
      await _azureSpeechService.startListening();

      // Écouter les résultats via streams
      _azureSpeechService.resultStream.listen((result) {
        if (result.recognizedText.isNotEmpty && result.isFinal) {
          processVoiceCommand(result.recognizedText);
        }
      });

      debugPrint('Reconnaissance vocale démarrée');
    } catch (e) {
      _isListening = false;
      debugPrint('Erreur lors du démarrage de la reconnaissance: $e');
      rethrow;
    }
  }

  Future<void> stopVoiceRecognition() async {
    try {
      _isListening = false;
      await _azureSpeechService.stopListening();
      debugPrint('Reconnaissance vocale arrêtée');
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt de la reconnaissance: $e');
      rethrow;
    }
  }

  Future<String> processVoiceCommand(String command) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      debugPrint('Traitement de la commande: $command');

      // Analyser l'émotion de la commande
      final emotion = await _emotionAnalysisService.analyzeEmotion(command);

      // Générer une réponse appropriée
      final response = await _aiService.generateContextualResponse(
        command,
        'voice_command',
        {'emotion': emotion, 'mood': _currentMood, 'context': 'voice_command'},
      );

      // Parler la réponse
      await speakText(response);

      // Exécuter la commande si nécessaire
      await _executeCommand(command);

      return response;
    } catch (e) {
      debugPrint('Erreur lors du traitement de la commande: $e');
      final errorResponse =
          'Désolé, je n\'ai pas pu traiter votre demande. Veuillez réessayer.';
      await speakText(errorResponse);
      return errorResponse;
    }
  }

  Future<void> _executeCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    // Contrôles vocaux des paramètres système
    if (lowerCommand.contains('luminosité') || lowerCommand.contains('écran')) {
      await _quickSettingsService.handleBrightnessVoiceCommand(command);
    } else if (lowerCommand.contains('volume') ||
        lowerCommand.contains('son')) {
      await _quickSettingsService.handleVolumeVoiceCommand(command);
    } else if (lowerCommand.contains('wifi') ||
        lowerCommand.contains('bluetooth')) {
      await _quickSettingsService.handleConnectivityVoiceCommand(command);
    } else if (lowerCommand.contains('mode avion') ||
        lowerCommand.contains('données mobiles') ||
        lowerCommand.contains('rotation')) {
      await _quickSettingsService.handlePhoneSettingsVoiceCommand(command);
    } else if (lowerCommand.contains('météo')) {
      await _handleWeatherRequest(command);
    } else if (lowerCommand.contains('musique') ||
        lowerCommand.contains('jouer')) {
      await _handleMusicRequest(command);
    } else if (lowerCommand.contains('aller à') ||
        lowerCommand.contains('navigation')) {
      await _handleNavigationRequest(command);
    } else if (lowerCommand.contains('calendrier') ||
        lowerCommand.contains('événement')) {
      await _handleCalendarRequest(command);
    } else if (lowerCommand.contains('santé') || lowerCommand.contains('pas')) {
      await _handleHealthRequest(command);
    } else if (lowerCommand.contains('appeler')) {
      await _handleCallRequest(command);
    } else if (lowerCommand.contains('message') ||
        lowerCommand.contains('sms')) {
      await _handleSMSRequest(command);
    }
  }

  Future<void> _handleCallRequest(String command) async {
    try {
      // Extraire le nom ou numéro de la commande
      final lowerCommand = command.toLowerCase();
      String contact = '';

      if (lowerCommand.contains('appeler ')) {
        contact = command
            .substring(command.toLowerCase().indexOf('appeler ') + 8)
            .trim();
      }

      if (contact.isNotEmpty) {
        await speakText('Je vais appeler $contact pour vous.');
        // Ici, vous pouvez intégrer avec l'API d'appels du téléphone
        debugPrint('Tentative d\'appel à: $contact');
      } else {
        await speakText('Qui voulez-vous appeler ?');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel: $e');
      await speakText('Désolé, je n\'ai pas pu passer l\'appel.');
    }
  }

  Future<void> _handleSMSRequest(String command) async {
    try {
      // Extraire le destinataire et le message
      final lowerCommand = command.toLowerCase();
      String contact = '';
      String message = '';

      if (lowerCommand.contains('envoyer message à ')) {
        final parts = command.split('envoyer message à ');
        if (parts.length > 1) {
          final remaining = parts[1];
          final messageParts = remaining.split(' dire ');
          if (messageParts.length > 1) {
            contact = messageParts[0].trim();
            message = messageParts[1].trim();
          }
        }
      }

      if (contact.isNotEmpty && message.isNotEmpty) {
        await speakText('J\'envoie le message "$message" à $contact.');
        // Ici, vous pouvez intégrer avec l'API SMS du téléphone
        debugPrint('Envoi SMS à $contact: $message');
      } else {
        await speakText('Veuillez préciser le destinataire et le message.');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi SMS: $e');
      await speakText('Désolé, je n\'ai pas pu envoyer le message.');
    }
  }

  /// Démarre la détection automatique de wake word en arrière-plan
  Future<void> _startWakeWordDetection() async {
    if (_wakeWordActive) return;

    try {
      _wakeWordActive = true;
      debugPrint('Démarrage de la détection automatique de wake word');

      // Démarrer l'écoute en continu pour le wake word
      _wakeWordTimer = Timer.periodic(const Duration(seconds: 5), (
        timer,
      ) async {
        if (!_isListening && _wakeWordActive) {
          await _listenForWakeWord();
        }
      });

      // Écouter immédiatement
      await _listenForWakeWord();
    } catch (e) {
      debugPrint('Erreur démarrage wake word detection: $e');
    }
  }

  /// Écoute pour le wake word
  Future<void> _listenForWakeWord() async {
    try {
      // Démarrer une reconnaissance courte pour détecter "Hey Ric" ou variantes
      final result = await _azureSpeechService.startSimpleRecognition();

      if (result != null && _containsWakeWord(result)) {
        debugPrint('Wake word détecté: $result');
        _wakeWordController.add(true);

        await speakText('Oui, je vous écoute');

        // Démarrer l'écoute complète pour la commande
        await startListening();
      }
    } catch (e) {
      debugPrint('Erreur écoute wake word: $e');
    }
  }

  /// Vérifie si le texte contient un wake word
  bool _containsWakeWord(String text) {
    final lowerText = text.toLowerCase();
    final wakeWords = [
      'hey ric',
      'salut ric',
      'ric',
      'rick',
      'hey rick',
      'salut rick',
      'bonjour ric',
      'bonjour rick',
    ];

    return wakeWords.any((wake) => lowerText.contains(wake));
  }

  /// Arrête la détection de wake word
  Future<void> stopWakeWordDetection() async {
    _wakeWordActive = false;
    _wakeWordTimer?.cancel();
    _wakeWordTimer = null;
    debugPrint('Détection wake word arrêtée');
  }

  // Accès au service de transition pour les animations
  TransitionAnimationService get transitionService => _transitionService;

  void dispose() {
    _monitoringTimer?.cancel();
    _batteryTimer?.cancel();
    _wakeWordTimer?.cancel();
    _aiResponseController.close();
    _moodController.close();
    _systemStatusController.close();
    _audioLevelController.close();
    _transcriptionController.close();
    _emotionController.close();
    _wakeWordController.close();
    _isSpeakingController.close();
  }
}
