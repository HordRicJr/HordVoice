-- Script de mise à jour pour HordVoice v2.0
-- Ajouter les tables manquantes et améliorer l'existant

-- Table pour gérer les reproches et comportements de surveillance
CREATE TABLE IF NOT EXISTS public.behavior_monitoring (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    behavior_type text NOT NULL CHECK (behavior_type = ANY (ARRAY['excessive_usage'::text, 'low_battery'::text, 'overheating'::text, 'midnight_usage'::text, 'poor_posture'::text])),
    severity_level text DEFAULT 'medium'::text CHECK (severity_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text])),
    warning_message text NOT NULL,
    african_tone_message text NOT NULL,
    intervention_count integer DEFAULT 1,
    last_intervention timestamp with time zone DEFAULT now(),
    user_response text,
    behavior_improved boolean DEFAULT false,
    monitoring_active boolean DEFAULT true,
    threshold_values jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT behavior_monitoring_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_monitoring_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour les réactions et appréciations
CREATE TABLE IF NOT EXISTS public.user_appreciation (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    appreciation_type text NOT NULL CHECK (appreciation_type = ANY (ARRAY['achievement'::text, 'good_behavior'::text, 'milestone'::text, 'improvement'::text, 'celebration'::text])),
    trigger_event text NOT NULL,
    appreciation_message text NOT NULL,
    african_celebration_message text NOT NULL,
    celebration_level text DEFAULT 'normal'::text CHECK (celebration_level = ANY (ARRAY['normal'::text, 'excited'::text, 'proud'::text, 'very_proud'::text])),
    reward_unlocked text,
    shared_with_family boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_appreciation_pkey PRIMARY KEY (id),
    CONSTRAINT user_appreciation_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour surveillance système avancée
CREATE TABLE IF NOT EXISTS public.device_health_monitoring (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    battery_level integer NOT NULL,
    temperature_celsius real,
    memory_usage_percent real,
    storage_usage_percent real,
    screen_time_minutes integer DEFAULT 0,
    app_crashes_count integer DEFAULT 0,
    network_quality text DEFAULT 'good'::text,
    charging_status boolean DEFAULT false,
    power_saving_mode boolean DEFAULT false,
    last_backup timestamp with time zone,
    warning_triggered boolean DEFAULT false,
    warning_message text,
    african_advice_message text,
    recorded_at timestamp with time zone DEFAULT now(),
    CONSTRAINT device_health_monitoring_pkey PRIMARY KEY (id),
    CONSTRAINT device_health_monitoring_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Table pour personnalités étendues et tons émotionnels
CREATE TABLE IF NOT EXISTS public.personality_responses (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    personality_type text NOT NULL CHECK (personality_type = ANY (ARRAY['mere_africaine'::text, 'grand_frere'::text, 'petite_amie'::text, 'ami'::text, 'sage_africain'::text])),
    emotion_context text NOT NULL CHECK (emotion_context = ANY (ARRAY['reproche'::text, 'encouragement'::text, 'celebration'::text, 'inquietude'::text, 'fierte'::text, 'deception'::text, 'amour'::text, 'protection'::text])),
    intensity_level text DEFAULT 'medium'::text CHECK (intensity_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'extreme'::text])),
    response_text text NOT NULL,
    voice_tone_instructions jsonb DEFAULT '{}'::jsonb,
    gestures_animation text,
    facial_expression text,
    background_music text,
    usage_frequency integer DEFAULT 0,
    effectiveness_rating real DEFAULT 0.0,
    cultural_authenticity_score real DEFAULT 5.0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT personality_responses_pkey PRIMARY KEY (id)
);

-- Table pour stockage des insultes et reproches culturellement appropriés
CREATE TABLE IF NOT EXISTS public.african_expressions (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    expression_type text NOT NULL CHECK (expression_type = ANY (ARRAY['reproche_doux'::text, 'reproche_ferme'::text, 'encouragement'::text, 'celebration'::text, 'inquietude'::text, 'protection'::text])),
    language_code text DEFAULT 'fr'::text,
    country_origin text DEFAULT 'togo'::text,
    expression_text text NOT NULL,
    literal_translation text,
    cultural_context text,
    appropriateness_level text DEFAULT 'family_friendly'::text CHECK (appropriateness_level = ANY (ARRAY['family_friendly'::text, 'adult_only'::text, 'elder_to_child'::text])),
    emotional_impact_score integer CHECK (emotional_impact_score >= 1 AND emotional_impact_score <= 10),
    usage_scenarios jsonb DEFAULT '[]'::jsonb,
    pronunciation_guide text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT african_expressions_pkey PRIMARY KEY (id)
);

