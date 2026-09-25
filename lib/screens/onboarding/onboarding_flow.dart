import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/onboarding_data.dart';
import 'custom_steps.dart';
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

  /// Overall position in the whole journey, not just the question steps —
  /// the top bar now shows on every screen, so the rail should reflect how
  /// far through the full 26-step flow the user actually is.
  double get _progress => (_index + 1) / _stepCount;

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

  static const _stepCount = 22;

  Widget _buildStep(int index) {
    // The very first screen has nowhere to go back to; every other step
    // wires the top bar's back arrow straight to `_back`.
    final back = index == 0 ? null : _back;

    switch (index) {
      case 0:
        return WelcomeStep(onNext: _next);

      case 1:
        return StatementStep(
          onNext: _next,
          progress: _progress,
          onBack: back,
          blocks: [heading("Today's verse is ready for you", size: 29)],
        );

      // The hook — each line lands on its own.
      case 2:
        return StatementStep(
          onNext: _next,
          progress: _progress,
          onBack: back,
          blocks: [
            heading('We check our phones **dozens of times a day**...'),
            heading('yet the **Quran** often waits untouched.'),
            bodyLine(
              "It happens to almost everyone. The world pulls our attention "
              'in a hundred directions.',
            ),
            bodyLine('What if a **verse a day** reached you first?'),
          ],
        );

      case 3:
        return StatementStep(
          onNext: _next,
          progress: _progress,
          onBack: back,
          blocks: [
            heading('Daily Quran Verse puts **Allah\'s words** in front of you, every day.'),
            bodyLine(
              'A single ayah, **matched to where you are**, arriving right '
              '**when it counts**.',
            ),
          ],
        );

      case 4:
        return NameStep(
          initial: _data.name,
          onChanged: (v) => _data.name = v,
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      case 5:
        return InterstitialStep(
          text: 'One more thing, ${_data.displayName}...',
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      case 6:
        return SingleChoiceStep(
          title: "What's your age range?",
          progress: _progress,
          onBack: back,
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
          title: 'On an average day, how long are you on your phone?',
          progress: _progress,
          onBack: back,
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
          progress: _progress,
          onBack: back,
          blocks: [
            heading('Just **5 minutes** a day can bring you **nearer to Allah**...'),
            bodyLine("Let's build that habit, one day at a time"),
          ],
        );

      case 9:
        return MultiChoiceStep(
          title: 'What are you **hoping for** from Daily Quran Verse?',
          progress: _progress,
          onBack: back,
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
          title: 'Picture your **iman** at its strongest. What does that look like?',
          progress: _progress,
          onBack: back,
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
        return SocialProofStep(
          data: _data,
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      case 12:
        return SliderStep(
          title: 'Honestly, how many days a week do you open the Quran?',
          progress: _progress,
          onBack: back,
          value: _data.readingDays,
          onChanged: (v) => _data.readingDays = v,
          onNext: _next,
        );

      case 13:
        return SingleChoiceStep(
          title: 'Right now, how close do you feel to **Allah**?',
          progress: _progress,
          onBack: back,
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
          title: 'And your **five daily salah**, how consistent are you?',
          progress: _progress,
          onBack: back,
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
          title: 'What tends to keep you away from **the Quran**?',
          progress: _progress,
          onBack: back,
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
          progress: _progress,
          onBack: back,
          blocks: [
            emojiLine('🤲'),
            heading(
              'Every hard moment is a chance for **iman** to grow, '
              '${_data.displayName}.',
            ),
            bodyLine(
              '**The Quran** speaks straight to **your heart**, offering '
              "comfort and strength right when you're low on either.",
            ),
            quoteLine('"Indeed, with hardship comes ease." (Ash-Sharh 94:6)'),
            bodyLine(
              "Keep **the Quran** close, and you won't walk through those "
              'moments by yourself.',
            ),
          ],
        );

      case 17:
        return SingleChoiceStep(
          title: 'Lastly, how do you identify?',
          subtitle: "This helps us tailor the experience to you.",
          progress: _progress,
          onBack: back,
          selected: _data.sex,
          onSelected: (v) => _data.sex = v,
          onNext: _next,
          choices: const [Choice('Male'), Choice('Female')],
        );

      case 18:
        return SummaryStep(
          data: _data,
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      case 19:
        return NotificationsPreviewStep(
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      case 20:
        return DailyMomentStep(
          onNext: _next,
          progress: _progress,
          onBack: back,
        );

      // A genuine loading beat — no back arrow, nothing to confirm. It's the
      // last screen in the flow now, so it resolves straight into onComplete.
      case 21:
        return LoadingStep(onNext: _next);

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
