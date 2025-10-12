import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/language_resolver.dart';
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
import 'voice_management_service.dart';
import 'quick_settings_service.dart';
import 'transition_animation_service.dart';
import 'spatial_overlay_service.dart';

final unifiedHordVoiceServiceProvider = Provider<UnifiedHordVoiceService>((ref) {
  return UnifiedHordVoiceService();
});

class UnifiedHordVoiceService {
  static final UnifiedHordVoiceService _instance = UnifiedHordVoiceService._internal();
  factory UnifiedHordVoiceService() => _instance;
  UnifiedHordVoiceService._internal();

  // Core services - initialized early
  SupabaseClient? _supabase;
  FlutterTts? _tts;
  Battery? _battery;
  FlutterLocalNotificationsPlugin? _notifications;

  // User and state
  UserProfile? _currentUser;
  Timer? _monitoringTimer;
  Timer? _batteryTimer;
  Timer? _wakeWordTimer;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _secondaryInitialized = false;
  bool _isListening = false;
  bool _wakeWordActive = false;
  String _currentMood = 'neutral';

  // AI Services - initialized as needed
  AzureOpenAIService? _aiService;
  AzureSpeechService? _azureSpeechService;
  EmotionAnalysisService? _emotionAnalysisService;
  WeatherService? _weatherService;
  NewsService? _newsService;
  SpotifyService? _spotifyService;
  NavigationService? _navigationService;
  CalendarService? _calendarService;
  HealthMonitoringService? _healthService;
  PhoneMonitoringService? _phoneMonitoringService;
  BatteryMonitoringService? _batteryMonitoringService;
  VoiceManagementService? _voiceManagementService;
  QuickSettingsService? _quickSettingsService;
  TransitionAnimationService? _transitionService;
  SpatialOverlayService? _spatialOverlayService;

  // Stream controllers
  final StreamController<String> _aiResponseController = StreamController<String>.broadcast();
  final StreamController<String> _moodController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _systemStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<double> _audioLevelController = StreamController<double>.broadcast();
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _emotionController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _wakeWordController = StreamController<bool>.broadcast();
  final StreamController<bool> _isSpeakingController = StreamController<bool>.broadcast();

  // Stream getters
  Stream<String> get aiResponseStream => _aiResponseController.stream;
  Stream<String> get moodStream => _moodController.stream;
  Stream<Map<String, dynamic>> get systemStatusStream => _systemStatusController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<Map<String, dynamic>> get emotionStream => _emotionController.stream;
  Stream<bool> get wakeWordStream => _wakeWordController.stream;
  Stream<bool> get isSpeakingStream => _isSpeakingController.stream;

