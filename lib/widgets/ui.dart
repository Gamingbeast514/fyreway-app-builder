import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'kovra_icons.dart';

// Shared building blocks for the "bottom sheet" layout (DESIGN_SYSTEM.md).

const kPageX = 20.0;
const kSheetRadius = 28.0;
const kSheetOverlap = 28.0;

/// Light status-bar icons (screens draw a coloured panel behind them), and a
/// navigation bar that matches the app background.
final kLightBars = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: KovraColors.dark.bg,
  systemNavigationBarIconBrightness: KovraColors.dark.isLight ? Brightness.dark : Brightness.light,
);

// ───────────────────────── Brand area ─────────────────────────

/// The solid panel at the top of a screen. [protected] = `primary`, otherwise
/// `surface` (not protected / error). Colour change animates on connect.
class BrandArea extends StatelessWidget {
  final double height;
  final bool protected;
  final Widget child;
  const BrandArea({super.key, required this.height, required this.protected, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: height,
      width: double.infinity,
      color: protected ? c.primary : c.surface,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: BrandDecoration(strong: protected)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Two thin circles top-right and two soft glows (reused on every primary panel).
class BrandDecoration extends StatelessWidget {
  final bool strong;
  const BrandDecoration({super.key, this.strong = true});

  @override
  Widget build(BuildContext context) {
    final stroke = Colors.white.withAlpha(strong ? 51 : 18); // 20% on primary
    final glow = Colors.white.withAlpha(strong ? 36 : 8); // 14%
    Widget circle(double d) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: stroke)),
        );
    return IgnorePointer(
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(1, -1), radius: 0.9, colors: [glow, glow.withAlpha(0)]),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(-1, 1), radius: 0.9, colors: [glow, glow.withAlpha(0)]),
            ),
          ),
        ),
        Positioned(right: -64, top: -40, child: circle(256)),
        Positioned(right: -16, top: 32, child: circle(160)),
      ]),
    );
  }
}

/// Status centre: rings + 92 pt circle with a 46 pt icon, then title and subtitle.
class StatusCenter extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool onPrimary;
  final bool spinning;
  final Color? circleColor, iconColor;
  const StatusCenter({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onPrimary = true,
    this.spinning = false,
    this.circleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final fg = onPrimary ? c.onPrimary : c.text;
    Widget ring(double d, int alpha) => OverflowBox(
          maxWidth: d,
          maxHeight: d,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withAlpha(alpha))),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 120,
        height: 120,
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          if (onPrimary) ...[ring(200, 38), ring(150, 64)],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(icon),
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor ?? (onPrimary ? Colors.white.withAlpha(38) : c.line.withAlpha(140)),
              ),
              child: Icon(icon, size: 46, color: iconColor ?? (onPrimary ? c.onPrimary : c.muted)),
            ),
          ),
          if (spinning)
            const SizedBox(
              width: 112,
              height: 112,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white, strokeCap: StrokeCap.round),
            ),
        ]),
      ),
      const SizedBox(height: 22),
      Text(title, textAlign: TextAlign.center, style: KovraText.display.copyWith(color: fg)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, color: fg.withAlpha(204), fontFeatures: KovraText.tabular),
          ),
        ),
      ],
    ]);
  }
}

// ───────────────────────── Sheets ─────────────────────────

class Grabber extends StatelessWidget {
  const Grabber({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 6,
          decoration: BoxDecoration(color: context.kc.line, borderRadius: BorderRadius.circular(3)),
        ),
      );
}

/// The panel that overlaps the brand area: 28 pt top radius, grabber, shadow.
class KovraSheet extends StatelessWidget {
  final Widget child;
  final Color? color;
  const KovraSheet({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color ?? c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Grabber(),
        Expanded(child: child),
      ]),
    );
  }
}

