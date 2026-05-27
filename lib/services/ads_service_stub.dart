import 'purchases_service.dart';

/// Stub do AdsService usado em plataformas sem suporte ao google_mobile_ads
/// (web, desktop). Todas as operações são no-op.
class AdsService {
  // ignore: avoid_unused_constructor_parameters
  AdsService(PurchasesService purchases);

  bool get adsRemoved => true;

  Future<void> init() async {}

  Future<void> maybeShowInterstitialAfterMatch() async {}

  Future<bool> showRewarded() async => false;

  void dispose() {}
}
