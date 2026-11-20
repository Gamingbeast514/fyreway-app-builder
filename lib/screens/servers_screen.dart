import 'package:flutter/material.dart';

import '../config.dart';
import '../models/server.dart';
import '../services/pro_controller.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import '../widgets/code_badge.dart';
import 'paywall_screen.dart';

/// Locations: demo server list driven by the form's Free / VIP / Gaming / Streaming counts.
class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  String _query = '';

  bool _match(VpnServer s) {
    final q = _query.toLowerCase();
    return s.country.toLowerCase().contains(q) || s.city.toLowerCase().contains(q);
  }

  void _pick(VpnServer s) {
    if (s.premium && AppConfig.paywallEnabled && !pro.isPro) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    vpn.selectServer(s);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final free = demoFreeServers.where(_match).toList();
    final gaming = demoPremiumServers.where((s) => s.category == 'gaming' && _match(s)).toList();
    final streaming = demoPremiumServers.where((s) => s.category == 'streaming' && _match(s)).toList();
    final vip = demoPremiumServers.where((s) => s.category == 'all' && _match(s)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([pro, vpn]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Search countries',
                  hintStyle: TextStyle(color: c.hint),
                  prefixIcon: Icon(Icons.search, color: c.muted),
                  filled: true,
                  fillColor: c.card,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (free.isNotEmpty) ...[
                _Label('Free (${free.length})'),
                for (final s in free) _Tile(server: s, onTap: () => _pick(s)),
              ],
              if (gaming.isNotEmpty) ...[
                _Label('Gaming · Low Ping (${gaming.length})'),
                for (final s in gaming) _Tile(server: s, onTap: () => _pick(s)),
              ],
              if (streaming.isNotEmpty) ...[
                _Label('Streaming · HD Ready (${streaming.length})'),
                for (final s in streaming) _Tile(server: s, onTap: () => _pick(s)),
              ],
              if (vip.isNotEmpty) ...[
                _Label('Pro · VIP Locations (${vip.length})'),
                for (final s in vip) _Tile(server: s, onTap: () => _pick(s)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.kc.muted)),
      );
}

class _Tile extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onTap;
  const _Tile({required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final selected = vpn.server.country == server.country && vpn.server.city == server.city;
    final locked = server.premium && AppConfig.paywallEnabled && !pro.isPro;
    final sub = server.pingMs != null ? '${server.city} · ${server.pingMs} ms' : server.city;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          CodeBadge(code: server.code),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(server.country, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
              if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 13, color: c.muted)),
            ]),
          ),
          if (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.gold.withAlpha(36), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_outline, size: 12, color: c.gold),
                const SizedBox(width: 4),
                Text('PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.gold)),
              ]),
            )
          else
            Icon(selected ? Icons.check_circle_rounded : Icons.signal_cellular_alt_rounded,
                color: selected ? c.accent : c.muted, size: 20),
        ]),
      ),
    );
  }
}
