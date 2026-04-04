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
  bool _showLoader = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final bgColor = ref.watch(backgroundColorProvider);
    final btnColor = ref.watch(buttonColorProvider);
    final borderW = ref.watch(buttonBorderWidthProvider);
    final borderC = ref.watch(buttonBorderColorProvider);
    final textInt = ref.watch(textIntensityProvider);
    final router = ref.watch(appRouterProvider);

    // Auto-redirect to profile on first load
    if (!_redirected) {
      _redirected = true;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          router.go(AppRoutes.profile);
          setState(() => _showLoader = false);
        }
      });
    }

    return Stack(
      children: [
        MaterialApp.router(
      title: 'Kuziini Task Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(primaryColor, backgroundColor: bgColor, buttonColor: btnColor, borderWidth: borderW, borderColor: borderC, textIntensity: textInt),
      darkTheme: AppTheme.darkTheme(primaryColor, backgroundColor: bgColor, buttonColor: btnColor, borderWidth: borderW, borderColor: borderC, textIntensity: textInt),
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
    ),
      ],
    );
  }
}
