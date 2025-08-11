import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voice_models.dart';
import 'environment_config.dart';

/// Étape 9: Service de gestion des voix voice-only
class VoiceManagementService {
  static final VoiceManagementService _instance =
      VoiceManagementService._internal();
  factory VoiceManagementService() => _instance;
  VoiceManagementService._internal();

  late SupabaseClient _supabase;
  bool _isInitialized = false;

  List<VoiceOption> _availableVoices = [];
  VoiceOption? _selectedVoice;
  DateTime? _lastVoiceRefresh;
  final Duration _voiceRefreshInterval = Duration(hours: 6);

  // Cache des voix Azure Speech
  final Map<String, List<String>> _azureVoicesCache = {};

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _supabase = Supabase.instance.client;
      await _loadSelectedVoice();
      await _loadAvailableVoices();

      _isInitialized = true;
      debugPrint(
        'VoiceManagementService initialisé avec ${_availableVoices.length} voix',
      );
    } catch (e) {
      debugPrint('Erreur initialisation VoiceManagementService: $e');
      _setupDefaultVoices();
    }
  }

  /// Étape 9: Charger voix disponibles depuis Supabase/Azure
  Future<void> _loadAvailableVoices() async {
    try {
      // Vérifier si on doit rafraîchir
      if (_lastVoiceRefresh != null &&
          DateTime.now().difference(_lastVoiceRefresh!) <
              _voiceRefreshInterval) {
        return;
      }

      // Charger depuis Supabase (manifest des voix) - avec gestion d'erreur
      try {
        final response = await _supabase
            .from('available_voices')
            .select()
            .eq('is_active', true)
            .order('name');

        if (response.isNotEmpty) {
          _availableVoices = (response as List)
              .map((json) => VoiceOption.fromJson(json))
              .toList();
          _lastVoiceRefresh = DateTime.now();
          return;
        }
      } catch (dbError) {
        debugPrint('Table available_voices non trouvée: $dbError');
      }

      // Fallback: charger voix Azure Speech directement ou voix par défaut
      try {
        await _loadAzureVoices();
      } catch (azureError) {
        debugPrint('Azure voices non disponibles: $azureError');
        _setupDefaultVoices();
      }

      _lastVoiceRefresh = DateTime.now();
    } catch (e) {
      debugPrint('Erreur chargement voix: $e');
      _setupDefaultVoices();
    }
  }

  /// Charger les voix Azure Speech disponibles
  Future<void> _loadAzureVoices() async {
    try {
      final envConfig = EnvironmentConfig();
      await envConfig.loadConfig();

      final region = envConfig.azureSpeechRegion;
      final key = envConfig.azureSpeechKey;

      if (region == null || key == null) {
        debugPrint('Configuration Azure Speech manquante pour les voix');
        return;
      }

      // Appel Azure Speech API pour lister les voix
      final url = Uri.parse(
        'https://$region.tts.speech.microsoft.com/cognitiveservices/voices/list',
      );

      final response = await http.get(
        url,
        headers: {'Ocp-Apim-Subscription-Key': key},
      );

      if (response.statusCode == 200) {
        final voicesData = jsonDecode(response.body) as List;

        // Filtrer les voix françaises
        final frenchVoices = voicesData
            .where((voice) => voice['Locale'].toString().startsWith('fr'))
            .map(
              (voice) => VoiceOption(
                id: voice['ShortName'],
                name: voice['DisplayName'],
                language: voice['Locale'],
                gender: voice['Gender'].toString().toLowerCase(),
                description: 'Voix Azure ${voice['LocalName']}',
                style: _getVoiceStyle(voice['VoiceType']),
              ),
            )
            .toList();

        _availableVoices.addAll(frenchVoices);
      }
    } catch (e) {
      debugPrint('Erreur chargement voix Azure: $e');
    }
  }

  String _getVoiceStyle(String voiceType) {
    switch (voiceType.toLowerCase()) {
      case 'neural':
        return 'natural';
      case 'standard':
        return 'classic';
      default:
        return 'standard';
    }
  }

  /// Étape 9: Setup voix par défaut si aucune n'est disponible
  void _setupDefaultVoices() {
    _availableVoices = [
      const VoiceOption(
        id: 'fr-FR-DeniseNeural',
        name: 'Denise',
        language: 'fr-FR',
        gender: 'female',
        description: 'Voix féminine naturelle française',
        style: 'natural',
      ),
      const VoiceOption(
        id: 'fr-FR-HenriNeural',
        name: 'Henri',
        language: 'fr-FR',
        gender: 'male',
        description: 'Voix masculine naturelle française',
        style: 'natural',
      ),
      const VoiceOption(
        id: 'fr-FR-BrigitteNeural',
        name: 'Brigitte',
        language: 'fr-FR',
        gender: 'female',
        description: 'Voix féminine expressive française',
        style: 'expressive',
      ),
    ];
  }

  /// Étape 9: Charger voix sélectionnée depuis les préférences
  Future<void> _loadSelectedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceId = prefs.getString('selected_voice_id');

      if (voiceId != null) {
        _selectedVoice = _availableVoices.firstWhere(
          (voice) => voice.id == voiceId,
          orElse: () => _availableVoices.first,
        );
      }
    } catch (e) {
      debugPrint('Erreur chargement voix sélectionnée: $e');
    }
  }

  /// Étape 9: Flow voice-only - Énumérer voix disponibles
  String generateVoiceListResponse() {
    if (_availableVoices.isEmpty) {
      return 'Aucune voix disponible pour le moment.';
    }

    final voiceNames = _availableVoices
        .take(5)
        .map((voice) {
          final genderText = voice.gender == 'female'
              ? 'féminine'
              : 'masculine';
          return '${voice.name} (voix $genderText)';
        })
        .join(', ');

    return 'Voix disponibles : $voiceNames. Dites "choisis" suivi du nom pour l\'activer.';
  }

  /// Étape 9: Sélectionner voix par nom vocal
  Future<String> selectVoiceByName(String voiceName) async {
    try {
      final normalizedName = voiceName.toLowerCase().trim();

      final selectedVoice = _availableVoices.firstWhere(
        (voice) => voice.name.toLowerCase() == normalizedName,
        orElse: () => throw Exception('Voix non trouvée'),
      );

      await _setSelectedVoice(selectedVoice);

      return 'Voix ${selectedVoice.name} activée. Comment ça sonne ?';
    } catch (e) {
      return 'Désolé, je ne trouve pas la voix "$voiceName". Dites "quelles voix" pour entendre la liste.';
    }
  }

  /// Étape 9: Activer voix et sauvegarder
  Future<void> _setSelectedVoice(VoiceOption voice) async {
    try {
      _selectedVoice = voice;

      // Sauvegarder dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_voice_id', voice.id);

      // Sauvegarder dans Supabase si utilisateur connecté
      try {
        await _supabase.from('user_voice_preferences').upsert({
          'user_id': 'current_user', // TODO: récupérer vrai user ID
          'voice_id': voice.id,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Erreur sauvegarde Supabase: $e');
      }

      debugPrint('Voix sélectionnée: ${voice.name}');
    } catch (e) {
      debugPrint('Erreur sélection voix: $e');
      throw Exception('Impossible de sélectionner la voix');
    }
  }

  /// Étape 9: Aperçu vocal automatique
  Future<String> generateVoicePreview(VoiceOption voice) async {
    final greetings = [
      'Salut, je suis ${voice.name}.',
      'Bonjour, c\'est ${voice.name} qui vous parle.',
      'Hello, ${voice.name} à votre service.',
    ];

    return greetings[DateTime.now().millisecond % greetings.length];
  }

  /// Étape 9: Ajouter nouvelle voix (opération admin)
  Future<bool> addNewVoice(VoiceOption newVoice) async {
    try {
      await _supabase.from('available_voices').insert({
        'id': newVoice.id,
        'name': newVoice.name,
        'language': newVoice.language,
        'gender': newVoice.gender,
        'description': newVoice.description,
        'style': newVoice.style,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      _availableVoices.add(newVoice);
      debugPrint('Nouvelle voix ajoutée: ${newVoice.name}');
      return true;
    } catch (e) {
      debugPrint('Erreur ajout voix: $e');
      return false;
    }
  }

  // Getters
  List<VoiceOption> get availableVoices => List.unmodifiable(_availableVoices);
  VoiceOption? get selectedVoice => _selectedVoice;
  bool get isInitialized => _isInitialized;

  /// Forcer rafraîchissement des voix
  Future<void> refreshVoices() async {
    _lastVoiceRefresh = null;
    await _loadAvailableVoices();
  }

  void dispose() {
    _availableVoices.clear();
    _selectedVoice = null;
    _azureVoicesCache.clear();
    _isInitialized = false;
  }
}
