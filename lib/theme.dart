import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kovra colours (dark only).
@immutable
class KovraColors extends ThemeExtension<KovraColors> {
  final Color bg, panel, card, cardDeep, border, ring, ring2, badge, selected;
  final Color text, muted, hint;
  final Color accent, onAccent, cyan, deepBlue, green, onGreen, gold, logoBar;

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
  });

  static const dark = KovraColors(
    bg: Color(int.fromEnvironment('BG_COLOR', defaultValue: 0xFF0E0F13)),
    panel: Color(0xFF17181D),
    card: Color(0xFF1D1E24),
    cardDeep: Color(0xFF23242B),
    border: Color(0xFF2A2B33),
    ring: Color(0xFF23242B),
    ring2: Color(0xFF30323B),
    badge: Color(0xFF26272E),
    selected: Color(0xFF1F2640),
    text: Color(0xFFF4F5F7),
    muted: Color(0xFF9B9DA6),
    hint: Color(0xFF80838D),
    accent: Color(int.fromEnvironment('PRIMARY_COLOR', defaultValue: 0xFF5B8CFF)),
    onAccent: Color(0xFFFFFFFF),
    cyan: Color(int.fromEnvironment('PRIMARY_COLOR', defaultValue: 0xFF5AA2FF)),
    deepBlue: Color(int.fromEnvironment('ACCENT_COLOR', defaultValue: 0xFF5B3DF5)),
    green: Color(int.fromEnvironment('ACCENT_COLOR', defaultValue: 0xFFA78BFA)),
    onGreen: Color(0xFF1E1036),
    gold: Color(0xFFF5C451),
    logoBar: Color(0xFFFFFFFF),
  );

  @override
  KovraColors copyWith() => this;

  @override
  KovraColors lerp(ThemeExtension<KovraColors>? other, double t) => this;
}

extension KovraThemeX on BuildContext {
  /// Short way to read colours: `context.kc.accent`.
  KovraColors get kc => Theme.of(this).extension<KovraColors>()!;
}

ThemeData buildKovraTheme() {
  const darkBase = KovraColors.dark;
  final isLight = darkBase.bg.computeLuminance() > 0.5;
  final c = isLight
      ? KovraColors(
          bg: darkBase.bg,
          panel: const Color(0xFFFFFFFF),
          card: const Color(0xFFFFFFFF),
          cardDeep: const Color(0xFFF1F5F9),
          border: const Color(0xFFE2E8F0),
          ring: const Color(0xFFE2E8F0),
          ring2: const Color(0xFFCBD5E1),
          badge: const Color(0xFFE2E8F0),
          selected: const Color(0xFFE0ECFF),
          text: const Color(0xFF0F172A),
          muted: const Color(0xFF475569),
          hint: const Color(0xFF64748B),
          accent: darkBase.accent,
          onAccent: Colors.white,
          cyan: darkBase.cyan,
          deepBlue: darkBase.deepBlue,
          green: darkBase.green,
          onGreen: Colors.white,
          gold: const Color(0xFFD97706),
          logoBar: const Color(0xFF0F172A),
        )
      : darkBase;

  final brightness = isLight ? Brightness.light : Brightness.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      surface: c.bg,
    ),
    appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, foregroundColor: c.text, elevation: 0),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.cardDeep,
      contentTextStyle: TextStyle(color: c.text),
    ),
    extensions: [c],
  );
}
