import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/server.dart';
import '../services/vpn_controller.dart';
import '../services/vpngate_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'permission_screen.dart';
import '../widgets/kovra_icons.dart';

enum SmartMode { best, ping, speed }

/// 3.4 Smart Connect, the honest version: three real ways to rank the free
/// VPN Gate servers. Each one changes which server Kovra connects to.
class SmartConnectScreen extends StatefulWidget {
  const SmartConnectScreen({super.key});

  @override
  State<SmartConnectScreen> createState() => _SmartConnectScreenState();
}

class _SmartConnectScreenState extends State<SmartConnectScreen> {
  SmartMode _mode = SmartMode.best;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    vpnGate.load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && vpn.status == VpnStatus.connected) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// The server each mode picks right now (null if the list is empty).
  static VpnServer? pick(SmartMode m) {
    final all = vpnGate.all;
    if (all.isEmpty) return null;
    switch (m) {
      case SmartMode.best:
        return autoFreeServer; // tries the top-scored servers, with backups
      case SmartMode.ping:
        final l = all.where((s) => (s.pingMs ?? 0) > 0).toList()..sort((a, b) => a.pingMs!.compareTo(b.pingMs!));
        return l.firstOrNull;
      case SmartMode.speed:
        final l = all.where((s) => (s.speedMbps ?? 0) > 0).toList()
          ..sort((a, b) => b.speedMbps!.compareTo(a.speedMbps!));
        return l.firstOrNull;
    }
  }

  Future<void> _go(VpnServer s) async {
    final nav = Navigator.of(context);
    final off = vpn.status == VpnStatus.disconnected;
    if (off && !await ensureVpnExplained(context)) return;
    nav.popUntil((r) => r.settings.name == kHomeRoute.name || r.isFirst);
    vpn.clearError();
    if (off) {
      await vpn.selectServer(s);
      vpn.connect();
    } else {
      vpn.selectServer(s); // switches on the fly
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([vpn, vpnGate]),
        builder: (context, _) {
          final on = vpn.status == VpnStatus.connected;
          final h = BrandSheetLayout.fit(context, 250);
          final target = pick(_mode);
          final start = vpn.connectedAt;
          final label = target == null
              ? (vpnGate.loading ? 'Loading servers…' : 'No free servers online')
              : target.isAuto
                  ? '${on ? 'Switch' : 'Connect'} to best free location'
                  : '${on ? 'Switch' : 'Connect'} to ${target.country}${target.stats.isEmpty ? '' : ' · ${_mode == SmartMode.speed ? '${target.speedMbps!.toStringAsFixed(0)} Mbps' : '${target.pingMs} ms'}'}';
          return BrandSheetLayout(
            brandHeight: h,
            brand: BrandArea(
              height: h,
              protected: on,
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 40, bottom: kSheetOverlap),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(on ? 'Connected' : 'Not protected',
                        style: KovraText.display.copyWith(color: on ? c.onPrimary : c.text)),
                    const SizedBox(height: 4),
                    Text(
                      on && start != null
                          ? fmtClock(DateTime.now().difference(start))
                          : 'Pick how ${AppConfig.brand} chooses',
                      style: TextStyle(
                          fontSize: 14,
                          color: (on ? c.onPrimary : c.muted).withAlpha(220),
                          fontFeatures: KovraText.tabular),
                    ),
                  ]),
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(kPageX, 0, kPageX, 8),
              children: [
                Row(children: [
                  Expanded(child: Text('Smart Connect', style: KovraText.title.copyWith(color: c.text))),
                  RoundIconButton(
                    icon: PhosphorIconsRegular.x,
                    tooltip: 'Close',
                    background: c.surface,
                    onTap: () => Navigator.pop(context),
                  ),
                ]),
                const SectionLabel('Optimize for', padding: EdgeInsets.fromLTRB(0, 16, 0, 8)),
                _Option(
                  title: 'Best overall',
                  hint: 'Top VPN Gate score',
                  selected: _mode == SmartMode.best,
                  onTap: () => setState(() => _mode = SmartMode.best),
                ),
                _Option(
                  title: 'Lowest ping',
                  hint: 'As VPN Gate measured',
                  selected: _mode == SmartMode.ping,
                  onTap: () => setState(() => _mode = SmartMode.ping),
                ),
                _Option(
                  title: 'Fastest server',
                  hint: 'For big downloads',
                  selected: _mode == SmartMode.speed,
                  onTap: () => setState(() => _mode = SmartMode.speed),
                ),
                const SizedBox(height: 12),
                const InfoCallout(
                  text: 'Picks from the free VPN Gate servers online right now. Ping and speed are the '
                      'values VPN Gate reports, so your own results can differ.',
                ),
              ],
            ),
            bottom: KovraButton.primary(
              label: label,
              busy: target == null && vpnGate.loading,
              onPressed: target == null ? null : () => _go(target),
            ),
          );
        },
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String title, hint;
  final bool selected;
  final VoidCallback onTap;
  const _Option({required this.title, required this.hint, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? c.primarySoft : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Expanded(
                      child: Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text))),
                  Text(hint, style: TextStyle(fontSize: 12, color: c.muted)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
