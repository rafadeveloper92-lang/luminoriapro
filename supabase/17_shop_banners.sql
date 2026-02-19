-- =============================================================================
-- Banners de propaganda da loja (editáveis no painel admin)
-- Execute após 13_shop_coins_products_orders.sql
-- =============================================================================

-- Tabela de banners da loja
create table if not exists public.shop_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  image_url text not null,
  link_url text,
  active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

comment on table public.shop_banners is 'Banners de propaganda da loja (carrossel)';
alter table public.shop_banners enable row level security;

-- Todos podem ler banners ativos
drop policy if exists "Anyone can read active shop_banners" on public.shop_banners;
create policy "Anyone can read active shop_banners"
  on public.shop_banners for select
  using (active = true);

-- Admins podem ler todos (incl. inativos), inserir, atualizar e apagar
drop policy if exists "Admins can manage shop_banners" on public.shop_banners;
create policy "Admins can manage shop_banners"
  on public.shop_banners for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );
