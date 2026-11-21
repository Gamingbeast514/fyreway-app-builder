import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';
import 'widgets/ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status bar, with light icons.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kLightBars);
  runApp(const KovraApp());
}

class KovraApp extends StatelessWidget {
  const KovraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildKovraTheme(), // dark only
      home: const SplashScreen(),
    );
  }
}
