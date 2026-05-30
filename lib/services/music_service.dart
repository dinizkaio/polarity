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
/// **Auto-advance**: usa `onPlayerStateChanged` em vez de `onPlayerComplete`
/// porque o último é instável no web (HTMLMediaElement.ended nem sempre
/// dispara). Detecta `PlayerState.completed` e avança.
///
/// Respeita o toggle `sound` em SettingsProvider. Quando desligado, pausa.
class MusicService extends ChangeNotifier {
  /// Trilha sonora — 14 faixas em modo shuffle. Nomes de arquivo genéricos
  /// (`01.mp3` … `14.mp3`); a ordem real é definida pelo embaralhador.
  static const List<String> tracks = [
    'music/01.mp3',
    'music/02.mp3',
    'music/03.mp3',
    'music/04.mp3',
    'music/05.mp3',
    'music/06.mp3',
    'music/07.mp3',
    'music/08.mp3',
    'music/09.mp3',
    'music/10.mp3',
    'music/11.mp3',
    'music/12.mp3',
    'music/13.mp3',
    'music/14.mp3',
  ];

  static const double _musicVolume = 0.35;

  final SettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer(playerId: 'music');
  final Random _rng = Random();
  List<int> _playOrder = [];
  int _playIndex = 0;
  bool _started = false;
  bool _initialized = false;
  bool _autoAdvanceArmed = false;
  bool _userPaused = false;
  PlayerState _lastState = PlayerState.stopped;
  StreamSubscription<PlayerState>? _stateSub;

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
    _stateSub = _player.onPlayerStateChanged.listen(_onPlayerStateChanged);
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

  /// Pula manualmente pra próxima faixa do shuffle.
  Future<void> skipToNext() async {
    if (!_initialized || _playOrder.isEmpty) return;
    _autoAdvanceArmed = false;
    _userPaused = false;
    if (!_started) {
      _started = true;
    }
    _advanceIndex();
    await _playCurrent();
  }

  /// Toggle manual de play/pause. Se ainda não começou, dispara o primeiro
  /// `_playCurrent()` (atua como gesture inicial também).
  Future<void> togglePlayPause() async {
    if (!_initialized || _playOrder.isEmpty) return;
    if (!_started) {
      _started = true;
      _userPaused = false;
      await _playCurrent();
      return;
    }
    if (_lastState == PlayerState.playing) {
      _userPaused = true;
      await _player.pause();
    } else {
      _userPaused = false;
      try {
        await _player.resume();
      } catch (_) {
        await _playCurrent();
      }
    }
    notifyListeners();
  }

  /// Tenta tocar a faixa atual da ordem embaralhada. Se falhar (arquivo
  /// faltando, por exemplo), avança e tenta a próxima. Para depois de
  /// uma volta completa pra evitar loop infinito.
  Future<void> _playCurrent() async {
    if (_playOrder.isEmpty) return;
    for (var attempts = 0; attempts < _playOrder.length; attempts++) {
      final idx = _playOrder[_playIndex];
      try {
        // Stop antes garante reset limpo — fix de glitch no web onde
        // play() consecutivo sem stop não dispara onComplete.
        await _player.stop();
        await _player.play(AssetSource(tracks[idx]));
        notifyListeners();
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

  void _onPlayerStateChanged(PlayerState state) {
    _lastState = state;
    if (state == PlayerState.playing) {
      _autoAdvanceArmed = true;
    } else if (state == PlayerState.completed && _autoAdvanceArmed && _started) {
      _autoAdvanceArmed = false;
      unawaited(_playNext());
    }
    notifyListeners();
  }

  Future<void> _playNext() async {
    _advanceIndex();
    if (_settings.sound && !_userPaused) {
      await _playCurrent();
    }
  }

  void _onSettingsChanged() {
    if (!_initialized || !_started) return;
    if (_settings.sound) {
      if (_lastState != PlayerState.playing && !_userPaused) {
        unawaited(_player.resume().catchError((_) => _playCurrent()));
      }
    } else {
      unawaited(_player.pause());
    }
  }

  /// Faixa atual (1-indexed) pra exibir no widget. Retorna null se ainda
  /// não começou a tocar nada.
  int? get currentTrackNumber {
    if (!_started || _playOrder.isEmpty) return null;
    return _playOrder[_playIndex] + 1;
  }

  bool get isPlaying => _lastState == PlayerState.playing;
  bool get hasStarted => _started;
  int get totalTracks => tracks.length;

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    unawaited(_stateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }
}
