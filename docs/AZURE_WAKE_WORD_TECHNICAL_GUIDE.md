# Documentation Technique - Azure Wake Word Service

## Vue d'ensemble

Le **Azure Wake Word Service** remplace Picovoice pour la détection de mots déclencheurs. Il utilise l'algorithme NBest d'Azure Speech Recognition avec un système de confiance sophistiqué basé sur les meilleures pratiques de reconnaissance vocale.

## Fonctionnalités principales

### 1. Détection NBest intelligente
- **Analyse multi-hypothèses** : Évaluation de toutes les hypothèses de reconnaissance
- **Seuils de confiance dynamiques** : 
  - `≥ 0.65` : Acceptation immédiate
  - `≥ 0.50` : Acceptation avec cooldown
  - `≥ 0.35` : Demande de confirmation
  - `< 0.35` : Rejet

### 2. Mots déclencheurs supportés
```dart
static const List<String> _wakeWords = [
  'salut rick',
  'salut ric', 
  'rick',
  'ric',
  'hey rick',
  'bonjour rick'
];
```

### 3. Fuzzy Matching
- **Distance de Levenshtein** pour gérer les variations phonétiques
- **Tolérance adaptative** :
  - Mots courts (3-5 lettres) : tolérance = 1
  - Mots longs (>5 lettres) : tolérance = 2

### 4. Phrase Hints
Configuration automatique des hints Azure pour améliorer la reconnaissance :
```dart
static const List<String> _phraseHints = [
  'salut rick', 'salut ric', 'rick', 'ric',
  'hey rick', 'bonjour rick', 'salut r', 'hey ric'
];
```

## Architecture

### Classes principales

#### `AzureWakeWordService`
Service singleton gérant la détection de mots déclencheurs :
- **Streams** : `detectionStream`, `transcriptionStream`, `confirmationStream`
- **Méthodes** : `initialize()`, `startListening()`, `stopListening()`
- **Algorithme** : `_analyzeNBestForWakeWord()`

#### `WakeWordPipelineNotifier`
Provider Riverpod intégrant le service dans l'UI :
- **État** : `WakeWordPipelineState` avec statuts et visualisations
- **Gestion** : Confirmations utilisateur, retours haptiques, TTS

### Modèles de données

```dart
class WakeWordDetectionResult {
  final bool isDetected;
  final double confidence;
  final String matchedText;
  final String originalText;
  final bool needsConfirmation;
  final DateTime timestamp;
  final String? error;
}

class WakeWordDetectionCandidate {
  final double confidence;
  final String matchedText;
  final String originalText;
  final double topConfidence;
  final WakeWordAction action;
  final DateTime timestamp;
}

enum WakeWordAction {
  accept,                // Confiance élevée
  acceptWithCooldown,    // Confiance moyenne
  requestConfirmation,   // Confiance faible
  ignore,               // Confiance très faible
}
```

## Algorithme de détection

### Étape 1 : Prétraitement
```dart
String _normalize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
```

### Étape 2 : Analyse NBest
1. **Parcours des hypothèses** : Examen de chaque hypothèse dans l'ordre de confiance
2. **Détection exacte** : Recherche de correspondances exactes avec les wake-words
3. **Fuzzy matching** : Si aucune correspondance exacte, utilisation de Levenshtein
4. **Validation contextuelle** : Vérification de la cohérence avec l'hypothèse principale

### Étape 3 : Décision d'action
```dart
WakeWordAction _determineAction(double confidence, double topConfidence) {
  if (topConfidence > 0.9 && !_detectWakeWordInText(topText).isMatch) {
    return WakeWordAction.ignore; // Hypothèse principale très confiante sans wake-word
  }
  
  if (confidence >= 0.65) return WakeWordAction.accept;
  if (confidence >= 0.50) return WakeWordAction.acceptWithCooldown;
  if (confidence >= 0.35) return WakeWordAction.requestConfirmation;
  return WakeWordAction.ignore;
}
```

## Gestion des confirmations

### Workflow de confirmation
1. **Détection incertaine** (conf 0.35-0.49) → Demande TTS
2. **Question type** : "Tu m'as appelé 'Rick' ?"
3. **Écoute réponse** : Oui/Non via reconnaissance vocale
4. **Action finale** : Activation ou rejet selon la réponse

### Interface utilisateur
```dart
void confirmWakeWord(bool confirmed) {
  if (_pendingConfirmation == null) return;
  
  _wakeWordService.confirmWakeWord(_pendingConfirmation!, confirmed);
  _pendingConfirmation = null;
  
  if (confirmed) {
    _startConversationListening();
  }
}
```

## Avantages vs Picovoice

| Aspect | Picovoice | Azure Speech NBest |
|--------|-----------|-------------------|
| **Précision** | Fixe, modèle pré-entraîné | Adaptable, analyse multi-hypothèses |
| **Personnalisation** | Limitée | Phrase hints, custom speech possible |
| **Gestion incertitude** | Binaire (détecté/non) | Système de confiance nuancé |
| **Intégration** | SDK séparé | Unifié avec reconnaissance vocale |
| **Coût** | Licence Picovoice | Inclus dans Azure Speech |
| **Hors ligne** | ✅ Oui | ❌ Nécessite connexion |

## Configuration requise

### Variables d'environnement
Les clés Picovoice ne sont plus nécessaires. Le service utilise les clés Azure Speech existantes :

```bash
# Supprimé de .env
# PICOVOICE_ACCESS_KEY=your_picovoice_access_key

# Utilise Azure Speech existant
AZURE_SPEECH_KEY=your_azure_speech_key_here
AZURE_SPEECH_REGION=eastus
```

### Permissions Android
Aucun changement requis - utilise les mêmes permissions :
- `RECORD_AUDIO`
- `WAKE_LOCK`

## Optimisations futures

### 1. Custom Speech Model
- Entraînement spécifique sur échantillons utilisateur
- Amélioration pour accents africains/Yoruba
- Dataset de 20-50 enregistrements recommandé

### 2. Partial Results
- Détection en temps réel sur résultats partiels
- Réduction de latence
- Détection précoce avec renforcement

### 3. Analytics et apprentissage
- Collecte anonymisée des détections incertaines
- Amélioration continue du modèle
- Métriques de performance en temps réel

## Tests et validation

### Scénarios de test
1. **Mots exacts** : "salut rick", "hey rick"
2. **Variations phonétiques** : "salut ric", "salut r"  
3. **Contexte bruité** : Détection en environnement bruyant
4. **Faux positifs** : Phrases similaires sans intention
5. **Confirmations** : Workflow complet de validation

### Métriques cibles
- **Précision** : >95% pour confidences élevées (≥0.65)
- **Rappel** : >90% pour intentions réelles
- **Latence** : <200ms pour détection + action
- **Faux positifs** : <2% avec système de confirmation

## Migration depuis Picovoice

### Étapes réalisées ✅
1. Suppression dépendance `picovoice_flutter: ^3.0.1`
2. Suppression `PICOVOICE_ACCESS_KEY` de `.env.example`
3. Remplacement `WakeWordPipelineService` 
4. Intégration `AzureWakeWordService`
5. Mise à jour documentation

### Compatibilité
- **Interface publique** : Identique (streams Riverpod)
- **Intégration UI** : Aucun changement requis
- **Configuration** : Simplifiée (moins de clés API)

Cette migration améliore significativement la robustesse et la précision de la détection de mots déclencheurs tout en réduisant les dépendances externes.
