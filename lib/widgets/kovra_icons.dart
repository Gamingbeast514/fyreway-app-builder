import 'package:flutter/widgets.dart';

// Phosphor icons (https://phosphoricons.com, MIT, see assets/fonts/PHOSPHOR_LICENSE.txt).
// The phosphor_flutter package no longer builds on current Flutter (IconData is
// a final class now), so the icon fonts are bundled here and only the icons the
// app uses are defined. Code points come from phosphor_flutter 2.1.0.
//
// To add an icon: find its code point in phosphor_flutter's
// lib/src/phosphor_icons_<style>.dart and add a line below.

class PhosphorIconsRegular {
  const PhosphorIconsRegular._();
  static const arrowClockwise = IconData(0xe036, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const arrowDown = IconData(0xe03e, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const arrowLeft = IconData(0xe058, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const arrowRight = IconData(0xe06c, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const arrowSquareOut = IconData(0xe5de, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const arrowUp = IconData(0xe08e, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const caretRight = IconData(0xe13a, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const chartBar = IconData(0xe150, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const clockCounterClockwise = IconData(0xe1a0, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const copy = IconData(0xe1ca, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const crownSimple = IconData(0xe616, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const gauge = IconData(0xe628, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const gift = IconData(0xe276, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const globe = IconData(0xe288, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const globeHemisphereWest = IconData(0xe28c, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const handPalm = IconData(0xe57e, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const handTap = IconData(0xec90, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const hardDrives = IconData(0xe2a0, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const info = IconData(0xe2ce, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const lightning = IconData(0xe2de, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const list = IconData(0xe2f0, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const mapPin = IconData(0xe316, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const path = IconData(0xe39c, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const prohibit = IconData(0xe3de, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const shareNetwork = IconData(0xe408, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const shield = IconData(0xe40a, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const shieldCheck = IconData(0xe40c, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const shieldSlash = IconData(0xe410, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const star = IconData(0xe46a, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const televisionSimple = IconData(0xeae6, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const timer = IconData(0xe492, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const toggleRight = IconData(0xe676, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const warningCircle = IconData(0xe4e2, fontFamily: 'PhosphorRegular', matchTextDirection: true);
  static const x = IconData(0xe4f6, fontFamily: 'PhosphorRegular', matchTextDirection: true);
}

class PhosphorIconsFill {
  const PhosphorIconsFill._();
  static const shield = IconData(0xe40a, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const checkCircle = IconData(0xe184, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const crownSimple = IconData(0xe616, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const key = IconData(0xe2d6, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const lightning = IconData(0xe2de, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const lockSimple = IconData(0xe308, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const shieldCheck = IconData(0xe40c, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const sparkle = IconData(0xe6a2, fontFamily: 'PhosphorFill', matchTextDirection: true);
  static const star = IconData(0xe46a, fontFamily: 'PhosphorFill', matchTextDirection: true);
}

class PhosphorIconsBold {
  const PhosphorIconsBold._();
  static const check = IconData(0xe182, fontFamily: 'PhosphorBold', matchTextDirection: true);
  static const power = IconData(0xe3da, fontFamily: 'PhosphorBold', matchTextDirection: true);
}
