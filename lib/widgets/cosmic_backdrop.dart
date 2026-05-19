import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Backdrop cósmico: gradiente base + estrelas estáticas + nebulosas radiais.
/// Não usa partículas reais (custo de CPU). 12 dots fixos posicionados pseudo-aleatoriamente.
class CosmicBackdrop extends StatelessWidget {
  final Widget child;
  const CosmicBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente base
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backdropGradient),
        ),
        // Nebulosas violeta/rosa (radial-gradients sobrepostos)
        IgnorePointer(
          child: CustomPaint(painter: _NebulaPainter()),
        ),
        // Estrelas
        IgnorePointer(
          child: CustomPaint(painter: _StarsPainter()),
        ),
        child,
      ],
    );
  }
}

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Nebulosa violeta superior-direita
    _paintRadial(
      canvas,
      Offset(w * 0.78, h * 0.18),
      h * 0.5,
      const Color(0x66A271DC),
    );
    // Nebulosa rosa inferior-esquerda
    _paintRadial(
      canvas,
      Offset(w * 0.18, h * 0.78),
      h * 0.45,
      const Color(0x44E27FB8),
    );
    // Nebulosa azul central
    _paintRadial(
      canvas,
      Offset(w * 0.5, h * 0.5),
      h * 0.6,
      const Color(0x227EE8FA),
    );
  }

  void _paintRadial(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) => false;
}

class _StarsPainter extends CustomPainter {
  static const int _starCount = 14;
  late final List<_Star> _stars;

  _StarsPainter() {
    final rng = Random(42); // seed fixo pra estrelas estáveis entre rebuilds
    _stars = List.generate(_starCount, (i) {
      return _Star(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 0.9,
        color: _starColors[i % _starColors.length],
      );
    });
  }

  static const List<Color> _starColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFEBC2),
    Color(0xFF7EE8FA),
    Color(0xFFC4B8FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _stars) {
      final paint = Paint()
        ..color = star.color.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter oldDelegate) => false;
}

class _Star {
  final double dx;
  final double dy;
  final double radius;
  final Color color;
  const _Star({required this.dx, required this.dy, required this.radius, required this.color});
}
