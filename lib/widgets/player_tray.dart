import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Bandeja com informação do jogador (humano ou IA).
class PlayerTray extends StatelessWidget {
  final PieceOwner owner;
  final String name;
  final int stockCount;
  final int onBoardCount;
  final bool isCurrent;
  final bool isThinking;

  const PlayerTray({
    super.key,
    required this.owner,
    required this.name,
    required this.stockCount,
    required this.onBoardCount,
    required this.isCurrent,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatarColor = owner == PieceOwner.player ? AppColors.player : AppColors.ai;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.haloMinus.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? AppColors.haloMinus.withValues(alpha: 0.4) : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [avatarColor, avatarColor.withValues(alpha: 0.4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Nome + estoque dots
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: AppTypography.uiLabel(size: 13)),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(GameState.stockSize, (i) {
                    final used = i >= stockCount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: used ? Colors.transparent : avatarColor,
                          border: used
                              ? Border.all(color: avatarColor.withValues(alpha: 0.4))
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // Contador / status
          Text(
            isThinking ? l10n.gameThinking : l10n.gameOnBoard(onBoardCount),
            style: AppTypography.monoSmall(
              color: isThinking ? AppColors.haloMinus : AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
