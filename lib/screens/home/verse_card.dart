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
class VersePage extends StatelessWidget {
  const VersePage({
    super.key,
    required this.verse,
    required this.languageCode,
  });

  final QuranVerse verse;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FractionallySizedBox(
                widthFactor: 0.85,
                child: Text(
                  verse.arabicText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: FeedText.arabic(),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                verse.textFor(languageCode),
                textAlign: TextAlign.center,
                style: FeedText.quote(),
              ),
              const SizedBox(height: 18),
              Text(
                '— ${verse.reference}',
                textAlign: TextAlign.center,
                style: FeedText.reference(),
              ),
            ],
          ),
        ),
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
