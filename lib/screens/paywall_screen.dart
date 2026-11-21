import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'upgrade_success_screen.dart';
import '../widgets/kovra_icons.dart';

/// 5.3 Kovra Pro: weekly / monthly / yearly. No ads in any plan. No free trial.
class PaywallScreen extends StatefulWidget {
  /// Where to go when closed (e.g. Home after the splash). Null = just pop.
  final Widget? next;
  const PaywallScreen({super.key, this.next});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  ProPlan _plan = ProPlan.all.firstWhere((p) => p.bestValue, orElse: () => ProPlan.all.first);
  bool _busy = false;

  void _close() {
    final next = widget.next;
    if (next != null) {
      Navigator.of(context).pushReplacement(fadeRoute(next, settings: kHomeRoute));
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
      Navigator.of(context).pushReplacement(fadeRoute(UpgradeSuccessScreen(next: widget.next)));
    } else {
      _toast('Subscriptions open once ${AppConfig.brand} is live on Google Play');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final ok = await pro.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(ok ? '${AppConfig.proName} restored' : 'No active subscription found');
    if (ok) _close();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final h = BrandSheetLayout.fit(context, 300);
    return PopScope(
      canPop: widget.next == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: BrandSheetLayout(
          brandHeight: h,
          brand: BrandArea(
            height: h,
            protected: true,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 48, bottom: kSheetOverlap),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    IconTile(
                      icon: PhosphorIconsFill.crownSimple,
                      size: 72,
                      radius: 22,
                      background: Colors.white.withAlpha(38),
                      foreground: c.onPrimary,
                      iconSize: 36,
                    ),
                    const SizedBox(height: 14),
                    Text(AppConfig.proName, style: KovraText.hero.copyWith(fontSize: 32, color: c.onPrimary)),
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
                RoundIconButton(icon: PhosphorIconsRegular.x, tooltip: 'Close', onTap: _busy ? null : _close),
                const Spacer(),
                PillButton(
                  label: 'Restore purchase',
                  background: Colors.white.withAlpha(38),
                  onTap: _busy ? null : _restore,
                ),
              ]),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(kPageX, 0, kPageX, 8),
            children: [
              const _Benefit(
                icon: PhosphorIconsRegular.globeHemisphereWest,
                title: 'All countries unlocked',
                sub: 'Every free and Pro location',
              ),
              _Benefit(
                icon: PhosphorIconsRegular.lightning,
                title: 'Fastest location, picked for you',
                sub: '${AppConfig.brand} chooses the Pro server',
              ),
              const _Benefit(
                icon: PhosphorIconsRegular.televisionSimple,
                title: 'Streaming & gaming servers',
                sub: 'Pro locations for video and games',
              ),
              if (!AppConfig.adsEnabled)
                _Benefit(
                  icon: PhosphorIconsRegular.prohibit,
                  title: 'No ads in any plan',
                  sub: '${AppConfig.brand} is paid for by Pro, not ads',
                ),
              const SizedBox(height: 14),
              for (final p in ProPlan.all)
                _PlanOption(plan: p, selected: p.id == _plan.id, onTap: () => setState(() => _plan = p)),
            ],
          ),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            KovraButton.primary(label: 'Continue', busy: _busy, onPressed: _buy),
            const SizedBox(height: 10),
            Text('${_plan.price}${_plan.period} · Cancel anytime in Google Play',
                style: KovraText.caption.copyWith(color: c.muted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _Benefit({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 22, color: c.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: KovraText.bodyStrong.copyWith(color: c.text)),
            Text(sub, style: KovraText.caption.copyWith(color: c.muted)),
          ]),
        ),
      ]),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final ProPlan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanOption({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final card = Material(
      color: selected ? c.primarySoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: selected ? 72 : 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            KovraRadio(selected: selected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: KovraText.bodyL.copyWith(color: c.text)),
                    Text(plan.note, style: KovraText.caption.copyWith(color: c.muted)),
                  ]),
            ),
            Text(plan.price,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: c.text, fontFeatures: KovraText.tabular)),
            Text(plan.period, style: TextStyle(fontSize: 12, color: c.muted)),
          ]),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '${plan.title} plan, ${plan.price}${plan.period}${plan.bestValue ? ', best value' : ''}',
      child: Padding(
        padding: EdgeInsets.only(top: plan.bestValue ? 10 : 0, bottom: 10),
        child: Stack(clipBehavior: Clip.none, children: [
          card,
          if (plan.bestValue)
            Positioned(
              top: -10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(999)),
                child: Text('BEST VALUE',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c.onPrimary)),
              ),
            ),
        ]),
      ),
    );
  }
}
