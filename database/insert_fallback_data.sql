-- Supabase data seed: default voice catalogue
-- Run after migrations to guarantee a minimum set of voices.

begin;

insert into public.available_voices (
  id,
  name,
  language,
  style,
  gender,
  description,
  provider,
  quality_level,
  accent,
  is_available,
  is_active,
  is_premium
)
values
  (
    'fr-FR-DeniseNeural',
    'Denise',
    'fr-FR',
    'natural',
    'female',
    'Voix féminine naturelle française.',
    'azure',
    'neural',
    'fr-standard',
    true,
    true,
    false
  ),
  (
    'fr-FR-HenriNeural',
    'Henri',
    'fr-FR',
    'natural',
    'male',
    'Voix masculine naturelle française.',
    'azure',
    'neural',
    'fr-standard',
    true,
    true,
    false
  ),
  (
    'fr-FR-BrigitteNeural',
    'Brigitte',
    'fr-FR',
    'expressive',
    'female',
    'Voix féminine expressive française.',
    'azure',
    'neural',
    'fr-standard',
    true,
    true,
    false
  ),
  (
    'en-US-JennyNeural',
    'Jenny',
    'en-US',
    'natural',
    'female',
    'Voix anglaise américaine naturelle.',
    'azure',
    'neural',
    'en-us',
    true,
    true,
    false
  ),
  (
    'en-US-GuyNeural',
    'Guy',
    'en-US',
    'natural',
    'male',
    'Voix anglaise américaine masculine chaleureuse.',
    'azure',
    'neural',
    'en-us',
    true,
    true,
    false
  )
on conflict (id) do update
set
  name = excluded.name,
  language = excluded.language,
  style = excluded.style,
  gender = excluded.gender,
  description = excluded.description,
  provider = excluded.provider,
  quality_level = excluded.quality_level,
  accent = excluded.accent,
  is_available = excluded.is_available,
  is_active = excluded.is_active,
  is_premium = excluded.is_premium,
  updated_at = timezone('utc', now());

commit;