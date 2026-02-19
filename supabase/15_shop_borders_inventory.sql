-- =============================================================================
-- Bordas de avatar e inventário: coluna equipada, tipo de produto, user_inventory, compra digital.
-- Execute após 13_shop_coins_products_orders.sql.
-- =============================================================================

-- Borda equipada no perfil (item_key da borda, ex.: border_rainbow)
alter table public.user_profiles
  add column if not exists equipped_border_key text;

comment on column public.user_profiles.equipped_border_key is 'Borda de avatar equipada (item_key de border_definitions)';

-- Tipo de produto e item_key para itens digitais (bordas)
alter table public.shop_products
  add column if not exists product_type text not null default 'physical',
  add column if not exists item_key text;

comment on column public.shop_products.product_type is 'physical = envio; border = item digital (borda de avatar)';
comment on column public.shop_products.item_key is 'Para product_type=border: id da borda (ex.: border_rainbow)';

-- Inventário do utilizador (itens adquiridos na loja: bordas, etc.)
create table if not exists public.user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_type text not null,
  item_key text not null,
  acquired_at timestamptz default now(),
  unique(user_id, item_type, item_key)
);

comment on table public.user_inventory is 'Itens digitais adquiridos na loja (bordas de avatar, etc.)';
create index if not exists idx_user_inventory_user_id on public.user_inventory(user_id);

alter table public.user_inventory enable row level security;

drop policy if exists "User can read own inventory" on public.user_inventory;
create policy "User can read own inventory"
  on public.user_inventory for select
  using (auth.uid() = user_id);

drop policy if exists "User can insert own inventory" on public.user_inventory;
create policy "User can insert own inventory"
  on public.user_inventory for insert
  with check (auth.uid() = user_id);

-- Apenas o sistema (RPC) insere; utilizador não insere diretamente. Policy acima permite insert para auth.uid().
-- Admins podem ler para suporte (opcional)
drop policy if exists "Admins can read all inventory" on public.user_inventory;
create policy "Admins can read all inventory"
  on public.user_inventory for select
  using (
    exists (select 1 from public.admins a where a.email = (auth.jwt() ->> 'email'))
  );

-- RPC: comprar borda (item digital) — debita moedas e adiciona ao inventário
create or replace function public.purchase_shop_border(p_product_id uuid)
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
  if v_product.product_type <> 'border' or v_product.item_key is null then
    raise exception 'Product is not a border item';
  end if;

  select coins into v_current_coins from user_profiles where user_id = v_user_id;
  v_current_coins := coalesce(v_current_coins, 0);
  if v_current_coins < v_product.price_coins then
    raise exception 'Insufficient coins: need %', v_product.price_coins;
  end if;

  insert into user_inventory (user_id, item_type, item_key)
  values (v_user_id, 'border', v_product.item_key)
  on conflict (user_id, item_type, item_key) do nothing;

  update user_profiles set coins = coins - v_product.price_coins, updated_at = now() where user_id = v_user_id;
end;
$$;

comment on function public.purchase_shop_border(uuid) is 'Compra item digital borda: debita moedas e adiciona ao user_inventory';
