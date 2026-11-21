import 'package:flutter/material.dart';

import '../services/network_tools.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/kovra_icons.dart';

/// Shows the public IP and location the internet currently sees.
class IpCheckScreen extends StatefulWidget {
  const IpCheckScreen({super.key});

  @override
  State<IpCheckScreen> createState() => _IpCheckScreenState();
}

class _IpCheckScreenState extends State<IpCheckScreen> {
  IpInfo? _info;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await NetworkTools.ipInfo();
      if (mounted) setState(() => _info = info);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not check your IP. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final protected = vpn.status == VpnStatus.connected;
    final info = _info;
    return SheetPage(
      title: 'My IP & location',
      bottom: KovraButton.outline(
        label: 'Check again',
        icon: PhosphorIconsRegular.arrowClockwise,
        busy: _loading,
        onPressed: _loading ? null : _load,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: protected ? c.successSoft : c.primarySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Icon(protected ? PhosphorIconsFill.shieldCheck : PhosphorIconsRegular.shieldSlash,
                size: 22, color: protected ? c.success : c.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                protected ? "VPN is on. Websites see the server's IP." : 'VPN is off. Websites can see this IP.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        if (_loading && info == null)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: c.primary)),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text(_error!, textAlign: TextAlign.center, style: KovraText.body.copyWith(color: c.muted)),
          )
        else if (info != null) ...[
          const SectionLabel('Your public IP', padding: EdgeInsets.fromLTRB(0, 4, 0, 6)),
          SelectableText(info.ip, style: KovraText.display.copyWith(color: c.text, fontFeatures: KovraText.tabular)),
          const SizedBox(height: 16),
          GroupCard(children: [
            KvRow(label: 'Location', value: info.place),
            KvRow(label: 'Region', value: info.region),
            KvRow(label: 'Provider', value: info.isp),
            KvRow(label: 'Time zone', value: info.timezone),
          ]),
        ],
      ],
    );
  }
}
