import 'package:flutter/material.dart';

/// Design tokens de cor do tema "Cosmos / Gravidade".
/// Valores espelhando o design handoff (README seção Design Tokens).
class AppColors {
  // Backdrops
  static const Color bgVoid = Color(0xFF06061A);
  static const Color bgDeep = Color(0xFF0A0A24);
  static const Color bgMid = Color(0xFF15103A);
  static const Color bgSoft = Color(0xFF1F1A4A);

  // Cores das peças (dono)
  static const Color player = Color(0xFFFFEBC2); // branco-quente
  static const Color playerHighlight = Color(0xFFFFFEF5);
  static const Color playerShadow = Color(0xFFE8C988);
  static const Color playerSymbol = Color(0xFF4A2E0A);

  static const Color ai = Color(0xFF7EE8FA); // ciano-frio
  static const Color aiHighlight = Color(0xFFC9F8FF);
  static const Color aiShadow = Color(0xFF3DA9C7);
  static const Color aiSymbol = Color(0xFF0A2530);

  // Halos por polaridade (NÃO por dono — vetor de acessibilidade)
  static const Color haloPlus = Color(0xFFF5C46B); // dourado ⊕
  static const Color haloMinus = Color(0xFFA271DC); // violeta ⊖

  // Tinta
  static const Color ink = Color(0xFFF5F2FF);
  static const Color ink2 = Color(0xFFB8B2D9);
  static const Color ink3 = Color(0xFF6B6498);
  static const Color ink4 = Color(0xFF3D375E);

  // Linhas
  static const Color line = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color lineStrong = Color(0x26FFFFFF); // rgba(255,255,255,0.15)

  // Estados
  static const Color critical = Color(0xFFFA9A4A); // turno crítico (laranja-quente)
  static const Color quit = Color(0xFFE17B5A); // botão "abandonar"

  // Daltônico (toggle em Ajustes troca a paleta)
  static const Color colorblindPositive = Color(0xFFFFA94D); // laranja
  static const Color colorblindNegative = Color(0xFF4D9CFF); // azul

  // Gradientes prontos
  static const LinearGradient backdropGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF08081F), Color(0xFF100A2C), Color(0xFF060616)],
  );

  static const RadialGradient playerBodyGradient = RadialGradient(
    center: Alignment(-0.3, -0.4), // 35% 30%
    radius: 0.7,
    colors: [playerHighlight, player, playerShadow],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient aiBodyGradient = RadialGradient(
    center: Alignment(-0.3, -0.4),
    radius: 0.7,
    colors: [aiHighlight, ai, aiShadow],
    stops: [0.0, 0.5, 1.0],
  );

  /// Glow do botão primário (gradient pill branco→dourado)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFEF5), Color(0xFFF5C46B)],
  );
}
