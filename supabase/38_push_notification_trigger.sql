-- Trigger que chama a Edge Function notify-push via pg_net
-- sempre que uma nova mensagem direta é inserida.
-- Isto garante notificações push mesmo com o app completamente fechado.

-- Extensão pg_net (já ativa no Supabase por padrão)
create extension if not exists pg_net;

-- Função que dispara o push para o destinatário
create or replace function notify_new_direct_message()
returns trigger language plpgsql security definer as $$
declare
  v_sender_name text;
  v_preview     text;
begin
  -- Obter nome do remetente
  select coalesce(display_name, 'Alguém')
    into v_sender_name
    from public.user_profiles
   where id = new.from_user_id
   limit 1;

  -- Preview da mensagem (máx. 60 chars; ignora indicações JSON)
  if new.text like '{"type":"recommendation"%' then
    v_preview := 'Indicou um filme/série para ti 🎬';
  else
    v_preview := left(new.text, 60);
  end if;

  -- Chamar Edge Function de forma assíncrona via pg_net
  perform net.http_post(
    url     := current_setting('app.supabase_url') || '/functions/v1/notify-push',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body    := jsonb_build_object(
      'to_user_id', new.to_user_id::text,
      'title',      v_sender_name,
      'body',       v_preview,
      'data',       jsonb_build_object(
        'type',         'message',
        'from_user_id', new.from_user_id::text
      )
    )::text
  );

  return new;
end;
$$;

-- Criar trigger na tabela de mensagens
drop trigger if exists trg_notify_new_direct_message on public.direct_messages;
create trigger trg_notify_new_direct_message
  after insert on public.direct_messages
  for each row
  execute function notify_new_direct_message();

-- Nota: as variáveis app.supabase_url e app.service_role_key devem ser
-- definidas via Supabase Dashboard → Settings → Database → Extensions & Settings
-- ou via: alter database postgres set app.supabase_url = '...';
--         alter database postgres set app.service_role_key = '...';
