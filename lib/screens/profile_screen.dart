import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/legal_links.dart';
import '../core/quran_language.dart';
import '../core/theme.dart';
import 'app_icon_screen.dart';
import 'customize_screen.dart';
import 'edit_gender_screen.dart';
import 'edit_name_screen.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import 'followed_topics_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'theme_screen.dart';
import 'widgets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Color get _bg => AppColors.bg;
  static Color get _card =>
      AppColors.isDark ? const Color(0xFF3B352F) : const Color(0xFFE7E1D7);
  static Color get _line =>
      AppColors.isDark ? const Color(0x1FFFFFFF) : Colors.transparent;
  static Color get _ink =>
      AppColors.isDark ? AppColors.ink : const Color(0xFF2C2926);
  static Color get _muted =>
      AppColors.isDark ? AppColors.inkSoft : const Color(0xFF69635D);
  static Color get _faint =>
      AppColors.isDark ? AppColors.inkFaint : const Color(0xFF918B85);
  static Color get _gold =>
      AppColors.isDark ? const Color(0xFFF6CC83) : const Color(0xFFDCAF59);
  static Color get _icon =>
      AppColors.isDark ? const Color(0xFFF6CC83) : const Color(0xFF8D8882);
  static Color get _chevron =>
      AppColors.isDark ? const Color(0xFF8F867D) : const Color(0xFFC9C1B8);
  static Color get _uncheckedDot =>
      AppColors.isDark ? const Color(0xFF272624) : const Color(0xFFF1ECE5);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Null while unfetched — the row hides its value text until then rather
  // than flashing a fallback like "Not set" for users who do have data.
  String? _name;
  String? _sex;
  bool _profileLoaded = false;
  StreakSummary _streak = StreakSummary.zero;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStreak();
    // Rebuilds this screen's copy the instant the language changes, however
    // it was changed — not just right after this screen's own Language row
    // is used, so the "change takes effect immediately, everywhere" holds
    // even if something else ever triggers a language change later.
    QuranLanguageController.instance.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    QuranLanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final summary = await AuthService.instance.fetchProfileSummary();
    if (!mounted) return;
    setState(() {
      _name = summary.name;
      _sex = summary.sex;
      _profileLoaded = true;
    });
  }

  Future<void> _loadStreak() async {
    final streak = await StreakService.instance.fetchStreak();
    if (!mounted) return;
    setState(() => _streak = streak);
  }

  Future<void> _editName() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => EditNameScreen(initial: _name ?? '')),
    );
    if (result != null && mounted) setState(() => _name = result);
  }

  Future<void> _editGender() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditGenderScreen(name: _name ?? '', initial: _sex),
      ),
    );
    if (result != null && mounted) setState(() => _sex = result);
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    // Pop back to the root route — its StreamBuilder has already swapped to
    // AuthScreen/OnboardingFlow now that the session is gone, this just
    // stops this screen from sitting on top of it, stale, until dismissed.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: ProfileScreen._bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopClose(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  AppStrings.t('profile_title'),
                  style: AppText.serif(
                    size: 42,
                    color: ProfileScreen._ink,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _UnlockCard(),
              const SizedBox(height: 16),
              _StreakCard(streak: _streak),
              const SizedBox(height: 52),
              _sectionTitle(AppStrings.t('quick_actions')),
              const SizedBox(height: 20),
              _QuickGrid(
                onRemindersTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                onWidgetsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WidgetsScreen()),
                  );
                },
                onAppIconTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppIconScreen()),
                  );
                },
                onTopicsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FollowedTopicsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 46),
              _sectionTitle(AppStrings.t('settings')),
              const SizedBox(height: 22),
              _SettingsGroup(
                onNameTap: _editName,
                onGenderTap: _editGender,
                onCustomizeTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomizeScreen()),
                  );
                },
                onThemeTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  );
                  if (mounted) setState(() {});
                },
                onLanguageTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  );
                  if (mounted) setState(() {});
                },
                rows: [
                  _ProfileRowData(
                    Icons.person_outline,
                    'name',
                    _profileLoaded
                        ? ((_name?.trim().isNotEmpty ?? false)
                              ? _name!.trim()
                              : AppStrings.t('not_set'))
                        : '',
                  ),
                  _ProfileRowData(
                    Icons.transgender,
                    'gender',
                    _profileLoaded ? (_sex ?? AppStrings.t('not_set')) : '',
                  ),
                  _ProfileRowData(
                    Icons.language,
                    'language',
                    supportedQuranLanguages[QuranLanguageController.instance.code] ??
                        QuranLanguageController.instance.code,
                  ),
                  _ProfileRowData(
                    Icons.brightness_6_outlined,
                    'theme',
                    AppStrings.t(
                      'theme_${AppThemeController.instance.mode.name}',
                    ),
                  ),
                  _ProfileRowData(Icons.wallpaper_outlined, 'customize', ''),
                  _ProfileRowData(Icons.credit_card, 'customer_center', ''),
                  _ProfileRowData(Icons.chat_bubble_outline, 'feedback', ''),
                ],
              ),
              const SizedBox(height: 46),
              _sectionTitle(AppStrings.t('legal')),
              const SizedBox(height: 22),
              _SettingsGroup(
                onPrivacyTap: () => openLegalUrl(legalPrivacyUrl),
                // Apple's standard EULA on iOS; Android has no equivalent
                // page of its own, so this row opens the same privacy link
                // there rather than dead-ending or disappearing.
                onTermsTap: () => openLegalUrl(legalTermsUrlFor(context)),
                rows: const [
                  _ProfileRowData(Icons.shield_outlined, 'privacy_policy', ''),
                  _ProfileRowData(
                    Icons.description_outlined,
                    'terms_of_use',
                    '',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(child: _SignOutButton(onTap: _signOut)),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  AuthService.instance.user?.id ?? '',
                  style: AppText.sans(
                    size: 12,
                    color: ProfileScreen._chevron,
                    spacing: 1.2,
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

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            AppStrings.t('sign_out'),
            style: AppText.sans(
              size: 16,
              color: AppColors.error,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopClose extends StatelessWidget {
  const _TopClose({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onClose,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Icon(Icons.close, size: 32, color: ProfileScreen._ink),
          ),
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: ProfileScreen._gold,
        borderRadius: BorderRadius.circular(33),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 24,
            child: Container(
              height: 112,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 19,
            top: 48,
            child: Icon(
              Icons.menu_book_outlined,
              size: 70,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 126, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.t('unlock_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 18, color: const Color(0xFF24211E)),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.t('unlock_subtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 16,
                    color: const Color(0xFF5E564D),
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StreakSummary streak;

  @override
  Widget build(BuildContext context) {
    final days = AppStrings.weekdaysShort();
    // DateTime.weekday is 1=Monday..7=Sunday; -1 lines it up with `days`
    // (and with the server's week array, which uses the same order) so the
    // bolded label is always today, not a hardcoded day.
    final todayIndex = DateTime.now().weekday - 1;
    return Container(
      height: 134,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ProfileScreen._card,
        borderRadius: BorderRadius.circular(33),
        border: Border.all(color: ProfileScreen._line),
      ),
      child: Row(
        children: [
          _AnimatedSunBadge(count: streak.currentStreak),
          const SizedBox(width: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // MainAxisAlignment.spaceBetween only distributes leftover
                // space between children — it can't shrink them — so the
                // only way to guarantee 7 dots never overflow a narrow card
                // is to size each one off the full available width itself,
                // not a fixed guess at how much room the gaps need. The
                // upper clamp is purely cosmetic, to stop dots ballooning on
                // wide screens.
                final dotSize = (constraints.maxWidth / days.length).clamp(
                  0.0,
                  34.0,
                );
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < days.length; i++)
                          SizedBox(
                            width: dotSize,
                            child: Center(
                              child: Text(
                                days[i],
                                style: AppText.sans(
                                  size: 13,
                                  color: i == todayIndex
                                      ? ProfileScreen._ink
                                      : ProfileScreen._faint,
                                  weight: i == todayIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 7; i++)
                          _DayDot(
                            checked: i < streak.week.length && streak.week[i],
                            size: dotSize,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSunBadge extends StatefulWidget {
  const _AnimatedSunBadge({required this.count});

  final int count;

  @override
  State<_AnimatedSunBadge> createState() => _AnimatedSunBadgeState();
}

class _AnimatedSunBadgeState extends State<_AnimatedSunBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _SunBadge(
          rotation: _controller.value * math.pi * 2,
          count: widget.count,
        );
      },
    );
  }
}

class _SunBadge extends StatelessWidget {
  const _SunBadge({required this.rotation, required this.count});

  final double rotation;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      width: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: const Size.square(76),
              painter: _SunRaysPainter(color: ProfileScreen._gold),
            ),
          ),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: ProfileScreen._gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: AppText.sans(
                  size: 26,
                  color: ProfileScreen._card,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  const _SunRaysPainter({required this.color});

  final Color color;

  static const _rayLengths = <double>[
    8,
    5,
    11,
    6,
    9,
    4,
    12,
    7,
    5,
    10,
    6,
    12,
    4,
    9,
    7,
    11,
    5,
    8,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _rayLengths.length; i++) {
      final angle = i * math.pi * 2 / _rayLengths.length;
      final length = _rayLengths[i];
      const startRadius = 29.0;
      final endRadius = startRadius + length;
      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.checked, required this.size});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: checked ? ProfileScreen._gold : ProfileScreen._uncheckedDot,
        shape: BoxShape.circle,
      ),
      child: checked
          ? Icon(Icons.check, size: size * 0.62, color: Colors.white)
          : null,
    );
  }
}

Widget _sectionTitle(String text) => Text(
  text,
  style: AppText.serif(size: 29, color: ProfileScreen._ink, height: 1.05),
);

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.onTopicsTap,
    required this.onAppIconTap,
    required this.onRemindersTap,
    required this.onWidgetsTap,
  });

  final VoidCallback onTopicsTap;
  final VoidCallback onAppIconTap;
  final VoidCallback onRemindersTap;
  final VoidCallback onWidgetsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: AppStrings.t('topics_you_follow'),
                icon: Icons.bookmark_border,
                onTap: onTopicsTap,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _QuickCard(
                title: AppStrings.t('app_icon'),
                icon: Icons.apps,
                onTap: onAppIconTap,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: AppStrings.t('reminders'),
                icon: Icons.notifications_none,
                onTap: onRemindersTap,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _QuickCard(
                title: AppStrings.t('widgets'),
                icon: Icons.grid_view_outlined,
                onTap: onWidgetsTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.title, required this.icon, this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(38),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Container(
          height: 138,
          padding: const EdgeInsets.fromLTRB(20, 21, 20, 20),
          decoration: BoxDecoration(
            color: ProfileScreen._card,
            borderRadius: BorderRadius.circular(33),
            border: Border.all(color: ProfileScreen._line),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  title,
                  style: AppText.sans(
                    size: 18,
                    color: ProfileScreen._ink,
                    height: 1.45,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(icon, size: 28, color: ProfileScreen._icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRowData {
  const _ProfileRowData(this.icon, this.labelKey, this.value);

  final IconData icon;

  /// An AppStrings key, not the display text itself — the label is rendered
  /// via AppStrings.t(labelKey), and _SettingsGroup also dispatches taps by
  /// this same stable key, so neither breaks when the displayed text
  /// changes language.
  final String labelKey;
  final String value;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.rows,
    this.onNameTap,
    this.onGenderTap,
    this.onLanguageTap,
    this.onThemeTap,
    this.onCustomizeTap,
    this.onPrivacyTap,
    this.onTermsTap,
  });

  final List<_ProfileRowData> rows;
  final VoidCallback? onNameTap;
  final VoidCallback? onGenderTap;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onThemeTap;
  final VoidCallback? onCustomizeTap;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileScreen._card,
        borderRadius: BorderRadius.circular(33),
        border: Border.all(color: ProfileScreen._line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _SettingsRow(
              data: rows[i],
              showDivider: i != rows.length - 1,
              onTap: switch (rows[i].labelKey) {
                'name' => onNameTap,
                'gender' => onGenderTap,
                'language' => onLanguageTap,
                'theme' => onThemeTap,
                'customize' => onCustomizeTap,
                'privacy_policy' => onPrivacyTap,
                'terms_of_use' => onTermsTap,
                _ => null,
              },
            ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.data,
    required this.showDivider,
    this.onTap,
  });

  final _ProfileRowData data;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Icon(data.icon, size: 24, color: ProfileScreen._icon),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      AppStrings.t(data.labelKey),
                      style: AppText.sans(size: 19, color: ProfileScreen._ink),
                    ),
                  ),
                  if (data.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        data.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 18,
                          color: ProfileScreen._muted,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right,
                    size: 29,
                    color: ProfileScreen._chevron,
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 22, right: 22),
            child: Divider(height: 1, thickness: 1, color: ProfileScreen._line),
          ),
      ],
    );
  }
}
