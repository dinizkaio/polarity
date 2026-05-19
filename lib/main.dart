import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'services/ads_service.dart';
import 'services/purchases_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF06061A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();

  final settings = SettingsProvider();
  await settings.init();

  final purchases = PurchasesService();
  await purchases.init();

  final ads = AdsService(purchases);
  // Ads inicializa em background — não bloqueia o startup
  unawaited(ads.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<PurchasesService>.value(value: purchases),
        Provider<AdsService>.value(value: ads),
      ],
      child: const PolaridadeApp(),
    ),
  );
}
