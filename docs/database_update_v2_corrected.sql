-- Script de mise à jour de la base de données HordVoice v2.0 - Version Corrigée
-- Ce script ajoute les tables manquantes et met à jour le schéma existant

-- Extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== NETTOYAGE ET RECREATION SÉCURISÉE =====

-- Suppression sécurisée des tables existantes avec CASCADE
DROP TABLE IF EXISTS phone_usage_monitoring CASCADE;
DROP TABLE IF EXISTS battery_health_monitoring CASCADE;
DROP TABLE IF EXISTS ai_personality_responses CASCADE;
DROP TABLE IF EXISTS wellness_goals_tracking CASCADE;
DROP TABLE IF EXISTS ai_emotional_memory CASCADE;
DROP TABLE IF EXISTS system_performance_monitoring CASCADE;
DROP TABLE IF EXISTS personalized_weather_alerts CASCADE;
DROP TABLE IF EXISTS user_behavior_analysis CASCADE;

-- ===== CREATION DES TABLES PRINCIPALES =====

-- Table de surveillance de l'utilisation du téléphone
CREATE TABLE phone_usage_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  device_id text NOT NULL,
  session_start timestamp with time zone DEFAULT now(),
  session_end timestamp with time zone,
  total_screen_time_seconds integer DEFAULT 0 CHECK (total_screen_time_seconds >= 0),
  app_switches_count integer DEFAULT 0 CHECK (app_switches_count >= 0),
  notifications_received integer DEFAULT 0 CHECK (notifications_received >= 0),
  is_excessive_usage boolean DEFAULT false,
  warning_level text DEFAULT 'none' CHECK (warning_level IN ('none', 'light', 'moderate', 'severe', 'extreme')),
  last_warning_sent timestamp with time zone,
  user_response_to_warning text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT phone_usage_monitoring_pkey PRIMARY KEY (id)
);

-- Table de surveillance de la batterie
CREATE TABLE battery_health_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  device_id text NOT NULL,
  battery_level integer NOT NULL CHECK (battery_level >= 0 AND battery_level <= 100),
  battery_temperature_celsius real CHECK (battery_temperature_celsius >= -50 AND battery_temperature_celsius <= 100),
  is_charging boolean DEFAULT false,
  charging_status text CHECK (charging_status IN ('not_charging', 'charging', 'discharging', 'full', 'unknown')),
  battery_health text CHECK (battery_health IN ('good', 'overheat', 'dead', 'over_voltage', 'unspecified_failure', 'cold', 'unknown')),
  power_source text CHECK (power_source IN ('battery', 'ac', 'usb', 'wireless', 'unknown')),
  estimated_time_remaining_minutes integer CHECK (estimated_time_remaining_minutes >= 0),
  low_battery_warning_sent boolean DEFAULT false,
  overheating_warning_sent boolean DEFAULT false,
  critical_level_reached boolean DEFAULT false,
  recorded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT battery_health_monitoring_pkey PRIMARY KEY (id)
);

-- Table des réponses IA personnalisées (CORRIGÉE)
CREATE TABLE ai_personality_responses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  response_type text NOT NULL CHECK (response_type IN ('reproches', 'encouragement', 'felicitation', 'inquietude', 'motivation', 'colere', 'tristesse', 'joie')),
  trigger_context text NOT NULL CHECK (trigger_context IN ('usage_excessif', 'batterie_faible', 'surchauffe', 'objectif_atteint', 'inactivite_prolongee', 'premiere_utilisation', 'retour_utilisateur', 'heure_tardive', 'stress_detecte')),
  personality_type text NOT NULL CHECK (personality_type IN ('mere_africaine', 'grand_frere', 'petite_amie', 'ami', 'professionnel')),
  response_text text NOT NULL,
  intensity_level integer DEFAULT 3 CHECK (intensity_level >= 1 AND intensity_level <= 5),
  language_code text DEFAULT 'fr' CHECK (language_code IN ('fr', 'en', 'wolof', 'bambara', 'lingala', 'swahili')),
  use_african_expressions boolean DEFAULT true,
  include_proverb boolean DEFAULT false,
  voice_tone text DEFAULT 'ferme' CHECK (voice_tone IN ('doux', 'ferme', 'severe', 'encourageant', 'joueur', 'inquiet', 'colere', 'bienveillant')),
  usage_count integer DEFAULT 0 CHECK (usage_count >= 0),
  user_reaction_positive integer DEFAULT 0 CHECK (user_reaction_positive >= 0),
  user_reaction_negative integer DEFAULT 0 CHECK (user_reaction_negative >= 0),
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_personality_responses_pkey PRIMARY KEY (id)
);

