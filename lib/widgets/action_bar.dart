import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

import '../providers/settings_provider.dart';

/// Barra de ação contextual: muda conforme a fase do jogo.
/// - Idle (sua vez): mostra instrução + chips opcionais (dica/desfazer)
/// - choosingPolarity: 2 botões grandes ⊕ / ⊖
/// - selectingPiece: botão grande "Girar polaridade"
/// - aiThinking / resolving: estado esmaecido
class ActionBar extends StatelessWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: switch (game.phase) {
        GamePhase.choosingPolarity => _PolarityChooser(
          onPlus: () {
            HapticsHelper.medium(settings);
            game.confirmPlace(Polarity.plus);
          },
          onMinus: () {
            HapticsHelper.medium(settings);
            game.confirmPlace(Polarity.minus);
          },
          onCancel: game.cancelSelection,
          prompt: l10n.gameChoosePolarity,
          cancelLabel: l10n.gameCancel,
        ),
        GamePhase.selectingPiece => _FlipConfirmer(
          piece: _selectedPiece(game),
          onConfirm: () {
            HapticsHelper.medium(settings);
            game.confirmFlip();
          },
          onCancel: game.cancelSelection,
          prompt: l10n.gamePieceSelected,
          cancelLabel: l10n.gameCancel,
          flipLabel: l10n.gameActionFlip,
        ),
        GamePhase.aiThinking => _Faded(text: l10n.gameAiTurn),
        GamePhase.resolving => _Faded(text: l10n.gameMagneticReaction),
        _ => _IdlePrompt(
          text: game.state.currentPlayer == PieceOwner.player
              ? l10n.gameYourTurn
              : l10n.gameAiTurn,
          instruction: l10n.gameInstructionPlace,
        ),
      },
    );
  }

  Piece? _selectedPiece(GameProvider game) {
    final sel = game.selectedPiece;
    if (sel == null) return null;
    return game.state.pieceAt(sel.row, sel.col);
  }
}

class _IdlePrompt extends StatelessWidget {
  final String text;
  final String instruction;
  const _IdlePrompt({required this.text, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text.toUpperCase(), style: AppTypography.eyebrow()),
        const SizedBox(height: 6),
        Text(
          instruction,
          style: AppTypography.body(color: AppColors.ink2, size: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Faded extends StatelessWidget {
  final String text;
  const _Faded({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: AppTypography.eyebrow(color: AppColors.ink4)),
    );
  }
}

class _PolarityChooser extends StatelessWidget {
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onCancel;
  final String prompt;
  final String cancelLabel;

  const _PolarityChooser({
    required this.onPlus,
    required this.onMinus,
    required this.onCancel,
    required this.prompt,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(prompt, style: AppTypography.eyebrow()),
            TextButton(onPressed: onCancel, child: Text(cancelLabel, style: AppTypography.monoSmall())),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _PolarityButton(symbol: '⊕', color: AppColors.haloPlus, onTap: onPlus)),
            const SizedBox(width: 12),
            Expanded(child: _PolarityButton(symbol: '⊖', color: AppColors.haloMinus, onTap: onMinus)),
          ],
        ),
      ],
    );
  }
}

class _PolarityButton extends StatelessWidget {
  final String symbol;
  final Color color;
  final VoidCallback onTap;
  const _PolarityButton({required this.symbol, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.18)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -4)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(
              child: Text(
                symbol,
                style: AppTypography.pieceSymbol(color: AppColors.ink, size: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipConfirmer extends StatelessWidget {
  final Piece? piece;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String prompt;
  final String cancelLabel;
  final String flipLabel;

  const _FlipConfirmer({
    required this.piece,
    required this.onConfirm,
    required this.onCancel,
    required this.prompt,
    required this.cancelLabel,
    required this.flipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final current = piece?.polarity;
    final preview = current == null
        ? '⊕ ↔ ⊖'
        : '${current.symbol} → ${current.opposite.symbol}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(prompt, style: AppTypography.eyebrow()),
            TextButton(onPressed: onCancel, child: Text(cancelLabel, style: AppTypography.monoSmall())),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFF3A2F77), Color(0xFF1F1A4A)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.haloMinus.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.haloMinus.withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onConfirm,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(preview, style: AppTypography.pieceSymbol(color: AppColors.ink, size: 22)),
                      const SizedBox(width: 12),
                      Text(flipLabel, style: AppTypography.uiButton()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
