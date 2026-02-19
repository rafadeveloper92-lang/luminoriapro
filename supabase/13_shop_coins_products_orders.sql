-- =============================================================================
-- Loja: moeda virtual (coins), produtos e pedidos.
-- Execute após 02_admins, 07_user_profiles, 08_user_profiles_xp_genres.
-- =============================================================================

-- Moeda virtual no perfil
alter table public.user_profiles
  add column if not exists coins integer not null default 0;

comment on column public.user_profiles.coins is 'Moedas virtuais (Luminárias) para compras na loja';

-- Tabela de produtos da loja
create table if not exists public.shop_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price_coins integer not null check (price_coins >= 0),
  image_urls text[] default '{}',
  active boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

comment on table public.shop_products is 'Produtos da loja (camisetas, copos, brindes) com preço em moedas';
alter table public.shop_products enable row level security;

-- Todos podem ler produtos ativos
drop policy if exists "Anyone can read active shop_products" on public.shop_products;
create policy "Anyone can read active shop_products"
  on public.shop_products for select
  using (active = true);

-- Admins podem ler todos (incl. inativos), inserir, atualizar e apagar
drop policy if exists "Admins can manage shop_products" on public.shop_products;
create policy "Admins can manage shop_products"
  on public.shop_products for all
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Permissão extra: admins podem SELECT em linhas inativas (policy "all" já cobre)
-- Para SELECT de todos os produtos pelo admin, a policy "Admins can manage shop_products" com FOR ALL inclui SELECT.

-- Tabela de pedidos
create table if not exists public.shop_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.shop_products(id) on delete restrict,
  quantity integer not null default 1 check (quantity >= 1),
  status text not null default 'pending' check (status in ('pending', 'shipped', 'cancelled')),
  delivery_name text,
  delivery_address text,
  delivery_phone text,
  delivery_postal_code text,
  created_at timestamptz default now()
);

comment on table public.shop_orders is 'Pedidos da loja; utilizador preenche entrega; admin marca como enviado';
alter table public.shop_orders enable row level security;

-- Utilizador pode inserir o próprio pedido (user_id = auth.uid())
drop policy if exists "User can insert own shop_order" on public.shop_orders;
create policy "User can insert own shop_order"
  on public.shop_orders for insert
  with check (auth.uid() = user_id);

-- Utilizador pode ler apenas os próprios pedidos
drop policy if exists "User can read own shop_orders" on public.shop_orders;
create policy "User can read own shop_orders"
  on public.shop_orders for select
  using (auth.uid() = user_id);

-- Admins podem ler todos os pedidos
drop policy if exists "Admins can read all shop_orders" on public.shop_orders;
create policy "Admins can read all shop_orders"
  on public.shop_orders for select
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- Admins podem atualizar (ex.: status para shipped)
drop policy if exists "Admins can update shop_orders" on public.shop_orders;
create policy "Admins can update shop_orders"
  on public.shop_orders for update
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  )
  with check (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- RPC: colocar pedido e debitar moedas (transação atómica)
create or replace function public.place_shop_order(
  p_product_id uuid,
  p_quantity int,
  p_delivery_name text,
  p_delivery_address text,
  p_delivery_phone text,
  p_delivery_postal_code text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_price int;
  v_total int;
  v_current_coins int;
  v_order_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select price_coins into v_price from shop_products where id = p_product_id and active = true;
  if v_price is null then
    raise exception 'Product not found or inactive';
  end if;

  v_total := v_price * p_quantity;
  select coins into v_current_coins from user_profiles where user_id = v_user_id;
  v_current_coins := coalesce(v_current_coins, 0);
  if v_current_coins < v_total then
    raise exception 'Insufficient coins: need %', v_total;
  end if;

  insert into shop_orders (user_id, product_id, quantity, status, delivery_name, delivery_address, delivery_phone, delivery_postal_code)
  values (v_user_id, p_product_id, p_quantity, 'pending', p_delivery_name, p_delivery_address, p_delivery_phone, p_delivery_postal_code)
  returning id into v_order_id;

  update user_profiles set coins = coins - v_total, updated_at = now() where user_id = v_user_id;

  return v_order_id;
end;
$$;

comment on function public.place_shop_order is 'Place shop order and deduct coins; called by app after user submits delivery form';
