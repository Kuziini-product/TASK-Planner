import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/providers/auth_provider.dart';

class KuziiniApp extends ConsumerWidget {
  const KuziiniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final bgColor = ref.watch(backgroundColorProvider);
    final btnColor = ref.watch(buttonColorProvider);
    final borderW = ref.watch(buttonBorderWidthProvider);
    final borderC = ref.watch(buttonBorderColorProvider);
    final textInt = ref.watch(textIntensityProvider);
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);

    // Show splash while auth is loading
    final isLoading = authState.isLoading ||
        authState.valueOrNull == AuthStatus.initial;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
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
          // Splash — visible until auth resolves
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Image.asset(
                  'assets/images/kuziini_logo_portrait.png',
                  width: 200,
                  color: primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
