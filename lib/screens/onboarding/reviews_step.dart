import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/reveal.dart';

/// Social proof — the last beat before account creation. It follows the same
/// adaptive onboarding palette as the rest of the flow: cream in light mode,
/// charcoal in dark mode.
class ReviewsStep extends StatelessWidget {
  const ReviewsStep({super.key, required this.onNext});

  final VoidCallback onNext;

  static const _reviews = [
    (
      'ACTUALLY CONSISTENT',
      "I've tried every Quran app out there but always gave up after a week. "
          "This is the only thing that's actually helped me read consistently.",
    ),
    (
      'REALLY HELPS',
      'No joke, I used to feel so guilty about how little I opened the Quran. '
          'The simple reminders just work. My heart feels so much closer to '
          'Allah now.',
    ),
    (
      'WIDGETS ARE GREAT',
      "It doesn't feel like another app on my phone. Seeing an ayah on my "
          'home screen quietly changes the whole day.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 26, 26, 130),
              child: RevealColumn(
                step: const Duration(milliseconds: 340),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text.rich(
                      TextSpan(
                        children: markup(
                          'Designed for believers who want **the Quran every '
                          'day.**',
                          AppText.serif(size: 26, color: AppColors.ink),
                          AppText.serif(size: 26, color: AppColors.gold),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: Text(
                      'Reviews from people using Daily Quran Verse.',
                      style: AppText.sans(size: 14.5, color: AppColors.inkSoft),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 26),
                    child: _LaurelBadge(),
                  ),
                  for (final (title, body) in _reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(title: title, body: body),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 26,
              right: 26,
              bottom: 22,
              child: DelayedFade(
                delay: const Duration(milliseconds: 1500),
                child: PrimaryButton(
                  label: 'Join Daily Quran Verse 🤲',
                  onPressed: onNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaurelBadge extends StatelessWidget {
  const _LaurelBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Laurel(mirrored: false, color: AppColors.gold),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily Quran',
                  textAlign: TextAlign.center,
                  style: AppText.sans(
                    size: 26,
                    color: AppColors.ink,
                    weight: FontWeight.w800,
                    height: 1.02,
                  ),
                ),
                Text(
                  'Verse App',
                  textAlign: TextAlign.center,
                  style: AppText.sans(
                    size: 24,
                    color: AppColors.ink,
                    weight: FontWeight.w400,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 16),
                const _Stars(size: 23, gap: 3),
                const SizedBox(height: 10),
                Text(
                  '🕊️🙏🥹 +10,000 people',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 16, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
        _Laurel(mirrored: true, color: AppColors.gold),
      ],
    );
  }
}

class _Laurel extends StatelessWidget {
  const _Laurel({required this.mirrored, required this.color});

  final bool mirrored;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(mirrored ? -1.0 : 1.0, 1, 1, 1),
      child: CustomPaint(
        size: const Size(58, 146),
        painter: _LaurelPainter(color),
      ),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  const _LaurelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = color;
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;

    final stem = Path()
      ..moveTo(size.width * 0.92, size.height * 0.96)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.80,
        size.width * 0.14,
        size.height * 0.24,
        size.width * 0.78,
        size.height * 0.04,
      );
    canvas.drawPath(stem, stemPaint);

    final metric = stem.computeMetrics().first;
    for (var i = 0; i < 11; i++) {
      final t = 0.05 + (i / 10) * 0.88;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent == null) continue;

      final leafLength = 18.5 - t * 4.5;
      final leafWidth = 7.2 - t * 1.6;

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle + math.pi / 2.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(leafLength / 2, 0),
          width: leafLength,
          height: leafWidth,
        ),
        leafPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Stars extends StatelessWidget {
  const _Stars({this.size = 13, this.gap = 1});

  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gap / 2),
            child: Icon(Icons.star, size: size, color: AppColors.gold),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Stars(),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppText.sans(
              size: 14,
              color: AppColors.ink,
              weight: FontWeight.w700,
              spacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppText.sans(
              size: 13.5,
              color: AppColors.inkSoft,
              height: 1.45,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
