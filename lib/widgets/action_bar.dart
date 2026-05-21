import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/game_action.dart';
import '../models/piece.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';

import '../providers/settings_provider.dart';

/// Barra de ação contextual. Mostra 3 botões de polaridade (⊕/⊖/○) tanto
/// no place quanto no flip; o botão de neutra é desabilitado se o jogador
/// já tem 2 neutras no tabuleiro.
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
          canPlaceNeutral: game.canPlaceNeutral(game.state.currentPlayer),
          onPlus: () {
            HapticsHelper.medium(settings);
            game.confirmPlace(Polarity.plus);
          },
          onMinus: () {
            HapticsHelper.medium(settings);
            game.confirmPlace(Polarity.minus);
          },
          onNeutral: () {
            HapticsHelper.medium(settings);
            game.confirmPlace(Polarity.neutral);
          },
          onCancel: game.cancelSelection,
          prompt: l10n.gameChoosePolarity,
          cancelLabel: l10n.gameCancel,
        ),
        GamePhase.selectingPiece => _FlipChooser(
          piece: _selectedPiece(game),
          canPickNeutral:
              game.canPlaceNeutral(game.state.currentPlayer) ||
              _selectedPiece(game)?.polarity == Polarity.neutral,
          onPick: (target) {
            HapticsHelper.medium(settings);
            game.confirmFlip(target);
          },
          onCancel: game.cancelSelection,
          prompt: l10n.gamePieceSelected,
          cancelLabel: l10n.gameCancel,
        ),
        GamePhase.previewing => _PreviewActions(
          currentPolarity: game.previewPolarity ?? Polarity.plus,
          isPlace: game.previewAction is PlaceAction,
          canPickNeutral: game.canPlaceNeutral(game.state.currentPlayer) ||
              game.previewPolarity == Polarity.neutral,
          onChange: (target) {
            HapticsHelper.selection(settings);
            if (game.previewAction is PlaceAction) {
              game.confirmPlace(target);
            } else {
              game.confirmFlip(target);
            }
          },
          onConfirm: () {
            HapticsHelper.medium(settings);
            game.confirmPreview();
          },
          onCancel: () {
            HapticsHelper.selection(settings);
            game.cancelPreview();
          },
          confirmLabel: l10n.previewConfirm,
          cancelLabel: l10n.previewCancel,
        ),
        GamePhase.aiThinking => _Faded(text: l10n.gameAiTurn),
        GamePhase.resolving => _Faded(text: l10n.gameMagneticReaction),
        _ => _IdlePrompt(
          text: game.localMultiplayer
              ? (game.state.currentPlayer == PieceOwner.player
                  ? l10n.gamePlayer1
                  : l10n.gamePlayer2)
              : (game.state.currentPlayer == PieceOwner.player
                  ? l10n.gameYourTurn
                  : l10n.gameAiTurn),
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
  final VoidCallback onNeutral;
  final VoidCallback onCancel;
  final bool canPlaceNeutral;
  final String prompt;
  final String cancelLabel;

  const _PolarityChooser({
    required this.onPlus,
    required this.onMinus,
    required this.onNeutral,
    required this.onCancel,
    required this.canPlaceNeutral,
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
            const SizedBox(width: 8),
            Expanded(child: _PolarityButton(symbol: '⊖', color: AppColors.haloMinus, onTap: onMinus)),
            const SizedBox(width: 8),
            Expanded(
              child: _PolarityButton(
                symbol: '○',
                color: AppColors.ink2,
                onTap: canPlaceNeutral ? onNeutral : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PolarityButton extends StatelessWidget {
  final String symbol;
  final Color color;
  final VoidCallback? onTap;
  const _PolarityButton({required this.symbol, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      height: 64,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.18)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            boxShadow: enabled
                ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -4)]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Center(
                child: Text(
                  symbol,
                  style: AppTypography.pieceSymbol(color: AppColors.ink, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seletor para FLIP — 3 botões alvo (⊕/⊖/○). Desabilita a polaridade
/// atual da peça (sem mudança) e a neutra se limite atingido.
class _FlipChooser extends StatelessWidget {
  final Piece? piece;
  final bool canPickNeutral;
  final ValueChanged<Polarity> onPick;
  final VoidCallback onCancel;
  final String prompt;
  final String cancelLabel;

  const _FlipChooser({
    required this.piece,
    required this.canPickNeutral,
    required this.onPick,
    required this.onCancel,
    required this.prompt,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final current = piece?.polarity;
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
            Expanded(
              child: _PolarityButton(
                symbol: '⊕',
                color: AppColors.haloPlus,
                onTap: current == Polarity.plus ? null : () => onPick(Polarity.plus),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PolarityButton(
                symbol: '⊖',
                color: AppColors.haloMinus,
                onTap: current == Polarity.minus ? null : () => onPick(Polarity.minus),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PolarityButton(
                symbol: '○',
                color: AppColors.ink2,
                onTap: (current == Polarity.neutral || !canPickNeutral)
                    ? null
                    : () => onPick(Polarity.neutral),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Barra de ação no modo PREVIEW. Mostra três opções de polaridade (com a
/// atual destacada), botão Confirmar (grande) e Cancelar.
class _PreviewActions extends StatelessWidget {
  final Polarity currentPolarity;
  final bool isPlace;
  final bool canPickNeutral;
  final ValueChanged<Polarity> onChange;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String confirmLabel;
  final String cancelLabel;

  const _PreviewActions({
    required this.currentPolarity,
    required this.isPlace,
    required this.canPickNeutral,
    required this.onChange,
    required this.onConfirm,
    required this.onCancel,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniPolarityChip(
                symbol: '⊕',
                color: AppColors.haloPlus,
                selected: currentPolarity == Polarity.plus,
                onTap: currentPolarity == Polarity.plus ? null : () => onChange(Polarity.plus),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniPolarityChip(
                symbol: '⊖',
                color: AppColors.haloMinus,
                selected: currentPolarity == Polarity.minus,
                onTap: currentPolarity == Polarity.minus ? null : () => onChange(Polarity.minus),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MiniPolarityChip(
                symbol: '○',
                color: AppColors.ink2,
                selected: currentPolarity == Polarity.neutral,
                onTap: (currentPolarity == Polarity.neutral || !canPickNeutral)
                    ? null
                    : () => onChange(Polarity.neutral),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _ConfirmButton(label: confirmLabel, onTap: onConfirm),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CancelButton(label: cancelLabel, onTap: onCancel),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniPolarityChip extends StatelessWidget {
  final String symbol;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  const _MiniPolarityChip({
    required this.symbol,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled || selected ? 1.0 : 0.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.3)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              height: 38,
              child: Center(
                child: Text(
                  symbol,
                  style: AppTypography.pieceSymbol(color: AppColors.ink, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ConfirmButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(color: AppColors.haloPlus.withValues(alpha: 0.4), blurRadius: 12),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: AppColors.bgVoid, size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: AppTypography.uiButton(color: AppColors.bgVoid).copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CancelButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: Text(label, style: AppTypography.uiButton(color: AppColors.ink2).copyWith(fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
