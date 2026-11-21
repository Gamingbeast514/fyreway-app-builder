import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kovra colours (dark only). Nocturne "bottom sheet" palette.
///
/// Old field names are kept (other code, including the hidden signature
/// painter, reads `accent` and `green`). Design token names in comments.
@immutable
class KovraColors extends ThemeExtension<KovraColors> {
  final Color bg, panel, card, cardDeep, border, ring, ring2, badge, selected;
  final Color text, muted, hint;
  final Color accent, onAccent, cyan, deepBlue, green, onGreen, gold, logoBar;
  final Color success, successSoft, danger, dangerSoft;

  const KovraColors({
    required this.bg,
    required this.panel,
    required this.card,
    required this.cardDeep,
    required this.border,
    required this.ring,
    required this.ring2,
    required this.badge,
    required this.selected,
    required this.text,
    required this.muted,
    required this.hint,
    required this.accent,
    required this.onAccent,
    required this.cyan,
    required this.deepBlue,
    required this.green,
    required this.onGreen,
    required this.gold,
    required this.logoBar,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
  });

  /// The Nocturne palette, exactly as designed.
  static const nocturne = KovraColors(
    bg: Color(0xFF0B0D17), // bg
    panel: Color(0xFF171B2C), // surface
    card: Color(0xFF141827), // card
    cardDeep: Color(0xFF171B2C), // surface (old token)
    border: Color(0xFF262B40), // line
    ring: Color(0x40FFFFFF), // white 25% (status rings)
    ring2: Color(0x26FFFFFF), // white 15%
    badge: Color(0xFF241D4D), // primarySoft
    selected: Color(0xFF241D4D), // primarySoft
    text: Color(0xFFF2F3FA),
    muted: Color(0xFF8D93AD),
    hint: Color(0xFF6B7190),
    accent: Color(0xFF7C5CFF), // primary
    onAccent: Color(0xFFFFFFFF),
    cyan: Color(0xFF5AA2FF),
    deepBlue: Color(0xFF5B3DF5),
    green: Color(0xFFA78BFA), // used by the signature gradient
    onGreen: Color(0xFF1E1036),
    gold: Color(0xFFF5C451), // star / crown
    logoBar: Color(0xFFFFFFFF),
    success: Color(0xFF3EE6B0),
    successSoft: Color(0xFF0F2E28),
    danger: Color(0xFFFF7A9A),
    dangerSoft: Color(0xFF3A1D2A),
  );

  /// The palette the app uses. White-label builds pass PRIMARY_COLOR,
  /// ACCENT_COLOR and BG_COLOR (0xFFRRGGBB); the other shades are derived
  /// from them. A light background gets a light palette.
  static final KovraColors dark = _fromDefines();

