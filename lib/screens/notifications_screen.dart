import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _daily = false;
  bool _prayer = false;
  bool _loaded = false;
  bool _busy = false;

  static Color get _card =>
      AppColors.isDark ? const Color(0xFF3B352F) : const Color(0xFFE7E1D7);
  static Color get _switchOff =>
      AppColors.isDark ? const Color(0xFF5A554F) : const Color(0xFFD5D0C6);
  static Color get _thumb =>
      AppColors.isDark ? const Color(0xFFF1EDE5) : Colors.white;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final settings = await NotificationService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _daily = settings.daily;
      _prayer = settings.prayer;
      _loaded = true;
    });
  }

  Future<void> _setDaily(bool value) async {
    await _setPreference(
      value: value,
      apply: NotificationService.instance.setDailyEnabled,
      updateLocal: () => _daily = value,
    );
  }

  Future<void> _setPrayer(bool value) async {
    await _setPreference(
      value: value,
      apply: NotificationService.instance.setPrayerEnabled,
      updateLocal: () => _prayer = value,
    );
  }

  Future<void> _setPreference({
    required bool value,
    required Future<void> Function(bool value) apply,
    required VoidCallback updateLocal,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      updateLocal();
    });

    try {
      if (value) {
        final allowed = await NotificationService.instance.requestPermission();
        if (!allowed) throw StateError('notification permission denied');
      }
      await apply(value);
    } catch (_) {
      if (mounted) await _restore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    final media = MediaQuery.of(context);
    final metrics = _NotificationMetrics.from(media.size);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              metrics.pagePadding,
              metrics.topPadding,
              metrics.pagePadding,
              34,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButton(size: metrics.backButtonSize),
                SizedBox(height: metrics.topGap),
                Center(
                  child: Text(
                    'Choose when you\nreceive your daily\nQuran verse',
                    textAlign: TextAlign.center,
                    style: AppText.serif(
                      size: metrics.titleSize,
                      color: AppColors.ink,
                      height: 1.1,
                    ),
                  ),
                ),
                SizedBox(height: metrics.subtitleGap),
                Center(
                  child: Text(
                    'Gentle reminders to pause, read, and\ncarry Allah\'s words with you',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      size: metrics.subtitleSize,
                      color: AppColors.inkSoft,
                      height: 1.34,
                    ),
                  ),
                ),
                SizedBox(height: metrics.cardTopGap),
                _NotificationCard(
                  title: 'Daily notifications',
                  subtitle: 'Receive Quran verses throughout the\nday',
                  value: _daily,
                  enabled: _loaded && !_busy,
                  onChanged: _setDaily,
                  cardColor: _card,
                  switchOffColor: _switchOff,
                  thumbColor: _thumb,
                  metrics: metrics,
                ),
                SizedBox(height: metrics.cardGap),
                _NotificationCard(
                  title: 'Prayer reminders',
                  subtitle: 'Get reminded to complete your daily\nprayer',
                  value: _prayer,
                  enabled: _loaded && !_busy,
                  onChanged: _setPrayer,
                  cardColor: _card,
                  switchOffColor: _switchOff,
                  thumbColor: _thumb,
                  metrics: metrics,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationMetrics {
  const _NotificationMetrics({required this.scale, required this.compact});

  factory _NotificationMetrics.from(Size size) {
    final widthScale = (size.width / 430).clamp(0.76, 1.0).toDouble();
    final heightScale = (size.height / 840).clamp(0.86, 1.0).toDouble();
    return _NotificationMetrics(
      scale: widthScale < heightScale ? widthScale : heightScale,
      compact: size.width < 380 || size.height < 720,
    );
  }

  final double scale;
  final bool compact;

  double get pagePadding => compact ? 18 : 24;
  double get topPadding => compact ? 16 : 20;
  double get backButtonSize => compact ? 40 : 44;
  double get topGap => compact ? 24 : 42 * scale;
  double get titleSize => (43 * scale).clamp(32, 43).toDouble();
  double get subtitleGap => compact ? 18 : 28 * scale;
  double get subtitleSize => (23 * scale).clamp(17, 23).toDouble();
  double get cardTopGap => compact ? 34 : 54 * scale;
  double get cardGap => compact ? 18 : 24;
  double get cardMinHeight => compact ? 106 : 126 * scale;
  double get cardRadius => compact ? 30 : 34;
  double get cardHPadding => compact ? 22 : 32 * scale;
  double get cardRightPadding => compact ? 20 : 28 * scale;
  double get cardVPadding => compact ? 18 : 24 * scale;
  double get cardTitleSize => (25 * scale).clamp(20, 25).toDouble();
  double get cardSubtitleSize => (19 * scale).clamp(15.5, 19).toDouble();
  double get titleSubtitleGap => compact ? 12 : 18 * scale;
  double get switchWidth => (86 * scale).clamp(68, 86).toDouble();
  double get switchHeight => (54 * scale).clamp(42, 54).toDouble();
  double get switchPadding => (5 * scale).clamp(4, 5).toDouble();
  double get switchThumb => switchHeight - switchPadding * 2;
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: size * 0.7,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.cardColor,
    required this.switchOffColor,
    required this.thumbColor,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final Color cardColor;
  final Color switchOffColor;
  final Color thumbColor;
  final _NotificationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(metrics.cardRadius),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        child: Container(
          constraints: BoxConstraints(minHeight: metrics.cardMinHeight),
          padding: EdgeInsets.fromLTRB(
            metrics.cardHPadding,
            metrics.cardVPadding,
            metrics.cardRightPadding,
            metrics.cardVPadding,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(metrics.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: metrics.cardTitleSize,
                        color: AppColors.ink,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: metrics.titleSubtitleGap),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: metrics.cardSubtitleSize,
                        color: AppColors.inkSoft,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: metrics.compact ? 12 : 18),
              _WarmSwitch(
                value: value,
                enabled: enabled,
                offColor: switchOffColor,
                thumbColor: thumbColor,
                onChanged: onChanged,
                metrics: metrics,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmSwitch extends StatelessWidget {
  const _WarmSwitch({
    required this.value,
    required this.enabled,
    required this.offColor,
    required this.thumbColor,
    required this.onChanged,
    required this.metrics,
  });

  final bool value;
  final bool enabled;
  final Color offColor;
  final Color thumbColor;
  final ValueChanged<bool> onChanged;
  final _NotificationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: metrics.switchHeight,
        width: metrics.switchWidth,
        padding: EdgeInsets.all(metrics.switchPadding),
        decoration: BoxDecoration(
          color: value ? AppColors.gold : offColor.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(40),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            height: metrics.switchThumb,
            width: metrics.switchThumb,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppColors.isDark ? 0.18 : 0.12,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
