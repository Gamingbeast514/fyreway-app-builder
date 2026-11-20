import 'package:flutter/material.dart';

import '../services/network_tools.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('My IP & location', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (protected ? c.green : c.gold).withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(protected ? Icons.verified_user_outlined : Icons.shield_outlined,
                  color: protected ? c.green : c.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  protected ? 'VPN is on. Websites see the server\'s IP.' : 'VPN is off. Websites can see this IP.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator(color: c.accent)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
            )
          else if (_info != null) ...[
            Text('YOUR PUBLIC IP',
                style: TextStyle(fontSize: 12, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: c.muted)),
            const SizedBox(height: 6),
            SelectableText(_info!.ip,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 20),
            _Row(label: 'Location', value: _info!.place),
            _Row(label: 'Region', value: _info!.region),
            _Row(label: 'Provider', value: _info!.isp),
            _Row(label: 'Time zone', value: _info!.timezone),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Check again'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: const StadiumBorder()),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
        ),
      ]),
    );
  }
}
