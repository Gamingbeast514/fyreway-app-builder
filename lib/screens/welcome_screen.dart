import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/glow_background.dart';
import '../widgets/logo.dart';
import 'home_screen.dart';

/// Launch offer: "Everything free for 3 months".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: GlowBackground(
        color: c.accent,
        child: SafeArea(
        // Scrolls on small phones instead of overflowing.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.ring, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const KovraLogo(size: 104),
                    ),
                    const SizedBox(height: 24),
                    Text('LAUNCH OFFER',
                        style: TextStyle(color: c.gold, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Text(
                      'Everything free\nfor 3 months',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, height: 1.15, fontWeight: FontWeight.w700, color: c.text),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Private, stable browsing on any WiFi. No card needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.5, color: c.muted),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border),
                      ),
                      child: const Column(
                        children: [
                          _Perk('All locations unlocked'),
                          SizedBox(height: 14),
                          _Perk('No ads, no card needed'),
                          SizedBox(height: 14),
                          _Perk('One-tap connect'),
                          SizedBox(height: 14),
                          _Perk('No browsing logs'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: c.onAccent,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        ),
                        child: const Text('Start free'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'By continuing you agree to our Terms and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: c.hint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final String label;
  const _Perk(this.label);

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Row(
      children: [
        Icon(Icons.check_rounded, color: c.green, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c.text))),
      ],
    );
  }
}