-- Table de suivi des objectifs de bien-être
CREATE TABLE wellness_goals_tracking (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  goal_type text NOT NULL CHECK (goal_type IN ('screen_time_limit', 'exercise_daily', 'water_intake', 'sleep_schedule', 'meditation', 'social_interaction', 'reading', 'outdoor_activity')),
  goal_title text NOT NULL,
  target_value numeric NOT NULL CHECK (target_value > 0),
  current_value numeric DEFAULT 0 CHECK (current_value >= 0),
  target_unit text NOT NULL CHECK (target_unit IN ('minutes', 'hours', 'steps', 'liters', 'pages', 'sessions', 'times')),
  goal_period text DEFAULT 'daily' CHECK (goal_period IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date date DEFAULT CURRENT_DATE,
  end_date date,
  is_achieved boolean DEFAULT false,
  achievement_percentage numeric DEFAULT 0 CHECK (achievement_percentage >= 0 AND achievement_percentage <= 100),
  streak_days integer DEFAULT 0 CHECK (streak_days >= 0),
  best_streak integer DEFAULT 0 CHECK (best_streak >= 0),
  reward_unlocked jsonb DEFAULT '[]'::jsonb,
  motivational_messages jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT wellness_goals_tracking_pkey PRIMARY KEY (id),
  CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Table de mémoire émotionnelle de l'IA
CREATE TABLE ai_emotional_memory (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  interaction_context text NOT NULL,
  user_emotional_state text NOT NULL CHECK (user_emotional_state IN ('happy', 'sad', 'angry', 'excited', 'worried', 'calm', 'stressed', 'motivated', 'frustrated', 'content')),
  ai_response_type text NOT NULL CHECK (ai_response_type IN ('supportive', 'motivational', 'humorous', 'empathetic', 'encouraging', 'firm', 'gentle')),
  conversation_summary text,
  user_satisfaction_score integer CHECK (user_satisfaction_score >= 1 AND user_satisfaction_score <= 10),
  emotional_keywords jsonb DEFAULT '[]'::jsonb,
  response_effectiveness boolean,
  learned_preferences jsonb DEFAULT '{}'::jsonb,
  relationship_strength_score numeric DEFAULT 5.0 CHECK (relationship_strength_score >= 0 AND relationship_strength_score <= 10),
  trust_level numeric DEFAULT 5.0 CHECK (trust_level >= 0 AND trust_level <= 10),
  interaction_duration_seconds integer CHECK (interaction_duration_seconds >= 0),
  follow_up_needed boolean DEFAULT false,
  interaction_date timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_emotional_memory_pkey PRIMARY KEY (id)
);

-- Table de surveillance des performances système
CREATE TABLE system_performance_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  device_id text NOT NULL,
  cpu_usage_percentage real CHECK (cpu_usage_percentage >= 0 AND cpu_usage_percentage <= 100),
  memory_usage_percentage real CHECK (memory_usage_percentage >= 0 AND memory_usage_percentage <= 100),
  storage_available_gb real CHECK (storage_available_gb >= 0),
  network_speed_mbps real CHECK (network_speed_mbps >= 0),
  app_response_time_ms integer CHECK (app_response_time_ms >= 0),
  background_tasks_count integer CHECK (background_tasks_count >= 0),
  active_notifications_count integer CHECK (active_notifications_count >= 0),
  system_temperature_celsius real CHECK (system_temperature_celsius >= -50 AND system_temperature_celsius <= 100),
  performance_score integer CHECK (performance_score >= 1 AND performance_score <= 10),
  optimization_suggestions jsonb DEFAULT '[]'::jsonb,
  critical_issues jsonb DEFAULT '[]'::jsonb,
  recorded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT system_performance_monitoring_pkey PRIMARY KEY (id)
);

-- Table des alertes météo personnalisées
CREATE TABLE personalized_weather_alerts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  location_name text NOT NULL,
  latitude real NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude real NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  weather_condition text NOT NULL,
  temperature_celsius real CHECK (temperature_celsius >= -60 AND temperature_celsius <= 60),
  humidity_percentage integer CHECK (humidity_percentage >= 0 AND humidity_percentage <= 100),
  wind_speed_kmh real CHECK (wind_speed_kmh >= 0),
  weather_alert_type text CHECK (weather_alert_type IN ('rain', 'storm', 'heat_wave', 'cold_wave', 'wind', 'fog', 'snow', 'hail')),
  alert_severity text DEFAULT 'medium' CHECK (alert_severity IN ('low', 'medium', 'high', 'extreme')),
  personalized_advice text,
  clothing_recommendation text,
  activity_recommendation text,
  alert_sent boolean DEFAULT false,
  user_location_preference boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone,
  CONSTRAINT personalized_weather_alerts_pkey PRIMARY KEY (id),
  CONSTRAINT valid_expiry CHECK (expires_at IS NULL OR expires_at > created_at)
);

