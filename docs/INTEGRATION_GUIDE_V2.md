# Guide d'intégration HordVoice v2.0 - Base de Données et Services

## ✅ Problèmes corrigés

### 1. **Erreur de contrainte `voice_tone`**
- **Problème**: La valeur 'inquiet' n'était pas acceptée dans la contrainte CHECK
- **Solution**: Ajout de 'inquiet' et 'colere', 'bienveillant' dans les valeurs autorisées

### 2. **Erreurs Supabase Service**
- **Problème**: Syntaxe incorrecte avec `PostgrestTransformBuilder`
- **Solution**: Utilisation correcte des méthodes de filtrage Supabase

## 📁 Fichiers créés/corrigés

### **Base de données**
- `docs/database_update_v2_corrected.sql` - Script principal corrigé
- `docs/database_test.sql` - Script de test et validation

### **Services Flutter**
- `lib/services/supabase_data_service.dart` - Service corrigé et complet

## 🚀 Instructions de déploiement

### 1. **Appliquer le script de base de données**

```bash
# Dans votre console Supabase SQL Editor
# Exécuter le fichier: docs/database_update_v2_corrected.sql
```

### 2. **Tester la base de données**

```bash
# Exécuter le script de test
# Fichier: docs/database_test.sql
```

### 3. **Vérification Flutter**

```dart
// Test dans votre application Flutter
final dataService = SupabaseDataService();

// Test de base
final aiResponses = await dataService.getAIResponses(
  responseType: 'encouragement',
  personalityType: 'mere_africaine',
);

print('Réponses IA chargées: ${aiResponses.length}');
```

## 🔧 Nouvelles fonctionnalités disponibles

### **1. Surveillance du téléphone**
```dart
// Enregistrer l'usage
await dataService.recordPhoneUsageSession({
  'user_id': userId,
  'device_id': 'device123',
  'total_screen_time_seconds': 3600,
  'app_switches_count': 45,
  'is_excessive_usage': true,
});

// Récupérer les données
final usage = await dataService.getPhoneUsageData(userId);
```

### **2. Surveillance batterie**
```dart
// Enregistrer l'état batterie
await dataService.recordBatteryStatus({
  'user_id': userId,
  'device_id': 'device123',
  'battery_level': 25,
  'battery_temperature_celsius': 35.5,
  'is_charging': false,
});
```

### **3. Réponses IA personnalisées**
```dart
// Récupérer des réponses contextuelles
final responses = await dataService.getAIResponses(
  responseType: 'reproches',
  triggerContext: 'usage_excessif',
  personalityType: 'mere_africaine',
);

// Marquer une réponse comme utilisée
await dataService.incrementAIResponseUsage(
  responseId, 
  userReactionPositive: true,
);
```

### **4. Objectifs bien-être**
```dart
// Récupérer les objectifs
final goals = await dataService.getWellnessGoals(userId);

// Mettre à jour progression
await dataService.updateGoalProgress(goalId, 75.0);

// Calculer score bien-être
final score = await dataService.calculateWellnessScore(userId);
```

### **5. Mémoire émotionnelle IA**
```dart
// Enregistrer interaction émotionnelle
await dataService.recordEmotionalInteraction({
  'user_id': userId,
  'interaction_context': 'stress_travail',
  'user_emotional_state': 'stressed',
  'ai_response_type': 'empathetic',
  'user_satisfaction_score': 8,
});
```

## 📊 Tables disponibles

| Table | Utilisation |
|-------|-------------|
| `phone_usage_monitoring` | Surveillance utilisation téléphone |
| `battery_health_monitoring` | Surveillance batterie et température |
| `ai_personality_responses` | Réponses personnalisées de l'IA |
| `wellness_goals_tracking` | Suivi objectifs bien-être |
| `ai_emotional_memory` | Mémoire émotionnelle interactions |
| `system_performance_monitoring` | Performance système temps réel |
| `personalized_weather_alerts` | Alertes météo personnalisées |
| `user_behavior_analysis` | Analyse comportementale avancée |

## 🔒 Sécurité RLS

- **Row Level Security** activé sur toutes les tables sensibles
- **Politiques d'accès** : utilisateur accède uniquement à ses données
- **Accès public** : lecture seule sur `ai_personality_responses`

## 🎯 Personnalités IA disponibles

1. **mère africaine** - Stricte mais bienveillante
2. **grand frère** - Protecteur et motivant  
3. **petite amie** - Douce et inquiète
4. **ami** - Décontracté et encourageant
5. **professionnel** - Formel et efficace

## 📱 Types de réponses IA

- `reproches` - Pour usage excessif
- `encouragement` - Pour motivation
- `inquiétude` - Pour inactivité  
- `motivation` - Pour objectifs
- `colère` - Pour non-respect règles
- `joie` - Pour célébrations
- `félicitation` - Pour réussites

## ⚡ Optimisations incluses

- **Index de performance** sur toutes les requêtes fréquentes
- **Triggers automatiques** pour timestamps
- **Fonctions utilitaires** pour nettoyage et calculs
- **Contraintes de validation** pour intégrité des données

## 🔄 Synchronisation complète

```dart
// Synchroniser toutes les données utilisateur
final allData = await dataService.syncAllUserData(userId);

// Contient:
// - profile, calendar_events, behavior_data
// - news, wellness_goals, phone_usage
// - battery_history, emotional_history
```

La base de données est maintenant prête pour toutes les fonctionnalités avancées de HordVoice v2.0 ! 🎉
