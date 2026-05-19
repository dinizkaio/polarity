import 'package:flutter/services.dart';

import '../providers/settings_provider.dart';

class HapticsHelper {
  static void selection(SettingsProvider settings) {
    if (!settings.vibration) return;
    HapticFeedback.selectionClick();
  }

  static void medium(SettingsProvider settings) {
    if (!settings.vibration) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy(SettingsProvider settings) {
    if (!settings.vibration) return;
    HapticFeedback.heavyImpact();
  }

  static Future<void> victoryPattern(SettingsProvider settings) async {
    if (!settings.vibration) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
  }
}
