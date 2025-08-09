# Dépendances supplémentaires à ajouter au pubspec.yaml pour l'onboarding vocal

## Nouvelles dépendances nécessaires :

# Reconnaissance vocale (alternative ou complément à Azure)
speech_to_text: ^7.0.0

# Gestion avancée des permissions avec explications
permission_handler_platform_interface: ^4.2.3

# Animations et transitions fluides pour l'onboarding
animations: ^2.0.11
lottie: ^3.1.2

# Stockage sécurisé pour le profil vocal
flutter_secure_storage: ^9.2.2

# Audio avancé pour la calibration
just_audio: ^0.9.40
audio_session: ^0.1.21

# Détection wake word (optionnel)
picovoice_flutter: ^3.0.1

## À ajouter dans pubspec.yaml après les dépendances existantes :

```yaml
  # ONBOARDING ET CALIBRATION VOCALE
  speech_to_text: ^7.0.0
  flutter_secure_storage: ^9.2.2
  animations: ^2.0.11
  lottie: ^3.1.2
  just_audio: ^0.9.40
  audio_session: ^0.1.21
```

## Notes d'implémentation :

1. **speech_to_text** : Service principal de reconnaissance vocale pour la calibration
2. **flutter_secure_storage** : Stockage sécurisé du profil vocal utilisateur
3. **animations** : Transitions fluides entre étapes d'onboarding
4. **lottie** : Animations d'avatar et feedbacks visuels
5. **just_audio** : Gestion audio avancée pour les feedbacks sonores
6. **audio_session** : Configuration de session audio optimisée

## Configuration Android (android/app/src/main/AndroidManifest.xml) :

```xml
<!-- Permissions onboarding -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- Wake word detection (optionnel) -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## Prochaines étapes d'implémentation :

1. ✅ Service d'onboarding vocal créé (VoiceOnboardingScreen)
2. ✅ Service de gestion des permissions (PermissionManagerService)  
3. ✅ Service de calibration vocale (VoiceCalibrationService)
4. ✅ Pipeline audio intégré (AudioPipelineService)
5. ✅ Main.dart mis à jour avec routing onboarding
6. 🔄 À faire : Ajouter les dépendances au pubspec.yaml
7. 🔄 À faire : Tester le flow complet onboarding → calibration → accueil
8. 🔄 À faire : Intégrer la vraie reconnaissance vocale (remplacer simulations)
9. 🔄 À faire : Connecter avec Azure Speech Services
10. 🔄 À faire : Implémenter la détection wake word

## Architecture finale :

```
lib/
├── main_new.dart (remplacera main.dart)
├── services/
│   ├── permission_manager_service.dart ✅
│   ├── voice_calibration_service.dart ✅
│   ├── audio_pipeline_service.dart ✅
│   └── ...autres services existants
├── views/
│   ├── voice_onboarding_screen.dart ✅
│   ├── home_view_new.dart ✅ (interface voice-first)
│   └── ...autres vues
├── widgets/
│   ├── animated_avatar.dart ✅
│   ├── audio_waveform.dart ✅
│   ├── voice_selector.dart ✅
│   └── ...autres widgets
└── theme/
    ├── design_tokens.dart ✅
    └── app_theme.dart ✅
```

L'application HordVoice v2.0 est maintenant prête pour l'intégration complète de l'onboarding vocal et de la calibration utilisateur !
