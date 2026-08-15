import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final progress = verse.ayahNumber / ayahCountInSurah;

    return Container(
      color: FeedColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  // Balances the settings button on the right so the
                  // indicator below reads as truly centered.
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: _TopIndicator(
                        label: '${verse.ayahNumber}/$ayahCountInSurah',
                        progress: progress,
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.person_outline,
                    onTap: onOpenSettings,
                  ),
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
      ),
    );
  }
}

/// One page of the feed — just the verse itself, since the surrounding
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
  });

  final QuranVerse verse;
  final String languageCode;

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
  static const minScale = 0.45;

  double _heightAt(
    double scale,
    double maxWidth,
    String translation,
    TextScaler scaler,
  ) {
    return _measure(
          verse.arabicText,
          FeedText.arabic(size: arabicSize * scale),
          maxWidth * _arabicWidthFactor,
          scaler,
          TextDirection.rtl,
        ) +
        _arabicGap * scale +
        _measure(
          translation,
          FeedText.quote(size: quoteSize * scale),
          maxWidth,
          scaler,
          TextDirection.ltr,
        ) +
        _referenceGap * scale +
        _measure(
          '— ${verse.reference}',
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
  /// nothing — but 2:282 (the longest ayah in the Quran) on the smallest
  /// supported phones can still be taller than one page even at that floor.
  /// [overflows] tells the caller to fall back to letting the page scroll
  /// for that one rare combination, rather than clipping or violating the
  /// floor.
  (double scale, bool overflows) _fitScale(
    BoxConstraints constraints,
    String translation,
    TextScaler scaler,
  ) {
    if (!constraints.hasBoundedHeight || constraints.maxWidth <= 0) {
      return (1, false);
    }

    final available = constraints.maxHeight;
    if (_heightAt(1, constraints.maxWidth, translation, scaler) <= available) {
      return (1, false);
    }

    // Ten halvings land within ~0.05% of the true crossover — far finer than
    // a reader could notice, and cheap enough to redo on every layout.
    var fits = minScale;
    var tooBig = 1.0;
    for (var i = 0; i < 10; i++) {
      final mid = (fits + tooBig) / 2;
      if (_heightAt(mid, constraints.maxWidth, translation, scaler) <=
          available) {
        fits = mid;
      } else {
        tooBig = mid;
      }
    }

    final floorFits =
        _heightAt(minScale, constraints.maxWidth, translation, scaler) <=
            available;
    return (fits, !floorFits);
  }

  @override
  Widget build(BuildContext context) {
    final translation = verse.textFor(languageCode);
    final scaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final (scale, overflows) =
              _fitScale(constraints, translation, scaler);

          final column = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                translation,
                textAlign: TextAlign.center,
                style: FeedText.quote(size: quoteSize * scale),
              ),
              SizedBox(height: _referenceGap * scale),
              Text(
                '— ${verse.reference}',
                textAlign: TextAlign.center,
                style: FeedText.reference(size: referenceSize * scale),
              ),
            ],
          );

          if (!overflows) return Center(child: column);

          // Escape valve for that one pathological case: scrolling inside a
          // vertical PageView page is otherwise avoided (drag would be
          // ambiguous between paging and scrolling), but a few extra pixels
          // of scroll on the single longest ayah beats clipped text.
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: column),
            ),
          );
        },
      ),
    );
  }
}

/// Small, low-contrast "♡ 1/5 ───" readout centered above the verse — never
/// competes with the Arabic and translation for attention.
class _TopIndicator extends StatelessWidget {
  const _TopIndicator({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_border, size: 13, color: FeedColors.inkFaint),
        const SizedBox(width: 7),
        Text(label, style: FeedText.label(color: FeedColors.inkSoft)),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 26,
            height: 3,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(FeedColors.inkFaint),
            ),
          ),
        ),
      ],
    );
  }
}

/// Recite, share and like, bottom center. Plain outline icons with no
/// background — they read as actions floating over the verse, not as UI
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
        const SizedBox(width: 26),
        _CircleButton(icon: Icons.ios_share, onTap: onShare),
        const SizedBox(width: 26),
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
          height: 40,
          width: 40,
          child: state == RecitationState.loading
              ? const Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(FeedColors.ink),
                    ),
                  ),
                )
              : Icon(
                  state == RecitationState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 22,
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
          height: 40,
          width: 40,
          child: Icon(icon, size: 20, color: FeedColors.ink),
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
          height: 40,
          width: 40,
          child: AnimatedScale(
            scale: widget.liked ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Icon(
              widget.liked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: widget.liked ? FeedColors.liked : FeedColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
