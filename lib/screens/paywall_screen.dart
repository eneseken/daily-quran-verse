import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../services/subscription_service.dart';
import '../widgets/breathing_loader.dart';
import '../widgets/reveal.dart';
import 'home/feed_theme.dart';

/// Apple requires the standard EULA to be linked from anywhere a subscription
/// is sold; the privacy policy is required on both stores.
const _termsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const _privacyUrl = 'https://sites.google.com/view/quran-verse/home';

/// What a subscription unlocks. Placeholders for now — the list is the promise
/// we design against, and each line gets built out later.
const _features = [
  (
    '🔊',
    'Every reciter, offline',
    'Alafasy, Sudais, Minshawi and more — downloaded for the commute, '
        'the plane, the quiet hours.',
  ),
  (
    '🗂️',
    'Unlimited collections',
    'Save any ayah into themed collections — hardship, gratitude, patience — '
        'instead of one flat list.',
  ),
  (
    '🔁',
    'Memorisation mode',
    'Spaced repetition built around the ayahs you saved, so what you read '
        'actually stays with you.',
  ),
  (
    '🎨',
    'Widgets & themes',
    'Every home-screen widget size, and the full set of paper and night '
        'themes for the feed.',
  ),
  (
    '🌍',
    'All translations',
    'Read side by side in any supported language, with word-by-word meaning.',
  ),
];