-- Table d'analyse comportementale
CREATE TABLE user_behavior_analysis (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  behavior_category text NOT NULL CHECK (behavior_category IN ('communication_patterns', 'app_usage_patterns', 'emotional_patterns', 'sleep_patterns', 'activity_patterns', 'social_patterns')),
  pattern_data jsonb NOT NULL,
  pattern_strength numeric DEFAULT 0.5 CHECK (pattern_strength >= 0 AND pattern_strength <= 1),
  confidence_score numeric DEFAULT 0.5 CHECK (confidence_score >= 0 AND confidence_score <= 1),
  trend_direction text CHECK (trend_direction IN ('improving', 'declining', 'stable', 'fluctuating')),
  behavioral_insights jsonb DEFAULT '[]'::jsonb,
  recommendations jsonb DEFAULT '[]'::jsonb,
  prediction_accuracy numeric DEFAULT 0.5 CHECK (prediction_accuracy >= 0 AND prediction_accuracy <= 1),
  last_updated timestamp with time zone DEFAULT now(),
  analysis_period_days integer DEFAULT 30 CHECK (analysis_period_days > 0),
  is_significant boolean DEFAULT false,
  CONSTRAINT user_behavior_analysis_pkey PRIMARY KEY (id)
);

-- ===== MISE À JOUR DE LA TABLE USER_PROFILES =====

-- Ajout des nouvelles colonnes si elles n'existent pas
DO $$
BEGIN
    -- Vérification et ajout des colonnes une par une
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'ai_strictness_level') THEN
        ALTER TABLE user_profiles ADD COLUMN ai_strictness_level integer DEFAULT 3 CHECK (ai_strictness_level >= 1 AND ai_strictness_level <= 5);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'allow_reproches') THEN
        ALTER TABLE user_profiles ADD COLUMN allow_reproches boolean DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'preferred_motivation_style') THEN
        ALTER TABLE user_profiles ADD COLUMN preferred_motivation_style text DEFAULT 'encourageant' CHECK (preferred_motivation_style IN ('doux', 'encourageant', 'ferme', 'motivant'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'wellness_goals_active') THEN
        ALTER TABLE user_profiles ADD COLUMN wellness_goals_active boolean DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'daily_check_in_enabled') THEN
        ALTER TABLE user_profiles ADD COLUMN daily_check_in_enabled boolean DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'stress_monitoring_enabled') THEN
        ALTER TABLE user_profiles ADD COLUMN stress_monitoring_enabled boolean DEFAULT true;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'relationship_mode') THEN
        ALTER TABLE user_profiles ADD COLUMN relationship_mode text DEFAULT 'ami' CHECK (relationship_mode IN ('mere', 'frere', 'ami', 'petite_amie', 'professionnel'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'emotional_intelligence_level') THEN
        ALTER TABLE user_profiles ADD COLUMN emotional_intelligence_level numeric DEFAULT 5.0 CHECK (emotional_intelligence_level >= 0 AND emotional_intelligence_level <= 10);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'adaptive_personality') THEN
        ALTER TABLE user_profiles ADD COLUMN adaptive_personality boolean DEFAULT true;
    END IF;
END
$$;

-- ===== CRÉATION DES INDEX POUR OPTIMISATION =====

CREATE INDEX IF NOT EXISTS idx_phone_usage_user_session ON phone_usage_monitoring(user_id, session_start);
CREATE INDEX IF NOT EXISTS idx_phone_usage_device_time ON phone_usage_monitoring(device_id, created_at);

