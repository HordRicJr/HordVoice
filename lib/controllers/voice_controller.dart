import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/unified_hordvoice_service.dart';
import '../models/user_profile.dart';
import '../models/ai_models.dart';

// Provider pour le service unifié
final unifiedServiceProvider = Provider<UnifiedHordVoiceService>((ref) {
  return UnifiedHordVoiceService();
});

// État de reconnaissance vocale
enum VoiceState { idle, listening, processing, speaking, error }

// Modèle d'état pour le contrôleur vocal
class VoiceControllerState {
  final VoiceState state;
  final String? currentText;
  final String? lastResponse;
  final bool isInitialized;
  final String? errorMessage;
  final double? audioLevel;

  const VoiceControllerState({
    this.state = VoiceState.idle,
    this.currentText,
    this.lastResponse,
    this.isInitialized = false,
    this.errorMessage,
    this.audioLevel,
  });

  VoiceControllerState copyWith({
    VoiceState? state,
    String? currentText,
    String? lastResponse,
    bool? isInitialized,
    String? errorMessage,
    double? audioLevel,
  }) {
    return VoiceControllerState(
      state: state ?? this.state,
      currentText: currentText ?? this.currentText,
      lastResponse: lastResponse ?? this.lastResponse,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}

// Contrôleur vocal principal
class VoiceController extends StateNotifier<VoiceControllerState> {
  final UnifiedHordVoiceService _unifiedService;

  VoiceController(this._unifiedService) : super(const VoiceControllerState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _unifiedService.initialize();
      state = state.copyWith(isInitialized: true, state: VoiceState.idle);
      debugPrint('VoiceController initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du VoiceController: $e');
      state = state.copyWith(
        state: VoiceState.error,
        errorMessage: 'Erreur d\'initialisation: $e',
      );
    }
  }

  Future<void> startListening() async {
    if (!state.isInitialized) {
      debugPrint('Service non initialisé');
      return;
    }

    if (state.state == VoiceState.listening) {
      debugPrint('Déjà en écoute');
      return;
    }

    try {
      state = state.copyWith(state: VoiceState.listening, errorMessage: null);
      await _unifiedService.startVoiceRecognition();
      debugPrint('Écoute vocale démarrée');
    } catch (e) {
      debugPrint('Erreur lors du démarrage de l\'écoute: $e');
      state = state.copyWith(
        state: VoiceState.error,
        errorMessage: 'Erreur d\'écoute: $e',
      );
    }
  }

  Future<void> stopListening() async {
    if (state.state != VoiceState.listening) {
      return;
    }

    try {
      await _unifiedService.stopVoiceRecognition();
      state = state.copyWith(state: VoiceState.idle);
      debugPrint('Écoute vocale arrêtée');
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt de l\'écoute: $e');
      state = state.copyWith(
        state: VoiceState.error,
        errorMessage: 'Erreur d\'arrêt: $e',
      );
    }
  }

  Future<void> processVoiceCommand(String command) async {
    if (!state.isInitialized) {
      debugPrint('Service non initialisé');
      return;
    }

    try {
      state = state.copyWith(
        state: VoiceState.processing,
        currentText: command,
        errorMessage: null,
      );

      final response = await _unifiedService.processVoiceCommand(command);

      state = state.copyWith(
        state: VoiceState.speaking,
        lastResponse: response,
      );

      // Retour à l'état idle après la réponse
      await Future.delayed(const Duration(seconds: 2));
      if (state.state == VoiceState.speaking) {
        state = state.copyWith(state: VoiceState.idle);
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement de la commande: $e');
      state = state.copyWith(
        state: VoiceState.error,
        errorMessage: 'Erreur de traitement: $e',
      );
    }
  }

  Future<void> speakText(String text) async {
    try {
      state = state.copyWith(state: VoiceState.speaking);
      await _unifiedService.speakText(text);
      state = state.copyWith(state: VoiceState.idle);
    } catch (e) {
      debugPrint('Erreur lors de la synthèse vocale: $e');
      state = state.copyWith(
        state: VoiceState.error,
        errorMessage: 'Erreur de synthèse: $e',
      );
    }
  }

  void updateAudioLevel(double level) {
    state = state.copyWith(audioLevel: level);
  }

  void clearError() {
    state = state.copyWith(state: VoiceState.idle, errorMessage: null);
  }

  bool get isListening => state.state == VoiceState.listening;
  bool get isProcessing => state.state == VoiceState.processing;
  bool get isSpeaking => state.state == VoiceState.speaking;
  bool get hasError => state.state == VoiceState.error;
  bool get isActive => isListening || isProcessing || isSpeaking;

  @override
  void dispose() {
    _unifiedService.dispose();
    super.dispose();
  }
}

// Provider pour le contrôleur vocal
final voiceControllerProvider =
    StateNotifierProvider<VoiceController, VoiceControllerState>((ref) {
      final unifiedService = ref.read(unifiedServiceProvider);
      return VoiceController(unifiedService);
    });

// Provider pour l'état de personnalité de l'IA
final aiPersonalityProvider = StateProvider<AIPersonalityType>((ref) {
  return AIPersonalityType.mere_africaine;
});

// Provider pour le profil utilisateur
final userProfileProvider = StateProvider<UserProfile?>((ref) {
  return null;
});

// Provider pour les notifications système
final systemNotificationsProvider = StateProvider<List<String>>((ref) {
  return [];
});

// Provider pour l'état de santé
final healthDataProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return null;
});

// Provider pour les événements du calendrier
final calendarEventsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

// Provider pour les données météo
final weatherDataProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return null;
});

// Provider pour l'état de la batterie
final batteryStatusProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return null;
});

// Provider pour les recommandations IA
final aiRecommendationsProvider = StateProvider<List<String>>((ref) {
  return [];
});
