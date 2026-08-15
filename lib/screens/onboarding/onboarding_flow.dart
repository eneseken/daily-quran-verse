import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/onboarding_data.dart';
import 'custom_steps.dart';
import 'reviews_step.dart';
import 'step_scaffolds.dart';

/// The full onboarding journey. Only the current step is built, so every screen
/// replays its reveal animation when it comes into view.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onComplete});

  final ValueChanged<OnboardingData> onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _data = OnboardingData();
  int _index = 0;

  /// Indices of the steps that count as questions, used for the progress rail.
  static const _questionSteps = [6, 7, 9, 10, 12, 13, 14, 15, 17];

  double _progressFor(int step) {
    final position = _questionSteps.indexOf(step);
    if (position < 0) return 0;
    return (position + 1) / _questionSteps.length;
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_index >= _stepCount - 1) {
      widget.onComplete(_data);
      return;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _index--);
  }

  static const _stepCount = 26;

  Widget _buildStep(int index) {
    switch (index) {
      case 0:
        return WelcomeStep(onNext: _next);

      case 1:
        return StatementStep(
          onNext: _next,
          blocks: [heading('Your daily Quran verse is waiting', size: 29)],
        );

      // The hook — each line lands on its own.
      case 2:
        return StatementStep(
          onNext: _next,
          blocks: [
            heading('Ever feel like you unlock your phone **100 times a day**...'),
            heading('but barely open your **Quran** once?'),
            bodyLine(
              "You're not alone. Distractions are everywhere, and it's easy to "
              'lose sight of what truly matters.',
            ),
            bodyLine('What if your **daily verse** met you before the scroll?'),
          ],
        );

      case 3:
        return StatementStep(
          onNext: _next,
          blocks: [
            heading('Daily Quran Verse brings **the words of Allah** into your day.'),
            bodyLine(
              'One verse each day, **chosen for your journey**, delivered '
              '**when you need it**.',
            ),
          ],
        );

      case 4:
        return NameStep(
          initial: _data.name,
          onChanged: (v) => _data.name = v,
          onNext: _next,
        );

      case 5:
        return InterstitialStep(
          text: 'Alright ${_data.displayName}, consider this...',
          onNext: _next,
        );

      case 6:
        return SingleChoiceStep(
          title: 'How old are you?',
          progress: _progressFor(6),
          selected: _data.ageRange,
          onSelected: (v) => _data.ageRange = v,
          onNext: _next,
          choices: const [
            Choice('13-17'),
            Choice('18-24'),
            Choice('25-34'),
            Choice('35-44'),
            Choice('45-54'),
            Choice('55+'),
          ],
        );

      case 7:
        return SingleChoiceStep(
          title: 'How much time do you spend on your phone each day?',
          progress: _progressFor(7),
          selected: _data.screenTime,
          onSelected: (v) => _data.screenTime = v,
          onNext: _next,
          choices: const [
            Choice('1-2 hours'),
            Choice('2-3 hours'),
            Choice('3-4 hours'),
            Choice('4-5 hours'),
            Choice('5-6 hours'),
            Choice('6+ hours'),
          ],
        );

      case 8:
        return StatementStep(
          onNext: _next,
          blocks: [
            heading('Imagine if even **5 minutes** brought you **closer to Allah**...'),
            bodyLine("Let's build that habit together"),
          ],
        );

      case 9:
        return MultiChoiceStep(
          title: 'What do you want to **achieve** with Daily Quran Verse?',
          progress: _progressFor(9),
          selected: _data.goals,
          onChanged: (v) => _data.goals = v,
          onNext: _next,
          choices: const [
            Choice('Start my day with the Quran', emoji: '🌅'),
            Choice('Get a Quran verse every day', emoji: '📖'),
            Choice('Deepen my relationship with Allah', emoji: '❤️'),
            Choice('Find peace in difficult moments', emoji: '🌿'),
            Choice('Memorize verses that matter', emoji: '🧠'),
            Choice('Share my deen with others', emoji: '🤝'),
          ],
        );

      case 10:
        return SingleChoiceStep(
          title: 'When you imagine your **iman** flourishing, what do you see?',
          progress: _progressFor(10),
          selected: _data.vision,
          onSelected: (v) => _data.vision = v,
          onNext: _next,
          choices: const [
            Choice("Unshakeable trust in Allah's plan", emoji: '🤲'),
            Choice('Faith that shines in my daily actions', emoji: '🌟'),
            Choice('Mercy and kindness toward others', emoji: '❤️'),
            Choice('Anchored deeply in the truth', emoji: '⚓'),
            Choice('Staying strong through every storm', emoji: '💪'),
            Choice("A constant sense of Allah's presence", emoji: '🌿'),
          ],
        );

      case 11:
        return SocialProofStep(data: _data, onNext: _next);

      case 12:
        return SliderStep(
          title: 'Be honest, how often do you read the Quran each week?',
          progress: _progressFor(12),
          value: _data.readingDays,
          onChanged: (v) => _data.readingDays = v,
          onNext: _next,
        );

      case 13:
        return SingleChoiceStep(
          title: 'Where do you stand with **Allah** today?',
          progress: _progressFor(13),
          selected: _data.faithStatus,
          onSelected: (v) => _data.faithStatus = v,
          onNext: _next,
          choices: const [
            Choice('Walking closely every day', emoji: '🤲'),
            Choice('It has its ups and downs', emoji: '🎢'),
            Choice("Feeling like there's a wall", emoji: '😔'),
            Choice('Finding my way back to Him', emoji: '🌱'),
          ],
        );

      // Added for a Muslim audience — the reference flow has no salah question.
      case 14:
        return SingleChoiceStep(
          title: 'How are your **five daily prayers** going?',
          progress: _progressFor(14),
          selected: _data.prayerStatus,
          onSelected: (v) => _data.prayerStatus = v,
          onNext: _next,
          choices: const [
            Choice('All five, on time', emoji: '🕌'),
            Choice('Most of them', emoji: '🌤️'),
            Choice('A few here and there', emoji: '🌙'),
            Choice('I want to start', emoji: '🌱'),
          ],
        );

      case 15:
        return MultiChoiceStep(
          title: 'What gets in the way of spending more time with **the Quran**?',
          progress: _progressFor(15),
          selected: _data.obstacles,
          onChanged: (v) => _data.obstacles = v,
          onNext: _next,
          choices: const [
            Choice('Too busy, always rushing', emoji: '⏰'),
            Choice('Phone distractions & social media', emoji: '📱'),
            Choice("Don't know where to start", emoji: '🧭'),
            Choice('Lack of motivation or discipline', emoji: '⚡'),
            Choice('Forget until it\'s too late', emoji: '📅'),
            Choice('Overwhelmed by everything', emoji: '🌊'),
          ],
        );

      case 16:
        return StatementStep(
          onNext: _next,
          blocks: [
            emojiLine('🤲'),
            heading(
              'Every struggle is an opportunity for **iman** to deepen, '
              '${_data.displayName}.',
            ),
            bodyLine(
              'But **the Quran** speaks directly to **your heart**, offering '
              'comfort and strength exactly when you need it most.',
            ),
            quoteLine('"Indeed, with hardship comes ease." (Ash-Sharh 94:6)'),
            bodyLine(
              "With **the Quran** at your fingertips, you'll never face those "
              'moments alone.',
            ),
          ],
        );

      case 17:
        return SingleChoiceStep(
          title: "What's your sex?",
          subtitle:
              "We'll personalize your experience based on your background.",
          progress: _progressFor(17),
          selected: _data.sex,
          onSelected: (v) => _data.sex = v,
          onNext: _next,
          choices: const [Choice('Male'), Choice('Female')],
        );

      case 18:
        return SummaryStep(data: _data, onNext: _next);

      case 19:
        return NotificationsPreviewStep(onNext: _next);

      case 20:
        return DailyMomentStep(onNext: _next);

      case 21:
        return LoadingStep(onNext: _next);

      case 22:
        return PlanDateStep(data: _data, onNext: _next);

      case 23:
        return SnapshotStep(data: _data, onNext: _next);

      case 24:
        return ReminderTimeStep(data: _data, onNext: _next);

      // Last beat before account creation.
      case 25:
        return ReviewsStep(onNext: _next);

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        // Set explicitly (rather than relying on the app-wide ThemeData,
        // which is only built once at startup) so this repaints immediately
        // when the palette flips between light and dark.
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _buildStep(_index),
          ),
        ),
      ),
    );
  }
}