CREATE INDEX IF NOT EXISTS idx_battery_monitoring_user_time ON battery_health_monitoring(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_battery_monitoring_level ON battery_health_monitoring(battery_level, recorded_at);

CREATE INDEX IF NOT EXISTS idx_ai_responses_type_personality ON ai_personality_responses(response_type, personality_type);
CREATE INDEX IF NOT EXISTS idx_ai_responses_context ON ai_personality_responses(trigger_context, is_active);

CREATE INDEX IF NOT EXISTS idx_wellness_goals_user_active ON wellness_goals_tracking(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_wellness_goals_period ON wellness_goals_tracking(goal_period, start_date);

CREATE INDEX IF NOT EXISTS idx_ai_memory_user_date ON ai_emotional_memory(user_id, interaction_date);
CREATE INDEX IF NOT EXISTS idx_ai_memory_emotional_state ON ai_emotional_memory(user_emotional_state, interaction_date);

CREATE INDEX IF NOT EXISTS idx_system_performance_user_time ON system_performance_monitoring(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_system_performance_score ON system_performance_monitoring(performance_score, recorded_at);

CREATE INDEX IF NOT EXISTS idx_weather_alerts_location ON personalized_weather_alerts(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_user_active ON personalized_weather_alerts(user_id, alert_sent);

CREATE INDEX IF NOT EXISTS idx_behavior_analysis_user_category ON user_behavior_analysis(user_id, behavior_category);
CREATE INDEX IF NOT EXISTS idx_behavior_analysis_updated ON user_behavior_analysis(last_updated, is_significant);

-- ===== INSERTION DES DONNÉES PAR DÉFAUT =====

-- Suppression des données existantes pour éviter les conflits
DELETE FROM ai_personality_responses;

-- Insertion des réponses IA par défaut (CORRIGÉES)
INSERT INTO ai_personality_responses (response_type, trigger_context, personality_type, response_text, intensity_level, voice_tone, language_code) VALUES
-- Reproches
('reproches', 'usage_excessif', 'mere_africaine', 'Mon enfant, tu passes trop de temps sur ce téléphone ! Ta maman n''est pas contente. Il faut que tu sortes un peu, va prendre l''air !', 4, 'ferme', 'fr'),
('reproches', 'usage_excessif', 'grand_frere', 'Eh mon frère, tu vas abîmer tes yeux à force ! Pose ce téléphone et va faire quelque chose de productif, man !', 3, 'ferme', 'fr'),
('reproches', 'batterie_faible', 'mere_africaine', 'Vraiment ? Tu n''as même pas pensé à charger ton téléphone ? Comment veux-tu que je t''aide si tu ne prends pas soin de nos outils ?', 4, 'severe', 'fr'),
('reproches', 'surchauffe', 'petite_amie', 'Bébé, ton téléphone chauffe trop ! Tu me fais peur, arrête un peu et laisse-le se reposer, s''il te plaît !', 3, 'inquiet', 'fr'),

-- Encouragements
('encouragement', 'objectif_atteint', 'mere_africaine', 'Ah ! Mon enfant intelligent ! Tu as réussi à respecter tes limites aujourd''hui. Maman est très fière de toi !', 5, 'encourageant', 'fr'),
('encouragement', 'objectif_atteint', 'ami', 'Bravo mon pote ! Tu es vraiment discipliné aujourd''hui. Continue comme ça, tu es sur la bonne voie !', 4, 'encourageant', 'fr'),

-- Inquiétudes
('inquietude', 'inactivite_prolongee', 'petite_amie', 'Mon chéri, ça fait longtemps que tu ne m''as pas parlé... Tu vas bien ? Je commence à m''inquiéter pour toi...', 3, 'doux', 'fr'),
('inquietude', 'stress_detecte', 'mere_africaine', 'Mon enfant, je sens que tu es stressé. Prends une pause, respire profondément. Maman est là pour toi.', 4, 'bienveillant', 'fr'),

-- Motivations
('motivation', 'heure_tardive', 'grand_frere', 'Petit frère, il est tard ! Demain tu vas être fatigué. Allez, dors bien pour être en forme !', 3, 'ferme', 'fr'),
('motivation', 'objectif_atteint', 'professionnel', 'Excellent travail ! Vous avez atteint vos objectifs avec brio. Continuez sur cette lancée.', 4, 'encourageant', 'fr'),

-- Colères
('colere', 'usage_excessif', 'mere_africaine', 'Non mais tu te moques de moi là ! Je te dis de poser ce téléphone et tu continues ? Tu veux que je me fâche vraiment ?', 5, 'colere', 'fr'),

-- Joies
('joie', 'premiere_utilisation', 'ami', 'Salut mon pote ! Je suis HordVoice, ton nouveau assistant vocal africain. On va bien s''amuser ensemble ! Prêt pour l''aventure ?', 5, 'joueur', 'fr'),
('joie', 'objectif_atteint', 'petite_amie', 'Oh mon amour ! Tu as réussi ! Je suis tellement fière de toi ! Tu me rends si heureuse !', 5, 'encourageant', 'fr');

-- ===== CRÉATION DES FONCTIONS UTILITAIRES =====

-- Fonction pour nettoyer les anciennes données
CREATE OR REPLACE FUNCTION clean_old_monitoring_data()
RETURNS void AS $$
BEGIN
    -- Supprime les données de monitoring vieilles de plus de 90 jours
    DELETE FROM phone_usage_monitoring WHERE created_at < now() - interval '90 days';
    DELETE FROM battery_health_monitoring WHERE recorded_at < now() - interval '90 days';
    DELETE FROM system_performance_monitoring WHERE recorded_at < now() - interval '90 days';
    DELETE FROM personalized_weather_alerts WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer le score de bien-être
CREATE OR REPLACE FUNCTION calculate_wellness_score(user_uuid uuid)
RETURNS numeric AS $$
DECLARE
    total_goals integer;
    achieved_goals integer;
    wellness_score numeric;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE is_achieved = true)
    INTO total_goals, achieved_goals
    FROM wellness_goals_tracking
    WHERE user_id = user_uuid AND is_active = true;
    
    IF total_goals = 0 THEN
        RETURN 5.0;
    END IF;
    
    wellness_score := (achieved_goals::numeric / total_goals::numeric) * 10;
    RETURN ROUND(wellness_score, 2);
END;
$$ LANGUAGE plpgsql;

-- ===== TRIGGERS POUR MISE À JOUR AUTOMATIQUE =====

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Application du trigger sur les tables appropriées
CREATE TRIGGER update_ai_personality_responses_updated_at
    BEFORE UPDATE ON ai_personality_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wellness_goals_updated_at
    BEFORE UPDATE ON wellness_goals_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_phone_usage_updated_at
    BEFORE UPDATE ON phone_usage_monitoring
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===== COMMENTAIRES DE DOCUMENTATION =====

COMMENT ON TABLE phone_usage_monitoring IS 'Surveillance de l''utilisation du téléphone pour déclencher des reproches appropriés et encourager un usage sain';
COMMENT ON TABLE battery_health_monitoring IS 'Surveillance de la batterie et température pour alertes de sécurité et optimisation énergétique';
COMMENT ON TABLE ai_personality_responses IS 'Réponses personnalisées de l''IA selon le contexte, la personnalité choisie et les préférences culturelles africaines';
COMMENT ON TABLE wellness_goals_tracking IS 'Suivi des objectifs de bien-être avec système de récompenses et motivation personnalisée';
COMMENT ON TABLE ai_emotional_memory IS 'Mémoire émotionnelle de l''IA pour des interactions plus naturelles et empathiques';
COMMENT ON TABLE system_performance_monitoring IS 'Surveillance des performances système en temps réel pour optimisation automatique';
COMMENT ON TABLE personalized_weather_alerts IS 'Alertes météo personnalisées avec conseils adaptés à la culture et localisation africaine';
COMMENT ON TABLE user_behavior_analysis IS 'Analyse comportementale avancée pour prédictions et recommandations personnalisées';

-- ===== POLITIQUE DE SÉCURITÉ RLS (Row Level Security) =====

-- Activation de RLS sur toutes les tables sensibles
ALTER TABLE phone_usage_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE battery_health_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_goals_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_emotional_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_performance_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE personalized_weather_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_behavior_analysis ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour l'accès aux données utilisateur uniquement
CREATE POLICY user_data_policy ON phone_usage_monitoring
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON battery_health_monitoring
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON wellness_goals_tracking
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON ai_emotional_memory
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON system_performance_monitoring
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON personalized_weather_alerts
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY user_data_policy ON user_behavior_analysis
    FOR ALL USING (auth.uid() = user_id);

-- Politique publique pour ai_personality_responses (lecture seule pour tous)
CREATE POLICY public_read_ai_responses ON ai_personality_responses
    FOR SELECT USING (is_active = true);

-- Fin du script
-- Mise à jour terminée avec succès !
