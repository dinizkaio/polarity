import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import '../widgets/primary_button.dart';
import 'game_screen.dart';

/// Setup do modo local 1×1 (pass-and-play). Só seleciona quantos turnos.
/// Sem dificuldade — não tem IA.
class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  int _selectedTurns = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [20, 30, 40, 50];

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.localSetupTitle, style: AppTypography.h1()),
                const SizedBox(height: 12),
                Text(
                  l10n.localSetupBody,
                  style: AppTypography.body(color: AppColors.ink2),
                ),
                const SizedBox(height: 32),
                Text(l10n.difficultyTurnsLabel, style: AppTypography.eyebrow()),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: options.map((n) {
                      final isSelected = n == _selectedTurns;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTurns = n),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.haloPlus.withOpacity(0.6),
                                        AppColors.haloPlus.withOpacity(0.3),
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Center(
                              child: Text(
                                '$n',
                                style: AppTypography.uiButton(
                                  color: isSelected ? AppColors.bgVoid : AppColors.ink2,
                                ).copyWith(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: l10n.localSetupStart,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(
                          difficulty: AiDifficulty.apprentice, // não usado no local
                          maxTurns: _selectedTurns,
                          localMultiplayer: true,
                        ),
                      ),
                    );
                  },
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
