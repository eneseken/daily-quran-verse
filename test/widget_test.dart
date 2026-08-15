import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/core/theme.dart';
import 'package:muslim/screens/onboarding/onboarding_flow.dart';

void main() {
  setUp(() => AppColors.apply(false));

  testWidgets('onboarding opens on the welcome screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OnboardingFlow(onComplete: (_) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Daily Quran Verse'), findsOneWidget);
    expect(find.text('Begin my journey'), findsOneWidget);
  });

  testWidgets('welcome advances into the flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OnboardingFlow(onComplete: (_) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Begin my journey'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Your daily Quran verse is waiting'), findsOneWidget);
  });
}
