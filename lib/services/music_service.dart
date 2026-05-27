import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';

/// Toca música ambiente em playlist contínua. Quando uma faixa termina,
/// pula pra próxima. Loopa no fim da lista. Volume baixo (não compete com SFX).
///
/// Respeita o toggle `sound` em SettingsProvider. Quando desligado, pausa.
class MusicService {
  /// Lista de tracks (relativos à pasta `assets/`). Pra adicionar mais,
  /// inclua o arquivo em `assets/music/` e adicione aqui na ordem da playlist.
  static const List<String> tracks = [
    'music/01_toroidal_edge.mp3',
    'music/02_clicking_into_place.mp3',
  ];

  static const double _musicVolume = 0.35;

  final SettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer(playerId: 'music');
  int _currentTrack = 0;
  bool _initialized = false;
  StreamSubscription<void>? _completeSub;

  MusicService(this._settings) {
    _settings.addListener(_onSettingsChanged);
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (tracks.isEmpty) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(_musicVolume);
    // Toca próxima ao terminar uma
    _completeSub = _player.onPlayerComplete.listen((_) => _playNext());
    if (_settings.sound) {
      await _playCurrent();
    }
  }

  Future<void> _playCurrent() async {
    if (tracks.isEmpty) return;
    try {
      await _player.play(AssetSource(tracks[_currentTrack]));
    } catch (e) {
      if (kDebugMode) debugPrint('Music falhou ${tracks[_currentTrack]}: $e');
    }
  }

  Future<void> _playNext() async {
    _currentTrack = (_currentTrack + 1) % tracks.length;
    if (_settings.sound) {
      await _playCurrent();
    }
  }

  void _onSettingsChanged() {
    if (!_initialized) return;
    if (_settings.sound) {
      // Retoma se está parado
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
