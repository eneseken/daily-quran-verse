import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/reveal.dart';

const kPagePadding = EdgeInsets.symmetric(horizontal: 26);

/// A choice offered on a question screen.
class Choice {
  const Choice(this.value, {this.emoji});

  final String value;
  final String? emoji;
}

// ---------------------------------------------------------------------------
// Copy helpers for statement screens. `**text**` renders in gold.
// ---------------------------------------------------------------------------

Widget heading(String text, {double size = 27}) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text.rich(
        TextSpan(
          children: markup(
            text,
            AppText.serif(size: size),
            AppText.serif(size: size, color: AppColors.gold),
          ),
        ),
      ),
    );

Widget bodyLine(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text.rich(
        TextSpan(
          children: markup(
            text,
            AppText.sans(size: 16),
            AppText.sans(size: 16, color: AppColors.gold, weight: FontWeight.w600),
          ),
        ),
      ),
    );

Widget quoteLine(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        text,
        style: AppText.serif(size: 17, height: 1.45, style: FontStyle.italic),
      ),
    );

Widget emojiLine(String emoji) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(emoji, style: const TextStyle(fontSize: 34)),
    );

// ---------------------------------------------------------------------------
// Statement screen: copy arrives one block at a time, tap anywhere to move on.
// ---------------------------------------------------------------------------

class StatementStep extends StatelessWidget {
  const StatementStep({
    super.key,
    required this.blocks,
    required this.onNext,
    this.stepDelay = const Duration(milliseconds: 640),
    this.alignment = CrossAxisAlignment.start,
  });

