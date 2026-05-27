import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';

/// Sons do jogo. Lê asset paths e toca via audioplayers (cross-platform).
/// Respeita o toggle `sound` do SettingsProvider — se desligado, é no-op.
///
/// Pool de players: usa instâncias dedicadas pra sons curtos (tap, move) e
/// uma pra sons mais longos (victory, line) pra evitar overlap excessivo.
enum Sfx {
  tap,
  place,
  flip,
  attract,
  repel,
  move,
  destroy,
  line,
  victory,
  defeat,
  draw;

  String get asset => 'audio/$name.wav';
}

class SoundService {
  final SettingsProvider _settings;
  final AudioPlayer _shortFx = AudioPlayer(playerId: 'sfx_short');
  final AudioPlayer _midFx = AudioPlayer(playerId: 'sfx_mid');
  final AudioPlayer _longFx = AudioPlayer(playerId: 'sfx_long');
  bool _initialized = false;

  SoundService(this._settings);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // ReleaseMode.stop: ao terminar, libera pra próximo play
    for (final p in [_shortFx, _midFx, _longFx]) {
      await p.setReleaseMode(ReleaseMode.stop);
      // Mode.lowLatency em mobile pra triggers rápidos
      try {
        await p.setPlayerMode(PlayerMode.lowLatency);
      } catch (_) {
        // Não suportado em todas as plataformas — ignora.
      }
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!_settings.sound) return;
    final player = switch (sfx) {
      Sfx.tap || Sfx.move || Sfx.flip => _shortFx,
      Sfx.place || Sfx.attract || Sfx.repel || Sfx.destroy || Sfx.line => _midFx,
      Sfx.victory || Sfx.defeat || Sfx.draw => _longFx,
    };
    try {
      await player.stop();
      await player.play(AssetSource(sfx.asset));
    } catch (e) {
      if (kDebugMode) debugPrint('SFX falhou ${sfx.name}: $e');
    }
  }

  Future<void> dispose() async {
    for (final p in [_shortFx, _midFx, _longFx]) {
      await p.dispose();
    }
  }
}
