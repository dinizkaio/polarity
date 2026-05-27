import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/purchases_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/cosmic_backdrop.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: CosmicBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(l10n.settingsTitle, style: AppTypography.h1()),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _Section(
                      title: l10n.settingsSectionGameplay,
                      children: [
                        _PreviewModeTile(
                          label: l10n.settingsPreviewMode,
                          selected: settings.previewMode,
                          onChanged: (v) => settings.previewMode = v,
                          autoLabel: l10n.settingsPreviewAuto,
                          alwaysLabel: l10n.settingsPreviewAlways,
                          neverLabel: l10n.settingsPreviewNever,
                        ),
                        _SwitchTile(
                          label: l10n.settingsReducedMotion,
                          value: settings.reducedMotion,
                          onChanged: (v) => settings.reducedMotion = v,
                        ),
                        _SwitchTile(
                          label: l10n.settingsColorblind,
                          value: settings.colorblind,
                          onChanged: (v) => settings.colorblind = v,
                        ),
                        _SegmentTile(
                          label: l10n.settingsAnimationSpeed,
                          options: [
                            (AnimationSpeed.normal, l10n.settingsAnimationNormal),
                            (AnimationSpeed.fast, l10n.settingsAnimationFast),
                          ],
                          selected: settings.animationSpeed,
                          onChanged: (v) => settings.animationSpeed = v,
                        ),
                      ],
                    ),
                    _Section(
                      title: l10n.settingsSectionSound,
                      children: [
                        _SwitchTile(
                          label: l10n.settingsSound,
                          value: settings.sound,
                          onChanged: (v) => settings.sound = v,
                        ),
                        _SwitchTile(
                          label: l10n.settingsVibration,
                          value: settings.vibration,
                          onChanged: (v) => settings.vibration = v,
                        ),
                      ],
                    ),
                    _Section(
                      title: l10n.settingsSectionLanguage,
                      children: [
                        _LanguageTile(
                          current: settings.locale,
                          onChanged: (v) => settings.locale = v,
                        ),
                      ],
                    ),
                    _Section(
                      title: l10n.settingsSectionStore,
                      children: const [_RemoveAdsTile()],
                    ),
                    _Section(
                      title: l10n.settingsSectionAbout,
                      children: const [_AboutTile(version: '0.9.0')],
                    ),
                    const SizedBox(height: 32),
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

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(title.toUpperCase(), style: AppTypography.eyebrow()),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label, style: AppTypography.body(color: AppColors.ink, size: 15)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.haloMinus,
    );
  }
}

class _SegmentTile extends StatelessWidget {
  final String label;
  final List<(AnimationSpeed, String)> options;
  final AnimationSpeed selected;
  final ValueChanged<AnimationSpeed> onChanged;
  const _SegmentTile({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.body(color: AppColors.ink, size: 15)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((o) {
                final isSel = o.$1 == selected;
                return GestureDetector(
                  onTap: () => onChanged(o.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.haloMinus.withOpacity(0.4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      o.$2,
                      style: AppTypography.monoSmall(
                        color: isSel ? AppColors.ink : AppColors.ink3,
                        size: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale? current;
  final ValueChanged<Locale?> onChanged;
  const _LanguageTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Idioma / Language / Idioma',
          style: AppTypography.body(color: AppColors.ink, size: 15)),
      trailing: DropdownButton<String>(
        value: current?.languageCode ?? 'auto',
        dropdownColor: AppColors.bgMid,
        underline: const SizedBox(),
        style: AppTypography.body(color: AppColors.ink2, size: 14),
        items: const [
          DropdownMenuItem(value: 'auto', child: Text('Auto')),
          DropdownMenuItem(value: 'pt', child: Text('Português')),
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'es', child: Text('Español')),
        ],
        onChanged: (v) {
          if (v == null) return;
          onChanged(v == 'auto' ? null : Locale(v));
        },
      ),
    );
  }
}

class _RemoveAdsTile extends StatelessWidget {
  const _RemoveAdsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final purchases = context.watch<PurchasesService>();
    final product = purchases.removeAdsProduct;
    final priceLabel = product?.price ?? l10n.iapRemoveAdsCta;
    final canBuy = purchases.available && product != null && !purchases.adsRemoved && !purchases.purchasing;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.haloPlus, size: 18),
              const SizedBox(width: 8),
              Text(l10n.iapRemoveAdsTitle, style: AppTypography.uiLabel(size: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            purchases.adsRemoved ? l10n.iapRemoveAdsActive : l10n.iapRemoveAdsBody,
            style: AppTypography.body(color: AppColors.ink2, size: 13),
          ),
          const SizedBox(height: 12),
          if (purchases.adsRemoved)
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.haloPlus, size: 18),
                const SizedBox(width: 6),
                Text(l10n.iapSuccess, style: AppTypography.monoSmall(color: AppColors.haloPlus)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.haloPlus,
                      foregroundColor: AppColors.bgVoid,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: canBuy
                        ? () async {
                            await purchases.buyRemoveAds();
                            if (!context.mounted) return;
                            final err = purchases.lastError;
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.iapErrorGeneric)),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      product != null
                          ? '${l10n.iapRemoveAdsTitle} — $priceLabel'
                          : l10n.iapRemoveAdsCta,
                      style: AppTypography.uiButton(color: AppColors.bgVoid),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: purchases.available ? () => purchases.restore() : null,
            child: Text(l10n.iapRestore, style: AppTypography.monoSmall()),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final String version;
  const _AboutTile({required this.version});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        ListTile(
          title: Text(l10n.settingsPrivacy, style: AppTypography.body(color: AppColors.ink, size: 15)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.ink3),
          onTap: () {/* TODO: abrir política */},
        ),
        ListTile(
          title: Text(l10n.settingsTerms, style: AppTypography.body(color: AppColors.ink, size: 15)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.ink3),
          onTap: () {/* TODO: abrir termos */},
        ),
        ListTile(
          title: Text(l10n.settingsCredits, style: AppTypography.body(color: AppColors.ink, size: 15)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.ink3),
          onTap: () {/* TODO: abrir créditos */},
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.settingsVersion(version),
              style: AppTypography.monoSmall(color: AppColors.ink4),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewModeTile extends StatelessWidget {
  final String label;
  final PreviewMode selected;
  final ValueChanged<PreviewMode> onChanged;
  final String autoLabel;
  final String alwaysLabel;
  final String neverLabel;

  const _PreviewModeTile({
    required this.label,
    required this.selected,
    required this.onChanged,
    required this.autoLabel,
    required this.alwaysLabel,
    required this.neverLabel,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (PreviewMode.auto, autoLabel),
      (PreviewMode.always, alwaysLabel),
      (PreviewMode.never, neverLabel),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.body(color: AppColors.ink, size: 15)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((o) {
                final isSel = o.$1 == selected;
                return GestureDetector(
                  onTap: () => onChanged(o.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.haloMinus.withOpacity(0.4) : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      o.$2,
                      style: AppTypography.monoSmall(
                        color: isSel ? AppColors.ink : AppColors.ink3,
                        size: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