  final List<Widget> blocks;
  final VoidCallback onNext;
  final Duration stepDelay;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final column = RevealColumn(
      start: const Duration(milliseconds: 220),
      step: stepDelay,
      crossAxisAlignment: alignment,
      children: blocks,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNext,
      child: SafeArea(
        child: Padding(
          padding: kPagePadding,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(child: column),
                ),
              ),
              DelayedFade(
                delay: column.settleTime(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap to continue',
                        style: AppText.sans(size: 14.5),
                      ),
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

/// A single line of copy that shows briefly, then moves on by itself.
class InterstitialStep extends StatefulWidget {
  const InterstitialStep({
    super.key,
    required this.text,
    required this.onNext,
    this.hold = const Duration(milliseconds: 2100),
  });

  final String text;
  final VoidCallback onNext;
  final Duration hold;

  @override
  State<InterstitialStep> createState() => _InterstitialStepState();
}

class _InterstitialStepState extends State<InterstitialStep> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.hold, () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onNext,
      child: SafeArea(
        child: Padding(
          padding: kPagePadding,
          child: Center(
            child: Reveal(
              child: Text.rich(
                TextSpan(
                  children: markup(
                    widget.text,
                    AppText.serif(size: 26),
                    AppText.serif(size: 26, color: AppColors.gold),
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question screens
// ---------------------------------------------------------------------------

/// Shared chrome for question screens: progress rail, revealed title, body.
class QuestionShell extends StatelessWidget {
  const QuestionShell({
    super.key,
    required this.title,
    required this.progress,
    required this.child,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final double progress;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            OnboardingProgress(value: progress),
            const SizedBox(height: 34),
            Reveal(
              offsetY: 16,
              duration: const Duration(milliseconds: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: markup(
                        title,
                        AppText.serif(size: 26),
                        AppText.serif(size: 26, color: AppColors.gold),
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 10),
                    Text(subtitle!, style: AppText.sans(size: 15)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 26),
            Expanded(child: child),
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pick one — advances on its own a beat after the tap.
class SingleChoiceStep extends StatefulWidget {
  const SingleChoiceStep({
    super.key,
    required this.title,
    required this.choices,
    required this.progress,
    required this.selected,
    required this.onSelected,
    required this.onNext,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Choice> choices;
  final double progress;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  @override
  State<SingleChoiceStep> createState() => _SingleChoiceStepState();
}

class _SingleChoiceStepState extends State<SingleChoiceStep> {
  String? _local;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _local = widget.selected;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(String value) {
    HapticFeedback.selectionClick();
    setState(() => _local = value);
    widget.onSelected(value);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuestionShell(
      title: widget.title,
      subtitle: widget.subtitle,
      progress: widget.progress,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (var i = 0; i < widget.choices.length; i++)
            Reveal(
              delay: Duration(milliseconds: 120 + i * 70),
              duration: const Duration(milliseconds: 420),
              offsetY: 12,
              child: OptionTile(
                label: widget.choices[i].value,
                emoji: widget.choices[i].emoji,
                selected: _local == widget.choices[i].value,
                onTap: () => _pick(widget.choices[i].value),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pick any number — confirmed with the dark Continue button.
class MultiChoiceStep extends StatefulWidget {
  const MultiChoiceStep({
    super.key,
    required this.title,
    required this.choices,
    required this.progress,
    required this.selected,
    required this.onChanged,
    required this.onNext,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Choice> choices;
  final double progress;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  @override
  State<MultiChoiceStep> createState() => _MultiChoiceStepState();
}

class _MultiChoiceStepState extends State<MultiChoiceStep> {
  late final List<String> _local = [...widget.selected];

  void _toggle(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_local.contains(value)) {
        _local.remove(value);
      } else {
        _local.add(value);
      }
    });
    widget.onChanged(_local);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionShell(
      title: widget.title,
      subtitle: widget.subtitle,
      progress: widget.progress,
      footer: PrimaryButton(
        label: 'Continue',
        onPressed: _local.isEmpty ? null : widget.onNext,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (var i = 0; i < widget.choices.length; i++)
            Reveal(
              delay: Duration(milliseconds: 120 + i * 70),
              duration: const Duration(milliseconds: 420),
              offsetY: 12,
              child: OptionTile(
                label: widget.choices[i].value,
                emoji: widget.choices[i].emoji,
                multi: true,
                selected: _local.contains(widget.choices[i].value),
                onTap: () => _toggle(widget.choices[i].value),
              ),
            ),
        ],
      ),
    );
  }
}

/// 0–7 day slider with the oversized serif read-out.
class SliderStep extends StatefulWidget {
  const SliderStep({
    super.key,
    required this.title,
    required this.progress,
    required this.value,
    required this.onChanged,
    required this.onNext,
  });

  final String title;
  final double progress;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;

  @override
  State<SliderStep> createState() => _SliderStepState();
}

class _SliderStepState extends State<SliderStep> {
  late int _local = widget.value;

  @override
  Widget build(BuildContext context) {
    return QuestionShell(
      title: widget.title,
      progress: widget.progress,
      footer: PrimaryButton(label: 'Continue', onPressed: widget.onNext),
      child: Reveal(
        delay: const Duration(milliseconds: 160),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_local', style: AppText.numeral(size: 46, color: AppColors.ink)),
                const SizedBox(width: 8),
                Text(
                  _local == 1 ? 'day' : 'days',
                  style: AppText.sans(size: 18, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 10,
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.track,
                thumbShape: const PillThumb(),
                tickMarkShape: const SquareTicks(),
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: _local.toDouble(),
                min: 0,
                max: 7,
                divisions: 7,
                onChanged: (v) {
                  final rounded = v.round();
                  if (rounded != _local) HapticFeedback.selectionClick();
                  setState(() => _local = rounded);
                  widget.onChanged(_local);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: AppText.sans(size: 13, color: AppColors.inkFaint)),
                  Text('7', style: AppText.sans(size: 13, color: AppColors.inkFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name capture — the only free-text step.
class NameStep extends StatefulWidget {
  const NameStep({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onNext,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: kPagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: RevealColumn(
                    step: const Duration(milliseconds: 320),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'first things first',
                          style: AppText.sans(size: 15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 26),
                        child: Text(
                          'Who are we praying with?',
                          style: AppText.serif(size: 26),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: TextField(
                          controller: _controller,
                          onChanged: (v) {
                            widget.onChanged(v);
                            setState(() {});
                          },
                          onSubmitted: (_) {
                            if (ready) widget.onNext();
                          },
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          cursorColor: AppColors.ink,
                          style: AppText.sans(size: 16, color: AppColors.ink),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your name',
                            hintStyle:
                                AppText.sans(size: 16, color: AppColors.inkFaint),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PrimaryButton(
              label: 'Continue',
              onPressed: ready ? widget.onNext : null,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
