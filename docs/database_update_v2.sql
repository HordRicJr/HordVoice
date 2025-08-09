-- Script de mise à jour de la base de données HordVoice v2.0
-- Ce script ajoute les tables manquantes et met à jour le schéma existant

-- Extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table pour surveiller l'utilisation du téléphone et réprimander l'utilisateur
CREATE TABLE IF NOT EXISTS phone_usage_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  device_id text NOT NULL,
  session_start timestamp with time zone DEFAULT now(),
  session_end timestamp with time zone,
  total_screen_time_seconds integer DEFAULT 0,
  app_switches_count integer DEFAULT 0,
  notifications_received integer DEFAULT 0,
  is_excessive_usage boolean DEFAULT false,
  warning_level text DEFAULT 'none' CHECK (warning_level = ANY (ARRAY['none'::text, 'light'::text, 'moderate'::text, 'severe'::text, 'extreme'::text])),
  last_warning_sent timestamp with time zone,
  user_response_to_warning text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT phone_usage_monitoring_pkey PRIMARY KEY (id),
  CONSTRAINT phone_usage_monitoring_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour surveiller la batterie et alerter
CREATE TABLE IF NOT EXISTS battery_health_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  device_id text NOT NULL,
  battery_level integer NOT NULL CHECK (battery_level >= 0 AND battery_level <= 100),
  battery_temperature_celsius real,
  is_charging boolean DEFAULT false,
  charging_status text,
  battery_health text,
  power_source text,
  estimated_time_remaining_minutes integer,
  low_battery_warning_sent boolean DEFAULT false,
  overheating_warning_sent boolean DEFAULT false,
  critical_level_reached boolean DEFAULT false,
  recorded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT battery_health_monitoring_pkey PRIMARY KEY (id),
  CONSTRAINT battery_health_monitoring_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour les reproches et encouragements personnalisés
CREATE TABLE IF NOT EXISTS ai_personality_responses (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  response_type text NOT NULL CHECK (response_type = ANY (ARRAY['reproches'::text, 'encouragement'::text, 'felicitation'::text, 'inquietude'::text, 'motivation'::text, 'colere'::text, 'tristesse'::text, 'joie'::text])),
  trigger_context text NOT NULL CHECK (trigger_context = ANY (ARRAY['usage_excessif'::text, 'batterie_faible'::text, 'surchauffe'::text, 'objectif_atteint'::text, 'inactivite_prolongee'::text, 'premiere_utilisation'::text, 'retour_utilisateur'::text, 'heure_tardive'::text, 'stress_detecte'::text])),
  personality_type text NOT NULL CHECK (personality_type = ANY (ARRAY['mere_africaine'::text, 'grand_frere'::text, 'petite_amie'::text, 'ami'::text])),
  response_text text NOT NULL,
  intensity_level integer DEFAULT 3 CHECK (intensity_level >= 1 AND intensity_level <= 5),
  language_code text DEFAULT 'fr'::text,
  use_african_expressions boolean DEFAULT true,
  include_proverb boolean DEFAULT false,
  voice_tone text DEFAULT 'ferme' CHECK (voice_tone = ANY (ARRAY['doux'::text, 'ferme'::text, 'severe'::text, 'encourageant'::text, 'joueur'::text, 'inquiet'::text])),
  usage_count integer DEFAULT 0,
  user_reaction_positive integer DEFAULT 0,
  user_reaction_negative integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_personality_responses_pkey PRIMARY KEY (id)
);

-- Table pour les objectifs de bien-être et récompenses
CREATE TABLE IF NOT EXISTS wellness_goals_tracking (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  goal_type text NOT NULL CHECK (goal_type = ANY (ARRAY['screen_time_limit'::text, 'exercise_daily'::text, 'water_intake'::text, 'sleep_schedule'::text, 'meditation'::text, 'social_interaction'::text])),
  goal_title text NOT NULL,
  target_value numeric NOT NULL,
  current_value numeric DEFAULT 0,
  target_unit text NOT NULL,
  goal_period text DEFAULT 'daily' CHECK (goal_period = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text])),
  start_date date DEFAULT CURRENT_DATE,
  end_date date,
  is_achieved boolean DEFAULT false,
  achievement_percentage numeric DEFAULT 0,
  streak_days integer DEFAULT 0,
  best_streak integer DEFAULT 0,
  reward_unlocked jsonb DEFAULT '[]'::jsonb,
  motivational_messages jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT wellness_goals_tracking_pkey PRIMARY KEY (id),
  CONSTRAINT wellness_goals_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour les interactions IA avancées avec mémoire émotionnelle
