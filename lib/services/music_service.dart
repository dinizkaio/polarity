import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';

/// Toca o álbum em modo **shuffle**: embaralha a ordem e toca até esgotar
/// a volta; quando esgota, reembaralha (evitando começar a próxima volta
/// com a mesma faixa que acabou). Volume baixo (não compete com SFX).
///
/// **Autoplay**: navegadores web bloqueiam reprodução de áudio antes da
/// primeira interação do usuário. Por isso, a música NÃO inicia em `init()`
/// — quem precisa começar é a primeira chamada de `startIfNeeded()`, que
/// pode vir de qualquer evento do usuário (tap em célula, botão, etc).
///
/// Respeita o toggle `sound` em SettingsProvider. Quando desligado, pausa.
class MusicService {
  /// Polaridade OST — álbum de 10 faixas. Nomes genéricos pra esconder
  /// o conceito de cada uma; mapeamento conceitual ao lado.
  static const List<String> tracks = [
    'music/01.mp3',  // Instrumental · five stones aligned — Menu / início
    'music/02.mp3',  // PT · Linhas de Força — Preview de jogada
    'music/03.mp3',  // PT · Dobra Toroidal — Atração orbital + wrap
    'music/04.mp3',  // PT · Ponto de Inércia — Stalemate / fim de estoque
    'music/05.mp3',  // EN · Kinetic Core — Atração e repulsão base
    'music/06.mp3',  // EN · Vector Field — Reações em cadeia e pontuação
    'music/07.mp3',  // EN · Alpha-Beta Mind — Confronto vs IA Mestre
    'music/08.mp3',  // ES · Fuerza Inversa — Repulsão tática
    'music/09.mp3',  // ES · Enlace Neutro — Peças neutras
    'music/10.mp3',  // ES · Cinco en Línea — 5 em linha + roubo
  ];

  static const double _musicVolume = 0.35;

  final SettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer(playerId: 'music');
  final Random _rng = Random();
  List<int> _playOrder = [];
  int _playIndex = 0;
  bool _started = false;
  bool _initialized = false;
  StreamSubscription<void>? _completeSub;

  MusicService(this._settings) {
    _settings.addListener(_onSettingsChanged);
  }

  /// Prepara o player mas NÃO toca ainda. Esperando primeiro user gesture
  /// pra contornar restrições de autoplay no web.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (tracks.isEmpty) return;
    _shuffleOrder();
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(_musicVolume);
    _completeSub = _player.onPlayerComplete.listen((_) => _playNext());
  }

  /// Embaralha a ordem de reprodução. Se [previousLast] for passado e cair
  /// como primeira faixa da nova volta, troca com outro índice pra evitar
  /// repetição imediata.
  void _shuffleOrder({int? previousLast}) {
    final indices = List<int>.generate(tracks.length, (i) => i);
    indices.shuffle(_rng);
    if (previousLast != null &&
        tracks.length > 1 &&
        indices.first == previousLast) {
      final swap = 1 + _rng.nextInt(tracks.length - 1);
      final tmp = indices[0];
      indices[0] = indices[swap];
      indices[swap] = tmp;
    }
    _playOrder = indices;
    _playIndex = 0;
  }

  /// Chamado no primeiro gesto do usuário (tap em qualquer lugar).
  /// Idempotente — só inicia uma vez.
  Future<void> startIfNeeded() async {
    if (_started || !_initialized) return;
    if (!_settings.sound) return;
    _started = true;
    await _playCurrent();
  }

  /// Tenta tocar a faixa atual da ordem embaralhada. Se falhar (arquivo
  /// faltando, por exemplo — nem todas as 10 faixas estão entregues),
  /// avança e tenta a próxima. Para depois de uma volta completa pra
  /// evitar loop infinito caso nenhuma faixa esteja disponível.
  Future<void> _playCurrent() async {
    if (_playOrder.isEmpty) return;
    for (var attempts = 0; attempts < _playOrder.length; attempts++) {
      final idx = _playOrder[_playIndex];
      try {
        await _player.play(AssetSource(tracks[idx]));
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('Music pulada ${tracks[idx]}: $e');
        _advanceIndex();
      }
    }
  }

  void _advanceIndex() {
    final last = _playOrder[_playIndex];
    _playIndex++;
    if (_playIndex >= _playOrder.length) {
      _shuffleOrder(previousLast: last);
    }
  }

  Future<void> _playNext() async {
    _advanceIndex();
    if (_settings.sound) {
      await _playCurrent();
    }
  }

  void _onSettingsChanged() {
    if (!_initialized || !_started) return;
    if (_settings.sound) {
      if (_player.state != PlayerState.playing) {
        unawaited(_player.resume().catchError((_) => _playCurrent()));
      }
    } else {
      unawaited(_player.pause());
    }
  }

  Future<void> dispose() async {
    _settings.removeListener(_onSettingsChanged);
    await _completeSub?.cancel();
    await _player.dispose();
  }
}
