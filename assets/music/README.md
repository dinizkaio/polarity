# Polaridade OST — 10 faixas

Álbum em **modo shuffle**: a cada partida, o `MusicService` embaralha as
faixas disponíveis e toca em sequência aleatória. Ao terminar a volta,
reembaralha (evitando repetir a última no início).

Nomes de arquivo **genéricos** (`01.mp3` … `10.mp3`) — o conceito de cada
um fica só na documentação, não no filesystem.

## Tracklist

| # | Arquivo | Idioma | Estilo | Conceito |
|---|---|---|---|---|
| 1 | `01.mp3` | Instrumental | Orquestral Cinemático + Glitch IDM | five stones aligned — Menu / início, tensão tática |
| 2 | `02.mp3` | PT | Neo-Space Ambient / Progressive Electronica | Linhas de Força — Preview de jogada, halos |
| 3 | `03.mp3` | PT | Electro / Breakbeat | Dobra Toroidal — Atração orbital + wrap |
| 4 | `04.mp3` | PT | Microhouse / Experimental | Ponto de Inércia — Stalemate, fim por estoque |
| 5 | `05.mp3` | EN | Glitch IDM / Downtempo | Kinetic Core — Atração/repulsão base |
| 6 | `06.mp3` | EN | Ambient DnB / Liquid Funk | Vector Field — Reações em cadeia, pontuação |
| 7 | `07.mp3` | EN | IDM Complexo / Math Rock | Alpha-Beta Mind — vs IA Mestre |
| 8 | `08.mp3` | ES | Dark Synth / Trip-Hop Industrial | Fuerza Inversa — Repulsão tática |
| 9 | `09.mp3` | ES | Dub Techno / Deep House Minimal | Enlace Neutro — Peças neutras (○) |
| 10 | `10.mp3` | ES | Glitch Hop / Synthwave Pesado | Cinco en Línea — 5 em linha + roubo |

## Como adicionar / substituir

- Drop o `.mp3` com **só o número** (`04.mp3`, `05.mp3` …) em `assets/music/`
- Lista em `lib/services/music_service.dart` (`MusicService.tracks`) já
  referencia os 10 paths
- Faixas que ainda não existem são puladas — sem travar a playlist
- Volume padrão: `0.35` (baixo, não compete com SFX)
- Música só inicia após o **primeiro toque/click** do usuário (autoplay
  block do browser)

## Status atual

- [x] 1. five stones aligned
- [x] 2. Linhas de Força
- [x] 3. Dobra Toroidal
- [ ] 4. Ponto de Inércia
- [ ] 5. Kinetic Core
- [ ] 6. Vector Field
- [ ] 7. Alpha-Beta Mind
- [ ] 8. Fuerza Inversa
- [ ] 9. Enlace Neutro
- [ ] 10. Cinco en Línea
