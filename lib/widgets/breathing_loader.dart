import 'package:flutter/material.dart';

/// A slow "breathing" 🤲 used wherever the app is waiting on something —
/// calmer and more in keeping with the app than a spinning progress ring.
///
/// The emoji swells and settles on an ease-in-out curve, with the glow behind
/// it breathing in step, so the motion reads as a held breath rather than a
/// mechanical pulse.
class BreathingLoader extends StatefulWidget {
  const BreathingLoader({
    super.key,
    this.size = 56,
    this.emoji = '🤲',
    this.glow,
  });

  final double size;
  final String emoji;

  /// Soft halo behind the emoji. Omit for no glow.
  final Color? glow;

  @override
  State<BreathingLoader> createState() => _BreathingLoaderState();
}

class _BreathingLoaderState extends State<BreathingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final Animation<double> _breath = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        return Opacity(
          opacity: 0.72 + 0.28 * t,
          child: Transform.scale(
            scale: 0.88 + 0.16 * t,
            child: widget.glow == null
                ? child
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.glow!
                              .withValues(alpha: 0.10 + 0.16 * t),
                          blurRadius: 26 + 18 * t,
                          spreadRadius: 2 + 6 * t,
                        ),
                      ],
                    ),
                    child: child,
                  ),
          ),
        );
      },
      child: Text(
        widget.emoji,
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }
}
