import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final levels = [
      _LevelData(
        difficulty: AiDifficulty.apprentice,
        name: l10n.difficultyApprentice,
        desc: l10n.difficultyApprenticeDesc,
        lookahead: l10n.difficultyLookahead1,
        glyph: '◔',
        hue: 200,
      ),
      _LevelData(
        difficulty: AiDifficulty.adept,
        name: l10n.difficultyAdept,
        desc: l10n.difficultyAdeptDesc,
        lookahead: l10n.difficultyLookahead3,
        glyph: '◑',
        hue: 280,
      ),
      _LevelData(
        difficulty: AiDifficulty.master,
        name: l10n.difficultyMaster,
        desc: l10n.difficultyMasterDesc,
        lookahead: l10n.difficultyLookahead5,
        glyph: '●',
        hue: 340,
      ),
    ];

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
                Text(l10n.difficultyTitle, style: AppTypography.h1()),
                const SizedBox(height: 24),
                ...levels.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LevelCard(
                        data: l,
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => GameScreen(difficulty: l.difficulty),
                            ),
                          );
                        },
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelData {
  final AiDifficulty difficulty;
  final String name;
  final String desc;
  final String lookahead;
  final String glyph;
  final int hue; // não usado diretamente; doc no design
  const _LevelData({
    required this.difficulty,
    required this.name,
    required this.desc,
    required this.lookahead,
    required this.glyph,
    required this.hue,
  });
}

class _LevelCard extends StatelessWidget {
  final _LevelData data;
  final VoidCallback onTap;
  const _LevelCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _hueColor(data.hue);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent, accent.withValues(alpha: 0.3)],
                ),
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 16),
                ],
              ),
              child: Center(
                child: Text(data.glyph,
                    style: AppTypography.h2(color: AppColors.bgVoid)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data.name, style: AppTypography.cardTitle()),
                      Text(data.lookahead, style: AppTypography.monoSmall(size: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data.desc, style: AppTypography.body(size: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hueColor(int hue) {
    // Aproximação de oklch(0.6 0.18 hue): converte HSL com saturação fixa
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.55).toColor();
  }
}
