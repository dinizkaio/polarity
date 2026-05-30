import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/music_service.dart';
import '../theme/app_colors.dart';

/// Pill compacta no canto superior direito da tela de jogo. Mostra a faixa
/// atual (`5/14`) e botões pra pausar/retomar e pular pra próxima.
/// Esconde quando o toggle de som está desligado ou enquanto a primeira
/// faixa ainda não começou (autoplay bloqueado).
class MusicIndicator extends StatelessWidget {
  const MusicIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final music = context.watch<MusicService>();

    if (!settings.sound) return const SizedBox.shrink();
    final trackNum = music.currentTrackNumber;
    if (trackNum == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              music.isPlaying ? Icons.graphic_eq : Icons.music_note,
              size: 14,
              color: AppColors.ink2,
            ),
            const SizedBox(width: 6),
            Text(
              '$trackNum/${music.totalTracks}',
              style: const TextStyle(
                color: AppColors.ink2,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            _MiniButton(
              icon: music.isPlaying ? Icons.pause : Icons.play_arrow,
              tooltip: music.isPlaying ? 'Pausar música' : 'Tocar música',
              onTap: music.togglePlayPause,
            ),
            _MiniButton(
              icon: Icons.skip_next,
              tooltip: 'Próxima faixa',
              onTap: music.skipToNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;

  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        radius: 14,
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Icon(icon, size: 18, color: AppColors.ink2),
        ),
      ),
    );
  }
}
