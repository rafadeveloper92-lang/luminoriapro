# Efeitos VFX em vídeo MP4/MOV para temas de perfil

Os efeitos de tema (névoa, fogo, estrelas, etc.) podem usar vídeos MP4 ou MOV realistas em vez de animações Lottie ou efeitos simples.

## Como adicionar efeitos em vídeo

1. **Preparar o vídeo**
   - Formatos aceites: **MP4** ou **MOV**
   - **IMPORTANTE**: Certifique-se de que o **fundo é preto puro** (#000000). O app usa `BlendMode.screen` para tornar o preto "transparente" e mostrar apenas o efeito VFX.
   - Se o vídeo vier em MOV com transparência, pode usar diretamente (o app tenta primeiro MP4, depois MOV)

2. **Colocar o ficheiro nesta pasta** (`assets/videos/effects/`) com o **nome exato**:

| Tipo de efeito | Nome do ficheiro (aceita `.mp4` ou `.mov`) |
|----------------|-------------------------------------------|
| Neblina / Stranger Things | `fog.mp4` ou `fog.mov` |
| Estrelas | `stars.mp4` ou `stars.mov` |
| Neve | `snow.mp4` ou `snow.mov` |
| Magia (Harry Potter) | `magic.mp4` ou `magic.mov` |
| Fogo | `fire.mp4` ou `fire.mov` |
| Neon / Cyberpunk | `neon.mp4` ou `neon.mov` |
| Sakura / Pétalas | `sakura.mp4` ou `sakura.mov` |

3. **Reiniciar o app** (hot restart ou rebuild completo)

## Por que fundo preto?

- MP4 não suporta canal alpha (transparência real)
- MOV pode ter alpha, mas ao converter para MP4 ou ao usar diretamente, o que era transparente pode virar fundo sólido (geralmente preto)
- O app usa `BlendMode.screen` para compor o vídeo: pixels pretos (#000000) ficam invisíveis e só o efeito VFX (luz, fumo, partículas) aparece sobre o tema

## Dicas de conversão

**Com FFmpeg:**
```bash
# Converter MOV para MP4 com fundo preto (se o MOV já tiver fundo preto)
ffmpeg -i efeito.mov -c:v libx264 -preset medium -crf 23 efeito.mp4

# Se o MOV tiver fundo transparente/verde e quiser converter para preto:
# (primeiro remova o alpha ou substitua por preto no editor de vídeo)
```

**Com HandBrake ou outros:**
- Escolha codec H.264
- Qualidade média-alta (para manter detalhes do efeito)
- Certifique-se de que o fundo é preto (#000000) antes de converter

## Prioridade dos efeitos

O app tenta carregar os efeitos nesta ordem:
1. **Vídeo MP4** (`assets/videos/effects/<tipo>.mp4`) ← **Mais realista** (tentado primeiro)
2. **Vídeo MOV** (`assets/videos/effects/<tipo>.mov`) ← Se MP4 não existir
3. **Lottie** (`assets/lottie/<tipo>.json`) ← Se nenhum vídeo existir
4. **Efeito simples** (CustomPaint) ← Se Lottie também não existir

Se um vídeo (MP4 ou MOV) existir e carregar corretamente, será usado automaticamente. Caso contrário, o app usa o efeito Lottie ou o efeito simples como fallback.

## Tamanho dos ficheiros

- Vídeos de efeito devem ser **curtos** (1-5 segundos) e em **loop**
- Resolução recomendada: **1080p ou menos** (para não aumentar muito o tamanho do app)
- Bitrate: **médio** (o efeito não precisa de qualidade máxima, já que é overlay)
