import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/feed_background.dart';
import '../../models/quran_verse.dart';
import '../../services/recitation_service.dart';
import 'feed_theme.dart';

/// The feed's fixed chrome: a subtle position indicator up top and the
/// play/share/like actions along the bottom, both reflecting whichever verse
/// is currently in view. Only [feed] scrolls between them.
class VerseFeedShell extends StatelessWidget {
  const VerseFeedShell({
    super.key,
    required this.verse,
    required this.ayahCountInSurah,
    required this.liked,
    required this.recitation,
    required this.feed,
    required this.onToggleLike,
    required this.onShare,
    required this.onOpenSettings,
    required this.onTogglePlayback,
    this.onOpenGift,
  });

  final QuranVerse verse;
  final int ayahCountInSurah;
  final bool liked;
  final RecitationState recitation;
  final Widget feed;
  final VoidCallback onToggleLike;
  final VoidCallback onShare;
  final VoidCallback onOpenSettings;
  final VoidCallback onTogglePlayback;
  final VoidCallback? onOpenGift;

  @override
  Widget build(BuildContext context) {
    final progress = verse.ayahNumber / ayahCountInSurah;
    final backgroundImage = FeedBackgroundController.instance.imagePath;

    return Container(
      decoration: BoxDecoration(
        color: FeedColors.bg,
        image: backgroundImage == null
            ? null
            : DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      _ProfileFab(onTap: onOpenSettings),
                      Expanded(
                        child: Center(
                          child: _TopIndicator(
                            label: '${verse.ayahNumber}/$ayahCountInSurah',
                            progress: progress,
                          ),
                        ),
                      ),
                      _GiftButton(onTap: onOpenGift ?? () {}),
                    ],
                  ),
                ),
                Expanded(child: feed),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _VerseActions(
                    liked: liked,
                    recitation: recitation,
                    onShare: onShare,
                    onToggleLike: onToggleLike,
                    onTogglePlayback: onTogglePlayback,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftButton extends StatefulWidget {
  const _GiftButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GiftButton> createState() => _GiftButtonState();
}

class _GiftButtonState extends State<_GiftButton>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/animation/gift.json';

  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _controller.value = 0;
    });
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _playOnce());
  }

  void _playOnce() {
    if (!_controller.isAnimating) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: Lottie.asset(
            _asset,
            controller: _controller,
            fit: BoxFit.contain,
            repeat: false,
            onLoaded: (composition) =>
                _controller.duration = composition.duration,
          ),
        ),
      ),
    );
  }
}

class _ProfileFab extends StatelessWidget {
  const _ProfileFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FeedColors.gold,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.person, size: 28, color: FeedColors.bg),
              const Icon(
                Icons.person_outline,
                size: 28,
                color: Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page of the feed ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â just the verse itself, since the surrounding
/// chrome lives in [VerseFeedShell] and does not scroll with it.
///
/// Ayah lengths vary enormously (2:282 is roughly forty times 108:1), so the
/// type is sized to the page rather than fixed: the largest scale at which
/// Arabic, translation and reference all still fit is measured and used.
class VersePage extends StatelessWidget {
  const VersePage({
    super.key,
    required this.verse,
    required this.languageCode,
    this.showArabic = true,
  });

  final QuranVerse verse;
  final String languageCode;

  /// When false, the Arabic block is omitted entirely ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â not just visually
  /// hidden ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â so the fit-scaling below stops reserving height for it and the
  /// translation gets to use that space instead.
  final bool showArabic;

  /// Sizes for a short ayah, scaled down from here as the text grows.
  /// Public so tests can assert against the actual values used.
  static const arabicSize = 30.0;
  static const quoteSize = 27.0;
  static const referenceSize = 13.0;
  static const _arabicGap = 30.0;
  static const _referenceGap = 18.0;

  /// The Arabic is set narrower than the translation, as in the design.
  static const _arabicWidthFactor = 0.85;

  /// Past this the verse stops being comfortably readable, so the longest
  /// ayahs settle here rather than shrinking into illegibility.
  static const minScale = 0.34;

  double _heightAt(
    double scale,
    double maxWidth,
    String translation,
    TextScaler scaler,
  ) {
    final arabicBlock = showArabic
        ? _measure(
                verse.arabicText,
                FeedText.arabic(size: arabicSize * scale),
                maxWidth * _arabicWidthFactor,
                scaler,
                TextDirection.rtl,
              ) +
              _arabicGap * scale
        : 0.0;
    return arabicBlock +
        _measure(
          translation,
          FeedText.quote(size: quoteSize * scale),
          maxWidth,
          scaler,
          TextDirection.ltr,
        ) +
        _referenceGap * scale +
        _measure(
          '\u2014 ${verse.reference}',
          FeedText.reference(size: referenceSize * scale),
          maxWidth,
          scaler,
          TextDirection.ltr,
        );
  }

  static double _measure(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textAlign: TextAlign.center,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);
    return painter.size.height;
  }

  /// The scale to render at, and whether that scale still overflows the
  /// available height even at the readability floor.
  ///
  /// The floor exists so long ayahs stay legible rather than shrinking to
  /// nothing ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â but 2:282 (the longest ayah in the Quran) on the smallest
  /// supported phones can still be taller than one page even at that floor.
  /// [overflows] tells the caller to fall back to letting the page scroll
  /// for that one rare combination, rather than clipping or violating the
  /// floor.
  (double scale, bool overflows) _fitScale({
    required double availableHeight,
    required double maxWidth,
    required String translation,
    required TextScaler scaler,
  }) {
    if (availableHeight <= 0 || maxWidth <= 0) return (1, false);

    if (_heightAt(1, maxWidth, translation, scaler) <= availableHeight) {
      return (1, false);
    }

    // Ten halvings land within ~0.05% of the true crossover ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â far finer than
    // a reader could notice, and cheap enough to redo on every layout.
    var fits = minScale;
    var tooBig = 1.0;
    for (var i = 0; i < 10; i++) {
      final mid = (fits + tooBig) / 2;
      if (_heightAt(mid, maxWidth, translation, scaler) <= availableHeight) {
        fits = mid;
      } else {
        tooBig = mid;
      }
    }

    final floorFits =
        _heightAt(minScale, maxWidth, translation, scaler) <= availableHeight;
    return (fits, !floorFits);
  }

  @override
  Widget build(BuildContext context) {
    final translation = verse.textFor(languageCode);
    const scaler = TextScaler.noScaling;
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: scaler),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fallbackHeight =
                media.size.height - media.padding.vertical - 154;
            final pageHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : fallbackHeight.clamp(320.0, double.infinity);
            final pageWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : (media.size.width - 44).clamp(240.0, double.infinity);
            final availableHeight = (pageHeight - 24).clamp(
              240.0,
              double.infinity,
            );
            final (scale, overflows) = _fitScale(
              availableHeight: availableHeight,
              maxWidth: pageWidth,
              translation: translation,
              scaler: scaler,
            );

            final column = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showArabic) ...[
                  FractionallySizedBox(
                    widthFactor: _arabicWidthFactor,
                    child: Text(
                      verse.arabicText,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: FeedText.arabic(size: arabicSize * scale),
                    ),
                  ),
                  SizedBox(height: _arabicGap * scale),
                ],
                Text(
                  translation,
                  textAlign: TextAlign.center,
                  style: FeedText.quote(size: quoteSize * scale),
                ),
                SizedBox(height: _referenceGap * scale),
                Text(
                  '\u2014 ${verse.reference}',
                  textAlign: TextAlign.center,
                  style: FeedText.reference(size: referenceSize * scale),
                ),
              ],
            );

            if (!overflows) {
              return SizedBox(
                height: pageHeight,
                child: Center(child: column),
              );
            }

            return SizedBox(
              height: pageHeight,
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: pageHeight - 36),
                  child: Center(child: column),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Small, low-contrast "ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬ÂÃ‚Â¢Ãƒâ€šÃ‚Â¡ 1/5 ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬" readout centered above the verse ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â never
