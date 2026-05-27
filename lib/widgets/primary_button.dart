import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Botão primário do design: pill 60px com gradiente branco→dourado e glow.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool dense;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      width: double.infinity,
      height: dense ? 52 : 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: disabled
              ? const LinearGradient(colors: [Color(0xFF3A3358), Color(0xFF2A2548)])
              : AppColors.primaryButtonGradient,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.haloPlus.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.bgVoid, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTypography.uiButton(color: AppColors.bgVoid)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão secundário (ghost): borda sutil, fundo translúcido.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color labelColor;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.labelColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Center(
              child: Text(label, style: AppTypography.uiButton(color: labelColor)),
            ),
          ),
        ),
      ),
    );
  }
}
