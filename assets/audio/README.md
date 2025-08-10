# Fichiers Audio pour Transitions HordVoice

Ce dossier contient les effets sonores pour les transitions animées.

## Fichiers requis:

### 1. transition_whoosh.mp3
- **Usage**: Son "whoosh" pendant la transition 3D
- **Durée**: ~1.5 secondes
- **Type**: Effet sonore futuriste, transition fluide
- **Volume**: Moyen, non-intrusif

### 2. transition_complete.mp3  
- **Usage**: Son de confirmation à la fin de la transition
- **Durée**: ~0.5 secondes
- **Type**: Chime doux, notification positive
- **Volume**: Léger, satisfaisant

## Intégration:

Les fichiers sont référencés dans `TransitionAnimationService.dart`:
```dart
await _audioPlayer.setAsset('assets/audio/transition_whoosh.mp3');
await _audioPlayer.setAsset('assets/audio/transition_complete.mp3');
```

## Production:

Pour la production, remplacer ces placeholders par de vrais fichiers audio.
Formats supportés: MP3, WAV, AAC.
