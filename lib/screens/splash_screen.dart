import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import 'menu_screen.dart';
import 'tutorial_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final next = settings.tutorialSeen ? const MenuScreen() : const TutorialScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo orbital
                SizedBox(
                  width: 140,
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _orbitController,
                    builder: (_, __) {
                      return Transform.rotate(
                        angle: _orbitController.value * 6.283185,
                        child: _OrbitalLogo(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(l10n.appName, style: AppTypography.displayXl()),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline.toUpperCase(),
                  style: AppTypography.eyebrow(color: AppColors.ink3),
                ),
                const SizedBox(height: 40),
                const _LoadingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow central
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.haloPlus.withOpacity(0.9),
                AppColors.haloMinus.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Peça ⊕ orbital esquerda
        Positioned(
          left: 0,
          child: _MiniPiece(color: AppColors.haloPlus, symbol: '⊕'),
        ),
        // Peça ⊖ orbital direita
        Positioned(
          right: 0,
          child: _MiniPiece(color: AppColors.haloMinus, symbol: '⊖'),
        ),
      ],
    );
  }
}

class _MiniPiece extends StatelessWidget {
  final Color color;
  final String symbol;
  const _MiniPiece({required this.color, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Text(symbol, style: AppTypography.pieceSymbol(color: AppColors.bgVoid, size: 16)),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value * 3 - i).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink2.withOpacity(opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
