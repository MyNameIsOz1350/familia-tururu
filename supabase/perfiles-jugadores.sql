-- Portal de jugadores · Reino 1350
-- Ejecuta este archivo completo en Supabase > SQL Editor > New query.
-- Es seguro volver a ejecutarlo: utiliza IF NOT EXISTS / CREATE OR REPLACE.

create table if not exists public.player_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  governor_name text not null check (char_length(trim(governor_name)) between 1 and 40),
  governor_id text not null unique check (char_length(trim(governor_id)) between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.player_profiles add column if not exists nickname text;
alter table public.player_profiles add column if not exists custom_text text;

alter table public.player_profiles enable row level security;
grant select, insert, update on public.player_profiles to anon, authenticated;

drop policy if exists "Public can view player profiles" on public.player_profiles;
create policy "Public can view player profiles"
on public.player_profiles for select
to anon, authenticated using (true);

drop policy if exists "Players can create own profile" on public.player_profiles;
create policy "Players can create own profile"
on public.player_profiles for insert
to authenticated with check (auth.uid() = id);

drop policy if exists "Players can update own profile" on public.player_profiles;
create policy "Players can update own profile"
on public.player_profiles for update
to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Estadísticas oficiales importadas por los administradores.
-- No incluye recursos recolectados ni recursos asistidos.
create table if not exists public.player_stats (
  governor_id text primary key,
  power bigint,
  kill_points bigint,
  t1_kills bigint,
  t2_kills bigint,
  t3_kills bigint,
  t4_kills bigint,
  t5_kills bigint,
  total_kills bigint,
  t4_t5_kills bigint,
  dead_troops bigint,
  alliance_name text,
  acclaim bigint,
  scanned_at timestamptz not null default now()
);

alter table public.player_stats enable row level security;
grant select on public.player_stats to anon, authenticated;
revoke insert, update, delete on public.player_stats from anon, authenticated;

drop policy if exists "Public can view player stats" on public.player_stats;
create policy "Public can view player stats"
on public.player_stats for select
to anon, authenticated using (true);

-- Tabla privada temporal para importar el Excel/CSV del escáner y la aclamación.
-- No conceder permisos de lectura ni escritura a usuarios públicos.
create table if not exists public.player_stats_import (
  governor_id text,
  power bigint,
  kill_points bigint,
  t1_kills bigint,
  t2_kills bigint,
  t3_kills bigint,
  t4_kills bigint,
  t5_kills bigint,
  total_kills bigint,
  t4_t5_kills bigint,
  dead_troops bigint,
  alliance_name text,
  acclaim bigint
);

alter table public.player_stats_import enable row level security;
revoke all on public.player_stats_import from anon, authenticated;

-- Tras importar el CSV a player_stats_import, ejecutar esta consulta
-- para actualizar todos los perfiles a la vez:
--
-- insert into public.player_stats (
--   governor_id, power, kill_points, t1_kills, t2_kills, t3_kills,
--   t4_kills, t5_kills, total_kills, t4_t5_kills, dead_troops,
--   alliance_name, acclaim, scanned_at
-- )
-- select trim(governor_id), power, kill_points, t1_kills, t2_kills, t3_kills,
--        t4_kills, t5_kills, total_kills, t4_t5_kills, dead_troops,
--        alliance_name, acclaim, now()
-- from public.player_stats_import
-- where governor_id is not null and trim(governor_id) <> ''
-- on conflict (governor_id) do update set
--   power=excluded.power, kill_points=excluded.kill_points,
--   t1_kills=excluded.t1_kills, t2_kills=excluded.t2_kills,
--   t3_kills=excluded.t3_kills, t4_kills=excluded.t4_kills,
--   t5_kills=excluded.t5_kills, total_kills=excluded.total_kills,
--   t4_t5_kills=excluded.t4_t5_kills, dead_troops=excluded.dead_troops,
--   alliance_name=excluded.alliance_name, acclaim=excluded.acclaim,
--   scanned_at=now();
--
-- truncate table public.player_stats_import;
--
-- El correo y la contraseña se gestionan exclusivamente en Supabase Auth.
-- No se guardan contraseñas en player_profiles.
