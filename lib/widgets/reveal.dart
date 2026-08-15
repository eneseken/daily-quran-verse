import 'dart:async';

import 'package:flutter/material.dart';

/// Fades a block in while it drifts up a little. Used to bring the copy on the
/// statement screens in one line at a time instead of all at once.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 720),
    this.offsetY = 26,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _timer;

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offsetY / 100),
    end: Offset.zero,
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps each child in a [Reveal] whose delay grows by [step], so a column of
/// text lands line by line.
class RevealColumn extends StatelessWidget {
  const RevealColumn({
    super.key,
    required this.children,
    this.start = const Duration(milliseconds: 180),
    this.step = const Duration(milliseconds: 620),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Duration start;
  final Duration step;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  /// When the last child has finished arriving — handy for timing a hint or an
  /// auto-advance behind the copy.
  Duration settleTime({int extra = 0}) =>
      start + step * (children.length - 1 + extra) + const Duration(milliseconds: 720);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          Reveal(delay: start + step * i, child: children[i]),
      ],
    );
  }
}

/// Shows [child] only after [delay], then fades it in place. Used for the
/// "Tap to continue" hint that appears once the copy has settled.
class DelayedFade extends StatefulWidget {
  const DelayedFade({
    super.key,
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<DelayedFade> {
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
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: Curves.easeOut,
      child: IgnorePointer(ignoring: !_visible, child: widget.child),
    );
  }
}
