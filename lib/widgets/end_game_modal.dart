import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../l10n/app_localizations.dart';
import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

class EndGameModal extends StatelessWidget {
  final PieceOwner? winner;
  final int playerPieces;
  final int aiPieces;
  final int totalTurns;
  final VoidCallback onNewGame;
  final VoidCallback onMenu;
  final VoidCallback? onShare;

  const EndGameModal({
    super.key,
    required this.winner,
    required this.playerPieces,
    required this.aiPieces,
    required this.totalTurns,
    required this.onNewGame,
    required this.onMenu,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVictory = winner == PieceOwner.player;
    final isDefeat = winner == PieceOwner.ai;

    String title;
    String tagline;
    Color titleColor;
    if (isVictory) {
      title = l10n.endVictory;
      tagline = l10n.endVictoryTagline;
      titleColor = AppColors.haloPlus;
    } else if (isDefeat) {
      title = l10n.endDefeat;
      tagline = l10n.endDefeatTagline;
      titleColor = AppColors.critical;
    } else {
      title = l10n.endDraw;
      tagline = l10n.endDrawTagline;
      titleColor = AppColors.ink;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1F1A4A), Color(0xFF0A0A24)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.haloMinus.withValues(alpha: 0.2),
                    blurRadius: 120,
                    spreadRadius: -20,
                  ),
                ],
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.endGameLabel, style: AppTypography.eyebrow()),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.displayXl(color: titleColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tagline,
                    style: AppTypography.body(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBox(label: l10n.endStatYou, value: playerPieces.toString()),
                      _StatBox(label: l10n.endStatTurns, value: totalTurns.toString()),
                      _StatBox(label: l10n.endStatAi, value: aiPieces.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: l10n.endNewGame, onPressed: onNewGame),
                  const SizedBox(height: 8),
                  GhostButton(label: l10n.endMenu, onPressed: onMenu),
                  if (onShare != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: l10n.shareText(playerPieces, aiPieces),
                        ));
                        onShare!();
                      },
                      child: Text(l10n.endShareResult, style: AppTypography.monoSmall()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.eyebrow()),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.h2(color: AppColors.ink)),
      ],
    );
  }
}

class PauseModal extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const PauseModal({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.bgMid,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.pauseTitle, style: AppTypography.h1()),
                  const SizedBox(height: 24),
                  PrimaryButton(label: l10n.pauseResume, onPressed: onResume),
                  const SizedBox(height: 8),
                  GhostButton(label: l10n.pauseRestart, onPressed: onRestart),
                  const SizedBox(height: 8),
                  GhostButton(
                    label: l10n.pauseQuit,
                    labelColor: AppColors.quit,
                    onPressed: onQuit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
