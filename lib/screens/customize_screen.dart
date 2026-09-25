import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/feed_background.dart';
import '../core/quran_language.dart';
import '../core/theme.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({super.key});

  static const _themeIds = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
  ];

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  late String? _selectedId = FeedBackgroundController.instance.themeId;

  @override
  void initState() {
    super.initState();
    QuranLanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    QuranLanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _select(String id, bool locked) async {
    if (locked) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => const PaywallScreen(),
        ),
      );
      if (!mounted) return;
      setState(() {});
      if (!SubscriptionService.instance.isPremium) return;
    }
    final nextId = _selectedId == id ? null : id;
    setState(() => _selectedId = nextId);
    await FeedBackgroundController.instance.select(nextId);
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    final isPremium = SubscriptionService.instance.isPremium;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Text(
                      AppStrings.t('customize'),
                      textAlign: TextAlign.center,
                      style: AppText.serif(
                        size: 43,
                        color: AppColors.ink,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              const _UnlockThemesCard(),
              const SizedBox(height: 37),
              Text(
                AppStrings.t('customize_for_you'),
                style: AppText.serif(size: 31, color: AppColors.ink, height: 1),
              ),
              const SizedBox(height: 38),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 31,
                  mainAxisSpacing: 33,
                  childAspectRatio: 0.62,
                ),
                itemCount: CustomizeScreen._themeIds.length,
                itemBuilder: (context, index) {
                  final id = CustomizeScreen._themeIds[index];
                  final locked = index >= 5 && !isPremium;
                  return _ThemeTile(
                    id: id,
                    locked: locked,
                    selected: _selectedId == id,
                    darkText: FeedBackgroundController.instance.darkTextFor(
                      id,
                    ),
                    onPickTextColor: _selectedId == id
                        ? (darkText) {
                            debugPrint(
                              'Customize: text override tap id=$id darkText=$darkText',
                            );
                            FeedBackgroundController.instance.setTextOverride(
                              id,
                              darkText,
                            );
                            setState(() {});
                          }
                        : null,
                    onTap: () => _select(id, locked),
                  );
                },
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
          height: 38,
          width: 38,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 27,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _UnlockThemesCard extends StatelessWidget {
  const _UnlockThemesCard();

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.isDark
        ? const Color(0xFFF6CC83)
        : const Color(0xFFDCAF59);
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(34),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -17,
            top: 25,
            child: Container(
              height: 118,
              width: 152,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 28,
            top: 41,
            child: Icon(
              Icons.menu_book_outlined,
              size: 59,
              color: Colors.black.withValues(alpha: 0.86),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 27, 150, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.t('customize_unlock_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 19, color: const Color(0xFF24211E)),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.t('customize_unlock_subtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 17,
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

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.id,
    required this.locked,
    required this.selected,
    required this.darkText,
    required this.onTap,
    this.onPickTextColor,
  });

  final String id;
  final bool locked;
  final bool selected;
  final bool darkText;
  final VoidCallback onTap;

  /// Non-null only for the currently selected tile — lets the user override
  /// this theme's verse-text color via the two dots in the corner. Null
  /// hides the dots entirely for unselected tiles.
  final ValueChanged<bool>? onPickTextColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: selected
                    ? Border.all(color: AppColors.gold, width: 3)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/themes/$id.png',
                        fit: BoxFit.cover,
                        cacheWidth: 260,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'Aa',
                      style: AppText.sans(
                        size: 31,
                        color: darkText
                            ? const Color(0xFF252320)
                            : Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 8,
                    child: locked ? const _LockBadge() : const _FreeBadge(),
                  ),
                  if (selected)
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: _SelectedBadge(),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Kept outside the InkWell above (rather than as one more Stack
        // child inside it) so tapping a dot never also fires the tile's own
        // onTap — with both as siblings of the same InkWell, tapping a dot
        // was toggling the tile's selection off in the same gesture.
        if (onPickTextColor != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: _TextColorDots(
              darkSelected: darkText,
              onPick: onPickTextColor!,
            ),
          ),
      ],
    );
  }
}

/// Two small dots — black and white — on the selected tile, letting the
/// user manually pick which one the verse text renders in over this
/// wallpaper, overriding the theme's built-in default contrast.
class _TextColorDots extends StatelessWidget {
  const _TextColorDots({required this.darkSelected, required this.onPick});

  final bool darkSelected;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(
              color: const Color(0xFF252320),
              selected: darkSelected,
              onTap: () => onPick(true),
            ),
            const SizedBox(width: 4),
            _Dot(
              color: Colors.white,
              selected: !darkSelected,
              onTap: () => onPick(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Material + InkWell (rather than a bare GestureDetector) so a tap
    // gives visible splash/highlight feedback — makes it obvious the tap
    // landed on this dot specifically, not its neighbor or the tile below.
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        // The visible dot stays small so two of them fit in a grid tile's
        // corner, but the tap target itself is padded out closer to a
        // comfortable thumb size.
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.6),
                width: selected ? 2 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
      child: const Icon(Icons.check, size: 15, color: Colors.white),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        AppStrings.t('badge_free'),
        style: AppText.sans(
          size: 10,
          color: AppColors.ctaOnBg,
          weight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock, size: 16, color: Colors.white),
    );
  }
}
