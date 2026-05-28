# Trilha sonora — 14 faixas

Modo **shuffle**: o `MusicService` embaralha as faixas disponíveis ao
iniciar e toca em sequência aleatória. Ao terminar a volta, reembaralha
(evitando repetir a última no início).

Nomes de arquivo são **genéricos** (`01.mp3` … `14.mp3`) — sem nomes de
música nem ordem fixa.

## Como adicionar / substituir

- Drop o `.mp3` com **só o número** (`05.mp3`, `06.mp3` …) em `assets/music/`
- Lista em `lib/services/music_service.dart` (`MusicService.tracks`) já
  referencia os 14 paths
- Faixas que ainda não existem são puladas — sem travar a playlist
- Volume padrão: `0.35` (baixo, não compete com SFX)
- Música só inicia após o **primeiro toque/click** do usuário (autoplay
  block do browser)

## Status atual

- [x] 1
- [x] 2
- [x] 3
- [x] 4
- [x] 5
- [x] 6
- [x] 7
- [x] 8
- [x] 9
- [x] 10
- [x] 11
- [x] 12
- [x] 13
- [x] 14
