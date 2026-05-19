import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class PolaridadeApp extends StatelessWidget {
  const PolaridadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Polaridade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      locale: settings.locale,
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
