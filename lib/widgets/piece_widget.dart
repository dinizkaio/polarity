import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renderização da peça. 4 camadas:
/// 1. Halo (cor da polaridade, blur)
/// 2. Corpo (cor do dono, gradient radial)
/// 3. Highlight especular
/// 4. Símbolo (⊕ ou ⊖)
///
/// IMPORTANTE: anel duplo interno na peça da IA é vetor de acessibilidade.
class PieceWidget extends StatelessWidget {
  final Piece piece;
  final double size;
  final bool colorblindMode;
  final bool selected;
  final bool epicenter;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.colorblindMode = false,
    this.selected = false,
    this.epicenter = false,
  });

  Color get _haloColor {
    if (colorblindMode) {
      return piece.polarity == Polarity.plus
          ? AppColors.colorblindPositive
          : AppColors.colorblindNegative;
    }
    return piece.polarity == Polarity.plus ? AppColors.haloPlus : AppColors.haloMinus;
  }

  RadialGradient get _bodyGradient =>
      piece.owner == PieceOwner.player ? AppColors.playerBodyGradient : AppColors.aiBodyGradient;

  Color get _symbolColor =>
      piece.owner == PieceOwner.player ? AppColors.playerSymbol : AppColors.aiSymbol;

  @override
  Widget build(BuildContext context) {
    final pieceSize = size * 0.78;
    final haloSize = pieceSize * 1.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              width: haloSize,
              height: haloSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _haloColor.withValues(alpha: 0.8),
                    _haloColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          Container(
            width: pieceSize,
            height: pieceSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _bodyGradient,
              boxShadow: [
                const BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                if (piece.owner == PieceOwner.player)
                  const BoxShadow(
                    color: Color(0x4D78501E),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: Offset(0, -2),
                    blurStyle: BlurStyle.inner,
                  ),
              ],
            ),
            child: piece.owner == PieceOwner.ai ? _aiInnerRing(pieceSize) : null,
          ),
          IgnorePointer(
            child: Container(
              width: pieceSize,
              height: pieceSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 0.5,
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Text(
            piece.polarity.symbol,
            style: AppTypography.pieceSymbol(
              color: _symbolColor,
              size: pieceSize * 0.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInnerRing(double pieceSize) {
    return Padding(
      padding: EdgeInsets.all(pieceSize * 0.08),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(pieceSize * 0.045),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0A2530).withValues(alpha: 0.6),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