  /// Initialisation progressive - Services essentiels SEULEMENT
  Future<void> initializeCore() async {
    if (_isInitialized) {
      debugPrint('UnifiedHordVoiceService déjà initialisé - Ignorer');
      return;
    }

    if (_isInitializing) {
      debugPrint('Initialisation en cours - Attendre');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('DEBUT Initialisation UnifiedHordVoiceService');

      // Vérifier que Supabase est initialisé
      try {
        _supabase = Supabase.instance.client;
      } catch (e) {
        debugPrint('Supabase non disponible, mode déconnecté: $e');
      }

      _tts = FlutterTts();
      _battery = Battery();
      _notifications = FlutterLocalNotificationsPlugin();

      // Initialisation des services essentiels
      await _initializeNotifications();
      await _initializeTTS();

      // Services critiques avec gestion d'erreur robuste
      _aiService = AzureOpenAIService();
      _azureSpeechService = AzureSpeechService();
      _emotionAnalysisService = EmotionAnalysisService();

      // Initialisation Azure sans bloquer l'interface
      try {
        await _aiService?.initialize();
      } catch (e) {
        debugPrint('Avertissement: AzureOpenAI non disponible: $e');
      }

      try {
        await _azureSpeechService?.initialize();
      } catch (e) {
        debugPrint('Avertissement: AzureSpeech non disponible: $e');
      }

      try {
        await _emotionAnalysisService?.initialize();
      } catch (e) {
        debugPrint('Avertissement: EmotionAnalysis non disponible: $e');
      }

      debugPrint('Services essentiels initialisés');
      _isInitialized = true;
      debugPrint('FIN Initialisation UnifiedHordVoiceService - SUCCES');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des services essentiels: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialisation progressive - Services secondaires
  Future<void> initializeSecondary() async {
    if (_secondaryInitialized) {
      debugPrint('Services secondaires déjà initialisés - Ignorer');
      return;
    }

    _secondaryInitialized = true;

    try {
      debugPrint('DEBUT Initialisation services secondaires');

      // Initialiser les services secondaires
      _weatherService = WeatherService();
      _newsService = NewsService();
      _spotifyService = SpotifyService();
      _navigationService = NavigationService();
      _calendarService = CalendarService();
      _healthService = HealthMonitoringService();
      _phoneMonitoringService = PhoneMonitoringService();
      _batteryMonitoringService = BatteryMonitoringService();
      _voiceManagementService = VoiceManagementService();
      _quickSettingsService = QuickSettingsService();
      _transitionService = TransitionAnimationService();
      _spatialOverlayService = SpatialOverlayService();

      // Initialisation safe avec gestion d'erreurs
      final services = [
        () => _weatherService?.initialize(),
        () => _newsService?.initialize(),
        () => _spotifyService?.initialize(),
        () => _navigationService?.initialize(),
        () => _calendarService?.initialize(),
        () => _healthService?.initialize(),
        () => _phoneMonitoringService?.initialize(),
        () => _batteryMonitoringService?.initialize(),
        () => _voiceManagementService?.initialize(),
        () => _quickSettingsService?.initialize(),
        () => _transitionService?.initialize(),
        () => _spatialOverlayService?.initialize(),
      ];

      for (final serviceInitializer in services) {
        try {
          await serviceInitializer();
        } catch (e) {
          debugPrint('Avertissement: Un service secondaire a échoué: $e');
        }
      }

      // Démarrer les services de monitoring
      try {
        await _startSystemMonitoring();
        await _startWakeWordDetection();
      } catch (e) {
        debugPrint('Avertissement: Monitoring non disponible: $e');
      }

      debugPrint('Tous les services initialisés');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des services secondaires: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('UnifiedHordVoiceService déjà complètement initialisé - Ignorer');
      return;
    }

    await initializeCore();
    await initializeSecondary();
  }

  Future<void> _initializeNotifications() async {
    if (_notifications == null) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications!.initialize(initSettings);
    } catch (e) {
      debugPrint('Erreur initialisation notifications: $e');
    }
  }

  Future<void> _initializeTTS() async {
    if (_tts == null) return;

    try {
      final ttsLang = await LanguageResolver.getTtsLanguage();
      await _tts!.setLanguage(ttsLang);
      await _tts!.setSpeechRate(0.8);
      await _tts!.setVolume(0.8);
      await _tts!.setPitch(1.0);
    } catch (e) {
      debugPrint('Erreur initialisation TTS: $e');
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      if (_supabase == null) {
        debugPrint('Supabase non initialisé');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id');

      if (deviceId == null) return null;

      final response = await _supabase!
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
      if (_supabase == null) {
        throw Exception('Supabase non initialisé pour la création d\'utilisateur');
      }

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

      final response = await _supabase!
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

    try {
      final responses = await _getPersonalityResponses('felicitation', 'premiere_utilisation');
      if (responses.isNotEmpty) {
        final welcomeMessage = responses.first.responseText;
        await speakText(welcomeMessage);
      }
    } catch (e) {
      debugPrint('Erreur message de bienvenue: $e');
    }
  }

  Future<void> speakText(String text, {String? emotion}) async {
    if (_tts == null) return;

    try {
      _isSpeakingController.add(true);

      if (_currentUser != null) {
        await _tts!.setSpeechRate(_currentUser!.speechSpeed);
        await _tts!.setVolume(_currentUser!.volume);
      }

      await _tts!.speak(text);
      _aiResponseController.add(text);

      _isSpeakingController.add(false);
    } catch (e) {
      _isSpeakingController.add(false);
      debugPrint('Erreur lors de la synthèse vocale: $e');
    }
  }

  Future<void> interruptSpeech() async {
    if (_tts == null) return;

    try {
      await _tts!.stop();
      _isSpeakingController.add(false);
      debugPrint('TTS interrompu par l\'utilisateur');
    } catch (e) {
      debugPrint('Erreur lors de l\'interruption TTS: $e');
    }
  }

  Future<void> startListening() async {
    if (_isListening || _azureSpeechService == null) return;

    _isListening = true;

    try {
      await _azureSpeechService!.startListening();

      _azureSpeechService!.resultStream.listen((result) {
        _transcriptionController.add(result.recognizedText);
        if (result.isFinal) {
          _processVoiceCommandWithEmotion(result.recognizedText);
        }
      });

      _azureSpeechService!.errorStream.listen((error) {
        debugPrint('Erreur STT: ${error.errorMessage}');
        speakText('Désolé, je n\'ai pas bien entendu.');
      });
    } catch (e) {
      _isListening = false;
      debugPrint('Erreur démarrage écoute: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening || _azureSpeechService == null) return;

    _isListening = false;
    try {
      await _azureSpeechService!.stopListening();
    } catch (e) {
      debugPrint('Erreur arrêt écoute: $e');
    }
  }

  Future<void> _processVoiceCommandWithEmotion(String command) async {
    if (_emotionAnalysisService == null || _aiService == null) return;

    try {
      final Future<String> emotionFuture = _emotionAnalysisService!.analyzeEmotion(command);
      final Future<String> intentFuture = _aiService!.analyzeIntent(command);

      final results = await Future.wait([emotionFuture, intentFuture]);
      final emotion = results[0];
      final intent = results[1];

      _emotionController.add({
        'emotion': emotion,
        'text': command,
        'timestamp': DateTime.now().toIso8601String(),
        'confidence': 0.85,
      });

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
      case 'voice':
      case 'voix':
        await _handleVoiceRequest(originalCommand);
        break;
      default:
        await _handleGeneralConversation(originalCommand);
    }
  }

  Future<void> _handleWeatherRequest(String command) async {
    if (_weatherService == null) {
      await speakText('Service météo non disponible.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final weather = await _weatherService!.getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      final response = await _aiService?.generateContextualResponse(
        'Donne-moi la météo',
        'weather',
        {'weather': weather},
      ) ?? 'Données météo récupérées';
      
      await speakText(response);
    } catch (e) {
      await speakText('Je ne peux pas accéder aux informations météo pour le moment.');
    }
  }

  Future<void> _handleNewsRequest(String command) async {
    if (_newsService == null) {
      await speakText('Service actualités non disponible.');
      return;
    }

    try {
      final news = await _newsService!.getLatestNews();
      final response = await _aiService?.generateContextualResponse(
        command,
        'news',
        {'news': news},
      ) ?? 'Actualités récupérées';
      
      await speakText(response);
    } catch (e) {
      await speakText('Je ne peux pas accéder aux actualités pour le moment.');
    }
  }

  Future<void> _handleMusicRequest(String command) async {
    if (_spotifyService == null) {
      await speakText('Service musique non disponible.');
      return;
    }

    try {
      if (command.toLowerCase().contains('spotify')) {
        await _spotifyService!.playMusic(command);
      } else {
        await _spotifyService!.searchAndPlay(command);
      }
      await speakText('Je lance votre musique !');
    } catch (e) {
      await speakText('Je ne peux pas lancer la musique pour le moment.');
    }
  }

  Future<void> _handleNavigationRequest(String command) async {
    if (_navigationService == null) {
      await speakText('Service navigation non disponible.');
      return;
    }

    try {
      await speakText('Fonctionnalité de navigation en cours de développement.');
    } catch (e) {
      await speakText('Je ne peux pas démarrer la navigation pour le moment.');
    }
  }

  Future<void> _handleCalendarRequest(String command) async {
    if (_calendarService == null) {
      await speakText('Service calendrier non disponible.');
      return;
    }

    try {
      await speakText('Fonctionnalité calendrier en cours de développement.');
    } catch (e) {
      await speakText('Je ne peux pas accéder à votre calendrier pour le moment.');
    }
  }

  Future<void> _handleHealthRequest(String command) async {
    if (_healthService == null) {
      await speakText('Service santé non disponible.');
      return;
    }

    try {
      await speakText('Fonctionnalité santé en cours de développement.');
    } catch (e) {
      await speakText('Je ne peux pas accéder à vos données de santé pour le moment.');
    }
  }

  Future<void> _handleSystemRequest(String command) async {
    try {
      final systemInfo = await _getSystemStatus();
      final response = await _aiService?.generateContextualResponse(
        command,
        'system',
        systemInfo,
      ) ?? 'Informations système récupérées';
      
      await speakText(response);
    } catch (e) {
      await speakText('Je ne peux pas accéder aux informations système pour le moment.');
    }
  }

  Future<void> _handleGeneralConversation(String command) async {
    try {
      final response = await _aiService?.generatePersonalizedResponse(
        command,
        'assistant_vocal',
        _currentUser?.id ?? 'anonymous',
        [],
      ) ?? 'Je vous écoute.';
      
      await speakText(response);
    } catch (e) {
      await speakText('Je ne comprends pas bien. Pouvez-vous reformuler ?');
    }
  }

  Future<void> _handleVoiceRequest(String command) async {
    if (_voiceManagementService == null) {
      await speakText('Service gestion des voix non disponible.');
      return;
    }

    try {
      await speakText('Fonctionnalité gestion des voix en cours de développement.');
    } catch (e) {
      await speakText('Problème avec la gestion des voix. Réessayez plus tard.');
    }
  }

  Future<void> _updateMood(String emotion) async {
    _currentMood = emotion;
    _moodController.add(emotion);

    if (_currentUser != null && _supabase != null) {
      try {
        await _supabase!.from('emotion_logs').insert({
          'user_id': _currentUser!.id,
          'emotion_type': emotion,
          'detection_method': 'voice_analysis',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Erreur lors de l\'enregistrement de l\'émotion: $e');
      }
    }
  }

  Future<void> _startSystemMonitoring() async {
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkPhoneUsage();
      await _checkSystemHealth();
    });

    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkBatteryStatus();
    });
  }

  Future<void> _checkPhoneUsage() async {
    if (_phoneMonitoringService == null) return;

    try {
      final usage = await _phoneMonitoringService!.getCurrentUsage();
      if (usage.isExcessiveUsage && _currentUser?.allowReproches == true) {
        await _sendUsageWarning(usage);
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'utilisation: $e');
    }
  }

  Future<void> _checkBatteryStatus() async {
    if (_battery == null) return;

    try {
      final batteryLevel = await _battery!.batteryLevel;
      final batteryState = await _battery!.batteryState;

      if (batteryLevel <= 15 && batteryState != BatteryState.charging) {
        await _sendBatteryWarning(batteryLevel);
      }

      if (_batteryMonitoringService != null) {
        final batteryInfo = await _batteryMonitoringService!.getCurrentBatteryHealth();
        if (batteryInfo.batteryTemperatureCelsius != null &&
            batteryInfo.batteryTemperatureCelsius! > 45.0) {
          await _sendOverheatingWarning(batteryInfo.batteryTemperatureCelsius!);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la batterie: $e');
    }
  }

  Future<void> _sendUsageWarning(PhoneUsageMonitoring usage) async {
    final responses = await _getPersonalityResponses('reproches', 'usage_excessif');
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
    final responses = await _getPersonalityResponses('reproches', 'batterie_faible');
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
      if (_supabase == null) {
        debugPrint('Supabase non initialisé pour les réponses de personnalité');
        return [];
      }

      final response = await _supabase!
          .from('ai_personality_responses')
          .select()
          .eq('response_type', responseType)
          .eq('trigger_context', context)
          .eq('personality_type', _currentUser?.personalityPreference ?? 'mere_africaine')
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
    if (_notifications == null) return;

    const androidDetails = AndroidNotificationDetails(
      'hordvoice_channel',
      'HordVoice Notifications',
      channelDescription: 'Notifications de l\'assistant vocal HordVoice',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications!.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Erreur affichage notification: $e');
    }
  }

  Future<Map<String, dynamic>> _getSystemStatus() async {
    final batteryLevel = _battery != null ? await _battery!.batteryLevel : 0;
    
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Erreur récupération position: $e');
    }

    return {
      'battery_level': batteryLevel,
      'location': position != null ? {
        'latitude': position.latitude,
        'longitude': position.longitude,
      } : null,
      'mood': _currentMood,
      'is_listening': _isListening,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _checkSystemHealth() async {
    final systemStatus = await _getSystemStatus();
    _systemStatusController.add(systemStatus);
  }

  // Getters
  String get currentMood => _currentMood;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  UserProfile? get currentUser => _currentUser;

  // Méthodes pour l'interface vocale
  Future<void> startVoiceRecognition() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      _isListening = true;
      if (_azureSpeechService != null) {
        await _azureSpeechService!.startListening();

        _azureSpeechService!.resultStream.listen((result) {
          if (result.recognizedText.isNotEmpty && result.isFinal) {
            processVoiceCommand(result.recognizedText);
          }
        });
      }

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
      if (_azureSpeechService != null) {
        await _azureSpeechService!.stopListening();
      }
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

      String emotion = 'neutral';
      if (_emotionAnalysisService != null) {
        emotion = await _emotionAnalysisService!.analyzeEmotion(command);
      }

      String response = 'Commande reçue';
      if (_aiService != null) {
        response = await _aiService!.generateContextualResponse(
          command,
          'voice_command',
          {'emotion': emotion, 'mood': _currentMood, 'context': 'voice_command'},
        );
      }

      await speakText(response);
      await _executeCommand(command);

      return response;
    } catch (e) {
      debugPrint('Erreur lors du traitement de la commande: $e');
      const errorResponse = 'Désolé, je n\'ai pas pu traiter votre demande. Veuillez réessayer.';
      await speakText(errorResponse);
      return errorResponse;
    }
  }

  Future<void> _executeCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('luminosité') || lowerCommand.contains('écran')) {
      await _quickSettingsService?.handleBrightnessVoiceCommand(command);
    } else if (lowerCommand.contains('volume') || lowerCommand.contains('son')) {
      await _quickSettingsService?.handleVolumeVoiceCommand(command);
    } else if (lowerCommand.contains('wifi') || lowerCommand.contains('bluetooth')) {
      await _quickSettingsService?.handleConnectivityVoiceCommand(command);
    } else if (lowerCommand.contains('mode avion') || 
               lowerCommand.contains('données mobiles') ||
               lowerCommand.contains('rotation')) {
      await _quickSettingsService?.handlePhoneSettingsVoiceCommand(command);
    } else if (lowerCommand.contains('météo')) {
      await _handleWeatherRequest(command);
    } else if (lowerCommand.contains('musique') || lowerCommand.contains('jouer')) {
      await _handleMusicRequest(command);
    } else if (lowerCommand.contains('aller à') || lowerCommand.contains('navigation')) {
      await _handleNavigationRequest(command);
    } else if (lowerCommand.contains('calendrier') || lowerCommand.contains('événement')) {
      await _handleCalendarRequest(command);
    } else if (lowerCommand.contains('santé') || lowerCommand.contains('pas')) {
      await _handleHealthRequest(command);
    } else if (lowerCommand.contains('appeler')) {
      await _handleCallRequest(command);
    } else if (lowerCommand.contains('message') || lowerCommand.contains('sms')) {
      await _handleSMSRequest(command);
    }
  }

  Future<void> _handleCallRequest(String command) async {
    try {
      final lowerCommand = command.toLowerCase();
      String contact = '';

      if (lowerCommand.contains('appeler ')) {
        contact = command.substring(command.toLowerCase().indexOf('appeler ') + 8).trim();
      }

      if (contact.isNotEmpty) {
        await speakText('Je vais appeler $contact pour vous.');
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
        debugPrint('Envoi SMS à $contact: $message');
      } else {
        await speakText('Veuillez préciser le destinataire et le message.');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi SMS: $e');
      await speakText('Désolé, je n\'ai pas pu envoyer le message.');
    }
  }

  Future<void> _startWakeWordDetection() async {
    if (_wakeWordActive) return;

    try {
      _wakeWordActive = true;
      debugPrint('Démarrage de la détection automatique de wake word');

      _wakeWordTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isListening && _wakeWordActive) {
          await _listenForWakeWord();
        }
      });

      await _listenForWakeWord();
    } catch (e) {
      debugPrint('Erreur démarrage wake word detection: $e');
    }
  }

  Future<void> _listenForWakeWord() async {
    if (_azureSpeechService == null) return;

    try {
      final result = await _azureSpeechService!.startSimpleRecognition();

      if (result != null && _containsWakeWord(result)) {
        debugPrint('Wake word détecté: $result');
        _wakeWordController.add(true);

        await speakText('Oui, je vous écoute');
        await startListening();
      }
    } catch (e) {
      debugPrint('Erreur écoute wake word: $e');
    }
  }

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

  Future<void> startWakeWordDetection() async {
    await _startWakeWordDetection();
  }

  Future<void> stopWakeWordDetection() async {
    _wakeWordActive = false;
    _wakeWordTimer?.cancel();
    _wakeWordTimer = null;
    debugPrint('Détection wake word arrêtée');
  }

  // Accès aux services
  TransitionAnimationService? get transitionService => _transitionService;
  SpatialOverlayService? get spatialOverlayService => _spatialOverlayService;

  Future<void> enablePersistentAI() async {
    debugPrint('Activation IA persistante...');
    try {
      await _spatialOverlayService?.enablePersistentMode();
      debugPrint('IA persistante activée');
    } catch (e) {
      debugPrint('Erreur activation IA persistante: $e');
      rethrow;
    }
  }

  Future<void> disablePersistentAI() async {
    debugPrint('Désactivation IA persistante...');
    try {
      await _spatialOverlayService?.disablePersistentMode();
      debugPrint('IA persistante désactivée');
    } catch (e) {
      debugPrint('Erreur désactivation IA persistante: $e');
    }
  }

  Future<void> showSpatialAvatar({
    SpatialOverlayMode mode = SpatialOverlayMode.overlay,
    SpatialOverlayConfig? config,
  }) async {
    debugPrint('Affichage avatar spatial...');
    try {
      await _spatialOverlayService?.showSpatialOverlay(mode: mode, config: config);
      debugPrint('Avatar spatial affiché');
    } catch (e) {
      debugPrint('Erreur affichage avatar spatial: $e');
    }
  }

  Future<void> speakWithEmotion(String text, {String emotion = 'neutral'}) async {
    if (_tts == null) return;

    debugPrint('Parole avec émotion: $emotion - $text');

    try {
      _isSpeakingController.add(true);

      switch (emotion) {
        case 'welcome':
          await _tts!.setPitch(1.1);
          await _tts!.setSpeechRate(0.9);
          break;
        case 'goodbye':
          await _tts!.setPitch(0.9);
          await _tts!.setSpeechRate(0.8);
          break;
        case 'excited':
          await _tts!.setPitch(1.2);
          await _tts!.setSpeechRate(1.1);
          break;
        case 'calm':
          await _tts!.setPitch(0.95);
          await _tts!.setSpeechRate(0.85);
          break;
        default:
          await _tts!.setPitch(1.0);
          await _tts!.setSpeechRate(0.95);
      }

      await _tts!.speak(text);
      await Future.delayed(Duration(milliseconds: text.length * 50));
      _isSpeakingController.add(false);
    } catch (e) {
      debugPrint('Erreur parole avec émotion: $e');
      _isSpeakingController.add(false);
    }
  }

  Future<void> hideSpatialAvatar() async {
    debugPrint('Masquage avatar spatial...');
    try {
      await _spatialOverlayService?.hideSpatialOverlay();
      debugPrint('Avatar spatial masqué');
    } catch (e) {
      debugPrint('Erreur masquage avatar spatial: $e');
    }
  }

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