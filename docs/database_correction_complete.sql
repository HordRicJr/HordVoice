-- ===============================================
-- DIAGNOSTIC ET CORRECTION BASE DE DONNÉES
-- HordVoice - Résolution définitive des tables manquantes
-- ===============================================

-- ÉTAPE 1: Diagnostic complet des objets existants
-- Vérifier s'il existe des vues ou tables avec ces noms

DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE 'DIAGNOSTIC BASE DE DONNÉES HORDVOICE';
    RAISE NOTICE '==========================================';
    
    -- Vérifier available_voices
    SELECT schemaname, tablename, tableowner INTO r
    FROM pg_tables 
    WHERE tablename = 'available_voices' AND schemaname = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'TABLE available_voices existe déjà';
    ELSE
        RAISE NOTICE 'TABLE available_voices MANQUANTE';
    END IF;
    
    -- Vérifier si c'est une vue
    SELECT schemaname, viewname, viewowner INTO r
    FROM pg_views 
    WHERE viewname = 'available_voices' AND schemaname = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'VUE available_voices détectée - CONFLIT POSSIBLE';
    END IF;
    
    -- Vérifier daily_emotions
    SELECT schemaname, tablename, tableowner INTO r
    FROM pg_tables 
    WHERE tablename = 'daily_emotions' AND schemaname = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'TABLE daily_emotions existe déjà';
    ELSE
        RAISE NOTICE 'TABLE daily_emotions MANQUANTE';
    END IF;
    
    -- Vérifier si c'est une vue
    SELECT schemaname, viewname, viewowner INTO r
    FROM pg_views 
    WHERE viewname = 'daily_emotions' AND schemaname = 'public';
    
    IF FOUND THEN
        RAISE NOTICE 'VUE daily_emotions détectée - CONFLIT DÉTECTÉ';
        RAISE NOTICE 'Action requise: Suppression de la vue avant création table';
    END IF;
    
END $$;

-- ÉTAPE 2: Suppression des vues conflictuelles (si elles existent)
-- ATTENTION: Ceci supprimera les vues existantes

DROP VIEW IF EXISTS public.daily_emotions CASCADE;
DROP VIEW IF EXISTS public.available_voices CASCADE;

-- ÉTAPE 3: Création sécurisée de la table available_voices
-- Avec gestion des erreurs et vérifications

DO $$
BEGIN
    -- Créer la table available_voices
    CREATE TABLE IF NOT EXISTS public.available_voices (
        id uuid NOT NULL DEFAULT gen_random_uuid(),
        voice_name text NOT NULL,
        voice_id text NOT NULL,
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
        CONSTRAINT available_voices_pkey PRIMARY KEY (id),
        CONSTRAINT available_voices_voice_id_unique UNIQUE (voice_id)
    );
    
    RAISE NOTICE 'TABLE available_voices créée avec succès';
    
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'TABLE available_voices existe déjà';
    WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR création available_voices: %', SQLERRM;
END $$;

-- ÉTAPE 4: Création sécurisée de la table daily_emotions

DO $$
BEGIN
    -- Créer la table daily_emotions
    CREATE TABLE IF NOT EXISTS public.daily_emotions (
        id uuid NOT NULL DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL,
        emotion_date date DEFAULT CURRENT_DATE,
        dominant_emotion text NOT NULL,
        emotion_intensity real DEFAULT 5.0 CHECK (emotion_intensity >= 1.0 AND emotion_intensity <= 10.0),
        emotion_triggers jsonb DEFAULT '[]'::jsonb,
        mood_description text,
        created_at timestamp with time zone DEFAULT now(),
        CONSTRAINT daily_emotions_pkey PRIMARY KEY (id)
    );
    
    RAISE NOTICE 'TABLE daily_emotions créée avec succès';
    
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'TABLE daily_emotions existe déjà';
    WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR création daily_emotions: %', SQLERRM;
END $$;

-- ÉTAPE 5: Création des index (seulement sur les tables, pas les vues)

DO $$
BEGIN
    -- Index pour available_voices
    CREATE INDEX IF NOT EXISTS idx_available_voices_language 
    ON public.available_voices(language_code);
    
    CREATE INDEX IF NOT EXISTS idx_available_voices_active 
    ON public.available_voices(is_active);
    
    CREATE INDEX IF NOT EXISTS idx_available_voices_provider 
    ON public.available_voices(provider);
    
    RAISE NOTICE 'Index available_voices créés';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR création index available_voices: %', SQLERRM;
END $$;

DO $$
BEGIN
    -- Index pour daily_emotions
    CREATE INDEX IF NOT EXISTS idx_daily_emotions_user_date 
    ON public.daily_emotions(user_id, emotion_date);
    
    CREATE INDEX IF NOT EXISTS idx_daily_emotions_date 
    ON public.daily_emotions(emotion_date);
    
    RAISE NOTICE 'Index daily_emotions créés';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR création index daily_emotions: %', SQLERRM;
END $$;

-- ÉTAPE 6: Insertion des données par défaut pour available_voices

DO $$
BEGIN
    -- Vérifier si des données existent déjà
    IF NOT EXISTS (SELECT 1 FROM public.available_voices LIMIT 1) THEN
        
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
        
        RAISE NOTICE 'Données par défaut insérées dans available_voices';
    ELSE
        RAISE NOTICE 'Données déjà présentes dans available_voices';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERREUR insertion données available_voices: %', SQLERRM;
END $$;

-- ÉTAPE 7: Vérification finale

DO $$
DECLARE
    voices_count integer;
    emotions_count integer;
BEGIN
    RAISE NOTICE 'VÉRIFICATION FINALE';
    RAISE NOTICE '==================';
    
    -- Compter les voix
    SELECT COUNT(*) INTO voices_count FROM public.available_voices;
    RAISE NOTICE 'available_voices: % enregistrements', voices_count;
    
    -- Compter les émotions
    SELECT COUNT(*) INTO emotions_count FROM public.daily_emotions;
    RAISE NOTICE 'daily_emotions: % enregistrements', emotions_count;
    
    -- Vérifier les index
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'available_voices') THEN
        RAISE NOTICE 'Index available_voices: OK';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'daily_emotions') THEN
        RAISE NOTICE 'Index daily_emotions: OK';
    END IF;
    
    RAISE NOTICE 'CORRECTION TERMINÉE AVEC SUCCÈS';
    
END $$;
