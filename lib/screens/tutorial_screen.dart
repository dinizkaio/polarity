import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';
import '../widgets/primary_button.dart';
import 'difficulty_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  final _pageController = PageController();

  static const int _totalSteps = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_StepData> _buildSteps(AppLocalizations l10n) => [
        _StepData(
          title: l10n.tutorialStep1Title,
          body: l10n.tutorialStep1Body,
          illustration: _placementIllustration,
        ),
        _StepData(
          title: l10n.tutorialStep2Title,
          body: l10n.tutorialStep2Body,
          illustration: _attractionIllustration,
        ),
        _StepData(
          title: l10n.tutorialStep3Title,
          body: l10n.tutorialStep3Body,
          illustration: _repulsionIllustration,
        ),
        _StepData(
          title: l10n.tutorialStep4Title,
          body: l10n.tutorialStep4Body,
          illustration: _destructionIllustration,
        ),
        _StepData(
          title: l10n.tutorialStep5Title,
          body: l10n.tutorialStep5Body,
          illustration: _victoryIllustration,
        ),
      ];

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    final settings = context.read<SettingsProvider>();
    settings.tutorialSeen = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DifficultyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _buildSteps(l10n);

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // Header com Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.tutorialStep(_step + 1, _totalSteps),
                      style: AppTypography.eyebrow(),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.tutorialSkip,
                        style: AppTypography.monoSmall(color: AppColors.ink2),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(_totalSteps, (i) {
                    final filled = i <= _step;
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: filled
                              ? AppColors.haloMinus
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Conteúdo
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _step = i),
                  itemCount: _totalSteps,
                  itemBuilder: (context, i) {
                    final step = steps[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Center(child: step.illustration()),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: AppTypography.h1(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  step.body,
                                  style: AppTypography.body(size: 15),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: PrimaryButton(
                  label: _step < _totalSteps - 1
                      ? l10n.tutorialNext
                      : l10n.tutorialPlayFirstGame,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === Ilustrações esquemáticas (CustomPaint simples) ===
  // Cada uma representa o conceito do passo com bolinhas estilizadas

  Widget _placementIllustration() => _IllustrationDot(symbol: '⊕', color: AppColors.haloPlus);
  Widget _attractionIllustration() => _PairIllustration(
        leftColor: AppColors.haloPlus,
        rightColor: AppColors.haloMinus,
        kind: _PairKind.attract,
      );
  Widget _repulsionIllustration() => _PairIllustration(
        leftColor: AppColors.haloPlus,
        rightColor: AppColors.haloPlus,
        kind: _PairKind.repel,
      );
  Widget _destructionIllustration() => _PairIllustration(
        leftColor: AppColors.haloPlus,
        rightColor: AppColors.haloPlus,
        kind: _PairKind.destroy,
      );
  Widget _victoryIllustration() => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.haloPlus.withValues(alpha: 0.9),
              AppColors.haloPlus.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.star, size: 60, color: AppColors.bgVoid),
        ),
      );
}

class _StepData {
  final String title;
  final String body;
  final Widget Function() illustration;
  const _StepData({
    required this.title,
    required this.body,
    required this.illustration,
  });
}

class _IllustrationDot extends StatelessWidget {
  final String symbol;
  final Color color;
  const _IllustrationDot({required this.symbol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 24),
        ],
      ),
      child: Center(
        child: Text(symbol, style: AppTypography.pieceSymbol(color: AppColors.bgVoid, size: 44)),
      ),
    );
  }
}

enum _PairKind { attract, repel, destroy }

class _PairIllustration extends StatelessWidget {
  final Color leftColor;
  final Color rightColor;
  final _PairKind kind;
  const _PairIllustration({
    required this.leftColor,
    required this.rightColor,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = switch (kind) {
      _PairKind.attract => '→ ←',
      _PairKind.repel => '← →',
      _PairKind.destroy => '← ✕',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IllustrationDot(
          symbol: leftColor == AppColors.haloPlus ? '⊕' : '⊖',
          color: leftColor,
        ),
        const SizedBox(width: 16),
        Text(arrow, style: AppTypography.h1(color: AppColors.ink2)),
        const SizedBox(width: 16),
        if (kind != _PairKind.destroy)
          _IllustrationDot(
            symbol: rightColor == AppColors.haloPlus ? '⊕' : '⊖',
            color: rightColor,
          )
        else
          const SizedBox(width: 100, height: 100),
      ],
    );
  }
}
