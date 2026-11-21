import 'dart:math';

import 'package:flutter/material.dart';

import '../services/network_tools.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/kovra_icons.dart';

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
    return SheetPage(
      title: 'Speed test',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        KovraButton.primary(
          label: _phase == _Phase.idle ? 'Start test' : (_running ? 'Testing…' : 'Test again'),
          icon: _running ? null : PhosphorIconsRegular.gauge,
          onPressed: _running ? null : _run,
        ),
        const SizedBox(height: 10),
        Text('Uses about 50–200 MB of data per test.', style: KovraText.caption.copyWith(color: c.hint)),
      ]),
      children: [
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: _GaugePainter(value: shown, track: c.line, fill: c.primary),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(_running || _phase == _Phase.done ? shown : null),
                      style: KovraText.displayXL.copyWith(fontSize: 46, color: c.text)),
                  Text('Mbps', style: TextStyle(fontSize: 14, color: c.muted)),
                  const SizedBox(height: 6),
                  Text(_label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _phase == _Phase.error ? c.danger : c.primary,
                      )),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GroupCard(children: [
          KvRow(icon: PhosphorIconsRegular.timer, label: 'Ping', value: _ping == null ? '—' : '$_ping ms'),
          KvRow(icon: PhosphorIconsRegular.arrowDown, label: 'Download', value: '${_fmt(_down)} Mbps'),
          KvRow(icon: PhosphorIconsRegular.arrowUp, label: 'Upload', value: '${_fmt(_up)} Mbps'),
        ]),
        const SizedBox(height: 12),
        Text(
          vpn.status == VpnStatus.connected
              ? 'Testing through the VPN: results show the speed of the server you are on.'
              : 'VPN is off: results show your own connection.',
          style: KovraText.caption.copyWith(color: c.muted),
        ),
      ],
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
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, p(track));
    final t = (value / max).clamp(0.0, 1.0);
    if (t > 0) canvas.drawArc(rect, start, sweep * t, false, p(fill));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.track != track || old.fill != fill;
}
