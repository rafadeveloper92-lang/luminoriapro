-- Tabela para armazenar tokens FCM de cada utilizador (notificações push com app fechado).
-- Um utilizador pode ter múltiplos dispositivos, mas guardamos apenas o token mais recente.

create table if not exists public.user_fcm_tokens (
  user_id uuid primary key references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'android', -- 'android' | 'ios'
  updated_at timestamptz not null default now()
);

-- Apenas o próprio utilizador pode ler/escrever o seu token
alter table public.user_fcm_tokens enable row level security;

create policy "user can manage own fcm token"
  on public.user_fcm_tokens
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Service role pode ler todos os tokens (para a Edge Function enviar notificações)
create policy "service role can read all tokens"
  on public.user_fcm_tokens
  for select
  using (auth.role() = 'service_role');
