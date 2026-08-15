import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/onboarding_data.dart';
import '../../widgets/common.dart';
import '../../widgets/reveal.dart';
import 'step_scaffolds.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String _formatHour(int hour) {
  final suffix = hour < 12 ? 'AM' : 'PM';
  final display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display:00 $suffix';
}

/// Soft clay card used across the summary screens.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final bool highlighted;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? Border.all(color: AppColors.gold, width: 1.4)
            : null,
      ),
      child: child,
    );
  }
}

class _StampProofCard extends StatefulWidget {
  const _StampProofCard({required this.vision, this.delay = Duration.zero});

  final String vision;
  final Duration delay;

  @override
  State<_StampProofCard> createState() => _StampProofCardState();
}

class _StampProofCardState extends State<_StampProofCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.55,
        end: 0.92,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 48,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.92,
        end: 1.05,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 32,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.05,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
  ]).animate(_controller);

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.16, curve: Curves.easeOut),
  );

  late final Animation<double> _angle = Tween<double>(
    begin: -7,
    end: -2.4,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.ctaOnBg.withValues(alpha: 0.68);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.rotate(
            angle: _angle.value * math.pi / 180,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.ctaBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.ctaBg.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text("WHERE YOU'RE HEADED", style: AppText.overline(color: muted)),
            const SizedBox(height: 10),
            Text(
              '🌿 ${widget.vision}',
              textAlign: TextAlign.center,
              style: AppText.serif(size: 18, color: AppColors.ctaOnBg),
            ),
            const SizedBox(height: 10),
            Text(
              'Thousands use Daily Quran Verse to start their day '
              'with the Book of Allah',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 13.5, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayedStampIn extends StatefulWidget {
  const _DelayedStampIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedStampIn> createState() => _DelayedStampInState();
}

class _DelayedStampInState extends State<_DelayedStampIn> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _visible ? 1 : 0),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final opacity = value.clamp(0.0, 1.0);
        final scale = value == 0 ? 1.18 : 0.88 + value * 0.12;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: IgnorePointer(ignoring: !_visible, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Welcome
// ---------------------------------------------------------------------------

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/themess/1.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
        child: SafeArea(
          child: Padding(
            padding: kPagePadding,
            child: Column(
              children: [
                const Spacer(flex: 3),
                Reveal(
                  duration: const Duration(milliseconds: 900),
                  child: Text(
                    'Daily Quran Verse',
                    textAlign: TextAlign.center,
                    style: AppText.serif(
                      size: 42,
                      color: AppColors.white,
                      height: 1.16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 520),
                  duration: const Duration(milliseconds: 900),
                  child: Text(
                    'Allah is always by your side',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      size: 16,
                      color: AppColors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                _DelayedStampIn(
                  delay: const Duration(milliseconds: 1250),
                  child: LightButton(
                    label: 'Begin my journey',
                    onPressed: onNext,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Social proof — reflects the goal and vision just chosen
// ---------------------------------------------------------------------------

class SocialProofStep extends StatelessWidget {
  const SocialProofStep({super.key, required this.data, required this.onNext});

  final OnboardingData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final goal = data.goals.isEmpty
        ? 'Get a Quran verse every day'
        : data.goals.first;
    final vision = data.vision ?? "A constant sense of Allah's presence";

    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RevealColumn(
                  step: const Duration(milliseconds: 480),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 14),
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📖  $goal',
                              style: AppText.sans(
                                size: 15,
                                color: AppColors.ink,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "We'll help you keep that daily verse rhythm with "
                              'gentle reminders, widgets, and satisfying streaks',
                              style: AppText.sans(size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: _StampProofCard(
                        vision: vision,
                        delay: const Duration(milliseconds: 660),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "You're in the right place!",
                        style: AppText.serif(size: 26),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Thousands use Daily Quran Verse to start their day with '
                        'the words of Allah',
                        style: AppText.sans(size: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DelayedFade(
              delay: const Duration(milliseconds: 2400),
              child: PrimaryButton(label: 'Continue', onPressed: onNext),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. "Thanks, {name}." — plays the three key answers back
// ---------------------------------------------------------------------------

class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.data, required this.onNext});

  final OnboardingData data;
  final VoidCallback onNext;

  Widget _card(String label, String value, {bool bullet = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.overline()),
            const SizedBox(height: 10),
            Text(
              bullet ? '•  $value' : value,
              style: AppText.sans(size: 15.5, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obstacle = data.obstacles.isEmpty
        ? "Don't know where to start"
        : data.obstacles.first;

    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RevealColumn(
                  step: const Duration(milliseconds: 420),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 28, bottom: 8),
                      child: Text(
                        'Thanks, ${data.displayName}.',
                        style: AppText.serif(size: 28),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Text(
                        "Based on what you've shared, here's your journey.",
                        style: AppText.sans(size: 15),
                      ),
                    ),
                    _card(
                      'WHERE YOU WANT TO GO',
                      '🌿 ${data.vision ?? "A constant sense of Allah's presence"}',
                    ),
                    _card(
                      'WHERE YOU ARE NOW',
                      '🌱 ${data.faithStatus ?? "Finding my way back to Him"}',
                    ),
                    _card(
                      "WHAT'S STANDING IN THE WAY",
                      '🧭 $obstacle',
                      bullet: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: Text.rich(
                        TextSpan(
                          children: markup(
                            '**${data.displayName}**, we see where you are and where '
                            'you want to go. Together, we\'ll build a personal daily '
                            'verse plan to help you grow stronger in your iman.',
                            AppText.sans(size: 14.5),
                            AppText.sans(
                              size: 14.5,
                              color: AppColors.ink,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DelayedFade(
              delay: const Duration(milliseconds: 2600),
              child: PrimaryButton(label: 'Continue', onPressed: onNext),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Notification & widget preview
// ---------------------------------------------------------------------------

class NotificationsPreviewStep extends StatelessWidget {
  const NotificationsPreviewStep({super.key, required this.onNext});

  final VoidCallback onNext;

  Widget _widgetTile(String text, String? source) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppText.sans(
                  size: 13,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: 8),
                Text(source, style: AppText.sans(size: 11.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNext,
      child: SafeArea(
        child: Padding(
          padding: kPagePadding,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: RevealColumn(
                    step: const Duration(milliseconds: 520),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 34, bottom: 10),
                        child: Text(
                          'The Quran comes to you',
                          style: AppText.serif(size: 28),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          "Throughout the day, you'll receive verses and du'as "
                          'right on your home screen.',
                          style: AppText.sans(size: 15.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'NOTIFICATIONS',
                          style: AppText.overline(color: AppColors.inkSoft),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            SoftCard(
                              padding: const EdgeInsets.all(14),
                              child: _Notification(
                                title: 'Daily Quran Verse',
                                body:
                                    '"Indeed, with hardship comes ease." — Ash-Sharh 94:6',
                                showMeta: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SoftCard(
                              padding: const EdgeInsets.all(14),
                              child: _Notification(
                                title: 'Daily Quran Verse',
                                body:
                                    'Ya Rabb, grant me strength to face today 🤲',
                                showMeta: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'WIDGETS',
                          style: AppText.overline(color: AppColors.inkSoft),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _widgetTile(
                                'And He is with you wherever you are',
                                '— Al-Hadid 57:4',
                              ),
                              const SizedBox(width: 12),
                              _widgetTile(
                                'Ya Allah, keep my heart firm upon Your deen',
                                null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DelayedFade(
                delay: const Duration(milliseconds: 3200),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Tap to continue', style: AppText.sans(size: 14.5)),
                      const SizedBox(width: 8),
                      Text(
                        '→',
                        style: TextStyle(color: AppColors.gold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notification extends StatelessWidget {
  const _Notification({
    required this.title,
    required this.body,
    required this.showMeta,
  });

  final String title;
  final String body;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/logo.png', height: 34, width: 34),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showMeta)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('now', style: AppText.sans(size: 11.5)),
                  ],
                ),
              if (showMeta) const SizedBox(height: 3),
              Text(
                body,
                style: AppText.sans(
                  size: 13,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Daily moment / streak
// ---------------------------------------------------------------------------

class DailyMomentStep extends StatelessWidget {
  const DailyMomentStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final todayIndex = DateTime.now().weekday % 7; // Sunday == 0
    final ordered = [for (var i = 0; i < 7; i++) labels[(todayIndex + i) % 7]];

    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            const Spacer(),
            Reveal(child: const StreakSun(count: 1)),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 520),
              child: Text('Your daily moment', style: AppText.serif(size: 27)),
            ),
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 900),
              child: Text(
                "When you open the app, you'll see your streak and today's du'a.",
                textAlign: TextAlign.center,
                style: AppText.sans(size: 15.5),
              ),
            ),
            const SizedBox(height: 26),
            Reveal(
              delay: const Duration(milliseconds: 1280),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Column(
                        children: [
                          Text(
                            ordered[i],
                            style: AppText.sans(
                              size: 12.5,
                              color: i == 0
                                  ? AppColors.ink
                                  : AppColors.inkFaint,
                              weight: i == 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? AppColors.gold : AppColors.chip,
                            ),
                            child: i == 0
                                ? const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: AppColors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            DelayedFade(
              delay: const Duration(milliseconds: 1700),
              child: PrimaryButton(
                label: 'Start my daily prayer',
                dark: false,
                onPressed: onNext,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Analysing / loading
// ---------------------------------------------------------------------------

class LoadingStep extends StatefulWidget {
  const LoadingStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with SingleTickerProviderStateMixin {
  static const _captions = [
    'Reviewing your answers...',
    'Matching verses to your goals...',
    'Aligning your goals with the Quran...',
    'Preparing your daily plan...',
  ];

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 5200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Future.delayed(const Duration(milliseconds: 420), () {
            if (mounted) widget.onNext();
          });
        }
      });

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = Curves.easeInOut.transform(_controller.value);
            final captionIndex = (value * _captions.length).floor().clamp(
              0,
              _captions.length - 1,
            );
            const dots = 6;
            final filled = (value * dots).floor();

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProgressDial(value: value),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < dots; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 26,
                          width: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < filled
                                ? AppColors.gold
                                : AppColors.track,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: i < filled
                                ? AppColors.white
                                : AppColors.inkFaint,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    _captions[captionIndex],
                    key: ValueKey(captionIndex),
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 15),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Projected habit date + how we get there
// ---------------------------------------------------------------------------

class PlanDateStep extends StatelessWidget {
  const PlanDateStep({super.key, required this.data, required this.onNext});

  final OnboardingData data;
  final VoidCallback onNext;

  // A slight alternating tilt gives the stack a hand-placed, scattered feel
  // instead of three flat, rigid rows.
  Widget _row(String emoji, String title, String body, {double tilt = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Transform.rotate(
        angle: tilt * math.pi / 180,
        child: SoftCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.sans(
                        size: 14.5,
                        color: AppColors.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(body, style: AppText.sans(size: 13.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = DateTime.now().add(const Duration(days: 30));
    final goal = data.goals.isEmpty
        ? 'Get a Quran verse every day'
        : data.goals.first;

    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RevealColumn(
                  step: const Duration(milliseconds: 420),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 26, bottom: 18),
                      child: SoftCard(
                        child: Column(
                          children: [
                            Text(
                              '${data.displayName}, your daily verse habit can '
                              'feel natural by',
                              textAlign: TextAlign.center,
                              style: AppText.serif(size: 20, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatDate(target),
                                style: AppText.sans(
                                  size: 15,
                                  color: AppColors.ink,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.chip,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '📖  $goal',
                                style: AppText.sans(
                                  size: 14,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "🤲 Just one verse a day, plus reminders and widgets "
                              'to keep the Quran close.',
                              textAlign: TextAlign.center,
                              style: AppText.sans(
                                size: 13,
                                height: 1.45,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "How we'll get you there:",
                        style: AppText.sans(size: 16, color: AppColors.ink),
                      ),
                    ),
                    _row(
                      '✍️',
                      'A verse every day.',
                      'Start with ayahs chosen for your journey, plus gentle '
                          'reminders that bring you back.',
                      tilt: -1.6,
                    ),
                    _row(
                      '🧩',
                      "Your verse where you'll see it.",
                      'Turn your home screen into a quiet place for daily '
                          "Qur'an and du'a.",
                      tilt: 1.6,
                    ),
                    _row(
                      '🙌',
                      'Join believers starting with the Quran.',
                      "You're not alone. Thousands start their day with the "
                          'words of Allah.',
                      tilt: -1.6,
                    ),
                  ],
                ),
              ),
            ),
            DelayedFade(
              delay: const Duration(milliseconds: 2600),
              child: PrimaryButton(
                label: 'Begin my transformation',
                onPressed: onNext,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Faith snapshot
// ---------------------------------------------------------------------------

class SnapshotStep extends StatelessWidget {
  const SnapshotStep({super.key, required this.data, required this.onNext});

  final OnboardingData data;
  final VoidCallback onNext;

  Widget _statCard({
    required String emoji,
    required String title,
    String? note,
    double? bar,
    Duration barDelay = Duration.zero,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.sans(
                      size: 15,
                      color: AppColors.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note, style: AppText.sans(size: 13)),
            ],
            if (bar != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'low',
                    style: AppText.sans(size: 11, color: AppColors.inkFaint),
                  ),
                  Text(
                    'high',
                    style: AppText.sans(size: 11, color: AppColors.inkFaint),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _Bar(value: bar, delay: barDelay),
            ],
            const SizedBox(height: 10),
            Text(value, style: AppText.numeral(size: 22, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthlyHours = (data.readingDays * 4.3 * 5 / 60);

    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RevealColumn(
                  step: const Duration(milliseconds: 400),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 26, bottom: 8),
                      child: Text(
                        '${data.displayName}, here is your personalized faith '
                        'snapshot',
                        style: AppText.serif(size: 26),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Text(
                        "Based on your answers, we've designed a path to help you "
                        'grow closer to Allah through His words.',
                        style: AppText.sans(size: 15),
                      ),
                    ),
                    _statCard(
                      emoji: '🔄',
                      title: 'Current Quran habit',
                      bar: data.readingDays / 7,
                      // Matches this card's own RevealColumn arrival time, so
                      // the fill starts right as the card appears.
                      barDelay: const Duration(milliseconds: 980),
                      value: '${data.readingDays}/7 days',
                    ),
                    _statCard(
                      emoji: '⏳',
                      title: 'Monthly time with the Quran',
                      note: 'Estimated from 5 min/day',
                      value: '${monthlyHours.toStringAsFixed(1)} hours',
                    ),
                    _statCard(
                      emoji: '🔥',
                      title: 'Commitment level',
                      bar: 1,
                      barDelay: const Duration(milliseconds: 1780),
                      value: '100%',
                    ),
                  ],
                ),
              ),
            ),
            DelayedFade(
              delay: const Duration(milliseconds: 2200),
              child: PrimaryButton(label: 'Continue', onPressed: onNext),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

/// Progress track that fills from empty once [delay] has passed, instead of
/// snapping straight to [value].
class _Bar extends StatefulWidget {
  const _Bar({required this.value, this.delay = Duration.zero});

  final double value;
  final Duration delay;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _filled = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _filled = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: _filled ? widget.value.clamp(0.0, 1.0) : 0.0,
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, fraction, child) => Container(
              height: 10,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 9. Reminder window
// ---------------------------------------------------------------------------

class ReminderTimeStep extends StatefulWidget {
  const ReminderTimeStep({super.key, required this.data, required this.onNext});

  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<ReminderTimeStep> createState() => _ReminderTimeStepState();
}

class _ReminderTimeStepState extends State<ReminderTimeStep> {
  Future<void> _pick({required bool isStart}) async {
    final current = isStart
        ? widget.data.reminderStartHour
        : widget.data.reminderEndHour;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: AppColors.isDark
              ? ColorScheme.dark(
                  primary: AppColors.gold,
                  onPrimary: AppColors.ctaOnBg,
                  surface: AppColors.bg,
                  onSurface: AppColors.ink,
                )
              : ColorScheme.light(
                  primary: AppColors.gold,
                  onPrimary: AppColors.white,
                  surface: AppColors.bg,
                  onSurface: AppColors.ink,
                ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        widget.data.reminderStartHour = picked.hour;
      } else {
        widget.data.reminderEndHour = picked.hour;
      }
    });
  }

  Widget _timeField(String label, int hour, {required bool isStart}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.sans(size: 14)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _pick(isStart: isStart),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatHour(hour),
                      style: AppText.sans(
                        size: 17,
                        color: AppColors.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.schedule, size: 20, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RevealColumn(
                  step: const Duration(milliseconds: 380),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 34, bottom: 10),
                      child: Text(
                        'Choose when you receive your daily verse',
                        style: AppText.serif(size: 26),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 26),
                      child: Text(
                        "Gentle reminders between these hours. No noise — just the "
                        'words you asked for.',
                        style: AppText.sans(size: 15),
                      ),
                    ),
                    _timeField(
                      'Start at',
                      widget.data.reminderStartHour,
                      isStart: true,
                    ),
                    _timeField(
                      'End at',
                      widget.data.reminderEndHour,
                      isStart: false,
                    ),
                  ],
                ),
              ),
            ),
            DelayedFade(
              delay: const Duration(milliseconds: 1500),
              child: PrimaryButton(label: 'Continue', onPressed: widget.onNext),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
