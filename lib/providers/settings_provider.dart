import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AnimationSpeed { normal, fast }

/// Preferências do usuário, persistidas em Hive box "settings".
class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  late final Box _box;

  static const String _kSound = 'sound';
  static const String _kVibration = 'vibration';
  static const String _kReducedMotion = 'reducedMotion';
  static const String _kColorblind = 'colorblind';
  static const String _kAnimationSpeed = 'animationSpeed';
  static const String _kLocale = 'locale';
  static const String _kTutorialSeen = 'tutorialSeen';

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  bool get sound => _box.get(_kSound, defaultValue: true) as bool;
  set sound(bool v) {
    _box.put(_kSound, v);
    notifyListeners();
  }

  bool get vibration => _box.get(_kVibration, defaultValue: true) as bool;
  set vibration(bool v) {
    _box.put(_kVibration, v);
    notifyListeners();
  }

  bool get reducedMotion => _box.get(_kReducedMotion, defaultValue: false) as bool;
  set reducedMotion(bool v) {
    _box.put(_kReducedMotion, v);
    notifyListeners();
  }

  bool get colorblind => _box.get(_kColorblind, defaultValue: false) as bool;
  set colorblind(bool v) {
    _box.put(_kColorblind, v);
    notifyListeners();
  }

  AnimationSpeed get animationSpeed {
    final raw = _box.get(_kAnimationSpeed, defaultValue: 'normal') as String;
    return AnimationSpeed.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => AnimationSpeed.normal,
    );
  }

  set animationSpeed(AnimationSpeed v) {
    _box.put(_kAnimationSpeed, v.name);
    notifyListeners();
  }

  /// Multiplicador de duração: rápido = 50% do normal.
  double get animationDurationMultiplier => animationSpeed == AnimationSpeed.fast ? 0.5 : 1.0;

  /// Locale escolhido manualmente. null = detectar do sistema.
  Locale? get locale {
    final raw = _box.get(_kLocale) as String?;
    if (raw == null) return null;
    return Locale(raw);
  }

  set locale(Locale? v) {
    if (v == null) {
      _box.delete(_kLocale);
    } else {
      _box.put(_kLocale, v.languageCode);
    }
    notifyListeners();
  }

  bool get tutorialSeen => _box.get(_kTutorialSeen, defaultValue: false) as bool;
  set tutorialSeen(bool v) {
    _box.put(_kTutorialSeen, v);
    notifyListeners();
  }
}