-- Table pour gérer les interventions d'urgence
CREATE TABLE IF NOT EXISTS public.emergency_interventions (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    intervention_type text NOT NULL CHECK (intervention_type = ANY (ARRAY['battery_critical'::text, 'overheating_danger'::text, 'excessive_usage_health'::text, 'late_night_concern'::text, 'poor_posture_health'::text])),
    severity_level text NOT NULL CHECK (severity_level = ANY (ARRAY['warning'::text, 'urgent'::text, 'critical'::text, 'emergency'::text])),
    intervention_message text NOT NULL,
    action_taken text,
    user_compliance boolean DEFAULT false,
    intervention_successful boolean DEFAULT false,
    follow_up_required boolean DEFAULT true,
    family_notified boolean DEFAULT false,
    health_impact_assessment text,
    created_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone,
    CONSTRAINT emergency_interventions_pkey PRIMARY KEY (id),
    CONSTRAINT emergency_interventions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Mise à jour de la table user_profiles pour ajouter les nouveaux champs
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS behavior_monitoring_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS strict_mode boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS family_protection_mode boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS health_warnings_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS african_expressions_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS intervention_sensitivity text DEFAULT 'medium'::text CHECK (intervention_sensitivity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
ADD COLUMN IF NOT EXISTS maximum_daily_screen_time_minutes integer DEFAULT 480,
ADD COLUMN IF NOT EXISTS bedtime_enforcement boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS battery_warning_threshold integer DEFAULT 20,
ADD COLUMN IF NOT EXISTS temperature_warning_threshold real DEFAULT 40.0;

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_behavior_monitoring_user_type ON public.behavior_monitoring(user_id, behavior_type);
CREATE INDEX IF NOT EXISTS idx_device_health_user_recorded ON public.device_health_monitoring(user_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_personality_responses_type_context ON public.personality_responses(personality_type, emotion_context);
CREATE INDEX IF NOT EXISTS idx_african_expressions_type_lang ON public.african_expressions(expression_type, language_code);
CREATE INDEX IF NOT EXISTS idx_emergency_interventions_user_severity ON public.emergency_interventions(user_id, severity_level);

-- Insérer quelques données d'exemple pour les expressions africaines
INSERT INTO public.african_expressions (expression_type, language_code, country_origin, expression_text, literal_translation, cultural_context, emotional_impact_score, usage_scenarios) VALUES
('reproche_doux', 'fr', 'togo', 'Mon enfant, tu sais que maman s''inquiète quand tu restes trop sur ton téléphone', 'Mon enfant, tu sais que maman s''inquiète quand tu restes trop sur ton téléphone', 'Expression maternelle douce typique de l''Afrique de l''Ouest', 6, '["excessive_phone_usage", "health_concern"]'),
('reproche_ferme', 'fr', 'togo', 'Ah bon ! Tu veux que ton téléphone chauffe comme un fer à repasser ? Pose-le maintenant !', 'Oh vraiment ! Tu veux que ton téléphone chauffe comme un fer à repasser ? Pose-le maintenant !', 'Reproche ferme mais bienveillant typiquement africain', 8, '["overheating_device", "immediate_action_required"]'),
('encouragement', 'fr', 'togo', 'Voilà mon champion ! Tu as bien fait d''écouter maman. Je suis fière de toi !', 'Voilà mon champion ! Tu as bien fait d''écouter maman. Je suis fière de toi !', 'Encouragement maternel africain avec fierté', 9, '["good_behavior", "achievement", "compliance"]'),
('celebration', 'fr', 'togo', 'Ayayaaaaaa ! Mon enfant a réussi ! Que Dieu te bénisse mon cœur !', 'Ayayaaaaaa ! Mon enfant a réussi ! Que Dieu te bénisse mon cœur !', 'Cri de joie traditionnel ouest-africain', 10, '["major_achievement", "success", "milestone"]'),
('inquietude', 'fr', 'togo', 'Mon cœur, ta batterie est presque finie. Maman s''inquiète, va vite chercher le chargeur', 'Mon cœur, ta batterie est presque finie. Maman s''inquiète, va vite chercher le chargeur', 'Inquiétude maternelle bienveillante', 7, '["low_battery", "device_care"]');

-- Insérer des réponses de personnalité par défaut
INSERT INTO public.personality_responses (personality_type, emotion_context, intensity_level, response_text, voice_tone_instructions, gestures_animation, facial_expression) VALUES
('mere_africaine', 'reproche', 'medium', 'Mon enfant, maman n''est pas contente. Tu passes trop de temps sur ce téléphone !', '{"tone": "motherly_concerned", "pitch": "slightly_higher", "speed": "slower"}', 'motherly_pointing', 'concerned_frown'),
('mere_africaine', 'celebration', 'high', 'Ayayaya ! Mon champion ! Maman est si fière de toi !', '{"tone": "joyful_celebration", "pitch": "higher", "speed": "excited"}', 'celebration_dance', 'proud_smile'),
('grand_frere', 'reproche', 'high', 'Eh petit frère ! Tu fais quoi là ? Ton téléphone va exploser si tu continues !', '{"tone": "big_brother_authority", "pitch": "lower", "speed": "firm"}', 'authoritative_gesture', 'serious_concern'),
('grand_frere', 'encouragement', 'medium', 'Voilà petit frère ! Tu apprends bien. Continue comme ça !', '{"tone": "encouraging_brother", "pitch": "normal", "speed": "confident"}', 'encouraging_nod', 'proud_smile');

COMMIT;
