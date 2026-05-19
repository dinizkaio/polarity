import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Header da tela de jogo: hamburger + título + contador de turno.
/// Nos últimos 2 turnos o contador fica laranja (tensão).
class GameHeader extends StatelessWidget {
  final GameState state;
  final VoidCallback onPause;

  const GameHeader({super.key, required this.state, required this.onPause});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxTurns = state.maxDisplayTurns;
    final current = state.displayTurn.clamp(1, maxTurns);
    final critical = current >= maxTurns - 1;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _IconCircle(icon: Icons.menu_rounded, onTap: onPause, semanticLabel: l10n.pauseTitle),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.appName.toUpperCase(),
                  style: AppTypography.uiLabel(size: 16).copyWith(letterSpacing: 0.96),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.gameTurnLabel(current, maxTurns),
                  style: AppTypography.monoSmall(
                    color: critical ? AppColors.critical : AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const _IconCircle({required this.icon, required this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, size: 20, color: AppColors.ink2, semanticLabel: semanticLabel),
          ),
        ),
      ),
    );
  }
}
