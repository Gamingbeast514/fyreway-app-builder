import 'package:flutter_test/flutter_test.dart';
import 'package:kovra_vpn/main.dart';

void main() {
  testWidgets('Splash then Welcome shows Start free', (tester) async {
    await tester.pumpWidget(const KovraApp());
    expect(find.text('Kovra VPN'), findsOneWidget);
    // Splash waits 1.6 s, then fades to Welcome.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Start free'), findsOneWidget);
  });
}