/// Full-screen subscription offer. Shown on app open for users without the
/// entitlement, and dismissible — never a hard wall.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.onDismiss});

  /// Called when the user closes the paywall or finishes purchasing. When
  /// null, the screen pops itself instead.
  final VoidCallback? onDismiss;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  Package? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offering = await SubscriptionService.instance.currentOffering();
    if (!mounted) return;
    setState(() {
      _offering = offering;
      // Default to the annual plan — the better deal, and what the layout
      // leads with.
      _selected = _preferredDefault(offering);
      _loading = false;
    });
  }

  Package? _preferredDefault(Offering? offering) {
    final packages = offering?.availablePackages ?? const [];
    if (packages.isEmpty) return null;
    return packages.firstWhere(
      (p) => p.packageType == PackageType.annual,
      orElse: () => packages.first,
    );
  }

  void _close() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _purchase() async {
    final package = _selected;
    if (package == null || _busy) return;

    HapticFeedback.lightImpact();
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

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offering?.availablePackages ?? const <Package>[];

    return Scaffold(
      backgroundColor: FeedColors.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: BreathingLoader(glow: FeedColors.gold))
            : Column(
                children: [
                  _CloseRow(onClose: _close),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 4, 26, 8),
                      child: RevealColumn(
                        step: const Duration(milliseconds: 260),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text.rich(
                              TextSpan(
                                children: markup(
                                  'Keep the Quran **close, every day.**',
                                  FeedText.quote(size: 27),
                                  FeedText.quote(
                                    size: 27,
                                  ).copyWith(color: FeedColors.gold),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: Text(
                              'Premium opens the whole app — recitation, '
                              'memorisation and every translation.',
                              style: AppText.sans(
                                size: 14.5,
                                color: FeedColors.inkSoft,
                              ),
                            ),
                          ),
                          for (final (emoji, title, body) in _features)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FeatureRow(
                                emoji: emoji,
                                title: title,
                                body: body,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _PurchasePanel(
                    packages: packages,
                    selected: _selected,
                    busy: _busy,
                    error: _error,
                    onSelect: (p) {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = p);
                    },
                    onPurchase: _purchase,
                    onRestore: _restore,
                    onTerms: () => _open(_termsUrl),
                    onPrivacy: () => _open(_privacyUrl),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CloseRow extends StatelessWidget {
  const _CloseRow({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          const Spacer(),
          // Deliberately low contrast: present and tappable, but not competing
          // with the offer. Full 44pt target for accessibility.
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: SizedBox(
                height: 44,
                width: 44,
                child: Icon(Icons.close, size: 20, color: FeedColors.inkFaint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 19)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.sans(
                  size: 14.5,
                  color: FeedColors.ink,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: AppText.sans(
                  size: 13,
                  color: FeedColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The plan picker, CTA and legal footer — pinned below the scrolling copy so
/// the price and the button are always on screen.
class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({
    required this.packages,
    required this.selected,
    required this.busy,
    required this.error,
    required this.onSelect,
    required this.onPurchase,
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
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 10),
      decoration: BoxDecoration(
        // A hairline lifts the panel off the scrolling list without a hard
        // slab of colour.
        border: Border(top: BorderSide(color: FeedColors.chipBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (packages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Plans aren't available right now. Please try again later.",
                textAlign: TextAlign.center,
                style: AppText.sans(size: 13.5, color: FeedColors.inkSoft),
              ),
            )
          else
            for (final package in packages)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanTile(
                  package: package,
                  selected:
                      identical(package, selected) ||
                      package.identifier == selected?.identifier,
                  onTap: () => onSelect(package),
                ),
              ),
          if (error != null) ...[
            const SizedBox(height: 2),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: AppText.sans(size: 12.5, color: FeedColors.liked),
            ),
          ],
          const SizedBox(height: 6),
          _PaywallCta(
            label: busy ? '' : 'Continue',
            busy: busy,
            onPressed: packages.isEmpty ? null : onPurchase,
          ),
          const SizedBox(height: 8),
          _LegalFooter(
            onRestore: onRestore,
            onTerms: onTerms,
            onPrivacy: onPrivacy,
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final VoidCallback onTap;

  /// "Yearly" / "Monthly" rather than RevenueCat's raw identifiers.
  String get _title => switch (package.packageType) {
    PackageType.annual => 'Yearly',
    PackageType.monthly => 'Monthly',
    PackageType.weekly => 'Weekly',
    PackageType.lifetime => 'Lifetime',
    _ => package.storeProduct.title,
  };

  String? get _perMonth {
    if (package.packageType != PackageType.annual) return null;
    final price = package.storeProduct.price;
    if (price <= 0) return null;
    final monthly = price / 12;
    return '${package.storeProduct.currencyCode} '
        '${monthly.toStringAsFixed(2)}/mo';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? FeedColors.chip : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? FeedColors.gold : FeedColors.chipBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppText.sans(
                        size: 15,
                        color: FeedColors.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                    if (_perMonth != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _perMonth!,
                        style: AppText.sans(
                          size: 12.5,
                          color: FeedColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                package.storeProduct.priceString,
                style: AppText.sans(
                  size: 15,
                  color: FeedColors.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? FeedColors.gold : Colors.transparent,
        border: Border.all(
          color: selected ? FeedColors.gold : FeedColors.inkFaint,
          width: 1.6,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 13, color: FeedColors.bg)
          : null,
    );
  }
}

/// Cream pill matching the reviews screen's CTA, so the two read as one flow.
class _PaywallCta extends StatelessWidget {
  const _PaywallCta({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: enabled ? FeedColors.ink : FeedColors.chip,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: busy
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(FeedColors.inkSoft),
                    ),
                  )
                : Text(
                    label,
                    style: AppText.sans(
                      size: 16.5,
                      color: enabled ? FeedColors.bg : FeedColors.inkFaint,
                      weight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Restore, terms and privacy. Small and quiet at the very bottom, as asked —
/// but still a real 44pt-tall tap target on each link.
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
    // Apple requires the standard EULA link wherever a subscription is sold;
    // Google has no such requirement, so Terms is iOS-only.
    final showTerms = Theme.of(context).platform == TargetPlatform.iOS;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FooterLink(label: 'Restore', onTap: onRestore),
        if (showTerms) ...[
          const _FooterDot(),
          _FooterLink(label: 'Terms', onTap: onTerms),
        ],
        const _FooterDot(),
        _FooterLink(label: 'Privacy', onTap: onPrivacy),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          label,
          style: AppText.sans(size: 11.5, color: FeedColors.inkFaint),
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: AppText.sans(size: 11.5, color: FeedColors.inkFaint),
    );
  }
}
