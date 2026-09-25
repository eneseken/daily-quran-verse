import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../core/theme.dart';

class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key});

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  bool _pinSupported = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (mounted) setState(() => _pinSupported = supported);
  }

  /// Asks Android to show its own "add this widget" confirmation sheet —
  /// only available on API 26+. Below that (or if the launcher declines),
  /// the numbered steps above remain the fallback path.
  Future<void> _addWidget() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await HomeWidget.requestPinWidget(androidName: 'DailyVerseWidgetProvider');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PhonePreview(),
              const SizedBox(height: 34),
              Text(
                'Home screen widgets',
                style: AppText.serif(size: 34, color: AppColors.ink, height: 1),
              ),
              const SizedBox(height: 22),
              const _StepLine(
                number: '1.',
                text: 'Long press on your home screen',
              ),
              const SizedBox(height: 16),
              const _StepLine(
                number: '2.',
                text: 'Tap the + button in the top corner',
              ),
              const SizedBox(height: 16),
              const _StepLine(
                number: '3.',
                text: 'Search for "Daily Quran Verse" and\nadd the widget',
              ),
              if (_pinSupported) ...[
                const SizedBox(height: 28),
                _AddWidgetButton(loading: _requesting, onTap: _addWidget),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddWidgetButton extends StatelessWidget {
  const _AddWidgetButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ctaBg,
          foregroundColor: AppColors.ctaOnBg,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ctaOnBg,
                ),
              )
            : Text(
                'Add widget to home screen',
                style: AppText.sans(size: 17, color: AppColors.ctaOnBg),
              ),
      ),
    );
  }
}

/// Colors shared by the phone-mock preview widgets below — kept outside
/// the screen's State since those widgets are const and built once.
class _Palette {
  static Color get frame =>
      AppColors.isDark ? const Color(0xFF575047) : const Color(0xFFC9C3BA);
  static Color get card =>
      AppColors.isDark ? const Color(0xFF3B352F) : const Color(0xFFE7E1D7);
  static Color get gold =>
      AppColors.isDark ? const Color(0xFFF6CC83) : const Color(0xFFDCAF59);
  static Color get body =>
      AppColors.isDark ? AppColors.inkSoft : const Color(0xFF312D29);
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 334,
      width: double.infinity,
      child: CustomPaint(
        painter: _PhoneFramePainter(color: _Palette.frame),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(56)),
          child: SizedBox(
            width: double.infinity,
            height: 322,
            child: Stack(
              children: [
                Positioned(
                  top: 15,
                  left: 116,
                  right: 116,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: _Palette.frame,
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
                Positioned(
                  top: 79,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 112,
                    decoration: BoxDecoration(
                      color: _Palette.card,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Today, I protect the peace\nthat God has planted in me.',
                        textAlign: TextAlign.center,
                        style: AppText.serif(
                          size: 17,
                          color: _Palette.gold,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 207,
                  left: 30,
                  right: 30,
                  child: Row(
                    children: const [
                      Expanded(child: _SmallWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _SmallWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _SmallWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _SmallWidgetBlock()),
                    ],
                  ),
                ),
                Positioned(
                  top: 286,
                  left: 30,
                  right: 30,
                  child: Row(
                    children: const [
                      Expanded(child: _FadedWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _FadedWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _FadedWidgetBlock()),
                      SizedBox(width: 2),
                      Expanded(child: _FadedWidgetBlock()),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 118,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.bg.withValues(alpha: 0),
                            AppColors.bg,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneFramePainter extends CustomPainter {
  const _PhoneFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    const radius = 56.0;
    final inset = stroke / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final path = Path()
      ..moveTo(inset, size.height)
      ..lineTo(inset, radius)
      ..quadraticBezierTo(inset, inset, radius, inset)
      ..lineTo(size.width - radius, inset)
      ..quadraticBezierTo(size.width - inset, inset, size.width - inset, radius)
      ..lineTo(size.width - inset, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PhoneFramePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SmallWidgetBlock extends StatelessWidget {
  const _SmallWidgetBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 69,
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _FadedWidgetBlock extends StatelessWidget {
  const _FadedWidgetBlock();

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.62, child: const _SmallWidgetBlock());
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(
            number,
            style: AppText.sans(
              size: 20,
              color: _Palette.gold,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppText.sans(
              size: 20,
              color: _Palette.body,
              height: 1.32,
            ),
          ),
        ),
      ],
    );
  }
}
