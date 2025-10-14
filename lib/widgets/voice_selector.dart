import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/voice_models.dart';
import '../theme/design_tokens.dart';

/// Provider pour les paramÃ¨tres vocaux
final voiceSettingsProvider =
    StateNotifierProvider<VoiceSettingsNotifier, VoiceSettings>((ref) {
      return VoiceSettingsNotifier();
    });

/// Notifier pour gÃ©rer les paramÃ¨tres vocaux
class VoiceSettingsNotifier extends StateNotifier<VoiceSettings> {
  VoiceSettingsNotifier()
    : super(VoiceSettings(selectedVoiceId: VoiceLibrary.getDefaultVoice().id));

  void updateVoice(String voiceId) {
    state = state.copyWith(selectedVoiceId: voiceId);
  }

  void updateSpeechSpeed(double speed) {
    state = state.copyWith(speechSpeed: speed.clamp(0.5, 2.0));
  }

  void updateVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void updatePitch(double pitch) {
    state = state.copyWith(pitch: pitch.clamp(0.5, 2.0));
  }

  void toggleEmotionalTone() {
    state = state.copyWith(useEmotionalTone: !state.useEmotionalTone);
  }

  void toggleAfricanAccent() {
    state = state.copyWith(useAfricanAccent: !state.useAfricanAccent);
  }

  void toggleProverbs() {
    state = state.copyWith(useProverbs: !state.useProverbs);
  }

  void toggleAutoTranslate() {
    state = state.copyWith(autoTranslate: !state.autoTranslate);
  }
}

/// Widget de sÃ©lection de voix
class VoiceSelector extends ConsumerWidget {
  final bool showPreview;
  final Function(VoiceOption)? onVoiceSelected;

