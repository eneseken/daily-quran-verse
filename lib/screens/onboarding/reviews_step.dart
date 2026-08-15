import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/reveal.dart';
import '../home/feed_theme.dart';

/// Social proof — the last beat before account creation. Styled after the
/// verse feed (dark ground, gold accents, serif headings, cream pill CTA) so
/// the hand-off into the app doesn't feel like a different product.
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
      color: FeedColors.bg,
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
                          FeedText.quote(size: 26),
                          FeedText.quote(size: 26)
                              .copyWith(color: FeedColors.gold),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: Text(
                      'Reviews from people using Daily Quran Verse.',
                      style: AppText.sans(size: 14.5, color: FeedColors.inkSoft),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
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
            // Lets the review list fade out under the pinned CTA instead of
            // being sliced off by a hard edge.
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
                      colors: [
                        FeedColors.bg.withValues(alpha: 0),
                        FeedColors.bg,
                      ],
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
                child: _FeedCta(
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

/// Gold laurel wreath around the app name and rating, as on the reference.
class _LaurelBadge extends StatelessWidget {
  const _LaurelBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Laurel(mirrored: false),
        // Flexible so the wreath never pushes the badge past a narrow screen.
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daily Quran',
                  textAlign: TextAlign.center,
                  style: FeedText.quote(size: 19),
                ),
                Text(
                  'Verse App',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 14.5, color: FeedColors.inkSoft),
                ),
                const SizedBox(height: 8),
                const _Stars(size: 15),
                const SizedBox(height: 6),
                Text(
                  '🕌 🤲 🌙  +10,000',
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 12, color: FeedColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
        const _Laurel(mirrored: true),
      ],
    );
  }
}

class _Laurel extends StatelessWidget {
  const _Laurel({required this.mirrored});

  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(mirrored ? -1.0 : 1.0, 1, 1, 1),
      child: CustomPaint(
        size: const Size(40, 92),
        painter: _LaurelPainter(),
      ),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..color = FeedColors.gold;
    final stemPaint = Paint()
      ..color = FeedColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // A shallow arc curving up the outer edge of the badge.
    final stem = Path()
      ..moveTo(size.width * 0.88, size.height * 0.96)
      ..quadraticBezierTo(
        size.width * 0.02,
        size.height * 0.70,
        size.width * 0.46,
        size.height * 0.04,
      );
    canvas.drawPath(stem, stemPaint);

    // Leaves fan off the stem, shrinking toward the tip.
    final metric = stem.computeMetrics().first;
    for (var i = 0; i < 7; i++) {
      final t = 0.05 + (i / 6) * 0.9;
      final tangent = metric.getTangentForOffset(metric.length * t);
      if (tangent == null) continue;

      final leafLength = 15.0 - t * 6;
      final leafWidth = 5.5 - t * 2;

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle + math.pi / 2.6);
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _Stars extends StatelessWidget {
  const _Stars({this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(Icons.star, size: size, color: FeedColors.gold),
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
        color: FeedColors.chip,
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
              color: FeedColors.ink,
              weight: FontWeight.w700,
              spacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppText.sans(
              size: 13.5,
              color: FeedColors.inkSoft,
              height: 1.45,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

/// Cream pill CTA matching the feed's contrast rather than the app-wide
/// palette — this screen stays dark regardless of the active theme.
class _FeedCta extends StatelessWidget {
  const _FeedCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: FeedColors.ink,
        borderRadius: BorderRadius.circular(29),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(29),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                size: 16.5,
                color: FeedColors.bg,
                weight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
