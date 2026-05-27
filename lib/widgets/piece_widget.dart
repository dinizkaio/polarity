import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renderização da peça.
///
/// **Peças ⊕/⊖**: discos circulares. 4 camadas — halo (cor da polaridade),
/// corpo (cor do dono), highlight especular, símbolo.
///
/// **Peças neutras**: forma HEXAGONAL sem símbolo central — a forma
/// diferente de ⊕/⊖ (que são círculos) já é suficiente pra distinguir.
/// Mantém cor de corpo do dono (player branco-quente, IA ciano-frio) pra
/// identidade. Halo cinza neutro. IA tem anel duplo hexagonal interno
/// (acessibilidade pra daltônicos).
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

  /// Peça neutra: HEXÁGONO pointy-top. Forma diferente de círculo pra ser
  /// instantaneamente distinguível de ⊕/⊖. Cores de corpo do dono.
  Widget _buildNeutral() {
    final pieceSize = size * 0.78;
    final haloSize = pieceSize * 1.22;
    final bodyColors = piece.owner == PieceOwner.player
        ? const [Color(0xFFFFFEF5), Color(0xFFFFEBC2), Color(0xFFE8C988)]
        : const [Color(0xFFC9F8FF), Color(0xFF7EE8FA), Color(0xFF3DA9C7)];

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
          // Hexagon body + sombra + highlight + anel duplo (se IA)
          SizedBox(
            width: pieceSize,
            height: pieceSize,
            child: CustomPaint(
              painter: _HexagonNeutralPainter(
                bodyColors: bodyColors,
                drawAiRing: piece.owner == PieceOwner.ai,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Anel duplo interno — vetor de acessibilidade pra peças ⊕/⊖ da IA.
  /// Distingue dono mesmo em b/w (daltônicos). Sempre circular.
  /// Peças neutras (hexagonais) têm seu próprio anel desenhado em
  /// `_HexagonNeutralPainter`.
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

/// Pinta peça neutra como hexagonal (pointy-top): sombra + corpo gradient
/// + highlight especular + anel duplo (se IA, pra acessibilidade).
class _HexagonNeutralPainter extends CustomPainter {
  final List<Color> bodyColors;
  final bool drawAiRing;

  const _HexagonNeutralPainter({
    required this.bodyColors,
    required this.drawAiRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hex = _hexPath(rect);

    // Sombra
    canvas.drawShadow(hex, Colors.black, 4, true);

    // Corpo (gradient radial cor do dono)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.7,
        colors: bodyColors,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawPath(hex, bodyPaint);

    // Highlight especular (top-left), clipado pelo hexagon
    canvas.save();
    canvas.clipPath(hex);
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, highlightPaint);
    canvas.restore();

    // Anel duplo interno (só pra IA)
    if (drawAiRing) {
      final inset1 = rect.width * 0.08;
      final innerRect1 = Rect.fromLTRB(
        rect.left + inset1,
        rect.top + inset1,
        rect.right - inset1,
        rect.bottom - inset1,
      );
      canvas.drawPath(
        _hexPath(innerRect1),
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final inset2 = inset1 + innerRect1.width * 0.08;
      final innerRect2 = Rect.fromLTRB(
        rect.left + inset2,
        rect.top + inset2,
        rect.right - inset2,
        rect.bottom - inset2,
      );
      canvas.drawPath(
        _hexPath(innerRect2),
        Paint()
          ..color = const Color(0xFF0A2530).withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  /// Hexágono pointy-top inscrito no `rect`. Altura = rect.height; largura
  /// efetiva = rect.height × √3/2 (ligeiramente mais estreita que o rect).
  Path _hexPath(Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = rect.height / 2;
    final s = r * math.sqrt(3) / 2;
    return Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + s, cy - r / 2)
      ..lineTo(cx + s, cy + r / 2)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - s, cy + r / 2)
      ..lineTo(cx - s, cy - r / 2)
      ..close();
  }

  @override
  bool shouldRepaint(_HexagonNeutralPainter old) =>
      old.bodyColors != bodyColors || old.drawAiRing != drawAiRing;
}
