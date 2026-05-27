import 'package:flutter/material.dart';

import '../game/ai.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import 'game_screen.dart';

class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  int _selectedTurns = 30; // padrão pra Adepto/Mestre

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
        fixedTurns: 20, // Aprendiz sempre 20 turnos
      ),
      _LevelData(
        difficulty: AiDifficulty.adept,
        name: l10n.difficultyAdept,
        desc: l10n.difficultyAdeptDesc,
        lookahead: l10n.difficultyLookahead3,
        glyph: '◑',
        hue: 280,
        fixedTurns: null,
      ),
      _LevelData(
        difficulty: AiDifficulty.master,
        name: l10n.difficultyMaster,
        desc: l10n.difficultyMasterDesc,
        lookahead: l10n.difficultyLookahead5,
        glyph: '●',
        hue: 340,
        fixedTurns: null,
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
                const SizedBox(height: 16),
                // Seletor de turnos (afeta Adepto/Mestre)
                _TurnsSelector(
                  selected: _selectedTurns,
                  onChanged: (v) => setState(() => _selectedTurns = v),
                  label: l10n.difficultyTurnsLabel,
                ),
                const SizedBox(height: 16),
                ...levels.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LevelCard(
                        data: l,
                        turnsLabel: l.fixedTurns != null
                            ? l10n.difficultyTurnsFixed(l.fixedTurns!)
                            : l10n.difficultyTurnsChosen(_selectedTurns),
                        onTap: () {
                          final turns = l.fixedTurns ?? _selectedTurns;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                difficulty: l.difficulty,
                                maxTurns: turns,
                              ),
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
  final int hue;
  final int? fixedTurns;
  const _LevelData({
    required this.difficulty,
    required this.name,
    required this.desc,
    required this.lookahead,
    required this.glyph,
    required this.hue,
    required this.fixedTurns,
  });
}

class _TurnsSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final String label;
  const _TurnsSelector({
    required this.selected,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final options = [30, 40, 50];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.eyebrow()),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: options.map((n) {
              final isSelected = n == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                        ).copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final _LevelData data;
  final String turnsLabel;
  final VoidCallback onTap;
  const _LevelCard({
    required this.data,
    required this.turnsLabel,
    required this.onTap,
  });

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
            colors: [accent.withOpacity(0.25), accent.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent, accent.withOpacity(0.3)],
                ),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.5), blurRadius: 16),
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
                  const SizedBox(height: 4),
                  Text(turnsLabel, style: AppTypography.monoSmall(color: AppColors.ink2, size: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hueColor(int hue) {
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.55).toColor();
  }
}
