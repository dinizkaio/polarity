# Trilha Sonora — Polaridade

Playlist contínua. Ordem definida pela dinâmica do jogo. Quando uma faixa
termina, a próxima toca; chega na 8ª, volta pra primeira.

| # | Arquivo | Idioma | Gênero | BPM | Tema |
|---|---|---|---|---|---|
| 1 | `01_kinetic_core.mp3` | EN | Glitch IDM / Downtempo | 105 | Abertura de jogo |
| 2 | `02_fuerza_inversa.mp3` | ES | Dark Synth / Trip-Hop | 98 | Guerra de repulsão |
| 3 | `03_linhas_de_forca.mp3` | PT | Neo-Space / Progressive | 115 | Construção de padrões |
| 4 | `04_cero_absoluto.mp3` | Trilíngue | Microhouse / Minimal | 120 | Fim de estoque / Stalemate |
| 5 | `05_vector_field.mp3` | EN | Ambient DnB / Liquid Funk | 165 | Previews e cálculo de rotas |
| 6 | `06_enlace_neutro.mp3` | ES | Dub Techno / Deep House | 118 | Posicionamento de neutras |
| 7 | `07_dobra_toroidal.mp3` | PT | Electro / Breakbeat | 126 | Wrap nas bordas |
| 8 | `08_alpha_beta.mp3` | Trilíngue | IDM Complexo / Glitch | 132 | Confronto vs IA Mestre |

## Como adicionar / substituir

- Drop o arquivo `.mp3` com o nome exato listado acima
- A lista em `lib/services/music_service.dart` (`MusicService.tracks`) já
  referencia esses paths
- Volume padrão: 0.35 (baixo, não compete com SFX)
- Música só inicia após o **primeiro toque/click** do usuário (autoplay
  block do browser)