CREATE TABLE IF NOT EXISTS ai_emotional_memory (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  interaction_context text NOT NULL,
  user_emotional_state text NOT NULL,
  ai_response_type text NOT NULL,
  conversation_summary text,
  user_satisfaction_score integer CHECK (user_satisfaction_score >= 1 AND user_satisfaction_score <= 10),
  emotional_keywords jsonb DEFAULT '[]'::jsonb,
  response_effectiveness boolean,
  learned_preferences jsonb DEFAULT '{}'::jsonb,
  relationship_strength_score numeric DEFAULT 5.0,
  trust_level numeric DEFAULT 5.0,
  interaction_duration_seconds integer,
  follow_up_needed boolean DEFAULT false,
  interaction_date timestamp with time zone DEFAULT now(),
  CONSTRAINT ai_emotional_memory_pkey PRIMARY KEY (id),
  CONSTRAINT ai_emotional_memory_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour les données de performance système en temps réel
CREATE TABLE IF NOT EXISTS system_performance_monitoring (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  device_id text NOT NULL,
  cpu_usage_percentage real,
  memory_usage_percentage real,
  storage_available_gb real,
  network_speed_mbps real,
  app_response_time_ms integer,
  background_tasks_count integer,
  active_notifications_count integer,
  system_temperature_celsius real,
  performance_score integer CHECK (performance_score >= 1 AND performance_score <= 10),
  optimization_suggestions jsonb DEFAULT '[]'::jsonb,
  critical_issues jsonb DEFAULT '[]'::jsonb,
  recorded_at timestamp with time zone DEFAULT now(),
  CONSTRAINT system_performance_monitoring_pkey PRIMARY KEY (id),
  CONSTRAINT system_performance_monitoring_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour les données météo personnalisées et alertes
CREATE TABLE IF NOT EXISTS personalized_weather_alerts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  location_name text NOT NULL,
  latitude real NOT NULL,
  longitude real NOT NULL,
  weather_condition text NOT NULL,
  temperature_celsius real,
  humidity_percentage integer,
  wind_speed_kmh real,
  weather_alert_type text CHECK (weather_alert_type = ANY (ARRAY['rain'::text, 'storm'::text, 'heat_wave'::text, 'cold_wave'::text, 'wind'::text, 'fog'::text])),
  alert_severity text DEFAULT 'medium' CHECK (alert_severity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'extreme'::text])),
  personalized_advice text,
  clothing_recommendation text,
  activity_recommendation text,
  alert_sent boolean DEFAULT false,
  user_location_preference boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone,
  CONSTRAINT personalized_weather_alerts_pkey PRIMARY KEY (id),
  CONSTRAINT personalized_weather_alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour l'analyse comportementale avancée
