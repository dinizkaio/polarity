import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/settings_provider.dart';
import 'services/ads_service.dart';
import 'services/music_service.dart';
import 'services/purchases_service.dart';
import 'services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait lock só faz sentido em mobile. Na web/desktop ignora.
  if (!kIsWeb) {
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
  }

  await Hive.initFlutter();

  final settings = SettingsProvider();
  await settings.init();

  // PurchasesService e AdsService usam conditional imports — em web,
  // resolvidos como stubs no-op.
  final purchases = PurchasesService();
  await purchases.init();

  final ads = AdsService(purchases);
  // Ads inicializa em background — não bloqueia o startup (no-op em web)
  unawaited(ads.init());

  final sound = SoundService(settings);
  unawaited(sound.init());

  final music = MusicService(settings);
  unawaited(music.init());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<PurchasesService>.value(value: purchases),
        Provider<AdsService>.value(value: ads),
        Provider<SoundService>.value(value: sound),
        Provider<MusicService>.value(value: music),
      ],
      child: const PolaridadeApp(),
    ),
  );
}
