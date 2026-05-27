import 'package:flutter/foundation.dart';

/// Stub do PurchasesService pra plataformas sem suporte ao in_app_purchase
/// (web, desktop). UI de loja fica desabilitada — sempre reporta "indisponível".
class PurchasesService extends ChangeNotifier {
  static const String productIdRemoveAds = 'remove_ads';

  bool get adsRemoved => false;
  bool get available => false;
  bool get purchasing => false;
  String? get lastError => null;

  // Retorna null — UI de loja mostra placeholder/preço estático
  dynamic get removeAdsProduct => null;

  Future<void> init() async {}
  Future<void> buyRemoveAds() async {}
  Future<void> restore() async {}

  void devOverride(bool removed) {}
}