/// Brand area on top, sheet below (overlapping by 28 pt). The sheet body
/// scrolls; [bottom] stays pinned (margin 20, bottom padding 28 + safe area).
class BrandSheetLayout extends StatelessWidget {
  final double brandHeight;
  final Widget brand;
  final Widget body;
  final Widget? bottom;
  final Widget? overlayTop; // e.g. the top bar, drawn over the brand area
  final Color? sheetColor;
  const BrandSheetLayout({
    super.key,
    required this.brandHeight,
    required this.brand,
    required this.body,
    this.bottom,
    this.overlayTop,
    this.sheetColor,
  });

  /// Brand height scaled down on short screens so the sheet keeps room.
  static double fit(BuildContext context, double design) {
    final h = MediaQuery.sizeOf(context).height;
    return math.min(design, math.max(design * 0.62, h * design / 844));
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kLightBars,
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, height: brandHeight, child: brand),
        Positioned(
          top: brandHeight - kSheetOverlap,
          left: 0,
          right: 0,
          bottom: 0,
          child: KovraSheet(
            color: sheetColor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: body),
              if (bottom != null)
                Padding(padding: EdgeInsets.fromLTRB(kPageX, 12, kPageX, 28 + safeBottom), child: bottom),
            ]),
          ),
        ),
        if (overlayTop != null) Positioned(top: 0, left: 0, right: 0, child: overlayTop!),
      ]),
    );
  }
}

/// Settings sub-page: 84 pt dimmed primary strip, full-height `surface` sheet
/// with a round back button and title.
class SheetPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottom;
  final bool closeIcon; // X instead of a back arrow (for the Settings root)
  final Widget? titleTrailing;
  const SheetPage({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.closeIcon = false,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final pad = MediaQuery.paddingOf(context);
    final back = RoundIconButton(
      icon: closeIcon ? PhosphorIconsRegular.x : PhosphorIconsRegular.arrowLeft,
      tooltip: closeIcon ? 'Close' : 'Back',
      background: closeIcon ? c.card : Colors.transparent,
      onTap: () => Navigator.of(context).maybePop(),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: kLightBars,
        child: Stack(children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: math.max(84, pad.top + 40),
            child: Stack(children: [
              Positioned.fill(child: ColoredBox(color: c.primary)),
              const Positioned.fill(child: BrandDecoration()),
              Positioned.fill(child: ColoredBox(color: Colors.black.withAlpha(77))),
            ]),
          ),
          Positioned.fill(
            top: pad.top + 16,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(kSheetRadius)),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, -10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Grabber(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(children: [
                    if (!closeIcon) back,
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: KovraText.title.copyWith(color: c.text))),
                    if (titleTrailing != null) titleTrailing!,
                    if (closeIcon) back,
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(kPageX, 8, kPageX, bottom == null ? 28 + pad.bottom : 16),
                    children: children,
                  ),
                ),
                if (bottom != null)
                  Padding(padding: EdgeInsets.fromLTRB(kPageX, 8, kPageX, 28 + pad.bottom), child: bottom),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Overlay sheet: 55% scrim, `card` sheet with grabber, anchored to the bottom.
Future<T?> showOverlaySheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final c = context.kc;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.card,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kSheetRadius))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(kPageX, 0, kPageX, 20 + MediaQuery.paddingOf(ctx).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Grabber(),
        builder(ctx),
      ]),
    ),
  );
}

/// Design-styled confirm dialog. Returns true when [confirm] is tapped.
Future<bool> showKovraConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
}) async {
  final ok = await showOverlaySheet<bool>(
    context,
    builder: (ctx) {
      final c = ctx.kc;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        Text(title, style: KovraText.title.copyWith(color: c.text)),
        const SizedBox(height: 6),
        Text(message, style: KovraText.body.copyWith(color: c.muted)),
        const SizedBox(height: 22),
        KovraButton.primary(label: cancel, onPressed: () => Navigator.pop(ctx, false)),
        const SizedBox(height: 4),
        KovraButton.ghost(label: confirm, onPressed: () => Navigator.pop(ctx, true)),
      ]);
    },
  );
  return ok ?? false;
}

