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
  /// Polaridade OST — álbum de 10 faixas. Abertura instrumental + 3
  /// sessões temáticas: PT (cálculo/movimento), EN (máquina/lógica),
  /// ES (defesa/ataque). Faixas faltantes são puladas silenciosamente.
  static const List<String> tracks = [
    // Abertura
    'music/01_five_stones_aligned.mp3',    // Instrumental · Orquestral Cinemático + Glitch IDM — Menu / início
    // Sessão 1 — PT · Cálculo e Movimento
    'music/02_linhas_de_forca.mp3',        // PT · Neo-Space Ambient / Progressive — Preview de jogada
    'music/03_dobra_toroidal.mp3',         // PT · Electro / Breakbeat — Atração orbital + wrap
    'music/04_ponto_de_inercia.mp3',       // PT · Microhouse / Experimental — Stalemate / fim de estoque
    // Sessão 2 — EN · Máquina e Lógica
    'music/05_kinetic_core.mp3',           // EN · Glitch IDM / Downtempo — Atração e repulsão base
    'music/06_vector_field.mp3',           // EN · Ambient DnB / Liquid Funk — Reações em cadeia e pontuação
    'music/07_alpha_beta_mind.mp3',        // EN · IDM Complexo / Math Rock — Confronto vs IA Mestre
    // Sessão 3 — ES · Defesa e Ataque
    'music/08_fuerza_inversa.mp3',         // ES · Dark Synth / Trip-Hop Industrial — Repulsão tática
    'music/09_enlace_neutro.mp3',          // ES · Dub Techno / Deep House Minimal — Peças neutras
    'music/10_cinco_en_linea.mp3',         // ES · Glitch Hop / Synthwave Pesado — 5 em linha + roubo
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

  /// Tenta tocar a faixa atual. Se falhar (arquivo faltando, por exemplo —
  /// nem todas as 10 faixas do álbum estão entregues), avança e tenta a
  /// próxima. Para depois de uma volta completa pra evitar loop infinito
  /// caso nenhuma faixa esteja disponível.
  Future<void> _playCurrent() async {
    if (tracks.isEmpty) return;
    for (var attempts = 0; attempts < tracks.length; attempts++) {
      try {
        await _player.play(AssetSource(tracks[_currentTrack]));
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('Music pulada ${tracks[_currentTrack]}: $e');
        _currentTrack = (_currentTrack + 1) % tracks.length;
      }
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