  const VoiceSelector({
    super.key,
    this.showPreview = true,
    this.onVoiceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceSettings = ref.watch(voiceSettingsProvider);
    final voiceSettingsNotifier = ref.read(voiceSettingsProvider.notifier);
    final availableVoices = VoiceLibrary.getAllVoices();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: const [DesignTokens.shadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÃ©lectionner une voix',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: DesignTokens.spaceM),

          // Liste des voix disponibles
          ...availableVoices.map(
            (voice) => _buildVoiceOption(
              context,
              voice,
              voiceSettings.selectedVoiceId == voice.id,
              () {
                voiceSettingsNotifier.updateVoice(voice.id);
                onVoiceSelected?.call(voice);
              },
            ),
          ),

          const SizedBox(height: DesignTokens.spaceL),

          // ParamÃ¨tres vocaux
          _buildVoiceControls(context, ref),
        ],
      ),
    );
  }

  Widget _buildVoiceOption(
    BuildContext context,
    VoiceOption voice,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Material(
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        color: isSelected
            ? DesignTokens.primaryBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            child: Row(
              children: [
                // Indicateur de sÃ©lection
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? DesignTokens.primaryBlue
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected
                        ? DesignTokens.primaryBlue
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: DesignTokens.spaceM),

                // Informations de la voix
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            voice.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? DesignTokens.primaryBlue
                                      : null,
                                ),
                          ),
                          const SizedBox(width: DesignTokens.spaceS),
                          if (voice.isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.accentOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${voice.style} â€¢ ${voice.gender} â€¢ ${voice.language.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voice.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Bouton d'aperÃ§u
                if (showPreview)
                  IconButton(
                    onPressed: () => _playVoicePreview(voice),
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: DesignTokens.primaryBlue.withOpacity(
                        0.1,
                      ),
                      foregroundColor: DesignTokens.primaryBlue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceControls(BuildContext context, WidgetRef ref) {
    final voiceSettings = ref.watch(voiceSettingsProvider);
    final voiceSettingsNotifier = ref.read(voiceSettingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ParamÃ¨tres vocaux',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: DesignTokens.spaceM),

        // Vitesse de parole
        _buildSliderControl(
          context,
          label: 'Vitesse de parole',
          value: voiceSettings.speechSpeed,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: voiceSettingsNotifier.updateSpeechSpeed,
          formatValue: (value) => '${(value * 100).round()}%',
        ),

        // Volume
        _buildSliderControl(
          context,
          label: 'Volume',
          value: voiceSettings.volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: voiceSettingsNotifier.updateVolume,
          formatValue: (value) => '${(value * 100).round()}%',
        ),

        // Hauteur de voix
        _buildSliderControl(
          context,
          label: 'Hauteur de voix',
          value: voiceSettings.pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: voiceSettingsNotifier.updatePitch,
          formatValue: (value) =>
              value == 1.0 ? 'Normal' : '${(value * 100).round()}%',
        ),

        const SizedBox(height: DesignTokens.spaceM),

        // Options avancÃ©es
        _buildSwitchOption(
          context,
          title: 'Ton Ã©motionnel',
          subtitle: 'Adapter la voix aux Ã©motions dÃ©tectÃ©es',
          value: voiceSettings.useEmotionalTone,
          onChanged: (_) => voiceSettingsNotifier.toggleEmotionalTone(),
        ),

        _buildSwitchOption(
          context,
          title: 'Accent africain',
          subtitle: 'Utiliser un accent africain authentique',
          value: voiceSettings.useAfricanAccent,
          onChanged: (_) => voiceSettingsNotifier.toggleAfricanAccent(),
        ),

        _buildSwitchOption(
          context,
          title: 'Proverbes et expressions',
          subtitle: 'Inclure des proverbes africains dans les rÃ©ponses',
          value: voiceSettings.useProverbs,
          onChanged: (_) => voiceSettingsNotifier.toggleProverbs(),
        ),

        _buildSwitchOption(
          context,
          title: 'Traduction automatique',
          subtitle: 'Traduire automatiquement dans d\'autres langues',
          value: voiceSettings.autoTranslate,
          onChanged: (_) => voiceSettingsNotifier.toggleAutoTranslate(),
        ),
      ],
    );
  }

  Widget _buildSliderControl(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required String Function(double) formatValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                formatValue(value),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceS),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: DesignTokens.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  void _playVoicePreview(VoiceOption voice) async {
    debugPrint('Lecture aperÃ§u pour ${voice.name}');
    
    try {
      final tts = FlutterTts();
      
      // Configuration de la voix selon les options
      await tts.setLanguage(voice.language);
      
      // DÃ©finir le texte d'aperÃ§u selon la langue
      String previewText;
      switch (voice.language.split('_')[0]) {
        case 'fr':
          previewText = 'Bonjour, je suis ${voice.name}';
          break;
        case 'es':
          previewText = 'Hola, soy ${voice.name}';
          break;
        case 'de':
          previewText = 'Hallo, ich bin ${voice.name}';
          break;
        case 'ar':
          previewText = 'Ù…Ø±Ø­Ø¨Ø§ØŒ Ø£Ù†Ø§ ${voice.name}';
          break;
        default:
          previewText = 'Hello, I am ${voice.name}';
      }
      
      // Jouer l'aperÃ§u vocal
      await tts.speak(previewText);
      
    } catch (e) {
      debugPrint('Erreur lecture aperÃ§u vocal: $e');
    }
  }
}

/// Widget compact pour afficher la voix sÃ©lectionnÃ©e
class CurrentVoiceDisplay extends ConsumerWidget {
  final VoidCallback? onTap;

  const CurrentVoiceDisplay({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceSettings = ref.watch(voiceSettingsProvider);
    final currentVoice = VoiceLibrary.getVoiceById(
      voiceSettings.selectedVoiceId,
    );

    if (currentVoice == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.record_voice_over,
              color: DesignTokens.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentVoice.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${currentVoice.style} â€¢ ${currentVoice.gender}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

