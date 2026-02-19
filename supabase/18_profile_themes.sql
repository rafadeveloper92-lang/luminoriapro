-- =============================================================================
-- Temas de perfil: tabela profile_themes, campos em user_profiles, RPC de compra.
-- Execute após 15_shop_borders_inventory.sql.
-- =============================================================================

-- Tabela de temas de perfil disponíveis
create table if not exists public.profile_themes (
  id uuid primary key default gen_random_uuid(),
  theme_key text not null unique,
  name text not null,
  description text,
  cover_image_url text,
  background_music_url text,
  primary_color text,
  secondary_color text,
  button_style jsonb,
  decorative_elements jsonb,
  preview_image_url text,
  active boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

comment on table public.profile_themes is 'Temas de perfil disponíveis (Stranger Things, etc.)';
comment on column public.profile_themes.theme_key is 'Identificador único do tema (ex: stranger_things)';
comment on column public.profile_themes.cover_image_url is 'URL da imagem de capa temática';
comment on column public.profile_themes.background_music_url is 'URL do arquivo de áudio de fundo';
comment on column public.profile_themes.primary_color is 'Cor primária em hex (ex: #E50914)';
comment on column public.profile_themes.secondary_color is 'Cor secundária em hex';
comment on column public.profile_themes.button_style is 'Configuração de estilo dos botões (JSON)';
comment on column public.profile_themes.decorative_elements is 'Elementos decorativos (ícones, animações) em JSON';

create index if not exists idx_profile_themes_theme_key on public.profile_themes(theme_key);
create index if not exists idx_profile_themes_active on public.profile_themes(active);

alter table public.profile_themes enable row level security;

-- Todos podem ler temas ativos
drop policy if exists "Anyone can read active profile_themes" on public.profile_themes;
create policy "Anyone can read active profile_themes"
  on public.profile_themes for select
  using (active = true);

-- Admins podem ler todos (incl. inativos), inserir, atualizar e apagar
drop policy if exists "Admins can manage profile_themes" on public.profile_themes;
create policy "Admins can manage profile_themes"
  on public.profile_themes for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Campos no perfil para tema equipado
alter table public.user_profiles
  add column if not exists equipped_theme_key text,
  add column if not exists theme_music_enabled boolean not null default true;

comment on column public.user_profiles.equipped_theme_key is 'Tema de perfil equipado (theme_key de profile_themes)';
comment on column public.user_profiles.theme_music_enabled is 'Se música de fundo do tema está ativa';

-- RPC: comprar tema (item digital) — debita moedas e adiciona ao inventário
create or replace function public.purchase_shop_theme(p_product_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_product record;
  v_current_coins int;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id, product_type, item_key, price_coins into v_product
  from shop_products where id = p_product_id and active = true;
  if v_product.id is null then
    raise exception 'Product not found or inactive';
  end if;
  if v_product.product_type <> 'theme' or v_product.item_key is null then
    raise exception 'Product is not a theme item';
  end if;

  -- Verificar se o tema existe
  if not exists (select 1 from profile_themes where theme_key = v_product.item_key and active = true) then
    raise exception 'Theme not found or inactive';
  end if;

  select coins into v_current_coins from user_profiles where user_id = v_user_id;
  v_current_coins := coalesce(v_current_coins, 0);
  if v_current_coins < v_product.price_coins then
    raise exception 'Insufficient coins: need %', v_product.price_coins;
  end if;

  insert into user_inventory (user_id, item_type, item_key)
  values (v_user_id, 'theme', v_product.item_key)
  on conflict (user_id, item_type, item_key) do nothing;

  update user_profiles set coins = coins - v_product.price_coins, updated_at = now() where user_id = v_user_id;
end;
$$;

comment on function public.purchase_shop_theme(uuid) is 'Compra item digital tema: debita moedas e adiciona ao user_inventory';
