import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/core/theme.dart';
import 'package:muslim/screens/auth_screen.dart';

/// The escape hatch that keeps an unreachable backend from locking a reader
/// out of a Quran that ships inside the app. App Review hit exactly that:
/// the project was paused, sign-in failed, and the app could not be opened
/// at all.
void main() {
  setUp(() => AppColors.apply(false));

  Future<void> pumpAuth(
    WidgetTester tester, {
    VoidCallback? onContinueWithoutAccount,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AuthScreen(
          onContinueWithoutAccount: onContinueWithoutAccount,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers no guest escape before anything has failed', (
    tester,
  ) async {
    await pumpAuth(tester, onContinueWithoutAccount: () {});

    // Signing in is still the expected path — the way out only appears
    // once it has actually proven unreachable.
    expect(find.text('Continue without an account'), findsNothing);
  });

  testWidgets('offers the guest escape once the backend is unreachable', (
    tester,
  ) async {
    var continued = false;
    await pumpAuth(tester, onContinueWithoutAccount: () => continued = true);

    // With no onboarding answers to attach, the screen opens in sign-in
    // mode. Credentials that pass validation are enough: with no Supabase
    // configured in tests the call fails as a transport error, which is
    // the unreachable case.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reviewer@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Continue without an account'), findsOneWidget);

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();
    expect(continued, isTrue);
  });

  testWidgets('hides the escape when the host gives no way to take it', (
    tester,
  ) async {
    await pumpAuth(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'reviewer@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Continue without an account'), findsNothing);
  });
}
