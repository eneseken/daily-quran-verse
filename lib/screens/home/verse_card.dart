import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/feed_background.dart';
import '../../models/quran_verse.dart';
import '../../models/surah.dart';
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
    this.surah,
    this.profilePhotoPath,
    this.onOpenGift,
    this.mostLikedMode = false,
    this.onToggleMostLiked,
    this.likesLabel,
  });

  final QuranVerse verse;

  /// The surah [verse] belongs to, named above the feed and held there
  /// while the reader swipes through that surah's ayahs — so the chapter
  /// stays on screen instead of scrolling away with the text.
  final Surah? surah;

  final int ayahCountInSurah;
  final bool liked;
  final RecitationState recitation;
  final Widget feed;
  final VoidCallback onToggleLike;
  final VoidCallback onShare;
  final VoidCallback onOpenSettings;
  final VoidCallback onTogglePlayback;
  final String? profilePhotoPath;
  final VoidCallback? onOpenGift;

  /// Whether the feed is currently pulling from the curated Most Liked
  /// ranking instead of the normal sequential-through-the-Quran feed.
  final bool mostLikedMode;
  final VoidCallback? onToggleMostLiked;

  /// The curated like count for the verse on screen, shown only in Most
  /// Liked mode — null in the normal feed, which has no such number.
  final String? likesLabel;

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
                      _ProfileFab(
                        onTap: onOpenSettings,
                        photoPath: profilePhotoPath,
                      ),
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
                if (surah != null) SurahTitleBar(surah: surah!),
                Expanded(child: feed),
                if (onToggleMostLiked != null) ...[
                  _MostLikedToggle(
                    active: mostLikedMode,
                    onTap: onToggleMostLiked!,
                  ),
                  const SizedBox(height: 14),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _VerseActions(
                    liked: liked,
                    recitation: recitation,
                    onShare: onShare,
                    onToggleLike: onToggleLike,
                    onTogglePlayback: onTogglePlayback,
                    likesLabel: likesLabel,
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
  const _ProfileFab({required this.onTap, this.photoPath});

  final VoidCallback onTap;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFF007A3D),
              Color(0xFF007A3D),
              Color(0xFFCE1126),
              Color(0xFFCE1126),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.22, 0.25, 0.47, 0.50, 0.72, 0.75, 0.97, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: FeedColors.gold,
            shape: const CircleBorder(),
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                height: 44,
                width: 44,
                child: ClipOval(
                  child: photoPath == null
                      ? Icon(Icons.person, size: 28, color: FeedColors.bg)
                      : Image.file(
                          File(photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 28,
                            color: FeedColors.bg,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One page of the feed: a single ayah, sized to fill the screen on its
/// own. Swiping moves to the next ayah, and past a surah's last ayah
/// straight into the next surah's first — the feed is one flat run through
/// the whole Quran, with [SurahTitleBar] above it naming whichever surah
/// the current ayah belongs to.
class AyahPage extends StatelessWidget {
  const AyahPage({
    super.key,
    required this.verse,
    required this.languageCode,
    this.showArabic = true,
  });

  final QuranVerse verse;
  final String languageCode;
  final bool showArabic;

  /// Sizes for a short ayah, scaled down from here as the text grows.
  /// Public so tests can assert against the actual values used.
  static const arabicSize = 29.0;
  static const translationSize = 24.0;
  static const numberSize = 13.0;
  static const _arabicGap = 26.0;
  static const _numberGap = 16.0;

  /// The Arabic is set narrower than the translation, as in the design.
  static const _arabicWidthFactor = 0.85;

  /// Past this the ayah stops being comfortably readable, so the longest
  /// ones settle here rather than shrinking into illegibility.
  static const minScale = 0.34;

  /// With Arabic chosen as the reading language the translation *is* the
  /// Arabic, so rendering the Arabic block too would print it twice.
  bool get _showArabicBlock => showArabic && languageCode != 'ar';

  bool get _isRtl => languageCode == 'ar' || languageCode == 'ur';

  TextStyle _translationStyle(double scale) => languageCode == 'ar'
      ? FeedText.arabic(size: arabicSize * scale)
      : FeedText.quote(size: translationSize * scale);

  double _heightAt(
    double scale,
    double maxWidth,
    String translation,
    TextScaler scaler,
  ) {
    final arabicBlock = _showArabicBlock
        ? _measureText(
              verse.arabicText,
              FeedText.arabic(size: arabicSize * scale),
              maxWidth * _arabicWidthFactor,
              scaler,
              TextDirection.rtl,
            ) +
            _arabicGap * scale
        : 0.0;
    return arabicBlock +
        _measureText(
          translation,
          _translationStyle(scale),
          maxWidth,
          scaler,
          _isRtl ? TextDirection.rtl : TextDirection.ltr,
        ) +
        _numberGap * scale +
        _measureText(
          '${verse.ayahNumber}',
          FeedText.reference(size: numberSize * scale),
          maxWidth,
          scaler,
          TextDirection.ltr,
        );
  }

  /// The scale to render at, and whether it still overflows the page even
  /// at the readability floor — 2:282 on a small phone can, and that one
  /// rare case falls back to letting the page scroll rather than clipping.
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

    // Ten halvings land within ~0.05% of the true crossover — far finer
    // than a reader could notice, and cheap enough to redo on every layout.
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
            final pageHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (media.size.height - media.padding.vertical - 260)
                    .clamp(280.0, double.infinity);
            final pageWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : (media.size.width - 44).clamp(240.0, double.infinity);
            final availableHeight =
                (pageHeight - 24).clamp(200.0, double.infinity);
            final (scale, overflows) = _fitScale(
              availableHeight: availableHeight,
              maxWidth: pageWidth,
              translation: translation,
              scaler: scaler,
            );

            final column = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showArabicBlock) ...[
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
                  textDirection:
                      _isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: _translationStyle(scale),
                ),
                SizedBox(height: _numberGap * scale),
                Text(
                  '${verse.ayahNumber}',
                  textAlign: TextAlign.center,
                  style: FeedText.reference(size: numberSize * scale),
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

/// The surah's identity, pinned above the paging ayahs: Arabic name, then
/// number, meaning and where it was revealed. Stays put as the reader
/// swipes through that surah's ayahs, and changes only when they cross into
/// the next surah.
class SurahTitleBar extends StatelessWidget {
  const SurahTitleBar({super.key, required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    // Generous room above so the title sits clear of the position chip
    // rather than crowding it, and a smaller gap below since the ayah is
    // centred in its own space anyway.
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
      child: Column(
        children: [
          Text(
            surah.nameArabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            // Smaller than the ayah's own Arabic: this names the chapter,
            // it shouldn't compete with the verse for attention. The
            // display line height is for running verse text — a one-line
            // title just gets padded by it, so tighten it here.
            style: FeedText.arabic(size: 20).copyWith(height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.number}. ${surah.nameTranslation} '
            '\u00b7 ${surah.revelationType} \u00b7 ${surah.ayahCount}',
            textAlign: TextAlign.center,
            style: FeedText.label(color: FeedColors.inkSoft)
                .copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Lays out [text] to find how tall it renders at [style] — shared by the
/// fit-scaling in [AyahPage] and [VersePage].
double _measureText(
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
    this.likesLabel,
  });

  final bool liked;
  final RecitationState recitation;
  final VoidCallback onShare;
  final VoidCallback onToggleLike;
  final VoidCallback onTogglePlayback;

  /// The curated like count under the heart icon, shown only in Most Liked
  /// mode.
  final String? likesLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlayButton(state: recitation, onTap: onTogglePlayback),
        const SizedBox(width: 32),
        _CircleButton(icon: Icons.ios_share, onTap: onShare),
        const SizedBox(width: 32),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LikeButton(liked: liked, onTap: onToggleLike),
            // Reserves the same height whether or not a label is showing,
            // so the heart icon itself never shifts up/down when this row's
            // taller neighbor (this same column) forces the row to grow.
            SizedBox(
              height: 16,
              child: likesLabel == null
                  ? null
                  : Center(
                      child: Text(
                        likesLabel!,
                        style: FeedText.label(
                          color: FeedColors.inkSoft,
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small pill above the action row that switches the feed between its
/// normal sequential-through-the-Quran order and the curated Most Liked
/// ranking.
class _MostLikedToggle extends StatelessWidget {
  const _MostLikedToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? FeedColors.gold
                : FeedColors.chip.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? Colors.transparent : FeedColors.chipBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.local_fire_department : Icons.trending_up,
                size: 16,
                color: active ? FeedColors.bg : FeedColors.ink,
              ),
              const SizedBox(width: 6),
              Text(
                'Most Liked',
                style: FeedText.label(
                  color: active ? FeedColors.bg : FeedColors.ink,
                ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              _MiniSwitch(active: active),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small on/off pill mirroring the toggle's own state, sized to sit
/// inline in a 13px-text row rather than the much larger stock [Switch].
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 18,
      width: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active
            ? FeedColors.bg.withValues(alpha: 0.35)
            : FeedColors.ink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(9),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? FeedColors.bg : FeedColors.ink,
          ),
        ),
      ),
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
