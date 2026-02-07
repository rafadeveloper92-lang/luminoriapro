# Correção: Filmes da Cinema Room não apareciam na linha do tempo

## 🐛 Problema

Quando você assistia filmes através da **Cinema Room** (sala de cinema com amigos), esses filmes **não eram registrados** na linha do tempo do perfil. Apenas filmes assistidos pelo botão "Assistir" normal apareciam no histórico.

## ✅ Solução Implementada

### 1. **Adicionada coluna `stream_id` ao modelo CinemaRoom**
   - Agora a sala de cinema armazena o ID do filme/série
   - Permite identificar qual conteúdo está sendo assistido

### 2. **Atualizado banco de dados Supabase**
   - Criado arquivo de migração: `supabase/06_cinema_rooms_add_stream_id.sql`
   - Adiciona coluna `stream_id` à tabela `cinema_rooms`

### 3. **Registro automático no histórico**
   - Quando você inicia a reprodução na Cinema Room, o filme é registrado automaticamente
   - Funciona tanto para o host quanto para participantes
   - Registra apenas uma vez por sessão

## 📝 Como aplicar a correção

### Passo 1: Atualizar o banco de dados Supabase

1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Clique em **New query**
4. Copie e cole o conteúdo do arquivo `supabase/06_cinema_rooms_add_stream_id.sql`
5. Clique em **Run** para executar

### Passo 2: Testar a correção

1. Abra o app
2. Escolha um filme
3. Clique em "Criar Sala de Cinema"
4. Inicie o filme na sala
5. Volte para o seu perfil
6. Verifique se o filme aparece na linha do tempo ✅

## 🔧 Arquivos modificados

- `lib/core/models/cinema_room.dart` - Adicionado campo `streamId`
- `lib/core/services/cinema_room_service.dart` - Suporte a `streamId` ao criar sala
- `lib/features/cinema/providers/cinema_room_provider.dart` - Passa `streamId` ao criar sala
- `lib/features/cinema/screens/cinema_room_screen.dart` - Registra histórico ao iniciar reprodução
- `lib/features/vod/screens/movie_detail_screen.dart` - Passa `streamId` ao criar sala
- `supabase/06_cinema_rooms_add_stream_id.sql` - Migração do banco de dados (NOVO)

## 💡 Detalhes técnicos

### Como funciona o registro

1. Quando uma sala é criada, o `streamId` do filme é armazenado
2. Quando a reprodução inicia (`_startPlaybackIfNeeded`), o sistema verifica:
   - Se já foi registrado nesta sessão (`_historyRecorded`)
   - Se existe `streamId` na sala
3. Se tudo estiver OK, registra no histórico local usando `VodWatchHistoryService`
4. O histórico é exibido na linha do tempo do perfil

### Proteções implementadas

- ✅ Registra apenas uma vez por sessão (flag `_historyRecorded`)
- ✅ Verifica se `streamId` existe antes de registrar
- ✅ Funciona tanto para host quanto participantes
- ✅ Compatível com salas antigas (sem `streamId`)

## 🎉 Resultado

Agora, **todos os filmes** que você assiste aparecerão na sua linha do tempo, seja assistindo sozinho ou com amigos na Cinema Room! 🍿
