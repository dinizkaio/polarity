import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'purchases_service.dart';

/// Wrapper sobre google_mobile_ads. Centraliza lógica de cap, frequência, e
/// integração com a compra "remover anúncios".
///
/// Configuração necessária antes de release:
/// - android/app/src/main/AndroidManifest.xml: <meta-data
///   android:name="com.google.android.gms.ads.APPLICATION_ID"
///   android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
/// - ios/Runner/Info.plist: GADApplicationIdentifier + SKAdNetworkItems
/// - Substituir os IDs de teste abaixo pelos IDs de produção do AdMob.
class AdsService {
  // IDs de TESTE oficiais do AdMob — sempre seguros pra debug.
  // Substituir antes do release.
  static const _interstitialIdAndroidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const _interstitialIdIosTest = 'ca-app-pub-3940256099942544/4411468910';
  static const _rewardedIdAndroidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const _rewardedIdIosTest = 'ca-app-pub-3940256099942544/1712485313';

  final PurchasesService _purchases;
  AdsService(this._purchases);

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _initialized = false;

  /// Número de partidas concluídas desde o último intersticial.
  /// Limite: 1 intersticial a cada 2 partidas (anti-fadiga).
  int _matchesSinceLastInterstitial = 0;
  static const int _interstitialFrequency = 2;

  String get _interstitialUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _interstitialIdIosTest : _interstitialIdAndroidTest;
  String get _rewardedUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _rewardedIdIosTest : _rewardedIdAndroidTest;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    if (!_purchases.adsRemoved) {
      _loadInterstitial();
    }
    _loadRewarded();
  }

  bool get adsRemoved => _purchases.adsRemoved;

  void _loadInterstitial() {
    if (_purchases.adsRemoved) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (err) {
          if (kDebugMode) debugPrint('Intersticial fail: $err');
          _interstitial = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (err) {
          if (kDebugMode) debugPrint('Rewarded fail: $err');
          _rewarded = null;
        },
      ),
    );
  }

  /// Chamado ao fim de cada partida. Mostra intersticial se aplicável.
  Future<void> maybeShowInterstitialAfterMatch() async {
    if (_purchases.adsRemoved) return;
    _matchesSinceLastInterstitial++;
    if (_matchesSinceLastInterstitial < _interstitialFrequency) return;

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    _matchesSinceLastInterstitial = 0;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  /// Mostra rewarded ad e retorna true se o usuário ganhou a recompensa.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final completer = _RewardCompleter();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        completer.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => completer.markEarned());
    return completer.future;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}

class _RewardCompleter {
  bool _earned = false;
  final _completer = Completer<bool>();
  void markEarned() => _earned = true;
  void complete() {
    if (!_completer.isCompleted) _completer.complete(_earned);
  }

  Future<bool> get future => _completer.future;
}
