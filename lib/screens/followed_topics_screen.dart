import 'package:flutter/material.dart';

import '../core/theme.dart';

class FollowedTopicsScreen extends StatelessWidget {
  const FollowedTopicsScreen({super.key});

  static Color get _bg => AppColors.bg;
  static Color get _card => AppColors.surfaceSoft;
  static Color get _ink => AppColors.ink;
  static Color get _muted => AppColors.inkSoft;
  static Color get _gold =>
      AppColors.isDark ? const Color(0xFFF6CC83) : const Color(0xFFE2AF56);
  static Color get _lock =>
      AppColors.isDark ? const Color(0xFF8D857A) : const Color(0xFF8F8A82);

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(19, 21, 19, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 33),
                child: Text(
                  'Followed topics',
                  style: AppText.serif(size: 40, color: _ink, height: 1.0),
                ),
              ),
              const SizedBox(height: 36),
              _TopicGroup(
                rows: const [
                  _TopicRowData(Icons.auto_awesome, 'General', 'Following'),
                  _TopicRowData(Icons.favorite, 'My favorites', 'Follow'),
                  _TopicRowData(
                    Icons.edit_square,
                    'My own quotes',
                    'Follow',
                    locked: true,
                  ),
                ],
              ),
              const SizedBox(height: 44),
              _SectionTitle('By type'),
              const SizedBox(height: 23),
              _TopicGroup(
                rows: const [
                  _TopicRowData(Icons.auto_awesome, 'Affirmations', 'Follow'),
                  _TopicRowData(
                    Icons.menu_book,
                    'Bible Verses',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.back_hand,
                    'Prayers',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.format_quote,
                    'Quotes',
                    'Follow',
                    locked: true,
                  ),
                ],
              ),
              const SizedBox(height: 44),
              _SectionTitle('Explore'),
              const SizedBox(height: 23),
              _TopicGroup(
                rows: const [
                  _TopicRowData(
                    Icons.water_drop,
                    'Faith',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.wb_sunny_outlined,
                    'Hope',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(Icons.favorite, 'Love', 'Follow', locked: true),
                  _TopicRowData(
                    Icons.water_drop_outlined,
                    'Peace',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.monitor_heart,
                    'Strength',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.favorite_border,
                    'Gratitude',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.medical_services,
                    'Healing',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.back_hand,
                    'Forgiveness',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.explore,
                    'Guidance',
                    'Follow',
                    locked: true,
                  ),
                  _TopicRowData(
                    Icons.flash_on,
                    'Courage',
                    'Follow',
                    locked: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 32,
          width: 32,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
            color: FollowedTopicsScreen._ink,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.serif(size: 29, color: FollowedTopicsScreen._ink),
    );
  }
}

class _TopicGroup extends StatelessWidget {
  const _TopicGroup({required this.rows});

  final List<_TopicRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: FollowedTopicsScreen._card,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(children: [for (final row in rows) _TopicRow(data: row)]),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.data});

  final _TopicRowData data;

  @override
  Widget build(BuildContext context) {
    final isFollowing = data.action == 'Following';
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          const SizedBox(width: 22),
          SizedBox(
            width: 29,
            child: Icon(data.icon, size: 22, color: FollowedTopicsScreen._gold),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 18,
                      color: FollowedTopicsScreen._ink,
                      height: 1.0,
                    ),
                  ),
                ),
                if (data.locked) ...[
                  const SizedBox(width: 9),
                  Icon(Icons.lock, size: 15, color: FollowedTopicsScreen._lock),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            data.action,
            style: AppText.sans(
              size: 18,
              color: isFollowing
                  ? FollowedTopicsScreen._gold
                  : FollowedTopicsScreen._muted,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 19),
        ],
      ),
    );
  }
}

class _TopicRowData {
  const _TopicRowData(
    this.icon,
    this.label,
    this.action, {
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final String action;
  final bool locked;
}
