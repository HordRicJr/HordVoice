# AUDIT DÉPENDANCES HORDVOICE v2.0

## PACKAGES VOIX & AUDIO (FONCTIONNALITÉS SENSIBLES)
✅ azure_speech_recognition_flutter: ^1.0.0  # PERMISSION: RECORD_AUDIO
✅ flutter_tts: 3.8.5                        # PERMISSION: aucune spéciale
✅ just_audio: ^0.9.40                       # PERMISSION: aucune spéciale
✅ audio_session: ^0.1.21                    # PERMISSION: MODIFY_AUDIO_SETTINGS
✅ azure_speech_recognition_flutter: ^2.0.3    # PERMISSION: RECORD_AUDIO
✅ audioplayers: ^6.1.0                      # PERMISSION: aucune spéciale
✅ audio_waveforms: ^1.1.6                   # PERMISSION: RECORD_AUDIO
✅ mic_stream: ^0.7.2                        # PERMISSION: RECORD_AUDIO
✅ record: ^5.1.2                            # PERMISSION: RECORD_AUDIO
✅ flutter_azure_tts: ^1.0.0                 # PERMISSION: INTERNET + éventuellement RECORD_AUDIO

## PACKAGES LOCALISATION (FONCTIONNALITÉS SENSIBLES)
✅ location: ^8.0.1                          # PERMISSION: ACCESS_FINE_LOCATION
✅ geolocator: 10.1.0                        # PERMISSION: ACCESS_FINE_LOCATION + ACCESS_COARSE_LOCATION
✅ geocoding: ^3.0.0                         # PERMISSION: INTERNET
✅ flutter_map: ^7.0.2                       # PERMISSION: INTERNET

## PACKAGES TÉLÉPHONIE (FONCTIONNALITÉS SENSIBLES)
✅ call_log: ^6.0.0                          # PERMISSION: READ_CALL_LOG
✅ flutter_phone_direct_caller: ^2.1.1       # PERMISSION: CALL_PHONE
✅ another_telephony: ^0.4.1                 # PERMISSION: READ_PHONE_STATE + SEND_SMS + READ_SMS

## PACKAGES CALENDRIER & CONTACTS (FONCTIONNALITÉS SENSIBLES)
✅ device_calendar: 4.3.3                    # PERMISSION: READ_CALENDAR + WRITE_CALENDAR
✅ google_sign_in: ^6.2.1                    # PERMISSION: INTERNET + GET_ACCOUNTS

## PACKAGES SYSTÈME & MONITORING (FONCTIONNALITÉS SENSIBLES)
✅ app_usage: ^4.0.1                         # PERMISSION: PACKAGE_USAGE_STATS (paramètres système)
✅ battery_plus: ^6.2.2                      # PERMISSION: aucune spéciale
✅ system_info2: ^4.0.0                      # PERMISSION: aucune spéciale
✅ health: ^13.1.1                           # PERMISSION: BODY_SENSORS + ACTIVITY_RECOGNITION

## PACKAGES BACKGROUND & SERVICES (FONCTIONNALITÉS SENSIBLES)
✅ flutter_background_service: 5.1.0         # PERMISSION: FOREGROUND_SERVICE + WAKE_LOCK
✅ home_widget: ^0.6.0                       # PERMISSION: aucune spéciale
✅ wakelock_plus: ^1.2.8                     # PERMISSION: WAKE_LOCK

## PACKAGES STOCKAGE (FONCTIONNALITÉS SENSIBLES)
✅ flutter_secure_storage: ^9.2.2            # PERMISSION: aucune spéciale (stockage interne sécurisé)
✅ hive: 2.2.3 + hive_flutter: 1.1.0         # PERMISSION: aucune spéciale (stockage interne)
✅ path_provider: ^2.1.5                     # PERMISSION: READ_EXTERNAL_STORAGE (optionnel)

## PACKAGES NOTIFICATIONS & UI
✅ flutter_local_notifications: ^18.0.1      # PERMISSION: POST_NOTIFICATIONS (Android 13+)
✅ vibration: ^2.0.0                         # PERMISSION: VIBRATE

## PACKAGES CONNECTIVITÉ & RÉSEAU
✅ http: 1.5.0                               # PERMISSION: INTERNET
✅ dio: ^5.7.0                               # PERMISSION: INTERNET
✅ connectivity_plus: ^6.1.0                 # PERMISSION: ACCESS_NETWORK_STATE
✅ network_info_plus: ^5.0.3                 # PERMISSION: ACCESS_NETWORK_STATE

## VERSIONS - STATUT MISE À JOUR
⚠️  flutter_riverpod: 2.6.1                 # CURRENT: 2.6.1 ✅ À jour
⚠️  permission_handler: 11.3.1              # CURRENT: 11.3.1 ✅ À jour  
⚠️  azure_speech_recognition_flutter: ^1.0.0 # ⚠️ Vérifier si nouvelle version
⚠️  picovoice_flutter: ^3.0.1               # CURRENT: 3.0.1 ✅ À jour
⚠️  geolocator: 10.1.0                      # CURRENT: 10.1.0 ✅ À jour

## PACKAGES MANQUANTS POTENTIELS POUR VOICE-FIRST
❌ camera: ^0.10.5                           # Pour analyse émotionnelle visuelle
❌ speech_to_text: ^6.6.0                    # Alternative STT si Azure échoue
❌ flutter_bluetooth_serial: ^0.4.0          # Si contrôle Bluetooth avancé requis

## RISQUES SÉCURITÉ IDENTIFIÉS
🔴 flutter_dotenv: ^5.1.0                   # RISQUE: Clés en dur potentielles
🔴 SUPPRIMÉ: picovoice_flutter: ^3.0.1       # REMPLACÉ par Azure Speech NBest wake-word
🔴 env_loader.dart + env_config.dart         # RISQUE: Gestion clés sensibles