  static KovraColors _fromDefines() {
    const hasP = bool.hasEnvironment('PRIMARY_COLOR');
    const hasA = bool.hasEnvironment('ACCENT_COLOR');
    const hasB = bool.hasEnvironment('BG_COLOR');
    if (!hasP && !hasA && !hasB) return nocturne;
    const n = nocturne;
    final primary = hasP ? Color(const int.fromEnvironment('PRIMARY_COLOR')) : n.accent;
    final accent2 = hasA ? Color(const int.fromEnvironment('ACCENT_COLOR')) : n.green;
    final bg = hasB ? Color(const int.fromEnvironment('BG_COLOR')) : n.bg;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final onPrimary = primary.computeLuminance() > 0.6 ? const Color(0xFF0B0D17) : Colors.white;

    if (bg.computeLuminance() > 0.5) {
      // Light background.
      return KovraColors(
        bg: bg,
        panel: mix(bg, const Color(0xFF0F172A), 0.05),
        card: Colors.white,
        cardDeep: mix(bg, const Color(0xFF0F172A), 0.05),
        border: const Color(0xFFE2E8F0),
        ring: n.ring,
        ring2: n.ring2,
        badge: mix(Colors.white, primary, 0.14),
        selected: mix(Colors.white, primary, 0.14),
        text: const Color(0xFF0F172A),
        muted: const Color(0xFF475569),
        hint: const Color(0xFF64748B),
        accent: primary,
        onAccent: onPrimary,
        cyan: primary,
        deepBlue: mix(primary, Colors.black, 0.2),
        green: accent2,
        onGreen: Colors.white,
        gold: const Color(0xFFD97706),
        logoBar: const Color(0xFF0F172A),
        success: const Color(0xFF059669),
        successSoft: const Color(0xFFD1FAE5),
        danger: const Color(0xFFE11D48),
        dangerSoft: const Color(0xFFFFE4EA),
      );
    }
    return KovraColors(
      bg: bg,
      panel: mix(bg, Colors.white, 0.07),
      card: mix(bg, Colors.white, 0.045),
      cardDeep: mix(bg, Colors.white, 0.07),
      border: mix(bg, Colors.white, 0.13),
      ring: n.ring,
      ring2: n.ring2,
      badge: mix(bg, primary, 0.28),
      selected: mix(bg, primary, 0.28),
      text: n.text,
      muted: n.muted,
      hint: n.hint,
      accent: primary,
      onAccent: onPrimary,
      cyan: primary,
      deepBlue: mix(primary, Colors.black, 0.2),
      green: accent2,
      onGreen: n.onGreen,
      gold: n.gold,
      logoBar: n.logoBar,
      success: n.success,
      successSoft: n.successSoft,
      danger: n.danger,
      dangerSoft: n.dangerSoft,
    );
  }

  bool get isLight => bg.computeLuminance() > 0.5;

  // Design-token aliases, so new widgets read like the spec.
  Color get surface => panel;
  Color get line => border;
  Color get primary => accent;
  Color get primarySoft => badge;
  Color get onPrimary => onAccent;
  Color get star => gold;
  Color get scrim => const Color(0x8C000000); // 55% black
  Color get glow => const Color(0x8C7C5CFF);

  @override
  KovraColors copyWith() => this;

  @override
  KovraColors lerp(ThemeExtension<KovraColors>? other, double t) => this;
}

extension KovraThemeX on BuildContext {
  /// Short way to read colours: `context.kc.accent`.
  KovraColors get kc => Theme.of(this).extension<KovraColors>()!;
}

/// Type scale from DESIGN_SYSTEM.md §3 (Manrope). Colour is applied by callers.
class KovraText {
  static const _tight = -0.03;
  static TextStyle _s(double size, FontWeight w, {double em = 0, double? height}) =>
      TextStyle(fontSize: size, fontWeight: w, letterSpacing: size * em, height: height);

  static final display = _s(30, FontWeight.w700, em: _tight);
  static final displayXL = _s(52, FontWeight.w700, em: _tight).copyWith(fontFeatures: tabular);
  static final hero = _s(34, FontWeight.w700, em: _tight);
  static final headline = _s(26, FontWeight.w700, em: _tight, height: 1.2);
  static final title = _s(22, FontWeight.w700, em: -0.02);
  static final bodyL = _s(16, FontWeight.w600);
  static final body = _s(15, FontWeight.w400, height: 1.4);
  static final bodyStrong = _s(15, FontWeight.w600);
  static final secondary = _s(13.5, FontWeight.w400, height: 1.35);
  static final caption = _s(12.5, FontWeight.w400, height: 1.35);
  static final section = _s(12, FontWeight.w600, em: 0.08);

  /// Tabular figures for timers, IPs, ms, MB.
  static const tabular = [FontFeature.tabularFigures()];
}

ThemeData buildKovraTheme() {
  final c = KovraColors.dark;
  final brightness = c.isLight ? Brightness.light : Brightness.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: GoogleFonts.manrope().fontFamily,
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text),
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.bg,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: c.text,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.cardDeep,
      contentTextStyle: TextStyle(color: c.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: c.border)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withAlpha(90),
      selectionHandleColor: c.accent,
    ),
    extensions: [c],
  );
}