// ───────────────────────── Buttons ─────────────────────────

enum _BtnKind { primary, light, outline, ghost, white }

class KovraButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final _BtnKind _kind;

  const KovraButton.primary({super.key, required this.label, this.icon, this.onPressed, this.busy = false})
      : _kind = _BtnKind.primary;
  const KovraButton.light({super.key, required this.label, this.icon, this.onPressed, this.busy = false})
      : _kind = _BtnKind.light;
  const KovraButton.outline({super.key, required this.label, this.icon, this.onPressed, this.busy = false})
      : _kind = _BtnKind.outline;
  const KovraButton.ghost({super.key, required this.label, this.icon, this.onPressed, this.busy = false})
      : _kind = _BtnKind.ghost;

  /// White button with a primary label (on full-bleed primary screens).
  const KovraButton.white({super.key, required this.label, this.icon, this.onPressed, this.busy = false})
      : _kind = _BtnKind.white;

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final (Color bg, Color fg, BorderSide side) = switch (_kind) {
      _BtnKind.primary => (c.primary, c.onPrimary, BorderSide.none),
      _BtnKind.light => (c.text, c.bg, BorderSide.none),
      _BtnKind.outline => (Colors.transparent, c.text, BorderSide(color: c.line)),
      _BtnKind.ghost => (Colors.transparent, c.muted, BorderSide.none),
      _BtnKind.white => (Colors.white, c.primary, BorderSide.none),
    };
    final ghost = _kind == _BtnKind.ghost;
    final enabled = onPressed != null && !busy;
    final content = busy
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: ghost ? 15 : 16, fontWeight: FontWeight.w600, color: fg)),
            ),
          ]);
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: ghost ? 48 : 56,
            width: double.infinity,
            child: Center(
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// 40 pt round icon button (menu, chart, back, close).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? background, foreground;
  const RoundIconButton({super.key, required this.icon, this.onTap, this.tooltip, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final btn = Material(
      color: background ?? Colors.white.withAlpha(38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: foreground ?? c.text)),
      ),
    );
    return Semantics(
      button: true,
      label: tooltip,
      child: tooltip == null ? btn : Tooltip(message: tooltip!, child: btn),
    );
  }
}

/// Small text-pill button (e.g. "Upgrade", "Restore purchase").
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? background, foreground;
  final double height;
  const PillButton({super.key, required this.label, this.onTap, this.background, this.foreground, this.height = 36});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Material(
      color: background ?? c.primary,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: foreground ?? c.onPrimary)),
        ),
      ),
    );
  }
}

// ───────────────────────── Inputs & rows ─────────────────────────

/// Search field look-alike that opens another screen when tapped.
class SearchFieldButton extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;
  const SearchFieldButton({super.key, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(PhosphorIconsRegular.magnifyingGlass, size: 19, color: c.muted),
            const SizedBox(width: 10),
            Text(hint, style: TextStyle(fontSize: 15, color: c.muted)),
          ]),
        ),
      ),
    );
  }
}

/// Real search field. Focused: 2 pt primary border + primary icon.
class KovraSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  const KovraSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.onChanged,
  });

  @override
  State<KovraSearchField> createState() => _KovraSearchFieldState();
}

class _KovraSearchFieldState extends State<KovraSearchField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 48,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: focused ? c.primary : Colors.transparent, width: 2),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        Icon(PhosphorIconsRegular.magnifyingGlass, size: 19, color: focused ? c.primary : c.muted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(fontSize: 15, color: c.text),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: TextStyle(fontSize: 15, color: c.muted),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ]),
    );
  }
}

/// Country flag in a circle. "AUTO" shows a lightning bolt.
class FlagCircle extends StatelessWidget {
  final String code;
  final double size;
  final Color? background;
  const FlagCircle({super.key, required this.code, this.size = 44, this.background});

