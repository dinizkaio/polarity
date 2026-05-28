# Polaridade OST — 10 faixas

Álbum em playlist contínua. Quando uma faixa termina, toca a próxima;
chega na última, volta pra primeira. Faixas faltantes são puladas
silenciosamente — dá pra ir entregando uma de cada vez.

## Tracklist

| # | Arquivo | Idioma | Estilo | Conceito |
|---|---|---|---|---|
| 1 | `01_five_stones_aligned.mp3` | Instrumental | Orquestral Cinemático + Glitch IDM | Menu / início de partida — tensão tática e magnetismo |
| 2 | `02_linhas_de_forca.mp3` | PT | Neo-Space Ambient / Progressive Electronica | Preview de jogada — halos, antecipação |
| 3 | `03_dobra_toroidal.mp3` | PT | Electro / Breakbeat | Atração orbital + wrap nas bordas |
| 4 | `04_ponto_de_inercia.mp3` | PT | Microhouse / Experimental | Stalemate — esgotar o estoque, fim forçado |
| 5 | `05_kinetic_core.mp3` | EN | Glitch IDM / Downtempo | Regra base — atração e repulsão, dança ⊕ vs ⊖ |
| 6 | `06_vector_field.mp3` | EN | Ambient DnB / Liquid Funk | Reações em cadeia, pontuação por linhas |
| 7 | `07_alpha_beta_mind.mp3` | EN | IDM Complexo / Math Rock Eletrônico | Confronto vs IA Mestre — minimax em ms |
| 8 | `08_fuerza_inversa.mp3` | ES | Dark Synth Minimalista / Trip-Hop Industrial | Repulsão tática — jogar peças fora |
| 9 | `09_enlace_neutro.mp3` | ES | Dub Techno / Deep House Minimal | Peças neutras (○) — paredes/escudos imunes |
| 10 | `10_cinco_en_linea.mp3` | ES | Glitch Hop / Synthwave Pesado | 5 em linha — pontos máximos + roubo de peça |

## Como adicionar / substituir

- Drop o `.mp3` com o nome exato listado acima em `assets/music/`
- A lista em `lib/services/music_service.dart` (`MusicService.tracks`) já
  referencia os 10 paths
- Faixas que ainda não existem são puladas — sem travar a playlist
- Volume padrão: `0.35` (baixo, não compete com SFX)
- Música só inicia após o **primeiro toque/click** do usuário (autoplay
  block do browser)

## Status atual

- [x] 1. five stones aligned
- [x] 2. Linhas de Força
- [ ] 3. Dobra Toroidal
- [ ] 4. Ponto de Inércia
- [ ] 5. Kinetic Core
- [ ] 6. Vector Field
- [ ] 7. Alpha-Beta Mind
- [ ] 8. Fuerza Inversa
- [ ] 9. Enlace Neutro
- [ ] 10. Cinco en Línea
