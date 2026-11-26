-- Portal de jugadores · Reino 1350
-- Ejecuta este archivo completo en Supabase > SQL Editor > New query.

create table if not exists public.player_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  governor_name text not null check (char_length(trim(governor_name)) between 1 and 40),
  governor_id text not null unique check (char_length(trim(governor_id)) between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.player_profiles enable row level security;

grant select, insert, update on public.player_profiles to anon, authenticated;

drop policy if exists "Public can view player profiles" on public.player_profiles;
create policy "Public can view player profiles"
on public.player_profiles for select
to anon, authenticated using (true);

drop policy if exists "Players can create own profile" on public.player_profiles;
create policy "Players can create own profile"
on public.player_profiles for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "Players can update own profile" on public.player_profiles;
create policy "Players can update own profile"
on public.player_profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- El correo y la contraseña se gestionan exclusivamente en Supabase Auth.
-- No se guardan contraseñas en player_profiles.
