import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'strings_pt.dart';
import 'strings_en.dart';
import 'strings_es.dart';

/// Localizações hand-rolled (não gerado por flutter gen-l10n).
/// Mantém o mesmo padrão de uso: `AppLocalizations.of(context).keyName`.
/// Para adicionar uma nova string: adicione em strings_pt.dart, strings_en.dart, strings_es.dart.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(loc != null, 'AppLocalizations não disponível. Adicione AppLocalizations.delegate.');
    return loc!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('pt'),
    Locale('en'),
    Locale('es'),
  ];

  String _get(String key) {
    final v = _strings[key];
    if (v == null) {
      if (kDebugMode) {
        // Cai pro PT como fallback de desenvolvimento
        return ptStrings[key] ?? 'MISSING:$key';
      }
      return ptStrings[key] ?? '';
    }
    return v;
  }

  String _format(String key, Map<String, Object?> params) {
    var s = _get(key);
    params.forEach((k, v) {
      s = s.replaceAll('{$k}', v?.toString() ?? '');
    });
    return s;
  }

  // ===== Strings simples =====
  String get appName => _get('appName');
  String get appTagline => _get('appTagline');

  String get menuPlay => _get('menuPlay');
  String get menuHowToPlay => _get('menuHowToPlay');
  String get menuSettings => _get('menuSettings');
  String get menuAbout => _get('menuAbout');
  String menuVersionLabel(String version) => _format('menuVersionLabel', {'version': version});

  String get difficultyTitle => _get('difficultyTitle');
  String get difficultyApprentice => _get('difficultyApprentice');
  String get difficultyAdept => _get('difficultyAdept');
  String get difficultyMaster => _get('difficultyMaster');
  String get difficultyApprenticeDesc => _get('difficultyApprenticeDesc');
  String get difficultyAdeptDesc => _get('difficultyAdeptDesc');
  String get difficultyMasterDesc => _get('difficultyMasterDesc');
  String get difficultyLookahead1 => _get('difficultyLookahead1');
  String get difficultyLookahead3 => _get('difficultyLookahead3');
  String get difficultyLookahead5 => _get('difficultyLookahead5');
  String get difficultyTurnsLabel => _get('difficultyTurnsLabel');
  String difficultyTurnsFixed(int n) => _format('difficultyTurnsFixed', {'n': n});
  String difficultyTurnsChosen(int n) => _format('difficultyTurnsChosen', {'n': n});

  String gameTurnLabel(int current, int total) =>
      _format('gameTurnLabel', {'current': current, 'total': total});
  String get gameYourTurn => _get('gameYourTurn');
  String get gameAiTurn => _get('gameAiTurn');
  String get gameThinking => _get('gameThinking');
  String get gameMagneticReaction => _get('gameMagneticReaction');
  String get gamePlayer => _get('gamePlayer');
  String get gameAi => _get('gameAi');
  String get gamePlayer1 => _get('gamePlayer1');
  String get gamePlayer2 => _get('gamePlayer2');
  String get gamePlayer1Short => _get('gamePlayer1Short');
  String get gamePlayer2Short => _get('gamePlayer2Short');
  String get gamePolarityNeutral => _get('gamePolarityNeutral');
  String get tutorialNeutralTitle => _get('tutorialNeutralTitle');
  String get tutorialNeutralBody => _get('tutorialNeutralBody');
  String get previewLabel => _get('previewLabel');
  String get previewNoEffect => _get('previewNoEffect');
  String previewOppGains(int n) => _format('previewOppGains', {'n': n});
  String previewSteal(int n) => _format('previewSteal', {'n': n});
  String get previewConfirm => _get('previewConfirm');
  String get previewCancel => _get('previewCancel');
  String get settingsPreviewMode => _get('settingsPreviewMode');
  String get settingsPreviewAuto => _get('settingsPreviewAuto');
  String get settingsPreviewAlways => _get('settingsPreviewAlways');
  String get settingsPreviewNever => _get('settingsPreviewNever');
  String get endPlayer1Wins => _get('endPlayer1Wins');
  String get endPlayer2Wins => _get('endPlayer2Wins');
  String get menuPlayLocal => _get('menuPlayLocal');
  String get localSetupTitle => _get('localSetupTitle');
  String get localSetupBody => _get('localSetupBody');
  String get localSetupStart => _get('localSetupStart');
  String gameOnBoard(int n) => _format('gameOnBoard', {'n': n});
  String get gameStockLabel => _get('gameStockLabel');
  String get gameActionPlace => _get('gameActionPlace');
  String get gameActionFlip => _get('gameActionFlip');
  String get gameChoosePolarity => _get('gameChoosePolarity');
  String get gamePieceSelected => _get('gamePieceSelected');
  String get gamePolarityPositive => _get('gamePolarityPositive');
  String get gamePolarityNegative => _get('gamePolarityNegative');
  String get gameInstructionPlace => _get('gameInstructionPlace');
  String get gameInstructionFlip => _get('gameInstructionFlip');
  String get gameHint => _get('gameHint');
  String get gameUndo => _get('gameUndo');
  String get gameCancel => _get('gameCancel');
  String get gameResonance => _get('gameResonance');
  String resonanceBonusToast(int n) => _format('resonanceBonusToast', {'n': n});
  String get gameCrossoverHint => _get('gameCrossoverHint');
  String lineToast(int length, int points) =>
      _format('lineToast', {'length': length, 'points': points});
  String get gameScoreLabel => _get('gameScoreLabel');

  String get endGameLabel => _get('endGameLabel');
  String get endVictory => _get('endVictory');
  String get endDefeat => _get('endDefeat');
  String get endDraw => _get('endDraw');
  String get endVictoryTagline => _get('endVictoryTagline');
  String get endDefeatTagline => _get('endDefeatTagline');
  String get endDrawTagline => _get('endDrawTagline');
  String get endStatYou => _get('endStatYou');
  String get endStatTurns => _get('endStatTurns');
  String get endStatAi => _get('endStatAi');
  String get endStatDestroyed => _get('endStatDestroyed');
  String get endStatPoints => _get('endStatPoints');
  String get endNewGame => _get('endNewGame');
  String get endMenu => _get('endMenu');
  String get endShareResult => _get('endShareResult');
  String shareText(int player, int ai) => _format('shareText', {'player': player, 'ai': ai});

  String get pauseTitle => _get('pauseTitle');
  String get pauseResume => _get('pauseResume');
  String get pauseRestart => _get('pauseRestart');
  String get pauseQuit => _get('pauseQuit');
  String get quitConfirmTitle => _get('quitConfirmTitle');
  String get quitConfirmBody => _get('quitConfirmBody');
  String get quitConfirmYes => _get('quitConfirmYes');
  String get quitConfirmNo => _get('quitConfirmNo');

  String get rewardedHintBody => _get('rewardedHintBody');
  String get rewardedUndoBody => _get('rewardedUndoBody');
  String get rewardedWatch => _get('rewardedWatch');
  String get rewardedNotNow => _get('rewardedNotNow');

  String get settingsTitle => _get('settingsTitle');
  String get settingsSectionGameplay => _get('settingsSectionGameplay');
  String get settingsSectionSound => _get('settingsSectionSound');
  String get settingsSectionLanguage => _get('settingsSectionLanguage');
  String get settingsSectionAbout => _get('settingsSectionAbout');
  String get settingsSectionStore => _get('settingsSectionStore');
  String get settingsSound => _get('settingsSound');
  String get settingsVibration => _get('settingsVibration');
  String get settingsLanguage => _get('settingsLanguage');
  String get settingsReducedMotion => _get('settingsReducedMotion');
  String get settingsColorblind => _get('settingsColorblind');
  String get settingsAnimationSpeed => _get('settingsAnimationSpeed');
  String get settingsAnimationNormal => _get('settingsAnimationNormal');
  String get settingsAnimationFast => _get('settingsAnimationFast');
  String get settingsPrivacy => _get('settingsPrivacy');
  String get settingsTerms => _get('settingsTerms');
  String get settingsCredits => _get('settingsCredits');
  String settingsVersion(String version) => _format('settingsVersion', {'version': version});

  String get iapRemoveAdsTitle => _get('iapRemoveAdsTitle');
  String get iapRemoveAdsBody => _get('iapRemoveAdsBody');
  String get iapRemoveAdsCta => _get('iapRemoveAdsCta');
  String get iapRemoveAdsActive => _get('iapRemoveAdsActive');
  String get iapRestore => _get('iapRestore');
  String get iapErrorGeneric => _get('iapErrorGeneric');
  String get iapSuccess => _get('iapSuccess');

  String get tutorialSkip => _get('tutorialSkip');
  String tutorialStep(int current, int total) =>
      _format('tutorialStep', {'current': current, 'total': total});
  String get tutorialNext => _get('tutorialNext');
  String get tutorialPlayFirstGame => _get('tutorialPlayFirstGame');
  String get tutorialStep1Title => _get('tutorialStep1Title');
  String get tutorialStep1Body => _get('tutorialStep1Body');
  String get tutorialStep2Title => _get('tutorialStep2Title');
  String get tutorialStep2Body => _get('tutorialStep2Body');
  String get tutorialStep3Title => _get('tutorialStep3Title');
  String get tutorialStep3Body => _get('tutorialStep3Body');
  String get tutorialStep4Title => _get('tutorialStep4Title');
  String get tutorialStep4Body => _get('tutorialStep4Body');
  String get tutorialStep5Title => _get('tutorialStep5Title');
  String get tutorialStep5Body => _get('tutorialStep5Body');
  String get tutorialStep6Title => _get('tutorialStep6Title');
  String get tutorialStep6Body => _get('tutorialStep6Body');

  String get howToPlayTitle => _get('howToPlayTitle');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['pt', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizations(locale, enStrings);
      case 'es':
        return AppLocalizations(locale, esStrings);
      case 'pt':
      default:
        return AppLocalizations(locale, ptStrings);
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
