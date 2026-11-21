import 'dart:async';

import 'package:flutter/material.dart';

import '../services/vpn_controller.dart';
import '../theme.dart';
import '../widgets/session_summary_sheet.dart';
import '../widgets/ui.dart';
import 'settings_pages.dart';
import '../widgets/kovra_icons.dart';

/// 2.6 Connection details: only values Kovra really knows.
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && vpn.status == VpnStatus.connected) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _disconnect() async {
    final ok = await showKovraConfirm(
      context,
      title: 'Turn off protection?',
      message: 'Your traffic will no longer be encrypted.',
      cancel: 'Stay protected',
      confirm: 'Disconnect',
    );
    if (!ok || !mounted) return;
    final summary = vpn.disconnect();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (summary != null) showSessionSummary(context, summary);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: ListenableBuilder(
        listenable: vpn,
        builder: (context, _) {
          final on = vpn.status == VpnStatus.connected;
          final s = vpn.activeServer ?? vpn.server;
          final start = vpn.connectedAt;
          final h = BrandSheetLayout.fit(context, 290);
          final top = MediaQuery.paddingOf(context).top;
          return BrandSheetLayout(
            brandHeight: h,
            brand: BrandArea(
              height: h,
              protected: on,
              child: Padding(
                padding: EdgeInsets.only(top: top + 52, bottom: kSheetOverlap + 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(on ? 'Connected for' : 'Not connected',
                          style: TextStyle(fontSize: 15, color: (on ? c.onPrimary : c.text).withAlpha(204))),
                      const SizedBox(height: 4),
                      Text(on && start != null ? fmtClock(DateTime.now().difference(start)) : '--:--:--',
                          style: KovraText.displayXL.copyWith(color: on ? c.onPrimary : c.muted)),
                    ]),
                  ),
                ),
              ),
            ),
            overlayTop: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  RoundIconButton(
                    icon: PhosphorIconsRegular.arrowLeft,
                    tooltip: 'Back',
                    background: on ? Colors.white.withAlpha(38) : c.card,
                    onTap: () => Navigator.pop(context),
                  ),
                ]),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(kPageX, 0, kPageX, 8),
              children: [
                Row(children: [
                  Expanded(
                      child: Text(on ? 'This session' : 'Selected location',
                          style: KovraText.title.copyWith(color: c.text))),
                  RoundIconButton(
                    icon: PhosphorIconsRegular.x,
                    tooltip: 'Close',
                    background: c.surface,
                    onTap: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 8),
                if (on && vpn.bytesIn != null) _row(PhosphorIconsRegular.arrowDown, 'Download', fmtBytes(vpn.bytesIn!)),
                if (on && vpn.bytesOut != null) _row(PhosphorIconsRegular.arrowUp, 'Upload', fmtBytes(vpn.bytesOut!)),
                if (s.pingMs != null && s.pingMs! > 0) _row(PhosphorIconsRegular.gauge, 'Ping', '${s.pingMs} ms'),
                if (s.speedMbps != null && s.speedMbps! > 0)
                  _row(PhosphorIconsRegular.lightning, 'Server speed', '${s.speedMbps!.toStringAsFixed(0)} Mbps'),
                _row(PhosphorIconsRegular.mapPin, 'Location', s.isLive ? s.country : s.displayName),
                if (s.isLive) _row(PhosphorIconsRegular.hardDrives, 'Server', s.host),
                if (s.ip != null) _row(PhosphorIconsRegular.globe, 'Server IP', s.ip!),
                _row(PhosphorIconsRegular.path, 'Protocol', 'OpenVPN'),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: c.primary),
                    onPressed: () => Navigator.of(context).push(sheetRoute(const AboutPage())),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('View diagnostics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Icon(PhosphorIconsRegular.caretRight, size: 14, color: c.primary),
                    ]),
                  ),
                ),
              ],
            ),
            bottom: on
                ? KovraButton.light(label: 'Disconnect', onPressed: _disconnect)
                : KovraButton.outline(label: 'Back to Home', onPressed: () => Navigator.pop(context)),
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    final c = context.kc;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: KvRow(icon: icon, label: label, value: value, padding: const EdgeInsets.symmetric(vertical: 16)),
    );
  }
}
