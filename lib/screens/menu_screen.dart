import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import '../widgets/primary_button.dart';
import 'difficulty_screen.dart';
import 'how_to_play_screen.dart';
import 'local_setup_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo + título
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.haloPlus.withOpacity(0.8),
                        AppColors.haloMinus.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.appName, style: AppTypography.displayL()),
                const SizedBox(height: 8),
                Text(
                  l10n.appTagline.toUpperCase(),
                  style: AppTypography.eyebrow(color: AppColors.ink3),
                ),
                const Spacer(flex: 3),
                PrimaryButton(
                  label: l10n.menuPlay,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DifficultyScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: l10n.menuPlayLocal,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LocalSetupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: l10n.menuHowToPlay,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                GhostButton(
                  label: l10n.menuSettings,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const Spacer(flex: 2),
                Text(
                  l10n.menuVersionLabel('0.1'),
                  style: AppTypography.monoSmall(color: AppColors.ink4),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
