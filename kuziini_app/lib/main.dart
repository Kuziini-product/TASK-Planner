import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://vhczrmfdvfzdxoozwkbb.supabase.co',
    anonKey: 'sb_publishable_NL-mjZSt61BZdmH2cKjImw_lOhXODIK',
  );

  // Initialize notification service + request permission
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermission();

  runApp(
    const ProviderScope(
      child: KuziiniApp(),
    ),
  );
}