  static String flag(String cc) {
    if (cc.length != 2) return cc;
    final up = cc.toUpperCase();
    return String.fromCharCodes(up.codeUnits.map((u) => 0x1F1E6 + (u - 0x41)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background ?? c.surface, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: code == 'AUTO'
          ? Icon(PhosphorIconsFill.lightning, size: size * 0.46, color: c.primary)
          : Text(flag(code), style: TextStyle(fontSize: size * 0.5, height: 1.15)),
    );
  }
}

/// 44 pt flag + name 16/600 + subtitle 13 muted + trailing.
class LocationRow extends StatelessWidget {
  final String code;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  const LocationRow({
    super.key,
    required this.code,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 8 : 6),
        child: Row(children: [
          FlagCircle(code: code, size: dense ? 40 : 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: KovraText.bodyL.copyWith(color: c.text)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.muted, fontFeatures: KovraText.tabular)),
              ],
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      ),
    );
  }
}

/// "Smart" chip: h36, primarySoft, sparkle + label in primary.
class SmartChip extends StatelessWidget {
  final VoidCallback onTap;
  const SmartChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Material(
      color: c.primarySoft,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(PhosphorIconsFill.sparkle, size: 14, color: c.primary),
            const SizedBox(width: 6),
            Text('Smart', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary)),
          ]),
        ),
      ),
    );
  }
}

/// Recent chip: h40, surface, flag + country.
class PlaceChip extends StatelessWidget {
  final String code, label;
  final VoidCallback onTap;
  const PlaceChip({super.key, required this.code, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Material(
      color: c.surface,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(FlagCircle.flag(code), style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.text)),
          ]),
        ),
      ),
    );
  }
}

/// Small status pill: FREE, SOON, CURRENT, PRO.
class Tag extends StatelessWidget {
  final String text;
  final Color? color, background;
  const Tag(this.text, {super.key, this.color, this.background});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final bg = background ?? c.surface;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: bg == Colors.transparent ? 0 : 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color ?? c.muted)),
    );
  }
}

/// 32 pt primarySoft circle with a 15 pt lock.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      child: Icon(PhosphorIconsFill.lockSimple, size: 15, color: c.primary),
    );
  }
}

/// Segmented tabs: surface container, active segment `card`.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              selected: i == index,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(labels[i],
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: i == index ? c.text : c.muted)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// "RECENT", "CONNECTION": 12/600 +0.08em uppercase muted.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(0, 20, 0, 8), this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: KovraText.section.copyWith(color: context.kc.muted))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Grouped list card: `card` bg, 1 pt line border, radius 18, line dividers.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  final double indent;
  const GroupCard({super.key, required this.children, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: indent, color: c.line),
            children[i],
          ],
        ]),
      ),
    );
  }
}

/// Settings row: 22 pt primary icon, title 15/600, subtitle 12.5 muted,
/// trailing value + chevron.
class GroupRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;
  const GroupRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, size: 22, color: iconColor ?? c.primary), const SizedBox(width: 14)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: KovraText.bodyStrong.copyWith(color: c.text)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: KovraText.caption.copyWith(color: c.muted)),
                ],
              ]),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Text(value!,
                  style: TextStyle(fontSize: 14, color: valueColor ?? c.muted, fontFeatures: KovraText.tabular)),
            ],
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (chevron && onTap != null) ...[
              const SizedBox(width: 6),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.muted),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Key–value row (details, diagnostics, IP).
class KvRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool selectable;
  final EdgeInsets padding;
  const KvRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.selectable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final style = TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      color: valueColor ?? c.text,
      fontFeatures: KovraText.tabular,
    );
    return Padding(
      padding: padding,
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20, color: c.primary), const SizedBox(width: 14)],
        Text(label, style: TextStyle(fontSize: 14.5, color: icon == null ? c.muted : c.text)),
        const SizedBox(width: 16),
        Expanded(
          child: selectable
              ? SelectableText(value.isEmpty ? '—' : value, textAlign: TextAlign.right, style: style)
              : Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right, style: style),
        ),
      ]),
    );
  }
}

