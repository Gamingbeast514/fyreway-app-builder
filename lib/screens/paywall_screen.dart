import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../theme.dart';
import '../widgets/glow_background.dart';
import '../widgets/logo.dart';

/// Kovra Pro: weekly / monthly / yearly. No ads in any plan.
class PaywallScreen extends StatefulWidget {
  /// Where to go when closed (e.g. Home after the splash). Null = just pop.
  final Widget? next;
  const PaywallScreen({super.key, this.next});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  ProPlan _plan = ProPlan.all.first;
  bool _busy = false;

  void _close() {
    final next = widget.next;
    if (next != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await pro.buy(_plan);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _toast('Welcome to ${AppConfig.appName} Pro');
      _close();
    } else {
      _toast('Subscriptions open once ${AppConfig.appName} is live on Google Play');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await pro.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(ok ? '${AppConfig.appName} Pro restored' : 'No active subscription found');
    if (ok) _close();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: GlowBackground(
        color: c.deepBlue,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, color: c.muted),
                  onPressed: _close,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const Center(child: KovraLogo(size: 76)),
                    const SizedBox(height: 18),
                    Text('${AppConfig.appName} Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: c.text)),
                    const SizedBox(height: 6),
                    Text('Faster servers and every location.\nNo ads, ever.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.45, color: c.muted)),
                    const SizedBox(height: 26),
                    const _Benefit(icon: Icons.rocket_launch_outlined, text: 'Fastest location, picked for you'),
                    const _Benefit(icon: Icons.live_tv_outlined, text: 'Streaming & gaming servers'),
                    const _Benefit(icon: Icons.public, text: 'All countries unlocked'),
                    const _Benefit(icon: Icons.block_outlined, text: 'No ads in any plan'),
                    const SizedBox(height: 22),
                    for (final p in ProPlan.all)
                      _PlanTile(plan: p, selected: p.id == _plan.id, onTap: () => setState(() => _plan = p)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(colors: [c.cyan, c.deepBlue]),
                    ),
                    child: TextButton(
                      onPressed: _busy ? null : _buy,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Continue'),
                    ),
                  ),
                ),
              ),
              Text('${_plan.price}${_plan.period} · Cancel anytime in Google Play',
                  style: TextStyle(fontSize: 12, color: c.hint)),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text('Restore purchases', style: TextStyle(fontSize: 13, color: c.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 22, color: c.accent),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text))),
      ]),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final ProPlan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? c.selected : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? c.accent : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? c.accent : c.muted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(plan.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
                    if (plan.bestValue) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(8)),
                        child: const Text('BEST VALUE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2A1E00))),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(plan.note, style: TextStyle(fontSize: 12, color: c.muted)),
                ]),
              ),
              Text(plan.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
              Text(plan.period, style: TextStyle(fontSize: 12, color: c.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
