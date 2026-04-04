import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class KuziiniApp extends ConsumerStatefulWidget {
  const KuziiniApp({super.key});

  @override
  ConsumerState<KuziiniApp> createState() => _KuziiniAppState();
}

class _KuziiniAppState extends ConsumerState<KuziiniApp> {
  bool _redirected = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final bgColor = ref.watch(backgroundColorProvider);
    final btnColor = ref.watch(buttonColorProvider);
    final borderW = ref.watch(buttonBorderWidthProvider);
    final borderC = ref.watch(buttonBorderColorProvider);
    final router = ref.watch(appRouterProvider);

    // Auto-redirect to profile after first build
    if (!_redirected) {
      _redirected = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          router.go(AppRoutes.profile);
        }
      });
    }

    return MaterialApp.router(
      title: 'Kuziini Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(primaryColor, backgroundColor: bgColor, buttonColor: btnColor, borderWidth: borderW, borderColor: borderC),
      darkTheme: AppTheme.darkTheme(primaryColor, backgroundColor: bgColor, buttonColor: btnColor, borderWidth: borderW, borderColor: borderC),
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
