import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final entries = <(String, String)>[
      (l10n.tutorialStep1Title, l10n.tutorialStep1Body),
      (l10n.tutorialStep2Title, l10n.tutorialStep2Body),
      (l10n.tutorialStep3Title, l10n.tutorialStep3Body),
      (l10n.tutorialStep4Title, l10n.tutorialStep4Body),
      (l10n.tutorialStep5Title, l10n.tutorialStep5Body),
      (l10n.tutorialStep6Title, l10n.tutorialStep6Body),
    ];

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(l10n.howToPlayTitle, style: AppTypography.h1()),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    for (int i = 0; i < entries.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.haloMinus.withOpacity(0.3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: AppTypography.uiLabel(size: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(entries[i].$1, style: AppTypography.cardTitle()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Text(entries[i].$2, style: AppTypography.body(size: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
