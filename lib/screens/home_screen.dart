import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../models/quran_verse.dart';
import '../services/quran_service.dart';
import '../services/recitation_service.dart';
import '../widgets/breathing_loader.dart';
import 'home/feed_theme.dart';
import 'home/verse_card.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';

/// The main feed: one ayah per screen, scroll down for the next ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â an endless
/// vertical reel through the whole Quran, starting at a random verse each
/// time the app opens.
///
/// Only the verse itself pages; the top indicator and the action row are
/// fixed chrome that stays put while the middle scrolls.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PageController();
  final _recitation = RecitationService();

  List<QuranVerse>? _verses;
  Set<int> _liked = {};
  String _language = 'en';
  int _startOffset = 0;
  int _page = 0;
  bool _loading = true;
  bool _showSwipeHint = true;
  String? _error;
  StreamSubscription<RecitationState>? _recitationSub;

  @override
  void initState() {
    super.initState();
    _recitationSub = _recitation.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _recitationSub?.cancel();
    _recitation.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        QuranService.instance.loadAll(),
        QuranService.instance.loadLikedVerseIds(),
        QuranService.instance.loadPreferredLanguage(),
      ]);
      if (!mounted) return;
      final verses = results[0] as List<QuranVerse>;
      setState(() {
        _verses = verses;
        _liked = results[1] as Set<int>;
        _language = results[2] as String;
        _startOffset = Random().nextInt(verses.length);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Couldn't load verses. Check your connection and try again.";
      });
    }
  }

  /// Maps a (possibly negative, unbounded) page index onto the verse list,
  /// wrapping around so the feed never runs out in either direction.
  QuranVerse _verseForPage(int page, List<QuranVerse> verses) {
    final n = verses.length;
    final index = ((_startOffset + page) % n + n) % n;
    return verses[index];
  }

  Future<void> _toggleLike(QuranVerse verse) async {
    final liked = _liked.contains(verse.id);
    setState(() {
      if (liked) {
        _liked.remove(verse.id);
      } else {
        _liked.add(verse.id);
      }
    });
    await QuranService.instance.setLiked(verse, !liked);
  }

  void _share(QuranVerse verse) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '${verse.textFor(_language)}\n\n'
            '${verse.arabicText}\n\n'
            '\u2014 ${verse.reference}',
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  /// Swiping to another verse always resets playback ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â the new verse never
  /// starts reciting on its own.
  void _onPageChanged(int page) {
    _recitation.stop();
    setState(() {
      _page = page;
      _showSwipeHint = false;
    });
  }

  Future<void> _togglePlayback(QuranVerse verse) async {
    if (_recitation.activeOwner == verse.id) {
      if (_recitation.state == RecitationState.playing) {
        await _recitation.pause();
      } else {
        await _recitation.resume();
      }
      return;
    }
    await _recitation.play(
      owner: verse.id,
      ayahNumbers: [verse.globalAyahNumber],
    );
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.watch(context);
    final verses = _verses;

    if (_loading) {
      return Scaffold(
        backgroundColor: FeedColors.bg,
        body: const _CenteredSpinner(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: FeedColors.bg,
        body: _ErrorState(
          message: _error!,
          onRetry: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }

    final current = _verseForPage(_page, verses!);
    final isCurrentAudio = _recitation.activeOwner == current.id;

    return Scaffold(
      backgroundColor: FeedColors.bg,
      body: Stack(
        children: [
          VerseFeedShell(
            verse: current,
            ayahCountInSurah: QuranService.instance.ayahCountForSurah(
              current.surahNumber,
            ),
            liked: _liked.contains(current.id),
            recitation: isCurrentAudio
                ? _recitation.state
                : RecitationState.idle,
            onToggleLike: () => _toggleLike(current),
            onShare: () => _share(current),
            onOpenSettings: _openProfile,
            onOpenGift: _openPaywall,
            onTogglePlayback: () => _togglePlayback(current),
            // Only this pages ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â the chrome above and below it stays fixed.
            feed: PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, page) => VersePage(
                key: ValueKey(page),
                verse: _verseForPage(page, verses),
                languageCode: _language,
              ),
            ),
          ),
          if (_showSwipeHint) const _SwipeHint(),
        ],
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return Center(child: BreathingLoader(glow: FeedColors.gold));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: FeedText.label(
                color: FeedColors.inkSoft,
              ).copyWith(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: FeedText.label(color: FeedColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: const Offset(0, -0.12),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 116,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_up, size: 38, color: FeedColors.ink),
              const SizedBox(height: 2),
              Text(
                'Swipe up for next',
                style: FeedText.label(
                  color: FeedColors.ink,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
