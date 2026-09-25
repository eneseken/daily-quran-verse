import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/core/theme.dart';
import 'package:muslim/models/onboarding_data.dart';
import 'package:muslim/screens/onboarding/onboarding_flow.dart';

/// Walks every onboarding screen. Any layout overflow or build error along the
/// way fails the test. Covers a current iPhone and a short Android screen
/// (the taller question lists are the ones at risk of overflowing) plus a
/// dark-mode pass, since [AppColors] swaps values rather than widgets.
void main() {
  const viewports = {
    'iPhone 14 (390x844)': Size(1170, 2532),
    'small Android (360x640)': Size(1080, 1920),
  };

  // Every test starts from a known palette and restores it afterwards, since
  // AppColors holds mutable static state shared across tests in this file.
  setUp(() => AppColors.apply(false));
  tearDown(() => AppColors.apply(false));

  viewports.forEach((name, physicalSize) {
    testWidgets('the whole onboarding flow can be completed — $name',
        (tester) => _walkFlow(tester, physicalSize));
  });

  testWidgets(
    'the whole onboarding flow can be completed — dark mode',
    (tester) => _walkFlow(tester, const Size(1170, 2532), dark: true),
  );
}

Future<void> _walkFlow(
  WidgetTester tester,
  Size physicalSize, {
  bool dark = false,
}) async {
  {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    AppColors.apply(dark);
    final expectedBg = dark ? AppPalette.dark.bg : AppPalette.light.bg;

    OnboardingData? completed;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OnboardingFlow(onComplete: (data) => completed = data),
      ),
    );

    /// Lets reveal delays, the switcher and any auto-advance timers run out.
    Future<void> settle([int seconds = 4]) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Taps a label. On short screens a choice can sit below the fold, so the
    /// finder is scrolled into view before tapping — the same thing a real user
    /// would do.
    Future<void> tapText(String label) async {
      final target = find.text(label, findRichText: true);
      if (target.evaluate().isEmpty) {
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          try {
            await tester.scrollUntilVisible(
              target,
              120,
              scrollable: scrollable.last,
            );
          } on StateError {
            // Scrolling ran to the end without the label ever appearing.
            // Let the expect below report which label, rather than failing
            // here with a bare "Bad state: No element".
          }
          await settle(1);
        }
      }
      expect(target, findsWidgets, reason: 'could not reach "$label"');

      try {
        await tester.ensureVisible(target.first);
        await settle(1);
      } on StateError {
        // Not inside a scrollable — already on screen.
      }

      await tester.tap(target.first, warnIfMissed: false);
      await settle();
    }

    await settle();

    // 0 welcome
    await tapText('Start my journey');
    expect(find.text("Today's verse is ready for you", findRichText: true),
        findsOneWidget);

    // 1-3 statement screens — each advances on its own Continue button,
    // not by tapping the statement itself.
    await tapText('Continue');
    await tapText('Continue');
    await tapText('Continue');

    // 4 name — a plain text-on-paper screen, so this confirms the Scaffold
    // is actually painting the palette that was requested.
    expect(find.text("What should we call you?", findRichText: true),
        findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, expectedBg,
        reason: dark ? 'expected the dark palette' : 'expected the light palette');
    await tester.enterText(find.byType(TextField), 'Enes');
    await settle(1);
    await tapText('Continue');

    // 5 interstitial — greets the name just entered, then waits for a tap
    await tapText('Continue');

    // 6 age
    expect(find.text("What's your age range?", findRichText: true),
        findsOneWidget);
    await tapText('18-24');
    await tapText('Continue');

    // 7 screen time
    await tapText('3-4 hours');
    await tapText('Continue');

    // 8 statement
    await tapText('Continue');

    // 9 goals (multi)
    await tapText('Get a Quran verse every day');
    await tapText('Continue');

    // 10 vision
    await tapText("A constant sense of Allah's presence");
    await tapText('Continue');

    // 11 social proof
    await settle(3);
    await tapText('Continue');

    // 12 slider
    expect(find.byType(Slider), findsOneWidget);
    await tapText('Continue');

    // 13 faith status
    await tapText('Finding my way back to Him');
    await tapText('Continue');

    // 14 salah (the step added for a Muslim audience)
    expect(find.textContaining('five daily salah', findRichText: true),
        findsWidgets);
    await tapText('Most of them');
    await tapText('Continue');

    // 15 obstacles (multi)
    await tapText("Don't know where to start");
    await tapText('Continue');

    // 16 statement with the ayah
    await settle(4);
    await tapText('Continue');

    // 17 sex
    expect(find.text('Lastly, how do you identify?', findRichText: true),
        findsOneWidget);
    await tapText('Male');
    await tapText('Continue');

    // 18 summary
    await settle(3);
    expect(find.text('Thanks, Enes.', findRichText: true), findsWidgets);
    await tapText('Continue');

    // 19 notification preview
    await settle(4);
    await tapText('Continue');

    // 20 daily moment
    await settle(2);
    await tapText('Begin my daily ritual');

    // 21 loading dial — the last screen, so running it out completes the
    // flow and hands the answers back.
    await settle(10);

    expect(completed, isNotNull);
    expect(completed!.name, 'Enes');
    expect(completed!.ageRange, '18-24');
    expect(completed!.prayerStatus, 'Most of them');
    expect(completed!.goals, contains('Get a Quran verse every day'));
    expect(completed!.obstacles, contains("Don't know where to start"));
  }
}
