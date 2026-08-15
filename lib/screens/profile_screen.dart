import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import 'followed_topics_screen.dart';
import 'theme_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
                  'Profile',
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
              _StreakCard(),
              const SizedBox(height: 52),
              _sectionTitle('Quick actions'),
              const SizedBox(height: 20),
              _QuickGrid(
                onTopicsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FollowedTopicsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 46),
              _sectionTitle('Settings'),
              const SizedBox(height: 22),
              _SettingsGroup(
                onThemeTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  );
                  if (mounted) setState(() {});
                },
                rows: [
                  _ProfileRowData(
                    Icons.person_outline,
                    'Name',
                    _profileLoaded
                        ? ((_name?.trim().isNotEmpty ?? false)
                              ? _name!.trim()
                              : 'Not set')
                        : '',
                  ),
                  _ProfileRowData(
                    Icons.transgender,
                    'Gender',
                    _profileLoaded ? (_sex ?? 'Not set') : '',
                  ),
                  _ProfileRowData(
                    Icons.brightness_6_outlined,
                    'Theme',
                    appThemeModeLabel(AppThemeController.instance.mode),
                  ),
                  const _ProfileRowData(
                    Icons.credit_card,
                    'Customer center',
                    '',
                  ),
                  const _ProfileRowData(
                    Icons.chat_bubble_outline,
                    'Feedback',
                    '',
                  ),
                ],
              ),
              const SizedBox(height: 46),
              _sectionTitle('Legal'),
              const SizedBox(height: 22),
              _SettingsGroup(
                rows: [
                  _ProfileRowData(Icons.shield_outlined, 'Privacy Policy', ''),
                  _ProfileRowData(
                    Icons.description_outlined,
                    'Terms of Use',
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
            'Sign out',
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
            right: 25,
            top: 34,
            child: Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: Colors.black.withValues(alpha: 0.86),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 126, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Unlock everything',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 18, color: const Color(0xFF24211E)),
                ),
                const SizedBox(height: 8),
                Text(
                  'All quotes, themes,\ncategories & no ads',
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
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
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
          const _AnimatedSunBadge(),
          const SizedBox(width: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dotSize = ((constraints.maxWidth - 36) / 7).clamp(
                  28.0,
                  34.0,
                );
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final d in days)
                          SizedBox(
                            width: dotSize,
                            child: Center(
                              child: Text(
                                d,
                                style: AppText.sans(
                                  size: 13,
                                  color: d == 'Su'
                                      ? ProfileScreen._ink
                                      : ProfileScreen._faint,
                                  weight: d == 'Su'
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
                          _DayDot(checked: i >= 5, size: dotSize),
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
  const _AnimatedSunBadge();

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
        return _SunBadge(rotation: _controller.value * math.pi * 2);
      },
    );
  }
}

class _SunBadge extends StatelessWidget {
  const _SunBadge({required this.rotation});

  final double rotation;

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
                '2',
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
  const _QuickGrid({required this.onTopicsTap});

  final VoidCallback onTopicsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'Topics you\nfollow',
                icon: Icons.bookmark_border,
                onTap: onTopicsTap,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _QuickCard(title: 'App icon', icon: Icons.apps),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                title: 'Reminders',
                icon: Icons.notifications_none,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _QuickCard(
                title: 'Widgets',
                icon: Icons.grid_view_outlined,
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
  const _ProfileRowData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows, this.onThemeTap});

  final List<_ProfileRowData> rows;
  final VoidCallback? onThemeTap;

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
              onTap: rows[i].label == 'Theme' ? onThemeTap : null,
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
                      data.label,
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
