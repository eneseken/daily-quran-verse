import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/legal_links.dart';
import '../core/theme.dart';
import '../services/admob_service.dart';
import '../services/subscription_service.dart';
import '../widgets/breathing_loader.dart';

const _premiumFeatures = [
  _PaywallFeature(
    icon: Icons.menu_book_rounded,
    title: 'Every Quran feature unlocked',
    subtitle: 'All quotes, themes, categories and future premium updates.',
  ),
  _PaywallFeature(
    icon: Icons.wallpaper_rounded,
    title: 'Premium themes',
    subtitle: 'Use the full background collection on your daily verse feed.',
  ),
  _PaywallFeature(
    icon: Icons.apps_rounded,
    title: 'Custom App Icons',
    subtitle: 'Choose a beautiful premium icon for your home screen.',
  ),
  _PaywallFeature(
    icon: Icons.favorite_rounded,
    title: 'Support the app',
    subtitle: 'Help us keep improving this peaceful Quran experience.',
  ),
  _PaywallFeature(
    icon: Icons.block_rounded,
    title: 'No ads',
    subtitle: 'A calm reading space for daily Quran verses and reminders.',
    slash: true,
  ),
];

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  Offering? _offering;
  Package? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  late final AnimationController _featureController;

  @override
  void initState() {
    super.initState();
    _featureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadOfferings();
  }

  @override
  void dispose() {
    _featureController.dispose();
    super.dispose();
  }

  Future<void> _loadOfferings() async {
    final offering = await SubscriptionService.instance.currentOffering();
    if (!mounted) return;
    setState(() {
      _offering = offering;
      _selected = _preferredDefault(offering);
      _loading = false;
    });
  }

  Package? _preferredDefault(Offering? offering) {
    final packages = offering?.availablePackages ?? const [];
    if (packages.isEmpty) return null;
    return _packageFor(PackageType.annual, packages) ?? packages.first;
  }

  Package? _packageFor(PackageType type, List<Package> packages) {
    for (final package in packages) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  void _close({bool showAd = true}) {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (showAd) {
      unawaited(AdMobService.instance.showInterstitialIfAvailable());
    }
  }

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null || _busy) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ok = await SubscriptionService.instance.purchase(package);
      if (!mounted) return;
      if (ok) {
        _close();
        return;
      }
      setState(() => _busy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "That didn't go through. Please try again.";
      });
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await SubscriptionService.instance.restore();
    if (!mounted) return;
    if (ok) {
      _close();
      return;
    }
    setState(() {
      _busy = false;
      _error = 'No previous purchase found on this account.';
    });
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    final packages = _offering?.availablePackages ?? const <Package>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: BreathingLoader(glow: AppColors.gold))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth <= 360 ? 17.0 : 20.0;
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            18,
                            horizontal,
                            8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: _CloseButton(onClose: _close),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock your daily\nQuran journey',
                                textAlign: TextAlign.center,
                                style: AppText.serif(
                                  size: 30,
                                  color: AppColors.ink,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 24),
                              for (var i = 0; i < _premiumFeatures.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 19),
                                  child: _AnimatedFeatureRow(
                                    controller: _featureController,
                                    index: i,
                                    child: _FeatureRow(
                                      feature: _premiumFeatures[i],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _BottomPaywallPanel(
                        packages: packages,
                        selected: _selected,
                        busy: _busy,
                        error: _error,
                        onSelect: (package) {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = package);
                        },
                        onPurchase: _purchase,
                        onDismiss: _close,
                        onRestore: _restore,
                        onTerms: () => openLegalUrl(legalTermsUrlFor(context)),
                        onPrivacy: () => openLegalUrl(legalPrivacyUrl),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _PaywallFeature {
  const _PaywallFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.slash = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool slash;
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onClose,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 38,
          width: 38,
          child: Icon(Icons.close, size: 22, color: AppColors.inkFaint),
        ),
      ),
    );
  }
}

