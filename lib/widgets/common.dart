import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Full-width pill button. [dark] matches the near-black CTA, otherwise gold.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.dark = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final background = !enabled
        ? AppColors.inkFaint
        : dark
            ? AppColors.ctaBg
            : AppColors.gold;
    // The near-black/cream CTA flips its text with the background so it stays
    // readable in both themes; the gold CTA always takes white text.
    final foreground = dark ? AppColors.ctaOnBg : AppColors.white;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(29),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(29),
          child: Center(
            child: busy
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Text(
                    label,
                    style: AppText.sans(
                      size: 16.5,
                      color: foreground,
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

/// White pill CTA used on the photographic welcome screen.
class LightButton extends StatelessWidget {
  const LightButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        // Always a white pill on the fixed dusk gradient, in both themes —
        // so the label stays a fixed dark ink rather than the flipping one.
        color: AppColors.white,
        borderRadius: BorderRadius.circular(29),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(29),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                size: 16.5,
                color: const Color(0xFF2B2825),
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

/// A choice row: optional emoji, label, and a radio dot or checkbox on the
/// right. Selection darkens the border, as in the design.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.multi = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppColors.ctaBg : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              child: Row(
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.sans(size: 15.5, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  multi
                      ? _CheckBox(selected: selected)
                      : _RadioDot(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.ctaBg : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.ctaBg : AppColors.inkFaint,
          width: 1.4,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 14, color: AppColors.ctaOnBg)
          : null,
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: selected ? AppColors.ctaBg : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.ctaBg : AppColors.inkFaint,
          width: 1.4,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: AppColors.ctaOnBg)
          : null,
    );
  }
}

/// Thin gold progress rail pinned above the question screens.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.track,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              height: 6,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The rounded rectangular slider handle from the "how often" screen.
class PillThumb extends SliderComponentShape {
  const PillThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(30, 34);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 30, height: 34),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rect.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.white);
  }
}

/// A horizontal row of small square ticks behind the slider track.
class SquareTicks extends SliderTickMarkShape {
  const SquareTicks();

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) =>
      const Size(4, 4);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required bool isEnabled,
    required TextDirection textDirection,
  }) {
    // Only the inactive side shows ticks in the reference design.
    if (center.dx <= thumbCenter.dx) return;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 5, height: 5),
        const Radius.circular(1),
      ),
      Paint()..color = AppColors.inkFaint,
    );
  }
}

/// Circular percentage dial for the "analysing your answers" screen.
class ProgressDial extends StatelessWidget {
  const ProgressDial({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: 190,
      child: CustomPaint(
        painter: _DialPainter(value),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: AppText.numeral(size: 42, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) => oldDelegate.value != value;
}

/// Sun burst behind the streak number on the "daily moment" screen. Plays a
/// one-shot burst on mount: rays shoot outward, a shockwave ring expands and
/// fades, and the count pops in with an elastic overshoot.
class StreakSun extends StatefulWidget {
  const StreakSun({super.key, required this.count});

  final int count;

  @override
  State<StreakSun> createState() => _StreakSunState();
}

class _StreakSunState extends State<StreakSun>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Rays shoot out to full length early in the burst.
  late final Animation<double> _rays = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );

  // A shockwave ring expands from the sun's edge and dissolves across the
  // whole burst — the "explosion" the rays and number ride out on.
  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  // The count itself pops in with a springy overshoot, as if launched by
  // the burst, slightly behind the rays so it reads as cause and effect.
  late final Animation<double> _pop = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 1.0, curve: Curves.elasticOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      width: 168,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _SunPainter(rayProgress: _rays.value, ringProgress: _ring.value),
          child: child,
        ),
        child: Center(
          child: ScaleTransition(
            scale: _pop,
            child: Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.count}',
                  style: AppText.numeral(color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  _SunPainter({required this.rayProgress, required this.ringProgress});

  final double rayProgress;
  final double ringProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (ringProgress > 0 && ringProgress < 1) {
      final ringPaint = Paint()
        ..color = AppColors.gold.withValues(alpha: (1 - ringProgress) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, 44 + ringProgress * 40, ringPaint);
    }

    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: rayProgress.clamp(0, 1))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 12; i++) {
      final angle = (math.pi * 2 / 12) * i - math.pi / 2;
      final inner = 52.0;
      final maxOuter = i.isEven ? 78.0 : 70.0;
      final outer = inner + (maxOuter - inner) * rayProgress;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) =>
      oldDelegate.rayProgress != rayProgress ||
      oldDelegate.ringProgress != ringProgress;
}
