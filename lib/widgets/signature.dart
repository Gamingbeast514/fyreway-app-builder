import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// THE HIDDEN MARK: six stars in a "D" shape. No name anywhere, just the symbol.
/// It also hides in the app icon's night sky and on the splash screen.
/// Revealed by tapping the logo/version line in More six times.
class Signature {
  static const taps = 6;

  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.kc.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _SignatureSheet(),
    );
  }
}

/// Wrap any widget: tapping it [Signature.taps] times quickly reveals the signature.
class SecretTapTarget extends StatefulWidget {
  final Widget child;
  const SecretTapTarget({super.key, required this.child});

  @override
  State<SecretTapTarget> createState() => _SecretTapTargetState();
}

class _SecretTapTargetState extends State<SecretTapTarget> {
  int _count = 0;
  DateTime _last = DateTime(2000);

  void _tap() {
    final now = DateTime.now();
    _count = now.difference(_last) < const Duration(milliseconds: 700) ? _count + 1 : 1;
    _last = now;
    if (_count >= Signature.taps) {
      _count = 0;
      Signature.show(context);
    } else if (_count >= 3) {
      HapticFeedback.selectionClick(); // a tiny hint that something is there
    }
  }

  @override
  Widget build(BuildContext context) =>
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, child: widget.child);
}

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet();
  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 22),
          AnimatedBuilder(
            animation: _a,
            builder: (_, __) => SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(painter: DConstellation(_a.value, c.accent, c.green)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The six-star mark. Also used (static, t = 1) anywhere we want the mark.
class DConstellation extends CustomPainter {
  final double t; // 0..1 draw progress
  final Color a, b;
  final bool glow;
  DConstellation(this.t, this.a, this.b, {this.glow = true});

  /// Star positions (0..1): the stem top-to-bottom, then the curve back up.
  static const pts = [
    Offset(0.28, 0.16),
    Offset(0.28, 0.50),
    Offset(0.28, 0.84),
    Offset(0.62, 0.76),
    Offset(0.78, 0.48),
    Offset(0.60, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final p = [for (final o in pts) Offset(o.dx * s.width, o.dy * s.height)];
    final shader = LinearGradient(colors: [a, b]).createShader(Offset.zero & s);

    // Lines draw in first (0 -> 0.55), closing back to the first star.
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 1; i < p.length; i++) {
      path.lineTo(p[i].dx, p[i].dy);
    }
    path.close();
    final lineT = (t / 0.55).clamp(0.0, 1.0);
    for (final m in path.computeMetrics()) {
      canvas.drawPath(
        m.extractPath(0, m.length * lineT),
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = (s.width * 0.009).clamp(1.0, 2.0)
          ..strokeCap = StrokeCap.round
          ..color = a.withAlpha(170),
      );
    }

    // Stars pop in one by one, each with a soft glow.
    for (var i = 0; i < p.length; i++) {
      final st = ((t - i * 0.07) / 0.3).clamp(0.0, 1.0);
      if (st == 0) continue;
      final r = s.width * 0.02 * Curves.easeOutBack.transform(st);
      if (glow) canvas.drawCircle(p[i], r * 3.2, Paint()..color = a.withAlpha((60 * st).round())..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      _star(canvas, p[i], r, Color.lerp(a, b, i / 5)!);

    }
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final ang = -math.pi / 2 + k * math.pi / 4;
      final rad = k.isEven ? r * 1.6 : r * 0.45;
      final pt = c + Offset(math.cos(ang) * rad, math.sin(ang) * rad);
      k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
    canvas.drawCircle(c, r * 0.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(DConstellation o) => o.t != t;
}
