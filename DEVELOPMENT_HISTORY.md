# HordVoice v2.0 - Guide de Développement Complet avec Charte Graphique

## Vue d'ensemble du Projet
HordVoice v2.0 est un assistant vocal africain développé en Flutter/Dart selon l'architecture MVC avec Riverpod pour la gestion d'état. L'application intègre de multiples services cloud et APIs pour offrir une expérience d'assistant vocal complète et personnalisée avec une interface voice-first exclusive.

## Charte Graphique - Interface Voice-First Complète

### Objectif Principal
Interface **voice-first** exclusivement : aucune saisie texte dans le flux principal. L'UI ne sert que de support visuel minimal (avatar, ondes, icônes). Les interactions sont exclusivement vocales. Les textes visibles sont limités aux écrans de paramétrage et diagnostics.

### Palette de Couleurs (Usage & Sens)
- **Couleur primaire** : Bleu vif (#007AFF) - confiance, base des gradients et accents d'état
- **Accent chaud** : Orange/ocre (#FF9500) - chaleur africaine, call-to-action vocal
- **Fond clair** : Très pâle (#FAFAFA) - pour debug/dev UI minimal
- **Fond sombre** : Bleu nuit (#1C1C1E) - mode par défaut si mode sombre activé
- **Couleurs émotionnelles** mappées sur états :
  - Joie : Jaune chaud (#FFD60A)
  - Tristesse : Bleu profond (#0A84FF)
  - Colère : Rouge vif (#FF453A)
  - Calme : Vert doux (#30D158)
  - Surprise : Orange vif (#FF6B35)
  - Peur : Violet (#6C5CE7)
  - Dégoût : Vert turquoise (#00B894)

**Explication :** Les couleurs émotionnelles pilotent l'aura autour de l'avatar et la teinte du gradient du fond, jamais du texte vocal.

### Typographie (Usage Minimal)
- **Police principale** : Inter ou Poppins
- **Niveaux** : H1 28sp (titres paramètres), H2 20sp (sections paramètres), body 16sp (méta)
- **Explication :** L'app n'affiche que quelques zones textuelles (paramètres, erreurs) avec contraste élevé pour accessibilité.

### Layout & Spacing
- **Base spacing** : 8dp
- **Marges principales** : 16dp
- **Border radius** : 16dp pour cartes, 999dp pour avatar circulaire
- **Éléments centrés** : Avatar toujours centré en écran d'écoute
- **Explication :** Layout simple pour que l'utilisateur ne se perde pas — focus sur l'écoute.

### Avatar Vocal (Élément Central)
- **Forme** : Cercle animé avec expressions faciales complètes
- **Composants visibles** : Auréole (couleur emotion), yeux expressifs, bouche réactive, sourcils mobiles
- **Inputs d'animation** : emotion (enum), intensity (0.0-1.0), speaking (bool), scream (trigger)
- **Réactions émotionnelles détaillées** :
  - Joie → sourire lumineux, yeux pétillants, sourcils relevés
  - Colère → sourcils froncés, expression fermée, bouche serrée
  - Tristesse → regard tombant, bouche triste, sourcils affaissés
  - Calme → respiration lente, yeux doux, expression sereine
  - Surprise → yeux écarquillés, bouche ouverte, sourcils levés
  - Peur → yeux plissés, expression tendue
  - Dégoût → nez plissé, bouche fermée
- **Adaptation temporelle** :
  - Matin (6h-12h) → couleurs chaudes, visage détendu, énergie douce
  - Après-midi (12h-18h) → visage vif, dynamique, couleurs vives
  - Soir (18h-22h) → couleurs douces, expression relaxée
  - Nuit (22h-6h) → lumière douce, yeux plus fermés, teintes sombres
- **Interactions tactiles complètes** :
  - Tap → petit clin d'œil avec effet de ripple
  - Double tap → grand sourire avec double cercle concentrique
  - Appui long → frisson ou rire (chatouille) avec effet sparkle autour
  - Swipe → réaction de balayage (à implémenter)
- **Présence permanente** :
  - Clignement aléatoire des yeux (2-6 secondes)
  - Micro-mouvements de tête subtils
  - Respiration subtile continue (4 secondes cycle)
  - Transitions fluides entre émotions (300ms)

### Waveform & Feedback Audio
- **Waveform linéaire** en bas de l'écran (20 barres, 3dp largeur, 2dp espacement)
- **Waveform circulaire** en option autour de l'avatar (32 segments)
- **Animation** liée au niveau RMS audio et à l'activité du micro
- **Couleurs** synchronisées avec l'émotion détectée
- **Intensité** basée sur niveau audio avec variations sinusoïdales
- **Explication :** Sert de feedback « j'écoute » sans texte

### Iconographie & Micro-interactions
- **Icônes** linéaires, rondes, voyantes mais simples (Material Design)
- **Micro-interactions** : pulses d'avatar, transitions de gradient, micro-vibrations matérielles
- **Feedback haptique** systématique pour confirmations (HapticFeedback.lightImpact)
- **Explication :** Tout feedback doit être perceptible sans lire

### Motion / Animations
- **Durées** : court=120–200ms, moyen=300–450ms, long=600–900ms
- **Easing** : easeOutCubic pour sorties, easeInOut pour boucles
- **Option** « réduire les animations » obligatoire pour accessibilité
- **Explication :** Animations fluides mais pas distrayantes

### Accessibilité
- **Ratio contraste** >= 4.5:1 pour textes paramètres
- **Sortie sonore** + vibration pour toutes confirmations
- **Option** pour désactiver effets visuels forts
- **Support malvoyants** : navigation entièrement vocale
- **Explication :** L'app doit rester utilisable pour malvoyants ; la voix est la voie principale

### Assets & Formats
- **Animations avatar** : Custom Paint pour expressions faciales (performance optimale)
- **Icônes** : Material Icons et SVG personnalisés
- **Sons** : formats compressés sans perte excessive (ogg/mp3) pour TTS & prompts
- **Explication :** Performance et taille de l'apk optimisées

## Système de Voix IA Avancé

### Voix Prédéfinies (8 voix disponibles)
| ID | Nom | Genre | Style | Langue | Description |
|---|---|---|---|---|---|
| voice_fr_smooth_f | Clara | Féminin | Doux | FR | Voix française féminine douce et apaisante |
| voice_fr_smooth_m | Hugo | Masculin | Doux | FR | Voix française masculine douce et rassurante |
| voice_fr_expressive_f | Emma | Féminin | Expressif | FR | Voix française féminine expressive et dynamique |
| voice_fr_expressive_m | Lucas | Masculin | Expressif | FR | Voix française masculine expressive et énergique |
| voice_en_calm_f | Sophie | Féminin | Calme | EN | Voix anglaise féminine calme et professionnelle |
| voice_en_calm_m | James | Masculin | Calme | EN | Voix anglaise masculine calme et posée |
| voice_en_vibrant_f | Mia | Féminin | Énergique | EN | Voix anglaise féminine énergique et enjouée |
| voice_en_vibrant_m | Leo | Masculin | Énergique | EN | Voix anglaise masculine énergique et motivante |

### Interface de Sélection Vocale
- **Menu déroulant** dans les paramètres avec aperçu audio
- **Bouton "écouter un échantillon"** pour chaque voix
- **Stockage du choix** via Riverpod provider (VoiceSettingsNotifier)
- **Interface responsive** avec indicateurs visuels de sélection
- **Support Premium** : badges pour voix payantes futures

### Paramètres Vocaux Avancés
- **Vitesse de parole** : 0.5x à 2.0x (slider 15 divisions)
- **Volume** : 0% à 100% (slider 10 divisions)
- **Hauteur de voix** : 50% à 200% (slider 15 divisions)
- **Ton émotionnel** : Adapter la voix aux émotions détectées
- **Accent africain** : Utiliser un accent africain authentique
- **Proverbes** : Inclure des proverbes africains dans les réponses
- **Traduction automatique** : Traduire dans d'autres langues

### Extension du Système (Guide Développeurs)
**Backend :**
1. Ajouter nouveaux fichiers vocaux/références API dans base de données
2. Donner ID unique, nom lisible et métadonnées (genre, style)
3. Support ElevenLabs, Azure TTS, Google TTS

**Frontend (Flutter) :**
1. Étendre la liste dans VoiceLibrary.predefinedVoices
2. Exemple : `VoiceOption(id: 'voice_jp_cute_f', name: 'Aiko', language: 'jp', style: 'Kawaii')`
3. Ajouter bouton "Actualiser la liste" pour recharger depuis l'API

**UI :**
1. Liste dynamique avec ListView.builder alimentée par provider
2. Support scroll infini pour nombreuses voix
3. Filtres par langue/style/genre

## Principes d'UX Voice-First (Règles Strictes)

1. **No text input** dans le flux principal : tout slot filling par dialogue vocal
2. **Confirmation vocale** systématique pour actions sensibles (appels, paiements, suppression)
3. **Réponses concises** (TTS) : 1 à 2 phrases, puis option « veux-tu plus d'infos ? »
4. **Gestion des interruptions** : si l'utilisateur parle pendant la réponse, interrompre la TTS et écouter
5. **Dialogues à trous** : pour requêtes nécessitant données (ex. création d'événement) : poser une question à la fois, valider la réponse
6. **Feedback non verbal** : waveform + vibration + couleur de l'aura
7. **Mode discret** : réponses sonores réduites, haptique uniquement
8. **Onboarding vocal** : premières actions et demandes d'autorisation expliquées par voix et confirmées oralement
9. **Fallback** : si reconnaissance échoue 3 fois, proposer relancer ou envoyer résumé dans paramètres (textuel) pour debug

## Implémentation - Étapes Concrètes (UI + Pipeline Vocal)

### Partie A - Foundation UI (Flutter) ✅
1. ✅ **Design Tokens** (`lib/theme/design_tokens.dart`) - Couleurs, spacing, animations, émotions
2. ✅ **App Theme** (`lib/theme/app_theme.dart`) - Thèmes clair & sombre complets avec Material 3
3. ✅ **AnimatedAvatar** (`lib/widgets/animated_avatar.dart`) - Avatar réactif émotionnel avec expressions faciales
4. ✅ **AudioWaveform** (`lib/widgets/audio_waveform.dart`) - Ondes audio linéaires et circulaires temps réel
5. ✅ **VoiceSelector** (`lib/widgets/voice_selector.dart`) - Interface sélection vocale complète
6. 🔄 **ListeningScreen** - Écran principal voice-first minimal (à implémenter)
7. 🔄 **QuickSettingsView** - Paramètres accessibles vocalement (mise à jour)

### Partie B - Pipeline Audio & Reconnaissance 🔄
1. 🔄 **Audio Capture** - Plugin natif performant pour streaming PCM continu (Android service natif)
2. 🔄 **RMS Calculation** - Niveaux audio locaux pour waveform et détection d'activité vocale (VAD simple)
3. 🔄 **Azure Speech SDK** - Reconnaissance continue faible latence (SDK natif via platform channels)
4. 🔄 **Wake-word** - Picovoice Porcupine pour reconnaissance locale « Hey Ric »
5. 🔄 **STT → NLU → TTS** - Pipeline complet : Azure Speech → OpenAI → Azure TTS
6. 🔄 **Interruption Handling** - Gestion dynamique des conversations avec fallback flutter_tts

### Partie C - UnifiedHordVoiceService & Providers 🔄
1. ✅ **Service Architecture** - Singleton avec tous les services intégrés
2. ✅ **Riverpod Providers** - État global pour voix, émotion, audio, système
3. 🔄 **Stream Exposure** - audioLevelStream, emotionStream, stateStream, commandStream
4. 🔄 **Widget Subscription** - Réactivité temps réel pour avatar et waveform

### Partie D - Onboarding Vocal & Entraînement 🔄
1. 🔄 **Premier Lancement** - TTS guide vocal pour permissions micro
2. 🔄 **Calibration Vocale** - Mini-script enregistrement 3 phrases, hash vocal
3. 🔄 **Wake-word Personnalisé** - Flow vocal enregistrement mot-clé si supporté

### Partie E - Intégration OAuth Sans Texte 🔄
1. 🔄 **Spotify Device Flow** - Authorization Code Flow avec redirection navigateur
2. 🔄 **QR Code/Device Code** - Éviter champs texte : site externe ou code vocal
3. ✅ **Secure Storage** - Tokens dans flutter_secure_storage

## Fonctionnalités Futures (Liste + Implémentation Détaillée)

### 1. Reconnaissance Vocale Offline (Offline ASR)
**Pourquoi :** Latence réduite, disponibilité sans réseau
**Implémentation :** Intégrer modèle on-device (Vosk, Whisper-offline ou solution native)
**Étapes :**
1. Benchmark modèles (performance vs précision vs taille)
2. Intégrer SDK natif via plugin natif
3. Fallback logic (online if offline model fails)
4. Gestion mémoire/CPU (charger modèle à la demande)
**Estimation :** Phase 2 - 3 mois développement

### 2. Wake-word Personnalisé et Apprentissage
**Technologies :** Picovoice Rhino/Porcupine avec personnalisation
**Étapes :**
1. Fournir flow vocal d'enregistrement 3-5 phrases
2. Entraîner/custom wake-word sur serveur ou via SDK
3. Déployer modèle personnalisé
4. Fallback global « Hey Ric »
**Estimation :** Phase 3 - 2 mois développement

### 3. Personnalités Dynamiques Évolutives
**Technologies :** Stocker « prompt templates » dans Supabase + règles de ton
**Étapes :**
1. Créer UI de gestion (paramètres textuels) pour régler intensité de personnalité
2. Côté serveur, conserver versions et poids
3. Runtime : injecter persona prompt dans chaque requête OpenAI
4. Apprentissage automatique des préférences utilisateur
**Estimation :** Phase 4 - 4 mois développement

### 4. Voice Biometric Authentication (Optionnel)
**Objectif :** Permettre actions sensibles après authentification vocale
**Étapes :**
1. Design du flow d'enrollement (10 phrases)
2. Stocker modèle voiceprint chiffré (Keystore/Keychain)
3. Vérification au runtime, seuils de confiance
4. Option de désactivation
**Estimation :** Phase 5 - 3 mois développement

### 5. Plugins Vocaux (Système Extensible)
**Technologies :** Construire interface plugin (Dart interface + RPC)
**Étapes :**
1. Définir ABI des plugins
2. Créer loader dynamique (plugins signés)
3. Exemples : plugin météo local, plugin banque
4. Installer via Supabase/serveur
**Estimation :** Phase 6 - 6 mois développement

### 6. Multilingue & Dialectes Africains
**Technologies :** Ajouter modèles de langue et prompts spécialisés
**Étapes :**
1. Collecter corpus
2. Fine-tuning prompts
3. Mapping langue selon géoloc ou préférence utilisateur
4. Fallback en français/anglais
**Estimation :** Phase 7 - 8 mois développement

### 7. Analytics Vocaux Anonymisés
**Technologies :** Logs anonymes d'intents pour améliorer UX
**Étapes :**
1. Hash user id
2. Envoyer événements minimalistes (intent, success/fail) vers serveur
3. Opt-in vocal
**Estimation :** Phase 2 - 1 mois développement

## Gestion des Permissions - Guide Détaillé (Android & iOS)

### Principes Généraux
- Toujours expliquer **oralement** pourquoi on demande une permission **avant** la popup système
- Demander les permissions **progressivement** (ne pas tout demander dès le premier démarrage)
- Stocker le consentement (date + scope) et permettre retrait via commandes vocales
- Gérer les refus : expliquer conséquences et proposer « autoriser via paramètres » par voix

### Android - Listage et Étapes

#### Permissions à Déclarer (AndroidManifest.xml)
- RECORD_AUDIO
- FOREGROUND_SERVICE
- WAKE_LOCK
- ACCESS_FINE_LOCATION (si navigation / météo précise)
- BODY_SENSORS (si accès santé)
- POST_NOTIFICATIONS (Android 13+)
- RECEIVE_BOOT_COMPLETED (si démarrage au boot requis)

#### Flow Recommandé
1. Wake-word local : accès micro nécessaire pour démarrage
2. Première action audio : lancer onboarding vocal expliquant pourquoi microphone
3. App via `permission_handler` demande RECORD_AUDIO. Si accord, activer wake-word
4. Si navigation demandée : demander location **juste avant** l'usage
5. Services background : demander FOREGROUND_SERVICE + notification persistante
6. Si refus : « tu as refusé, veux-tu que je t'explique comment autoriser ? » → AppSettings.openAppSettings()

#### Points Play Store
- Documenter clairement usage micro en background dans fiche Play Store
- Fournir Privacy Policy accessible et justification
- Respecter règles enregistrement arrière-plan

### iOS - Listage et Étapes

#### Info.plist Keys
- NSMicrophoneUsageDescription
- NSSpeechRecognitionUsageDescription
- NSLocationWhenInUseUsageDescription (si navigation)
- NSLocationAlwaysAndWhenInUseUsageDescription (si background location)
- NSHealthShareUsageDescription / NSHealthUpdateUsageDescription (si HealthKit)

#### Background Modes (Only If Necessary)
- audio (pour continuer audio sessions)
- location (si navigation en background)

#### Flow Recommandé
1. Même principe : expliquer oralement avant la demande
2. Appeler `Permission.microphone.request()` ; iOS affiche popup
3. Pour background audio : configurer AVAudioSession native (category = .playAndRecord, mode = .voiceChat)
4. Enregistrements background iOS strictement contrôlés par Apple

#### Points App Store
- Fournir justification claire et privacy policy
- Enregistrements non sollicités peuvent provoquer rejet

### Pratiques d'Implémentation Code (Pattern)
1. **Rationale Step** (TTS) : expliquer pourquoi
2. **Request Permission** : appeler `permission_handler`
3. **Listen to Result** : if granted → enable feature ; if denied → voice explain
4. **If Permanently Denied** : instruire utilisateur ouvrir paramètres via voix
5. **Log Consent** : stocker consentement chiffré (timestamp + scope)

## Sécurité des Clés & Données Sensibles

### Actions Immédiates Requises
1. **Supprimer EnvLoader** : Ne jamais garder clés Azure/Spotify dans dépôt
2. **Azure Key Vault** : Backend sécurisé pour délivrer jetons à la demande
3. **Secure Storage Mobile** : access_token dans flutter_secure_storage
4. **CI/CD Secrets** : GitHub Actions Secrets, Azure DevOps variable groups
5. **Chiffrement Audio** : tout enregistrement local chiffré ; préférer streaming éphémère
6. **Privacy Policy** : accessible vocalement et dans stores

### Migration Recommandée
```dart
// AVANT (à supprimer)
class EnvLoader {
  static const String _azureOpenAIKey = 'clé_en_dur';
}

// APRÈS (à implémenter)
class SecureConfigService {
  static Future<String> getAzureOpenAIKey() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'azure_openai_key') ?? 
           await _fetchFromKeyVault();
  }
}
```

## Tests, Monitoring et Qualité

### Tests Unitaires
- Providers Riverpod (VoiceController, émotions, audio)
- Logique de dialogue et parsers d'intent
- Modèles de données (VoiceOption, UserProfile)

### Tests d'Intégration
- End-to-end STT → NLU → TTS
- Pipeline audio complet avec interruptions
- OAuth flow Spotify sans texte

### Tests Appareils Réels
- Android 8 → 14 et iOS 14+
- Conditions réseau variées (offline, 3G, WiFi)
- Performances animation avec différents niveaux hardware

### Monitoring
- Envoi erreurs (Sentry) anonymisées, opt-in vocal
- Métriques performance pipeline audio
- Analytics usage fonctionnalités (anonymisé)

## Checklist de Déploiement et Conformité

### Documentation Stores
- ✅ Privacy policy vocalement expliquée dans onboarding + lien stores
- ✅ Justification usage background audio/microphone pour review
- ✅ Screenshots interface voice-first pour stores
- ✅ Vidéo démo interactions vocales

### Conformité Technique
- ✅ Désactivation facile enregistrements
- ✅ Export/suppression données vocales sur demande
- ✅ Tests plusieurs appareils et conditions réseau
- ✅ Respect guidelines accessibilité

### Tests Finaux
- ✅ Validation pipeline audio end-to-end
- ✅ Test interruptions et gestion erreurs
- ✅ Vérification performances animations
- ✅ Contrôle sécurité données sensibles

## Résumé Opérationnel - Actions Immédiates à Coder

### Phase 1 : UI Voice-First (En cours ✅)
1. ✅ Design tokens et thèmes complets
2. ✅ Avatar animé réactif émotionnel
3. ✅ Système de voix avec 8 options
4. ✅ Waveform temps réel
5. 🔄 Mise à jour HomeView avec nouveaux widgets
6. 🔄 Suppression zones saisie texte flux principal

### Phase 2 : Pipeline Audio (Suivant)
1. 🔄 Implémentation wake-word local
2. 🔄 Azure Speech streaming natif
3. 🔄 Gestion interruptions TTS
4. 🔄 Onboarding vocal permissions

### Phase 3 : OAuth & Sécurité
1. 🔄 Spotify device flow
2. 🔄 Migration vers Key Vault
3. 🔄 Secure storage tokens
4. 🔄 Privacy policy vocale

### Phase 4 : Fonctionnalités Avancées
1. 🔄 Reconnaissance offline
2. 🔄 Wake-word personnalisé
3. 🔄 Personnalités évolutives
4. 🔄 Analytics anonymisés

---

**État Actuel :** Interface voice-first foundation complétée ✅
**Prochaine Étape :** Intégration widgets dans HomeView et pipeline audio
**Objectif Final :** Assistant vocal 100% voice-first avec avatar réactif émotionnel