CREATE TABLE IF NOT EXISTS user_behavior_analysis (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid,
  behavior_category text NOT NULL CHECK (behavior_category = ANY (ARRAY['communication_patterns'::text, 'app_usage_patterns'::text, 'emotional_patterns'::text, 'sleep_patterns'::text, 'activity_patterns'::text, 'social_patterns'::text])),
  pattern_data jsonb NOT NULL,
  pattern_strength numeric DEFAULT 0.5,
  confidence_score numeric DEFAULT 0.5,
  trend_direction text CHECK (trend_direction = ANY (ARRAY['improving'::text, 'declining'::text, 'stable'::text, 'fluctuating'::text])),
  behavioral_insights jsonb DEFAULT '[]'::jsonb,
  recommendations jsonb DEFAULT '[]'::jsonb,
  prediction_accuracy numeric DEFAULT 0.5,
  last_updated timestamp with time zone DEFAULT now(),
  analysis_period_days integer DEFAULT 30,
  is_significant boolean DEFAULT false,
  CONSTRAINT user_behavior_analysis_pkey PRIMARY KEY (id),
  CONSTRAINT user_behavior_analysis_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Mise à jour de la table user_profiles pour inclure les nouveaux champs
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS ai_strictness_level integer DEFAULT 3 CHECK (ai_strictness_level >= 1 AND ai_strictness_level <= 5),
ADD COLUMN IF NOT EXISTS allow_reproaches boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS preferred_motivation_style text DEFAULT 'encourageant' CHECK (preferred_motivation_style = ANY (ARRAY['doux'::text, 'encourageant'::text, 'ferme'::text, 'motivant'::text])),
ADD COLUMN IF NOT EXISTS wellness_goals_active boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS daily_check_in_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS stress_monitoring_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS relationship_mode text DEFAULT 'ami' CHECK (relationship_mode = ANY (ARRAY['mere'::text, 'frere'::text, 'ami'::text, 'petite_amie'::text, 'professionnel'::text])),
ADD COLUMN IF NOT EXISTS emotional_intelligence_level numeric DEFAULT 5.0,
ADD COLUMN IF NOT EXISTS adaptive_personality boolean DEFAULT true;

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_phone_usage_user_session ON phone_usage_monitoring(user_id, session_start);
CREATE INDEX IF NOT EXISTS idx_battery_monitoring_user_time ON battery_health_monitoring(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_ai_responses_type_personality ON ai_personality_responses(response_type, personality_type);
CREATE INDEX IF NOT EXISTS idx_wellness_goals_user_active ON wellness_goals_tracking(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_ai_memory_user_date ON ai_emotional_memory(user_id, interaction_date);
CREATE INDEX IF NOT EXISTS idx_system_performance_user_time ON system_performance_monitoring(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_location ON personalized_weather_alerts(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_behavior_analysis_user_category ON user_behavior_analysis(user_id, behavior_category);

-- Insertion de données par défaut pour les réponses de l'IA
INSERT INTO ai_personality_responses (response_type, trigger_context, personality_type, response_text, intensity_level, voice_tone) VALUES
('reproches', 'usage_excessif', 'mere_africaine', 'Mon enfant, tu passes trop de temps sur ce téléphone ! Ta maman n''est pas contente. Il faut que tu sortes un peu, va prendre l''air !', 4, 'ferme'),
('reproches', 'usage_excessif', 'grand_frere', 'Eh mon frère, tu vas abîmer tes yeux à force ! Pose ce téléphone et va faire quelque chose de productif, man !', 3, 'ferme'),
('reproches', 'batterie_faible', 'mere_africaine', 'Vraiment ? Tu n''as même pas pensé à charger ton téléphone ? Comment veux-tu que je t''aide si tu ne prends pas soin de nos outils ?', 4, 'severe'),
('reproches', 'surchauffe', 'petite_amie', 'Bébé, ton téléphone chauffe trop ! Tu me fais peur, arrête un peu et laisse-le se reposer, s''il te plaît !', 3, 'inquiet'),
('encouragement', 'objectif_atteint', 'mere_africaine', 'Ah ! Mon enfant intelligent ! Tu as réussi à respecter tes limites aujourd''hui. Maman est très fière de toi !', 5, 'encourageant'),
('felicitation', 'objectif_atteint', 'ami', 'Bravo mon pote ! Tu es vraiment discipliné aujourd''hui. Continue comme ça, tu es sur la bonne voie !', 4, 'encourageant'),
('inquietude', 'inactivite_prolongee', 'petite_amie', 'Mon chéri, ça fait longtemps que tu ne m''as pas parlé... Tu vas bien ? Je commence à m''inquiéter pour toi...', 3, 'doux'),
('motivation', 'heure_tardive', 'grand_frere', 'Petit frère, il est tard ! Demain tu vas être fatigué. Allez, dors bien pour être en forme !', 3, 'ferme'),
('colere', 'usage_excessif', 'mere_africaine', 'Non mais tu te moques de moi là ! Je te dis de poser ce téléphone et tu continues ? Tu veux que je me fâche vraiment ?', 5, 'severe'),
('joie', 'premiere_utilisation', 'ami', 'Salut mon pote ! Je suis HordVoice, ton nouveau assistant vocal. On va bien s''amuser ensemble ! Prêt pour l''aventure ?', 5, 'joueur')
ON CONFLICT (id) DO NOTHING;

-- Mise à jour terminée
COMMENT ON TABLE phone_usage_monitoring IS 'Surveillance de l''utilisation du téléphone pour déclencher des reproches appropriés';
COMMENT ON TABLE battery_health_monitoring IS 'Surveillance de la batterie et température pour alertes de sécurité';
COMMENT ON TABLE ai_personality_responses IS 'Réponses personnalisées de l''IA selon le contexte et la personnalité choisie';
COMMENT ON TABLE wellness_goals_tracking IS 'Suivi des objectifs de bien-être avec système de récompenses';
COMMENT ON TABLE ai_emotional_memory IS 'Mémoire émotionnelle de l''IA pour des interactions plus naturelles';
COMMENT ON TABLE system_performance_monitoring IS 'Surveillance des performances système en temps réel';
COMMENT ON TABLE personalized_weather_alerts IS 'Alertes météo personnalisées avec conseils adaptés';
COMMENT ON TABLE user_behavior_analysis IS 'Analyse comportementale avancée pour prédictions et recommandations';