/// competes with the Arabic and translation for attention.
class _TopIndicator extends StatelessWidget {
  const _TopIndicator({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = FeedBackgroundController.instance.imagePath != null;
    final chipColor = hasPhoto
        ? (FeedBackgroundController.instance.usesDarkText
              ? Colors.white.withValues(alpha: 0.42)
              : Colors.black.withValues(alpha: 0.38))
        : FeedColors.chip;
    final chipBorder = hasPhoto
        ? Colors.white.withValues(alpha: 0.55)
        : FeedColors.chipBorder;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: chipBorder),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 16, color: FeedColors.gold),
            const SizedBox(width: 7),
            Text(
              label,
              style: FeedText.label(
                color: FeedColors.ink,
              ).copyWith(fontSize: 13.5),
            ),
            const SizedBox(width: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 46,
                height: 6,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: FeedColors.track,
                  valueColor: AlwaysStoppedAnimation(FeedColors.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recite, share and like, bottom center. Plain outline icons with no
/// background ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â they read as actions floating over the verse, not as UI
/// chrome.
class _VerseActions extends StatelessWidget {
  const _VerseActions({
    required this.liked,
    required this.recitation,
    required this.onShare,
    required this.onToggleLike,
    required this.onTogglePlayback,
  });

  final bool liked;
  final RecitationState recitation;
  final VoidCallback onShare;
  final VoidCallback onToggleLike;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PlayButton(state: recitation, onTap: onTogglePlayback),
        const SizedBox(width: 32),
        _CircleButton(icon: Icons.ios_share, onTap: onShare),
        const SizedBox(width: 32),
        _LikeButton(liked: liked, onTap: onToggleLike),
      ],
    );
  }
}

/// Play / pause for the current ayah, with a spinner while the mp3 buffers.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.state, required this.onTap});

  final RecitationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        // Taps during buffering would queue a second play on the same ayah.
        onTap: state == RecitationState.loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: state == RecitationState.loading
              ? Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(FeedColors.ink),
                    ),
                  ),
                )
              : Icon(
                  state == RecitationState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 30,
                  color: FeedColors.ink,
                ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
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
          height: 52,
          width: 52,
          child: Icon(icon, size: 28, color: FeedColors.ink),
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.liked, required this.onTap});

  final bool liked;
  final VoidCallback onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 52,
          width: 52,
          child: AnimatedScale(
            scale: widget.liked ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Icon(
              widget.liked ? Icons.favorite : Icons.favorite_border,
              size: 28,
              color: widget.liked ? FeedColors.liked : FeedColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
