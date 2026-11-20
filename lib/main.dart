import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() => runApp(const KovraApp());

class KovraApp extends StatelessWidget {
  const KovraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kovra VPN',
      debugShowCheckedModeBanner: false,
      theme: buildKovraTheme(), // dark only
      home: const SplashScreen(),
    );
  }
}
