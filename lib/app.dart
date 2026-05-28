import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/music_service.dart';
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
      // Listener no root captura o PRIMEIRO toque/click do usuário e
      // inicia a música. Contorna autoplay block do browser (web não toca
      // áudio sem interação prévia). Mobile não tem esse bloqueio mas o
      // listener é idempotente — startIfNeeded() só dispara uma vez.
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            context.read<MusicService>().startIfNeeded();
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
