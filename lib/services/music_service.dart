import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';

/// Toca música ambiente em playlist contínua. Quando uma faixa termina,
/// pula pra próxima. Loopa no fim da lista. Volume baixo (não compete com SFX).
///
/// **Autoplay**: navegadores web bloqueiam reprodução de áudio antes da
/// primeira interação do usuário. Por isso, a música NÃO inicia em `init()`
/// — quem precisa começar é a primeira chamada de `startIfNeeded()`, que
/// pode vir de qualquer evento do usuário (tap em célula, botão, etc).
///
/// Respeita o toggle `sound` em SettingsProvider. Quando desligado, pausa.
class MusicService {
  /// Playlist do álbum Polaridade. Ordem definida pela dinâmica do jogo —
  /// abertura, repulsão, padrões, estoque/stalemate, previews, neutras,
  /// wrap, IA mestre.
  static const List<String> tracks = [
    'music/01_kinetic_core.mp3',           // EN · Glitch IDM / Downtempo (105 BPM) — Abertura de jogo
    'music/02_fuerza_inversa.mp3',         // ES · Dark Synth / Trip-Hop (98 BPM) — Guerra de repulsão
    'music/03_linhas_de_forca.mp3',        // PT · Neo-Space / Progressive (115 BPM) — Construção de padrões
    'music/04_cero_absoluto.mp3',          // Trilíngue · Microhouse / Minimal (120 BPM) — Fim de estoque / Stalemate
    'music/05_vector_field.mp3',           // EN · Ambient DnB / Liquid Funk (165 BPM) — Previews e cálculo
    'music/06_enlace_neutro.mp3',          // ES · Dub Techno / Deep House (118 BPM) — Peças neutras
    'music/07_dobra_toroidal.mp3',         // PT · Electro / Breakbeat (126 BPM) — Wrap nas bordas
    'music/08_alpha_beta.mp3',             // Trilíngue · IDM Complexo / Glitch (132 BPM) — IA Mestre
  ];

  static const double _musicVolume = 0.35;

  final SettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer(playerId: 'music');
  int _currentTrack = 0;
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
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(_musicVolume);
    _completeSub = _player.onPlayerComplete.listen((_) => _playNext());
  }

  /// Chamado no primeiro gesto do usuário (tap em qualquer lugar).
  /// Idempotente — só inicia uma vez.
  Future<void> startIfNeeded() async {
    if (_started || !_initialized) return;
    if (!_settings.sound) return;
    _started = true;
    await _playCurrent();
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
