-- ===============================================
-- TABLES MANQUANTES POUR HORDVOICE
-- Correction des erreurs de base de données
-- ===============================================

-- Table available_voices manquante (référencée dans VoiceManagementService)
CREATE TABLE IF NOT EXISTS public.available_voices (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  voice_name text NOT NULL,
  voice_id text NOT NULL UNIQUE,
  language_code text NOT NULL,
  gender text CHECK (gender = ANY (ARRAY['male'::text, 'female'::text, 'neutral'::text])),
  accent text,
  provider text DEFAULT 'azure'::text CHECK (provider = ANY (ARRAY['azure'::text, 'google'::text, 'amazon'::text, 'system'::text])),
  quality_level text DEFAULT 'standard'::text CHECK (quality_level = ANY (ARRAY['basic'::text, 'standard'::text, 'premium'::text, 'neural'::text])),
  sample_rate integer DEFAULT 24000,
  is_active boolean DEFAULT true,
  is_premium boolean DEFAULT false,
  description text,
  sample_audio_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT available_voices_pkey PRIMARY KEY (id)
);

-- Données initiales pour available_voices (voix Azure Speech)
INSERT INTO public.available_voices (voice_name, voice_id, language_code, gender, accent, provider, quality_level, is_active, description) VALUES
('Denise (Française)', 'fr-FR-DeniseNeural', 'fr-FR', 'female', 'parisien', 'azure', 'neural', true, 'Voix féminine française naturelle'),
('Henri (Français)', 'fr-FR-HenriNeural', 'fr-FR', 'male', 'parisien', 'azure', 'neural', true, 'Voix masculine française naturelle'),
('Brigitte (Française)', 'fr-FR-BrigitteNeural', 'fr-FR', 'female', 'parisien', 'azure', 'neural', true, 'Voix féminine française expressive'),
('Alain (Français)', 'fr-FR-AlainNeural', 'fr-FR', 'male', 'parisien', 'azure', 'neural', true, 'Voix masculine française claire'),
('Léa (Belge)', 'fr-BE-CharlineNeural', 'fr-BE', 'female', 'belge', 'azure', 'neural', true, 'Voix féminine belge'),
('Gérard (Belge)', 'fr-BE-GerardNeural', 'fr-BE', 'male', 'belge', 'azure', 'neural', true, 'Voix masculine belge'),
('Ariane (Canadienne)', 'fr-CA-SylvieNeural', 'fr-CA', 'female', 'quebecois', 'azure', 'neural', true, 'Voix féminine québécoise'),
('Antoine (Canadien)', 'fr-CA-AntoineNeural', 'fr-CA', 'male', 'quebecois', 'azure', 'neural', true, 'Voix masculine québécoise'),
('Aria (Anglaise)', 'en-US-AriaNeural', 'en-US', 'female', 'americain', 'azure', 'neural', true, 'Voix féminine anglaise naturelle'),
('Davis (Anglais)', 'en-US-DavisNeural', 'en-US', 'male', 'americain', 'azure', 'neural', true, 'Voix masculine anglaise naturelle');

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_available_voices_language ON public.available_voices(language_code);
CREATE INDEX IF NOT EXISTS idx_available_voices_active ON public.available_voices(is_active);
CREATE INDEX IF NOT EXISTS idx_available_voices_provider ON public.available_voices(provider);

-- Table daily_emotions référencée dans les logs
CREATE TABLE IF NOT EXISTS public.daily_emotions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  emotion_date date DEFAULT CURRENT_DATE,
  dominant_emotion text NOT NULL,
  emotion_intensity real DEFAULT 5.0 CHECK (emotion_intensity >= 1.0 AND emotion_intensity <= 10.0),
  emotion_triggers jsonb DEFAULT '[]'::jsonb,
  mood_description text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT daily_emotions_pkey PRIMARY KEY (id),
  CONSTRAINT daily_emotions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);

-- Index pour daily_emotions
CREATE INDEX IF NOT EXISTS idx_daily_emotions_user_date ON public.daily_emotions(user_id, emotion_date);
