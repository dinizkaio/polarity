import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renderização da peça.
///
/// **Peças ⊕/⊖**: discos circulares. 4 camadas — halo (cor da polaridade),
/// corpo (cor do dono), highlight especular, símbolo.
///
/// **Peças neutras**: forma DIAMANTE (quadrado rotacionado 45°) sem símbolo
/// central — a forma diferente de ⊕/⊖ (que são círculos) já é suficiente
/// pra distinguir. Mantém cor de corpo do dono (player branco-quente, IA
/// ciano-frio) pra identidade. Halo cinza neutro.
///
/// **IA**: anel duplo interno (vetor de acessibilidade — distingue dono
/// mesmo em b/w).
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

  bool get _isNeutral => piece.polarity == Polarity.neutral;

  Color get _haloColor {
    if (_isNeutral) return AppColors.ink2;
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
    if (_isNeutral) return _buildNeutral();
    return _buildCharged();
  }

  /// Peça normal (⊕/⊖): disco circular com halo colorido por polaridade.
  Widget _buildCharged() {
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
                    _haloColor.withOpacity(0.8),
                    _haloColor.withOpacity(0.0),
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
                    Colors.white.withOpacity(0.45),
                    Colors.white.withOpacity(0.0),
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

  /// Peça neutra: DIAMANTE (quadrado rotacionado 45°). Forma diferente de
  /// círculo pra ser instantaneamente distinguível de ⊕/⊖.
  Widget _buildNeutral() {
    // Diamante cabe dentro do círculo de raio pieceSize/2 → diagonal do
    // quadrado = pieceSize. Lado do quadrado = pieceSize / sqrt(2) ≈ 0.707×.
    final pieceSize = size * 0.78;
    final diamondSide = pieceSize * 0.72;
    final haloSize = pieceSize * 1.22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo cinza sutil (sem pulse — neutra é estática)
          IgnorePointer(
            child: Container(
              width: haloSize,
              height: haloSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _haloColor.withOpacity(0.4),
                    _haloColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          // Corpo: diamante (rotated square). Sem anel duplo interno —
          // a forma diferente + cor do dono já distinguem suficientemente.
          Transform.rotate(
            angle: 0.785398, // 45° em radianos
            child: Container(
              width: diamondSide,
              height: diamondSide,
              decoration: BoxDecoration(
                gradient: _bodyGradient,
                borderRadius: BorderRadius.circular(diamondSide * 0.12),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Highlight especular (sutil, rotacionado também)
          IgnorePointer(
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: diamondSide,
                height: diamondSide,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(diamondSide * 0.12),
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    radius: 0.5,
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Neutra não tem símbolo central — a forma diamante já distingue.
        ],
      ),
    );
  }

  /// Anel duplo interno — vetor de acessibilidade pra peças ⊕/⊖ da IA.
  /// Distingue dono mesmo em b/w. Não usado nas neutras (forma já distingue).
  Widget _aiInnerRing(double pieceSize) {
    return Padding(
      padding: EdgeInsets.all(pieceSize * 0.08),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(pieceSize * 0.045),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0A2530).withOpacity(0.6),
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
