import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema tipográfico do jogo.
/// 3 famílias: Space Grotesk (display), Manrope (UI), JetBrains Mono (eyebrow/mono).
class AppTypography {
  static TextStyle get _display => GoogleFonts.spaceGrotesk();
  static TextStyle get _ui => GoogleFonts.manrope();
  static TextStyle get _mono => GoogleFonts.jetBrainsMono();

  // === Display ===
  static TextStyle displayXl({Color color = AppColors.ink}) => _display.copyWith(
    fontSize: 44,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.88, // -0.02em
    color: color,
    height: 1.1,
  );

  static TextStyle displayL({Color color = AppColors.ink}) => _display.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.72,
    color: color,
    height: 1.15,
  );

  static TextStyle h1({Color color = AppColors.ink}) => _display.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.56,
    color: color,
    height: 1.2,
  );

  static TextStyle h2({Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      _display.copyWith(
        fontSize: 20,
        fontWeight: weight,
        letterSpacing: -0.2,
        color: color,
        height: 1.25,
      );

  static TextStyle cardTitle({Color color = AppColors.ink}) => _display.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.19,
    color: color,
    height: 1.3,
  );

  // === Body / UI ===
  static TextStyle body({Color color = AppColors.ink2, double size = 14}) => _ui.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle uiButton({Color color = AppColors.ink}) => _ui.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.16, // 0.01em
    color: color,
  );

  static TextStyle uiLabel({Color color = AppColors.ink, double size = 13, FontWeight weight = FontWeight.w600}) =>
      _ui.copyWith(fontSize: size, fontWeight: weight, color: color);

  // === Mono / eyebrow ===
  static TextStyle eyebrow({Color color = AppColors.ink3}) => _mono.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.98, // 0.18em
    color: color,
  );

  static TextStyle monoSmall({Color color = AppColors.ink3, double size = 11}) => _mono.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.1, // 0.1em
    color: color,
  );

  // Símbolo da peça (⊕ / ⊖)
  static TextStyle pieceSymbol({required Color color, double size = 22}) => _display.copyWith(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.0,
  );
}
