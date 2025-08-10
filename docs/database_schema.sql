-- ===============================================
-- DATABASE UPDATE V3 - VOICE AI SYSTEM COMPLETE
-- Date: 2025-08-09
-- HordVoice IA - Système vocal complet
-- ===============================================

-- =============================================
-- NOUVELLES TABLES POUR SYSTÈME VOCAL IA
-- =============================================

-- Table pour la détection d'émotion dans la voix
CREATE TABLE IF NOT EXISTS public.voice_emotion_detection (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  detection_session_id uuid DEFAULT uuid_generate_v4(),
  audio_sample_data bytea,
  audio_sample_url text,
  audio_duration_seconds real NOT NULL CHECK (audio_duration_seconds > 0),
  sample_rate_hz integer DEFAULT 16000 CHECK (sample_rate_hz > 0),
  
  -- Caractéristiques vocales extraites
  voice_pitch_hz real CHECK (voice_pitch_hz >= 50 AND voice_pitch_hz <= 500),
  voice_pitch_variation real CHECK (voice_pitch_variation >= 0),
  voice_energy real CHECK (voice_energy >= 0 AND voice_energy <= 1),
  voice_energy_variation real CHECK (voice_energy_variation >= 0),
  voice_speech_rate_wpm real CHECK (voice_speech_rate_wpm >= 60 AND voice_speech_rate_wpm <= 300),
  voice_shimmer real CHECK (voice_shimmer >= 0 AND voice_shimmer <= 1),
  voice_jitter real CHECK (voice_jitter >= 0 AND voice_jitter <= 1),
  voice_hnr real CHECK (voice_hnr >= 0), -- Harmonic-to-Noise Ratio
  voice_spectral_centroid real CHECK (voice_spectral_centroid >= 0),
  voice_spectral_rolloff real CHECK (voice_spectral_rolloff >= 0),
  voice_formants jsonb DEFAULT '[]'::jsonb, -- F1, F2, F3
  voice_mfcc jsonb DEFAULT '[]'::jsonb, -- Mel-frequency cepstral coefficients
  
  -- Émotions détectées
  primary_emotion text NOT NULL CHECK (primary_emotion = ANY (ARRAY[
    'voice_joy'::text, 'voice_sadness'::text, 'voice_anger'::text, 'voice_calm'::text,
    'voice_neutral'::text, 'voice_surprise'::text, 'voice_fear'::text, 'voice_stress'::text,
    'voice_fatigue'::text, 'voice_excitement'::text
  ])),
  emotion_confidence real NOT NULL CHECK (emotion_confidence >= 0 AND emotion_confidence <= 1),
  emotion_intensity real NOT NULL CHECK (emotion_intensity >= 0 AND emotion_intensity <= 1),
  secondary_emotions jsonb DEFAULT '[]'::jsonb,
  
  -- Métadonnées
  detection_method text DEFAULT 'ml_analysis'::text,
  processing_time_ms integer CHECK (processing_time_ms >= 0),
  voice_context jsonb DEFAULT '{}'::jsonb,
  user_feedback_accurate boolean,
  user_feedback_comment text,
  
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_emotion_detection_pkey PRIMARY KEY (id),
  CONSTRAINT voice_emotion_detection_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour les profils vocaux émotionnels des utilisateurs
CREATE TABLE IF NOT EXISTS public.voice_emotion_profiles (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  
  -- Profil vocal par émotion
  joy_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  sadness_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  anger_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  calm_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  neutral_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  stress_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  fatigue_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  excitement_voice_characteristics jsonb DEFAULT '{}'::jsonb,
  
  -- Métadonnées de calibration
  calibration_date timestamp with time zone DEFAULT now(),
  calibration_accuracy real CHECK (calibration_accuracy >= 0 AND calibration_accuracy <= 1),
  total_calibration_samples integer DEFAULT 0 CHECK (total_calibration_samples >= 0),
  last_detection_accuracy real CHECK (last_detection_accuracy >= 0 AND last_detection_accuracy <= 1),
  
  -- Configuration de détection
  confidence_threshold real DEFAULT 0.65 CHECK (confidence_threshold >= 0 AND confidence_threshold <= 1),
  intensity_threshold real DEFAULT 0.45 CHECK (intensity_threshold >= 0 AND intensity_threshold <= 1),
  real_time_detection_enabled boolean DEFAULT false,
  detection_sensitivity text DEFAULT 'medium'::text CHECK (detection_sensitivity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_emotion_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT voice_emotion_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour les effets vocaux et leur configuration
CREATE TABLE IF NOT EXISTS public.voice_effects_configuration (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- Configuration des effets
  effect_name text NOT NULL,
  effect_type text NOT NULL CHECK (effect_type = ANY (ARRAY[
    'predefined'::text, 'custom'::text, 'emotional'::text, 'character'::text
  ])),
  effect_category text CHECK (effect_category = ANY (ARRAY[
    'robot'::text, 'chipmunk'::text, 'darth_vader'::text, 'echo'::text, 'whisper'::text,
    'happy'::text, 'sad'::text, 'angry'::text, 'excited'::text, 'calm'::text, 'custom'::text
  ])),
  
  -- Paramètres d'effet
  pitch_shift real DEFAULT 1.0 CHECK (pitch_shift >= 0.1 AND pitch_shift <= 3.0),
  speed_multiplier real DEFAULT 1.0 CHECK (speed_multiplier >= 0.1 AND speed_multiplier <= 3.0),
  volume_multiplier real DEFAULT 1.0 CHECK (volume_multiplier >= 0.1 AND volume_multiplier <= 2.0),
  reverb_level real DEFAULT 0.0 CHECK (reverb_level >= 0 AND reverb_level <= 1),
  echo_delay_ms integer DEFAULT 0 CHECK (echo_delay_ms >= 0 AND echo_delay_ms <= 2000),
  echo_decay real DEFAULT 0.0 CHECK (echo_decay >= 0 AND echo_decay <= 1),
  distortion_level real DEFAULT 0.0 CHECK (distortion_level >= 0 AND distortion_level <= 1),
  
  -- Configuration avancée
  custom_parameters jsonb DEFAULT '{}'::jsonb,
  text_transformations jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  is_favorite boolean DEFAULT false,
  usage_count integer DEFAULT 0 CHECK (usage_count >= 0),
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_effects_configuration_pkey PRIMARY KEY (id),
  CONSTRAINT voice_effects_configuration_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour la mémoire contextuelle conversationnelle
CREATE TABLE IF NOT EXISTS public.contextual_conversation_memory (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  conversation_session_id uuid DEFAULT uuid_generate_v4(),
  
  -- Contenu conversationnel
  conversation_text text NOT NULL,
  user_intent text,
  ai_response text,
  conversation_topic text,
  conversation_context jsonb DEFAULT '{}'::jsonb,
  
  -- Analyse contextuelle
  extracted_keywords jsonb DEFAULT '[]'::jsonb,
  detected_emotions jsonb DEFAULT '[]'::jsonb,
  user_preferences_extracted jsonb DEFAULT '{}'::jsonb,
  conversation_sentiment text CHECK (conversation_sentiment = ANY (ARRAY['positive'::text, 'negative'::text, 'neutral'::text])),
  engagement_level real CHECK (engagement_level >= 0 AND engagement_level <= 1),
  
  -- Gestion temporelle
  conversation_timestamp timestamp with time zone DEFAULT now(),
  retention_until timestamp with time zone DEFAULT (now() + interval '30 minutes'),
  is_important boolean DEFAULT false,
  importance_score real DEFAULT 0.5 CHECK (importance_score >= 0 AND importance_score <= 1),
  
  -- Métadonnées
  processing_time_ms integer CHECK (processing_time_ms >= 0),
  memory_type text DEFAULT 'short_term'::text CHECK (memory_type = ANY (ARRAY['short_term'::text, 'long_term'::text, 'preference'::text])),
  
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT contextual_conversation_memory_pkey PRIMARY KEY (id),
  CONSTRAINT contextual_conversation_memory_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour la calibration karaoké et profilage vocal
CREATE TABLE IF NOT EXISTS public.karaoke_vocal_calibration (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- Session de calibration
  calibration_session_id uuid DEFAULT uuid_generate_v4(),
  calibration_type text NOT NULL CHECK (calibration_type = ANY (ARRAY[
    'pitch_test'::text, 'tempo_test'::text, 'vocal_range'::text, 'karaoke_performance'::text
  ])),
  
  -- Données de calibration
  reference_audio_url text,
  user_audio_url text,
  reference_pitch_hz real CHECK (reference_pitch_hz >= 50 AND reference_pitch_hz <= 500),
  user_pitch_hz real CHECK (user_pitch_hz >= 50 AND user_pitch_hz <= 500),
  pitch_accuracy_percentage real CHECK (pitch_accuracy_percentage >= 0 AND pitch_accuracy_percentage <= 100),
  tempo_accuracy_percentage real CHECK (tempo_accuracy_percentage >= 0 AND tempo_accuracy_percentage <= 100),
  overall_score real CHECK (overall_score >= 0 AND overall_score <= 100),
  
  -- Profil vocal déterminé
  vocal_range_low_hz real CHECK (vocal_range_low_hz >= 50),
  vocal_range_high_hz real CHECK (vocal_range_high_hz >= 50),
  vocal_type text CHECK (vocal_type = ANY (ARRAY[
    'bass'::text, 'baritone'::text, 'tenor'::text, 'alto'::text, 'soprano'::text, 'undefined'::text
  ])),
  vocal_characteristics jsonb DEFAULT '{}'::jsonb,
  
  -- Recommandations
  recommended_songs jsonb DEFAULT '[]'::jsonb,
  vocal_exercises jsonb DEFAULT '[]'::jsonb,
  improvement_suggestions jsonb DEFAULT '[]'::jsonb,
  
  -- Métadonnées
  calibration_duration_seconds integer CHECK (calibration_duration_seconds >= 0),
  calibration_completed boolean DEFAULT false,
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT karaoke_vocal_calibration_pkey PRIMARY KEY (id),
  CONSTRAINT karaoke_vocal_calibration_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour les commandes secrètes et sécurité
CREATE TABLE IF NOT EXISTS public.secret_commands_security (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- Commande et sécurité
  command_phrase text NOT NULL,
  command_hash text NOT NULL, -- SHA-256 hash
  command_type text NOT NULL CHECK (command_type = ANY (ARRAY[
    'developer_mode'::text, 'debug_info'::text, 'system_diagnostics'::text, 
    'advanced_settings'::text, 'factory_reset'::text, 'backup_data'::text,
    'performance_mode'::text, 'security_check'::text, 'ai_training_mode'::text,
    'emergency_contact'::text
  ])),
  
  -- Données de sécurité
  security_level integer DEFAULT 1 CHECK (security_level >= 1 AND security_level <= 5),
  authentication_required boolean DEFAULT true,
  authentication_method text DEFAULT 'voice_pattern'::text CHECK (authentication_method = ANY (ARRAY[
    'voice_pattern'::text, 'biometric'::text, 'pin'::text, 'phrase'::text
  ])),
  
  -- Tentatives et protection
  failed_attempts integer DEFAULT 0 CHECK (failed_attempts >= 0),
  max_failed_attempts integer DEFAULT 3 CHECK (max_failed_attempts >= 1),
  lockout_until timestamp with time zone,
  last_successful_use timestamp with time zone,
  
  -- Configuration
  is_active boolean DEFAULT true,
  usage_count integer DEFAULT 0 CHECK (usage_count >= 0),
  command_parameters jsonb DEFAULT '{}'::jsonb,
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT secret_commands_security_pkey PRIMARY KEY (id),
  CONSTRAINT secret_commands_security_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour la configuration multilingue
CREATE TABLE IF NOT EXISTS public.multilingual_voice_configuration (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- Configuration par langue
  language_code text NOT NULL CHECK (language_code = ANY (ARRAY[
    'fr'::text, 'en'::text, 'es'::text, 'de'::text, 'it'::text, 'pt'::text
  ])),
  country_code text,
  
  -- Configuration vocale
  tts_voice_name text NOT NULL,
  speech_rate real DEFAULT 1.0 CHECK (speech_rate >= 0.1 AND speech_rate <= 3.0),
  pitch_level real DEFAULT 1.0 CHECK (pitch_level >= 0.1 AND pitch_level <= 2.0),
  volume_level real DEFAULT 0.8 CHECK (volume_level >= 0.1 AND volume_level <= 1.0),
  
  -- Adaptation culturelle
  cultural_context jsonb DEFAULT '{}'::jsonb,
  greeting_style text,
  formality_level text DEFAULT 'medium'::text CHECK (formality_level = ANY (ARRAY['formal'::text, 'medium'::text, 'casual'::text])),
  cultural_expressions_enabled boolean DEFAULT true,
  
  -- Détection automatique
  auto_detection_enabled boolean DEFAULT true,
  detection_confidence_threshold real DEFAULT 0.75 CHECK (detection_confidence_threshold >= 0 AND detection_confidence_threshold <= 1),
  fallback_language text DEFAULT 'fr'::text,
  
  -- Cache de traduction
  translation_cache_enabled boolean DEFAULT true,
  cache_size_limit_mb integer DEFAULT 50 CHECK (cache_size_limit_mb >= 10),
  
  -- Statistiques
  usage_count integer DEFAULT 0 CHECK (usage_count >= 0),
  last_used timestamp with time zone,
  is_primary_language boolean DEFAULT false,
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT multilingual_voice_configuration_pkey PRIMARY KEY (id),
  CONSTRAINT multilingual_voice_configuration_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  CONSTRAINT unique_user_language UNIQUE (user_id, language_code)
);

-- Table pour l'avatar temps réel et synchronisation
CREATE TABLE IF NOT EXISTS public.realtime_avatar_state (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- État émotionnel actuel
  current_emotion text NOT NULL CHECK (current_emotion = ANY (ARRAY[
    'neutral'::text, 'happy'::text, 'sad'::text, 'angry'::text, 'surprised'::text,
    'calm'::text, 'excited'::text, 'confused'::text, 'focused'::text
  ])),
  emotion_intensity real NOT NULL CHECK (emotion_intensity >= 0 AND emotion_intensity <= 1),
  emotion_confidence real NOT NULL CHECK (emotion_confidence >= 0 AND emotion_confidence <= 1),
  
  -- Animation et synchronisation
  current_animation text,
  animation_duration_ms integer CHECK (animation_duration_ms >= 0),
  lip_sync_data jsonb DEFAULT '[]'::jsonb,
  facial_expression_data jsonb DEFAULT '{}'::jsonb,
  
  -- Contexte conversationnel
  conversation_context text,
  voice_activity_level real DEFAULT 0.0 CHECK (voice_activity_level >= 0 AND voice_activity_level <= 1),
  speaking_detected boolean DEFAULT false,
  
  -- Timing et synchronisation
  emotion_change_timestamp timestamp with time zone DEFAULT now(),
  last_sync_timestamp timestamp with time zone DEFAULT now(),
  next_contextual_trigger timestamp with time zone,
  
  -- Configuration
  real_time_updates_enabled boolean DEFAULT true,
  emotion_smoothing_enabled boolean DEFAULT true,
  contextual_triggers_enabled boolean DEFAULT true,
  
  -- Métadonnées
  state_duration_seconds integer DEFAULT 0 CHECK (state_duration_seconds >= 0),
  transition_count integer DEFAULT 0 CHECK (transition_count >= 0),
  
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT realtime_avatar_state_pkey PRIMARY KEY (id),
  CONSTRAINT realtime_avatar_state_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour les logs d'événements vocaux
CREATE TABLE IF NOT EXISTS public.voice_system_events (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  
  -- Type d'événement
  event_type text NOT NULL CHECK (event_type = ANY (ARRAY[
    'voice_emotion_detected'::text, 'voice_effect_applied'::text, 'contextual_memory_stored'::text,
    'karaoke_calibrated'::text, 'secret_command_executed'::text, 'language_switched'::text,
    'avatar_emotion_changed'::text, 'real_time_analysis_started'::text, 'real_time_analysis_stopped'::text,
    'system_error'::text, 'performance_warning'::text
  ])),
  event_category text NOT NULL CHECK (event_category = ANY (ARRAY[
    'emotion_detection'::text, 'voice_effects'::text, 'contextual_memory'::text,
    'karaoke_calibration'::text, 'secret_commands'::text, 'multilingual'::text,
    'avatar_realtime'::text, 'system'::text
  ])),
  
  -- Données de l'événement
  event_data jsonb DEFAULT '{}'::jsonb,
  event_severity text DEFAULT 'info'::text CHECK (event_severity = ANY (ARRAY[
    'debug'::text, 'info'::text, 'warning'::text, 'error'::text, 'critical'::text
  ])),
  event_message text,
  
  -- Contexte
  session_id uuid,
  conversation_id uuid,
  processing_time_ms integer CHECK (processing_time_ms >= 0),
  
  -- Métadonnées
  device_info jsonb DEFAULT '{}'::jsonb,
  app_version text,
  
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_system_events_pkey PRIMARY KEY (id),
  CONSTRAINT voice_system_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- =============================================
-- TABLES DE SUPPORT ET CONFIGURATION
-- =============================================

-- Table pour les sessions de service vocal
CREATE TABLE IF NOT EXISTS public.voice_service_sessions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  session_type text NOT NULL CHECK (session_type = ANY (ARRAY[
    'voice_interaction'::text, 'emotion_detection'::text, 'karaoke_calibration'::text,
    'voice_effects'::text, 'multilingual'::text, 'avatar_realtime'::text
  ])),
  
  -- Données de session
  session_start timestamp with time zone DEFAULT now(),
  session_end timestamp with time zone,
  session_duration_seconds integer CHECK (session_duration_seconds >= 0),
  
  -- Statistiques
  total_interactions integer DEFAULT 0 CHECK (total_interactions >= 0),
  successful_operations integer DEFAULT 0 CHECK (successful_operations >= 0),
  failed_operations integer DEFAULT 0 CHECK (failed_operations >= 0),
  average_response_time_ms integer CHECK (average_response_time_ms >= 0),
  
  -- Configuration de session
  session_config jsonb DEFAULT '{}'::jsonb,
  user_satisfaction_score real CHECK (user_satisfaction_score >= 1 AND user_satisfaction_score <= 5),
  session_notes text,
  
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_service_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT voice_service_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON DELETE CASCADE
);

-- Table pour la configuration globale du système vocal
CREATE TABLE IF NOT EXISTS public.voice_system_configuration (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  
  -- Configuration générale
  system_version text NOT NULL DEFAULT '3.0.0',
  voice_ai_enabled boolean DEFAULT true,
  real_time_processing_enabled boolean DEFAULT true,
  
  -- Limites et seuils
  max_audio_duration_seconds integer DEFAULT 300 CHECK (max_audio_duration_seconds > 0),
  max_memory_retention_minutes integer DEFAULT 30 CHECK (max_memory_retention_minutes > 0),
  max_concurrent_sessions integer DEFAULT 10 CHECK (max_concurrent_sessions > 0),
  
  -- Performance
  processing_timeout_ms integer DEFAULT 5000 CHECK (processing_timeout_ms > 0),
  cache_retention_hours integer DEFAULT 24 CHECK (cache_retention_hours > 0),
  
  -- Sécurité
  encryption_enabled boolean DEFAULT true,
  audit_logging_enabled boolean DEFAULT true,
  data_retention_days integer DEFAULT 90 CHECK (data_retention_days > 0),
  
  -- Configuration mise à jour
  config_updated_at timestamp with time zone DEFAULT now(),
  config_updated_by text DEFAULT 'system',
  
  created_at timestamp with time zone DEFAULT now(),
  
  CONSTRAINT voice_system_configuration_pkey PRIMARY KEY (id)
);

-- =============================================
-- MISE À JOUR DES TABLES EXISTANTES
-- =============================================

-- Ajout de colonnes manquantes à user_profiles pour le système vocal IA
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS voice_emotion_detection_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS voice_effects_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS contextual_memory_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS karaoke_mode_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS secret_commands_enabled boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS multilingual_mode_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS realtime_avatar_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS voice_ai_strictness_level integer DEFAULT 3 CHECK (voice_ai_strictness_level >= 1 AND voice_ai_strictness_level <= 5),
ADD COLUMN IF NOT EXISTS preferred_voice_emotion_sensitivity text DEFAULT 'medium'::text CHECK (preferred_voice_emotion_sensitivity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
ADD COLUMN IF NOT EXISTS voice_training_completed boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS voice_training_accuracy real CHECK (voice_training_accuracy >= 0 AND voice_training_accuracy <= 1);

-- Mise à jour de la table conversations pour inclure le contexte vocal
ALTER TABLE public.conversations 
ADD COLUMN IF NOT EXISTS voice_context jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS primary_language text DEFAULT 'fr'::text,
ADD COLUMN IF NOT EXISTS emotion_analysis_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS voice_effects_used jsonb DEFAULT '[]'::jsonb;

-- Mise à jour de la table messages pour le système vocal IA
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS voice_emotion_detected text,
ADD COLUMN IF NOT EXISTS voice_emotion_confidence real CHECK (voice_emotion_confidence >= 0 AND voice_emotion_confidence <= 1),
ADD COLUMN IF NOT EXISTS voice_characteristics jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS voice_effect_applied text,
ADD COLUMN IF NOT EXISTS contextual_memory_id uuid,
ADD COLUMN IF NOT EXISTS multilingual_data jsonb DEFAULT '{}'::jsonb;

-- =============================================
-- INDEX POUR PERFORMANCE
-- =============================================

-- Index pour la détection d'émotion vocale
CREATE INDEX IF NOT EXISTS idx_voice_emotion_detection_user_id ON public.voice_emotion_detection(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_emotion_detection_timestamp ON public.voice_emotion_detection(created_at);
CREATE INDEX IF NOT EXISTS idx_voice_emotion_detection_emotion ON public.voice_emotion_detection(primary_emotion);
CREATE INDEX IF NOT EXISTS idx_voice_emotion_detection_session ON public.voice_emotion_detection(detection_session_id);

-- Index pour la mémoire contextuelle
CREATE INDEX IF NOT EXISTS idx_contextual_memory_user_id ON public.contextual_conversation_memory(user_id);
CREATE INDEX IF NOT EXISTS idx_contextual_memory_retention ON public.contextual_conversation_memory(retention_until);
CREATE INDEX IF NOT EXISTS idx_contextual_memory_session ON public.contextual_conversation_memory(conversation_session_id);
CREATE INDEX IF NOT EXISTS idx_contextual_memory_timestamp ON public.contextual_conversation_memory(conversation_timestamp);

-- Index pour les événements système
CREATE INDEX IF NOT EXISTS idx_voice_events_user_id ON public.voice_system_events(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_events_type ON public.voice_system_events(event_type);
CREATE INDEX IF NOT EXISTS idx_voice_events_timestamp ON public.voice_system_events(created_at);
CREATE INDEX IF NOT EXISTS idx_voice_events_severity ON public.voice_system_events(event_severity);

-- Index pour les sessions
CREATE INDEX IF NOT EXISTS idx_voice_sessions_user_id ON public.voice_service_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_type ON public.voice_service_sessions(session_type);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_start ON public.voice_service_sessions(session_start);

-- Index pour la configuration multilingue
CREATE INDEX IF NOT EXISTS idx_multilingual_user_lang ON public.multilingual_voice_configuration(user_id, language_code);
CREATE INDEX IF NOT EXISTS idx_multilingual_primary ON public.multilingual_voice_configuration(user_id, is_primary_language);

-- Index pour l'état avatar temps réel
CREATE INDEX IF NOT EXISTS idx_avatar_state_user_id ON public.realtime_avatar_state(user_id);
CREATE INDEX IF NOT EXISTS idx_avatar_state_emotion ON public.realtime_avatar_state(current_emotion);
CREATE INDEX IF NOT EXISTS idx_avatar_state_timestamp ON public.realtime_avatar_state(updated_at);

-- =============================================
-- FONCTIONS DE NETTOYAGE AUTOMATIQUE
-- =============================================

-- Fonction pour nettoyer la mémoire contextuelle expirée
CREATE OR REPLACE FUNCTION cleanup_expired_contextual_memory()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
BEGIN
    DELETE FROM public.contextual_conversation_memory 
    WHERE retention_until < now() AND is_important = false;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    INSERT INTO public.voice_system_events (user_id, event_type, event_category, event_message, event_data)
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        'system_cleanup',
        'system',
        'Nettoyage mémoire contextuelle expirée',
        jsonb_build_object('deleted_records', deleted_count)
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour nettoyer les anciens logs d'événements
CREATE OR REPLACE FUNCTION cleanup_old_voice_events()
RETURNS integer AS $$
DECLARE
    deleted_count integer;
    retention_days integer;
BEGIN
    -- Récupérer la période de rétention depuis la configuration
    SELECT data_retention_days INTO retention_days 
    FROM public.voice_system_configuration 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF retention_days IS NULL THEN
        retention_days := 90; -- Valeur par défaut
    END IF;
    
    DELETE FROM public.voice_system_events 
    WHERE created_at < (now() - (retention_days || ' days')::interval);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- TRIGGERS POUR MISE À JOUR AUTOMATIQUE
-- =============================================

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables avec updated_at
DROP TRIGGER IF EXISTS update_voice_emotion_profiles_updated_at ON public.voice_emotion_profiles;
CREATE TRIGGER update_voice_emotion_profiles_updated_at
    BEFORE UPDATE ON public.voice_emotion_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_voice_effects_updated_at ON public.voice_effects_configuration;
CREATE TRIGGER update_voice_effects_updated_at
    BEFORE UPDATE ON public.voice_effects_configuration
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_karaoke_calibration_updated_at ON public.karaoke_vocal_calibration;
CREATE TRIGGER update_karaoke_calibration_updated_at
    BEFORE UPDATE ON public.karaoke_vocal_calibration
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_secret_commands_updated_at ON public.secret_commands_security;
CREATE TRIGGER update_secret_commands_updated_at
    BEFORE UPDATE ON public.secret_commands_security
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_multilingual_config_updated_at ON public.multilingual_voice_configuration;
CREATE TRIGGER update_multilingual_config_updated_at
    BEFORE UPDATE ON public.multilingual_voice_configuration
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_avatar_state_updated_at ON public.realtime_avatar_state;
CREATE TRIGGER update_avatar_state_updated_at
    BEFORE UPDATE ON public.realtime_avatar_state
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- VUES POUR ANALYSES ET REPORTING
-- =============================================

-- Vue pour les statistiques d'émotion par utilisateur
CREATE OR REPLACE VIEW voice_emotion_stats AS
SELECT 
    u.id as user_id,
    u.first_name,
    COUNT(ved.*) as total_detections,
    AVG(ved.emotion_confidence) as avg_confidence,
    AVG(ved.emotion_intensity) as avg_intensity,
    ved.primary_emotion,
    COUNT(ved.primary_emotion) as emotion_count,
    DATE_TRUNC('day', ved.created_at) as detection_date
FROM public.user_profiles u
LEFT JOIN public.voice_emotion_detection ved ON u.id = ved.user_id
WHERE ved.created_at >= (now() - interval '30 days')
GROUP BY u.id, u.first_name, ved.primary_emotion, DATE_TRUNC('day', ved.created_at)
ORDER BY detection_date DESC, emotion_count DESC;

-- Vue pour l'utilisation des services vocaux
CREATE OR REPLACE VIEW voice_services_usage AS
SELECT 
    u.id as user_id,
    u.first_name,
    vss.session_type,
    COUNT(vss.*) as total_sessions,
    AVG(vss.session_duration_seconds) as avg_duration_seconds,
    AVG(vss.successful_operations::numeric / NULLIF(vss.total_interactions, 0)) as success_rate,
    MAX(vss.session_start) as last_session
FROM public.user_profiles u
LEFT JOIN public.voice_service_sessions vss ON u.id = vss.user_id
WHERE vss.session_start >= (now() - interval '7 days')
GROUP BY u.id, u.first_name, vss.session_type
ORDER BY total_sessions DESC;

-- =============================================
-- CONFIGURATION INITIALE
-- =============================================

-- Insérer la configuration système par défaut
INSERT INTO public.voice_system_configuration (
    system_version,
    voice_ai_enabled,
    real_time_processing_enabled,
    max_audio_duration_seconds,
    max_memory_retention_minutes,
    max_concurrent_sessions,
    processing_timeout_ms,
    cache_retention_hours,
    encryption_enabled,
    audit_logging_enabled,
    data_retention_days
) VALUES (
    '3.0.0',
    true,
    true,
    300,
    30,
    10,
    5000,
    24,
    true,
    true,
    90
) ON CONFLICT DO NOTHING;

-- =============================================
-- COMMANDES DE VALIDATION
-- =============================================

-- Vérifier l'intégrité des données
DO $$
DECLARE
    table_count integer;
    index_count integer;
    trigger_count integer;
BEGIN
    -- Compter les nouvelles tables
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN (
        'voice_emotion_detection',
        'voice_emotion_profiles', 
        'voice_effects_configuration',
        'contextual_conversation_memory',
        'karaoke_vocal_calibration',
        'secret_commands_security',
        'multilingual_voice_configuration',
        'realtime_avatar_state',
        'voice_system_events',
        'voice_service_sessions',
        'voice_system_configuration'
    );
    
    -- Compter les index
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_voice_%' OR indexname LIKE 'idx_contextual_%' OR indexname LIKE 'idx_multilingual_%' OR indexname LIKE 'idx_avatar_%';
    
    -- Compter les triggers
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers 
    WHERE trigger_schema = 'public' 
    AND trigger_name LIKE '%voice_%' OR trigger_name LIKE '%multilingual_%' OR trigger_name LIKE '%avatar_%';
    
    RAISE NOTICE 'Validation du système vocal IA:';
    RAISE NOTICE '- Tables créées: % sur 11 attendues', table_count;
    RAISE NOTICE '- Index créés: %', index_count;
    RAISE NOTICE '- Triggers créés: %', trigger_count;
    
    IF table_count = 11 THEN
        RAISE NOTICE '✅ SYSTÈME VOCAL IA CONFIGURÉ AVEC SUCCÈS';
    ELSE
        RAISE WARNING '⚠️ Certaines tables n''ont pas été créées correctement';
    END IF;
END $$;

-- =============================================
-- SCRIPT COMPLET TERMINÉ
-- =============================================

COMMIT;
