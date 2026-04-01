import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class KuziiniApp extends ConsumerWidget {
  const KuziiniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final bgColor = ref.watch(backgroundColorProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Kuziini Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(primaryColor, backgroundColor: bgColor),
      darkTheme: AppTheme.darkTheme(primaryColor, backgroundColor: bgColor),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ro', ''),
      ],
    );
  }
}