class _AnimatedFeatureRow extends StatelessWidget {
  const _AnimatedFeatureRow({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.12).clamp(0.0, 0.82);
    final end = (start + 0.18).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final _PaywallFeature feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(top: 1, left: 12),
          decoration: BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(feature.icon, color: AppColors.ctaOnBg, size: 21),
              if (feature.slash)
                Transform.rotate(
                  angle: -0.78,
                  child: Container(
                    width: 25,
                    height: 1.8,
                    color: AppColors.ctaOnBg,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: AppText.sans(
                  size: 20,
                  color: AppColors.ink,
                  weight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                feature.subtitle,
                style: AppText.sans(
                  size: 16,
                  color: AppColors.inkSoft,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomPaywallPanel extends StatelessWidget {
  const _BottomPaywallPanel({
    required this.packages,
    required this.selected,
    required this.busy,
    required this.error,
    required this.onSelect,
    required this.onPurchase,
    required this.onDismiss,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
  });

  final List<Package> packages;
  final Package? selected;
  final bool busy;
  final String? error;
  final ValueChanged<Package> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onDismiss;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final monthly = _packageFor(PackageType.monthly) ?? _fallbackPackage(0);
    final yearly = _packageFor(PackageType.annual) ?? _fallbackPackage(1);

    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.bg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (packages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "Plans aren't available right now. Please try again later.",
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 14, color: AppColors.inkSoft),
                ),
              )
            else
              Row(
                children: [
                  if (monthly != null)
                    Expanded(
                      child: _PlanCard(
                        package: monthly,
                        isPopular: monthly.packageType == PackageType.monthly,
                        isSelected: _samePackage(monthly, selected),
                        onTap: () => onSelect(monthly),
                      ),
                    ),
                  if (monthly != null && yearly != null)
                    const SizedBox(width: 8),
                  if (yearly != null)
                    Expanded(
                      child: _PlanCard(
                        package: yearly,
                        isPopular: monthly == null,
                        isSelected: _samePackage(yearly, selected),
                        onTap: () => onSelect(yearly),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            const _CancelNotice(),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 12.5, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: packages.isEmpty || busy ? null : onPurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ctaBg,
                  foregroundColor: AppColors.ctaOnBg,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: busy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(AppColors.ctaOnBg),
                        ),
                      )
                    : Text(
                        'Start my Quran journey',
                        style: AppText.sans(
                          size: 17,
                          color: AppColors.ctaOnBg,
                          weight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: busy ? null : onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                minimumSize: const Size.fromHeight(24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'No, thank you',
                style: AppText.sans(size: 17, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 9),
            _LegalFooter(
              onRestore: onRestore,
              onTerms: onTerms,
              onPrivacy: onPrivacy,
            ),
          ],
        ),
      ),
    );
  }

  Package? _packageFor(PackageType type) {
    for (final package in packages) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  Package? _fallbackPackage(int index) {
    if (packages.length <= index) return null;
    return packages[index];
  }

  bool _samePackage(Package a, Package? b) {
    return identical(a, b) || a.identifier == b?.identifier;
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
    this.isPopular = false,
  });

  final Package package;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback onTap;

  String get _label => switch (package.packageType) {
    PackageType.annual => 'Yearly',
    PackageType.monthly => 'Monthly',
    PackageType.weekly => 'Weekly',
    PackageType.lifetime => 'Lifetime',
    _ => package.storeProduct.title,
  };

  String get _priceSuffix => switch (package.packageType) {
    PackageType.annual => '/yr',
    PackageType.monthly => '/mo',
    PackageType.weekly => '/wk',
    _ => '',
  };

  String get _price => '${package.storeProduct.priceString}$_priceSuffix';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 74,
        padding: const EdgeInsets.fromLTRB(19, 14, 15, 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.track,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isPopular)
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Most Popular',
                      style: AppText.sans(
                        size: 9,
                        color: AppColors.ctaOnBg,
                        weight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 14, color: AppColors.ink),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 17,
                          color: AppColors.ink,
                          weight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectionDot(isSelected: isSelected),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.gold : AppColors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.track, width: 1.6),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, color: AppColors.ctaOnBg, size: 16)
          : null,
    );
  }
}

class _CancelNotice extends StatelessWidget {
  const _CancelNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_rounded, color: AppColors.ink, size: 24),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            defaultTargetPlatform == TargetPlatform.iOS
                ? 'No commitment, cancel anytime in App Store Subscriptions'
                : 'No commitment, cancel anytime on Google Play Subscriptions Page',
            textAlign: TextAlign.left,
            style: AppText.sans(size: 15, color: AppColors.ink, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 15,
      runSpacing: 2,
      children: [
        _LegalLink(text: 'Restore', onTap: onRestore),
        _LegalLink(text: 'Terms of Use', onTap: onTerms),
        _LegalLink(text: 'Privacy', onTap: onPrivacy),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: 0.62,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(
            text,
            style: AppText.sans(size: 11, color: AppColors.ink, height: 1.2),
          ),
        ),
      ),
    );
  }
}
