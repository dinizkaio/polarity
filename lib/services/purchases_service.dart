import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Gerencia compras non-consumable. Hoje só tem um produto: `remove_ads`.
///
/// Configuração de loja necessária:
/// - Play Console: produto não-consumível `remove_ads` por R\$ 9,90.
/// - App Store Connect: in-app purchase `remove_ads` (non-consumable),
///   localizado pra PT/EN/ES com preço Tier 2 (≈ R\$ 9,90 / US\$ 1.99).
///
/// O status é persistido localmente em Hive como fonte da verdade pra UI
/// offline; o status real vem do `restorePurchases()` na inicialização.
class PurchasesService extends ChangeNotifier {
  static const String productIdRemoveAds = 'remove_ads';
  static const String _boxName = 'purchases';
  static const String _kAdsRemoved = 'ads_removed';

  late final Box _box;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final InAppPurchase _iap = InAppPurchase.instance;

  bool _available = false;
  bool _purchasing = false;
  String? _lastError;
  List<ProductDetails> _products = const [];

  bool get adsRemoved => _box.get(_kAdsRemoved, defaultValue: false) as bool;
  bool get available => _available;
  bool get purchasing => _purchasing;
  String? get lastError => _lastError;
  List<ProductDetails> get products => _products;

  /// Override pra dev: marca como comprado sem ir na loja (não chamar em prod).
  void devOverride(bool removed) {
    _box.put(_kAdsRemoved, removed);
    notifyListeners();
  }

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _available = await _iap.isAvailable();
    if (!_available) {
      if (kDebugMode) debugPrint('IAP indisponível neste device');
      return;
    }

    _sub = _iap.purchaseStream.listen(_onPurchasesUpdate, onError: (e) {
      _lastError = e.toString();
      notifyListeners();
    });

    await _loadProducts();
    // Restaura compras no startup (em caso de reinstalação ou troca de device)
    unawaited(_iap.restorePurchases());
  }

  Future<void> _loadProducts() async {
    final resp = await _iap.queryProductDetails({productIdRemoveAds});
    if (resp.error != null && kDebugMode) {
      debugPrint('Erro ao buscar produtos: ${resp.error}');
    }
    _products = resp.productDetails;
    notifyListeners();
  }

  ProductDetails? get removeAdsProduct {
    for (final p in _products) {
      if (p.id == productIdRemoveAds) return p;
    }
    return null;
  }

  /// Inicia o fluxo de compra. Em iOS pode falhar se o usuário cancelar (sem
  /// erro tratado aqui — observe `lastError` e `purchasing`).
  Future<void> buyRemoveAds() async {
    final p = removeAdsProduct;
    if (p == null) {
      _lastError = 'product_unavailable';
      notifyListeners();
      return;
    }
    _purchasing = true;
    _lastError = null;
    notifyListeners();
    final param = PurchaseParam(productDetails: p);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    _lastError = null;
    notifyListeners();
    await _iap.restorePurchases();
  }

  void _onPurchasesUpdate(List<PurchaseDetails> purchases) {
    for (final pd in purchases) {
      if (pd.status == PurchaseStatus.pending) {
        _purchasing = true;
      } else {
        _purchasing = false;
        if (pd.status == PurchaseStatus.purchased ||
            pd.status == PurchaseStatus.restored) {
          if (pd.productID == productIdRemoveAds) {
            _box.put(_kAdsRemoved, true);
          }
        } else if (pd.status == PurchaseStatus.error) {
          _lastError = pd.error?.message ?? 'unknown_error';
        }
        if (pd.pendingCompletePurchase) {
          unawaited(_iap.completePurchase(pd));
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
