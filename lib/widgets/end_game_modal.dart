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
  final int playerPoints;
  final int aiPoints;
  final int totalTurns;
  final bool localMultiplayer;
  final VoidCallback onNewGame;
  final VoidCallback onMenu;
  final VoidCallback? onShare;

  const EndGameModal({
    super.key,
    required this.winner,
    required this.playerPoints,
    required this.aiPoints,
    required this.totalTurns,
    this.localMultiplayer = false,
    required this.onNewGame,
    required this.onMenu,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    String title;
    String tagline;
    Color titleColor;

    if (localMultiplayer) {
      // No modo local, mostra "Jogador X venceu" em vez de "Vitória/Derrota"
      if (winner == PieceOwner.player) {
        title = l10n.endPlayer1Wins;
        tagline = l10n.endVictoryTagline;
        titleColor = AppColors.haloPlus;
      } else if (winner == PieceOwner.ai) {
        title = l10n.endPlayer2Wins;
        tagline = l10n.endVictoryTagline;
        titleColor = AppColors.haloMinus;
      } else {
        title = l10n.endDraw;
        tagline = l10n.endDrawTagline;
        titleColor = AppColors.ink;
      }
    } else {
      if (winner == PieceOwner.player) {
        title = l10n.endVictory;
        tagline = l10n.endVictoryTagline;
        titleColor = AppColors.haloPlus;
      } else if (winner == PieceOwner.ai) {
        title = l10n.endDefeat;
        tagline = l10n.endDefeatTagline;
        titleColor = AppColors.critical;
      } else {
        title = l10n.endDraw;
        tagline = l10n.endDrawTagline;
        titleColor = AppColors.ink;
      }
    }

    final p1Label = localMultiplayer ? l10n.gamePlayer1Short : l10n.endStatYou;
    final p2Label = localMultiplayer ? l10n.gamePlayer2Short : l10n.endStatAi;

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
                      _StatBox(label: p1Label, value: playerPoints.toString()),
                      _StatBox(label: l10n.endStatTurns, value: totalTurns.toString()),
                      _StatBox(label: p2Label, value: aiPoints.toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.endStatPoints, style: AppTypography.eyebrow()),
                  const SizedBox(height: 24),
                  PrimaryButton(label: l10n.endNewGame, onPressed: onNewGame),
                  const SizedBox(height: 8),
                  GhostButton(label: l10n.endMenu, onPressed: onMenu),
                  if (onShare != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: l10n.shareText(playerPoints, aiPoints),
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
