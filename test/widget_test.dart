import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kovra_vpn/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({}); // first launch
    GoogleFonts.config.allowRuntimeFetching = false; // no network in tests
  });

  testWidgets('First launch: splash, Welcome, then the VPN explainer', (tester) async {
    // A phone-sized screen (390 x 844 pt), like the design.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KovraApp());
    expect(find.text('Kovra VPN'), findsOneWidget);
    expect(find.text('Private by default'), findsOneWidget);

    // Splash loads settings and waits 1.6 s, then fades to Welcome.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Start free'), findsOneWidget);
    expect(find.text('No ads, ever'), findsOneWidget);
    // No false claims on Welcome.
    expect(find.textContaining('log'), findsNothing);
    expect(find.textContaining('3 months'), findsNothing);

    await tester.tap(find.text('Start free'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Allow a VPN connection'), findsOneWidget);
    expect(find.text('Encrypts your traffic with OpenVPN'), findsOneWidget);
    expect(find.textContaining('WireGuard'), findsNothing);
  });
}
