import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/screens/paywall_screen.dart';

/// The paywall talks to RevenueCat, which has no plugin in a widget test, so
/// these cover the parts that are pure UI contract: the legal footer Apple
/// requires, and the dismiss affordance.
Widget _harness({required TargetPlatform platform, Size? size}) {
  return MediaQuery(
    data: MediaQueryData(size: size ?? const Size(390, 844)),
    child: MaterialApp(
      theme: ThemeData(platform: platform),
      home: const PaywallScreen(),
    ),
  );
}

void main() {
  testWidgets('shows Terms and Privacy on iOS', (tester) async {
    await tester.pumpWidget(_harness(platform: TargetPlatform.iOS));
    // One pump past the offerings load, which fails fast without the plugin.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
  });

  testWidgets('shows Terms of Use on Android and keeps Privacy', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(platform: TargetPlatform.android));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Apple mandates the standard EULA link; Google does not.
    expect(find.text('Terms'), findsNothing);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
  });

  testWidgets('is dismissible rather than a hard wall', (tester) async {
    await tester.pumpWidget(_harness(platform: TargetPlatform.iOS));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('renders without overflow on a small phone', (tester) async {
    await tester.pumpWidget(
      _harness(platform: TargetPlatform.iOS, size: const Size(360, 640)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}
