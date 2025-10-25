-- Supabase migration: available_voices table and related policies
-- Run this script in the Supabase SQL editor (production project)
-- to provision the voice catalogue infrastructure.

begin;

create table if not exists public.available_voices (
  id text primary key,
  name text not null,
  language text not null,
  style text not null default 'standard',
  gender text not null check (gender in ('male', 'female', 'neutral', 'unknown')),
  description text,
  provider text not null default 'azure',
  quality_level text not null default 'neural',
  accent text,
  tags text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  is_available boolean not null default true,
  is_active boolean not null default true,
  is_premium boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists available_voices_is_available_idx
  on public.available_voices (is_available)
  where is_available = true;

create index if not exists available_voices_language_idx
  on public.available_voices (language);

create index if not exists available_voices_provider_idx
  on public.available_voices (provider);

create unique index if not exists available_voices_name_unique
  on public.available_voices (lower(name));

create or replace function public.set_available_voices_updated_at()
returns trigger as $function$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$function$ language plpgsql;

drop trigger if exists set_available_voices_updated_at on public.available_voices;

create trigger set_available_voices_updated_at
before update on public.available_voices
for each row
execute function public.set_available_voices_updated_at();

alter table if exists public.available_voices enable row level security;

-- Clean up policies before re-creating them
drop policy if exists "Allow public read on active voices" on public.available_voices;
drop policy if exists "Allow service role insert on available voices" on public.available_voices;
drop policy if exists "Allow service role update on available voices" on public.available_voices;
drop policy if exists "Allow service role delete on available voices" on public.available_voices;

create policy "Allow public read on active voices"
  on public.available_voices
  for select
  using (is_available = true and auth.role() in ('anon', 'authenticated', 'service_role'));

create policy "Allow service role insert on available voices"
  on public.available_voices
  for insert
  with check (auth.role() = 'service_role');

create policy "Allow service role update on available voices"
  on public.available_voices
  for update
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');

create policy "Allow service role delete on available voices"
  on public.available_voices
  for delete
  using (auth.role() = 'service_role');

commit;