/// 46 x 28 toggle: on = primary, off = line, 22 pt white knob.
class KovraToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const KovraToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? c.primary : c.line, borderRadius: BorderRadius.circular(14)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// 22 pt radio: on = 7 pt primary ring; off = 2 pt line ring.
class KovraRadio extends StatelessWidget {
  final bool selected;
  final bool enabled;
  const KovraRadio({super.key, required this.selected, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? Colors.white : Colors.transparent,
        border:
            Border.all(color: selected ? c.primary : c.line.withAlpha(enabled ? 255 : 120), width: selected ? 7 : 2),
      ),
    );
  }
}

/// 22 pt checkbox, radius 7.
class KovraCheck extends StatelessWidget {
  final bool checked;
  const KovraCheck({super.key, required this.checked});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? c.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: checked ? null : Border.all(color: c.line, width: 2),
      ),
      child: checked ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white) : null,
    );
  }
}

/// primarySoft callout with an icon.
class InfoCallout extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? child;
  const InfoCallout({super.key, this.icon = PhosphorIconsRegular.info, required this.text, this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: TextStyle(fontSize: 13.5, height: 1.4, color: c.text)),
            if (child != null) child!,
          ]),
        ),
      ]),
    );
  }
}

/// Rounded square tile holding an icon (feature rows, hero tiles).
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double? radius;
  final Color? background, foreground;
  final double? iconSize;
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.radius,
    this.background,
    this.foreground,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.primarySoft,
        borderRadius: BorderRadius.circular(radius ?? (size >= 80 ? 28 : 14)),
      ),
      child: Icon(icon, size: iconSize ?? size * 0.5, color: foreground ?? c.primary),
    );
  }
}

/// Feature row: 44 pt icon tile, title, subtitle.
class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const FeatureRow({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        IconTile(icon: icon, size: 44, iconSize: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: KovraText.bodyStrong.copyWith(color: c.text)),
            if (subtitle != null) Text(subtitle!, style: KovraText.secondary.copyWith(color: c.muted)),
          ]),
        ),
      ]),
    );
  }
}

/// Compact perk line: 20 pt primary icon + text.
class PerkLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const PerkLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: c.text))),
      ]),
    );
  }
}

/// Numbered step: 22 pt primary circle with a digit + text.
class NumberedStep extends StatelessWidget {
  final int n;
  final InlineSpan text;
  const NumberedStep({super.key, required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.onPrimary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(text, style: TextStyle(fontSize: 14.5, height: 1.4, color: c.text)),
        ),
      ]),
    );
  }
}

/// Speed bar: 64 x 6 track `line`, fill `primary`.
class SpeedBar extends StatelessWidget {
  final double value; // 0..1
  const SpeedBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: 64,
      height: 6,
      decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.04, 1.0),
        child: Container(decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(3))),
      ),
    );
  }
}

// ───────────────────────── Formatting ─────────────────────────

String two(int n) => n.toString().padLeft(2, '0');

String fmtClock(Duration d) => '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';

String fmtDuration(Duration d) => d.inHours > 0
    ? '${d.inHours} h ${d.inMinutes % 60} min'
    : d.inMinutes > 0
        ? '${d.inMinutes} min ${d.inSeconds % 60} s'
        : '${d.inSeconds} s';

String fmtBytes(int b) {
  if (b < 1024) return '$b B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var v = b / 1024;
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

// ───────────────────────── Routes ─────────────────────────

/// Sheet pages slide up (250 ms, decelerate).
Route<T> sheetRoute<T>(Widget page, {RouteSettings? settings}) => PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.decelerate)),
        child: child,
      ),
    );

/// Full-screen fade (onboarding hand-offs).
Route<T> fadeRoute<T>(Widget page, {RouteSettings? settings}) => PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    );

/// Home is always pushed with this name so other screens can return to it.
const kHomeRoute = RouteSettings(name: '/home');

void popToHome(BuildContext context) =>
    Navigator.of(context).popUntil((r) => r.settings.name == kHomeRoute.name || r.isFirst);
