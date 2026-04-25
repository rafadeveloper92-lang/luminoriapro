-- =============================================================================
-- Carrossel de jogos/eventos na home (editável no painel admin)
-- Execute após 02_admins.sql (políticas usam public.admins)
-- =============================================================================

create table if not exists public.home_sports_slides (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  icon_key text,
  active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.home_sports_matches (
  id uuid primary key default gen_random_uuid(),
  slide_id uuid not null references public.home_sports_slides(id) on delete cascade,
  home_name text not null,
  away_name text not null,
  home_logo_url text,
  away_logo_url text,
  league_label text,
  match_time text not null,
  broadcast_channels text not null default '',
  channel_db_id integer,
  match_weekday smallint,
  sort_index integer not null default 0,
  created_at timestamptz default now()
);

comment on table public.home_sports_slides is 'Secções do carrossel de desporto na home (ex.: Futebol, NBA)';
comment on table public.home_sports_matches is 'Jogos/eventos por slide; match_weekday null = qualquer dia';
comment on column public.home_sports_matches.channel_db_id is 'ID local do canal na app (SQLite channels.id) para abrir o player';
comment on column public.home_sports_matches.match_weekday is '1=Seg … 7=Dom; null = mostrar em qualquer dia';

create index if not exists idx_home_sports_matches_slide on public.home_sports_matches(slide_id);
create index if not exists idx_home_sports_slides_order on public.home_sports_slides(display_order);

alter table public.home_sports_slides enable row level security;
alter table public.home_sports_matches enable row level security;

drop policy if exists "Anyone can read active home_sports_slides" on public.home_sports_slides;
create policy "Anyone can read active home_sports_slides"
  on public.home_sports_slides for select
  using (active = true);

drop policy if exists "Anyone can read home_sports_matches for active slides" on public.home_sports_matches;
create policy "Anyone can read home_sports_matches for active slides"
  on public.home_sports_matches for select
  using (
    exists (
      select 1 from public.home_sports_slides s
      where s.id = slide_id and s.active = true
    )
  );

drop policy if exists "Admins manage home_sports_slides" on public.home_sports_slides;
create policy "Admins manage home_sports_slides"
  on public.home_sports_slides for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

drop policy if exists "Admins manage home_sports_matches" on public.home_sports_matches;
create policy "Admins manage home_sports_matches"
  on public.home_sports_matches for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

alter table public.home_sports_matches add column if not exists match_weekday smallint;
