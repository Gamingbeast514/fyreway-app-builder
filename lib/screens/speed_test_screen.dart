import 'dart:math';

import 'package:flutter/material.dart';

import '../services/network_tools.dart';
import '../theme.dart';

enum _Phase { idle, ping, download, upload, done, error }

/// Real internet speed test: ping, download, upload.
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  _Phase _phase = _Phase.idle;
  double _live = 0;
  int? _ping;
  double? _down, _up;

  bool get _running => _phase == _Phase.ping || _phase == _Phase.download || _phase == _Phase.upload;

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.ping;
      _live = 0;
      _ping = null;
      _down = null;
      _up = null;
    });
    try {
      final p = await NetworkTools.pingMs();
      if (!mounted) return;
      setState(() {
        _ping = p;
        _phase = _Phase.download;
      });
      final d = await NetworkTools.downloadMbps(onProgress: (v) {
        if (mounted) setState(() => _live = v);
      });
      if (!mounted) return;
      setState(() {
        _down = d;
        _live = 0;
        _phase = _Phase.upload;
      });
      final u = await NetworkTools.uploadMbps(onProgress: (v) {
        if (mounted) setState(() => _live = v);
      });
      if (!mounted) return;
      setState(() {
        _up = u;
        _live = u;
        _phase = _Phase.done;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  String get _label => switch (_phase) {
        _Phase.idle => 'Ready',
        _Phase.ping => 'Checking ping…',
        _Phase.download => 'Download',
        _Phase.upload => 'Upload',
        _Phase.done => 'Done',
        _Phase.error => 'Test failed. Check your internet.',
      };

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(v >= 100 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final shown = _phase == _Phase.done ? (_down ?? 0) : _live;
    return Scaffold(
      appBar: AppBar(title: const Text('Speed test', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _GaugePainter(value: shown, track: c.ring2, fill: c.accent),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_fmt(_running || _phase == _Phase.done ? shown : null),
                        style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: c.text)),
                    Text('Mbps', style: TextStyle(fontSize: 14, color: c.muted)),
                    const SizedBox(height: 6),
                    Text(_label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accent)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _Stat(icon: Icons.timer_outlined, label: 'Ping', value: _ping == null ? '—' : '$_ping ms')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(icon: Icons.download_rounded, label: 'Download', value: '${_fmt(_down)} Mbps')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(icon: Icons.upload_rounded, label: 'Upload', value: '${_fmt(_up)} Mbps')),
          ]),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: _running ? null : _run,
              child: Text(_phase == _Phase.idle ? 'Start test' : (_running ? 'Testing…' : 'Test again')),
            ),
          ),
          const SizedBox(height: 12),
          Text('Uses about 50–200 MB of data per test.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.hint)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: c.accent),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
        ),
      ]),
    );
  }
}

/// 270° arc gauge. Scale grows to 500 Mbps for fast connections.
class _GaugePainter extends CustomPainter {
  final double value;
  final Color track, fill;
  _GaugePainter({required this.value, required this.track, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    const start = pi * 0.75;
    const sweep = pi * 1.5;
    final max = value > 100 ? 500.0 : 100.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 14);
    Paint p(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, p(track));
    final t = (value / max).clamp(0.0, 1.0);
    if (t > 0) canvas.drawArc(rect, start, sweep * t, false, p(fill));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.track != track || old.fill != fill;
}
