# Animações Lottie para temas de perfil

Os efeitos do perfil (névoa, estrelas, fogo, etc.) usam **Lottie** quando existir um arquivo JSON aqui. Caso contrário, é usado o efeito simples embutido no app.

## Como adicionar efeitos realistas

1. Acesse [LottieFiles](https://lottiefiles.com) e pesquise animações **gratuitas**.
2. Baixe no formato **Lottie JSON**.
3. Coloque o ficheiro nesta pasta com o **nome exato** indicado abaixo.

## Nomes dos ficheiros (obrigatório)

| Efeito no tema | Nome do ficheiro |
|----------------|------------------|
| Neblina / Stranger Things | `fog.json` |
| Estrelas | `stars.json` |
| Neve | `snow.json` |
| Magia (Harry Potter) | `magic.json` |
| Fogo | `fire.json` |
| Neon / Cyberpunk | `neon.json` |
| Sakura / Pétalas | `sakura.json` |

## Sugestões de animações (gratuitas no LottieFiles)

- **Neblina / fumaça:** pesquise "fog", "smoke", "mist"  
  Ex.: [Fog](https://lottiefiles.com/free-animations/fog), [Smoke](https://lottiefiles.com/free-animations/smoke)
- **Estrelas:** "stars", "particles", "sparkle"
- **Neve:** "snow", "snowfall"
- **Fogo:** "fire", "flame", "burn"
- **Magia:** "magic", "sparkle", "dust"
- **Neon:** "neon", "glow", "cyber"
- **Sakura:** "sakura", "petals", "cherry blossom"

Depois de colocar os JSON aqui, faça **flutter pub get** (se precisar) e execute o app. O tema que usar esse efeito passará a mostrar a animação Lottie em vez do efeito simples.
