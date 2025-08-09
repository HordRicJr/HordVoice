# PROBLÈME CRITIQUE - iOS NON CONFIGURÉ

## ❌ DOSSIER IOS MANQUANT
Le projet HordVoice ne contient pas de dossier `ios/` qui est OBLIGATOIRE pour:
1. Déploiement App Store iOS
2. Configuration permissions iOS
3. Fonctionnement sur iPhone/iPad

## ACTIONS REQUISES IMMÉDIATES

### 1. CRÉER CONFIGURATION iOS
```bash
# Recréer support iOS
flutter create --platforms=ios .
```

### 2. CONFIGURER Info.plist OBLIGATOIRE
Créer `ios/Runner/Info.plist` avec:

```xml
<dict>
    <!-- PERMISSIONS MICROPHONE & VOIX (OBLIGATOIRES) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>HordVoice utilise le microphone pour écouter vos commandes vocales et vous assister dans vos tâches quotidiennes.</string>
    
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>HordVoice utilise la reconnaissance vocale pour comprendre et traiter vos demandes parlées.</string>
    
    <!-- PERMISSIONS LOCALISATION -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>HordVoice utilise votre position pour vous fournir des informations météo locales et des services de navigation personnalisés.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>HordVoice peut utiliser votre position en arrière-plan pour des fonctions avancées de navigation et d'assistance contextuelle.</string>
    
    <!-- PERMISSIONS CAMÉRA (si analyse émotionnelle) -->
    <key>NSCameraUsageDescription</key>
    <string>HordVoice peut utiliser la caméra pour analyser vos expressions et adapter ses réponses à votre état émotionnel.</string>
    
    <!-- PERMISSIONS CONTACTS -->
    <key>NSContactsUsageDescription</key>
    <string>HordVoice accède à vos contacts pour vous permettre d'appeler ou d'envoyer des messages à vos proches par commande vocale.</string>
    
    <!-- PERMISSIONS CALENDRIER -->
    <key>NSCalendarsUsageDescription</key>
    <string>HordVoice consulte votre calendrier pour vous rappeler vos rendez-vous et vous aider à organiser votre planning.</string>
    
    <!-- PERMISSIONS PHOTOS (si sauvegarde) -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>HordVoice peut sauvegarder des captures d'écran ou des images de ses réponses dans votre photothèque.</string>
    
    <!-- BACKGROUND MODES -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>        <!-- Pour wake-word et TTS en arrière-plan -->
        <string>background-processing</string>  <!-- Pour traitement vocal -->
        <string>location</string>     <!-- Si navigation arrière-plan -->
    </array>
    
    <!-- CONFIGURATION APP -->
    <key>CFBundleDisplayName</key>
    <string>HordVoice</string>
    
    <key>CFBundleIdentifier</key>
    <string>com.hordvoice.app</string>
    
    <key>LSRequiresIPhoneOS</key>
    <true/>
    
    <!-- ORIENTATIONS SUPPORTÉES -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
```

### 3. CONFIGURATIONS SPÉCIFIQUES iOS

#### A. Capacities (si nécessaire)
Dans Xcode, activer:
- ✅ Background Modes → Audio, AirPlay, Picture in Picture
- ✅ Background Modes → Background processing  
- ✅ Background Modes → Location updates (si requis)

#### B. App Transport Security
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>your-api-domain.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## IMPACT CRITIQUE
Sans configuration iOS:
❌ Impossible de publier sur App Store
❌ Pas de test sur iPhone/iPad
❌ Pas de permissions microphone iOS
❌ Wake-word ne fonctionne pas sur iOS
❌ Services background non autorisés iOS

## PRIORITÉ MAXIMALE
Cette configuration iOS est BLOQUANTE pour le déploiement cross-platform.
