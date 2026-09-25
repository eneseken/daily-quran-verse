import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/arabic_visibility.dart';
import '../core/feed_background.dart';
import '../core/quran_language.dart';
import '../core/theme.dart';
import '../models/quran_verse.dart';
import '../models/surah.dart';
import '../services/daily_verse_widget_service.dart';
import '../services/most_liked_verses.dart';
import '../services/profile_photo_service.dart';
import '../services/quran_service.dart';
import '../services/recitation_service.dart';
import '../services/streak_service.dart';
import '../services/subscription_service.dart';
import '../widgets/breathing_loader.dart';
import 'home/feed_theme.dart';
import 'home/verse_card.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';

/// The main feed: one ayah per screen, swipe up for the next. The run is
/// flat — swiping past a surah's last ayah lands on the next surah's
/// first — while the surah's name stays pinned above the text, so a verse
/// is always read knowing which chapter it belongs to without that chapter
/// scrolling away with it.
///
/// The feed starts at a random surah's opening ayah each time the app
/// opens. Only the ayah pages; the surah title, the position indicator and
/// the action row are fixed chrome.
///
/// Most Liked mode swaps the flat run for the curated ranking — the ayahs
/// people liked most, highest first — paging the same way.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PageController();
  final _recitation = RecitationService();

  List<Surah>? _surahs;
  List<QuranVerse>? _verses;
  List<LikedVerse> _mostLiked = [];
  Set<int> _liked = {};
  String _language = 'en';
  int _startOffset = 0;
  int _page = 0;
  bool _loading = true;
  bool _showSwipeHint = true;
  bool _mostLikedMode = false;
  String? _error;
  StreamSubscription<RecitationState>? _recitationSub;

  @override
  void initState() {
    super.initState();
    _recitationSub = _recitation.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    // The Customize screen's background photo (and the ink colors that
    // follow it) live outside this widget's state, so rebuild here when it
    // changes rather than only picking up the new value next time this
    // screen happens to rebuild for some other reason.
    FeedBackgroundController.instance.addListener(_onBackgroundChanged);
    // Same story for the translation language, changed from the profile
    // screen's Language row.
    QuranLanguageController.instance.addListener(_onLanguageChanged);
    // And for the Arabic show/hide toggle, changed from the same screen.
    ArabicVisibilityController.instance.addListener(_onLanguageChanged);
    ProfilePhotoService.instance.addListener(_onProfilePhotoChanged);
    _load();
    // Fire-and-forget: opening the feed is what counts as "read today" for
    // the streak, and a slow network shouldn't hold up anything on screen.
    unawaited(StreakService.instance.logTodayIfNeeded());
  }

  void _onBackgroundChanged() {
    if (mounted) setState(() {});
    // Mirror the new Customize wallpaper (and its text-color choice) onto
    // the home screen widget. Fire-and-forget for the same reason as the
    // language sync below.
    unawaited(DailyVerseWidgetService.updateForToday(_language));
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() => _language = QuranLanguageController.instance.code);
    }
    // Re-render the home screen widget in the newly chosen language.
    // Fire-and-forget: Android-only and a widget refresh is never worth
    // blocking the feed UI on.
    unawaited(DailyVerseWidgetService.updateForToday(_language));
  }

  void _onProfilePhotoChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _recitationSub?.cancel();
    _recitation.dispose();
    FeedBackgroundController.instance.removeListener(_onBackgroundChanged);
    QuranLanguageController.instance.removeListener(_onLanguageChanged);
    ArabicVisibilityController.instance.removeListener(_onLanguageChanged);
    ProfilePhotoService.instance.removeListener(_onProfilePhotoChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        QuranService.instance.loadSurahs(),
        QuranService.instance.loadLikedVerseIds(),
        QuranLanguageController.instance.restore(),
        ArabicVisibilityController.instance.restore(),
      ]);
      if (!mounted) return;
      final surahs = results[0] as List<Surah>;
      final verses = await QuranService.instance.loadAll();
      final mostLiked = await MostLikedVerses.resolve(verses);
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _verses = verses;
        _mostLiked = mostLiked;
        _liked = results[1] as Set<int>;
        _language = QuranLanguageController.instance.code;
        // Start on some surah's opening ayah rather than mid-chapter, so
        // the first thing on screen reads as a beginning.
        _startOffset = surahs[Random().nextInt(surahs.length)]
            .verses
            .first
            .globalAyahNumber -
            1;
        _loading = false;
      });
      // Keep the home screen widget in sync with today's verse in the
      // user's current language every time the feed loads.
      unawaited(DailyVerseWidgetService.updateForToday(_language));
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

  /// Same wrap-around indexing into the pre-ranked Most Liked list — always
  /// starting from its top, unlike the normal feed's random offset, since
  /// the ranking itself is the point of this mode.
  LikedVerse _likedEntryForPage(int page) {
    final n = _mostLiked.length;
    final index = (page % n + n) % n;
    return _mostLiked[index];
  }

  bool get _isMostLikedMode => _mostLikedMode && _mostLiked.isNotEmpty;

  QuranVerse _pageVerse(int page) => _isMostLikedMode
      ? _likedEntryForPage(page).verse
      : _verseForPage(page, _verses!);

  /// The surah a given ayah belongs to. Surahs are numbered 1..114 and held
  /// in that order, so the number indexes straight into the list.
  Surah _surahOf(QuranVerse verse) => _surahs![verse.surahNumber - 1];

  void _toggleMostLikedMode() {
    HapticFeedback.selectionClick();
    _recitation.stop();
    setState(() {
      _mostLikedMode = !_mostLikedMode;
      _page = 0;
      _showSwipeHint = true;
    });
    _controller.jumpToPage(0);
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
            '— ${verse.reference}',
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

  /// Swiping to another ayah always resets playback — the new ayah never
  /// starts reciting on its own.
  void _onPageChanged(int page) {
    _recitation.stop();
    setState(() {
      _page = page;
      _showSwipeHint = false;
    });
  }

  Future<void> _togglePlayback(QuranVerse verse) async {
    if (!SubscriptionService.instance.isPremium) {
      await _openPaywall();
      return;
    }

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
    if (_error != null || verses == null) {
      return Scaffold(
        backgroundColor: FeedColors.bg,
        body: _ErrorState(
          message: _error ?? 'Something went wrong.',
          onRetry: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _load();
          },
        ),
      );
    }

    final mostLikedMode = _isMostLikedMode;
    final current = _pageVerse(_page);
    final currentSurah = _surahOf(current);
    final isCurrentAudio = _recitation.activeOwner == current.id;

    return Scaffold(
      backgroundColor: FeedColors.bg,
      body: Stack(
        children: [
          VerseFeedShell(
            verse: current,
            surah: currentSurah,
            ayahCountInSurah: currentSurah.ayahCount,
            liked: _liked.contains(current.id),
            recitation: isCurrentAudio
                ? _recitation.state
                : RecitationState.idle,
            onToggleLike: () => _toggleLike(current),
            onShare: () => _share(current),
            onOpenSettings: _openProfile,
            profilePhotoPath: ProfilePhotoService.instance.path,
            onOpenGift: _openPaywall,
            onTogglePlayback: () => _togglePlayback(current),
            mostLikedMode: mostLikedMode,
            onToggleMostLiked: _toggleMostLikedMode,
            likesLabel:
                mostLikedMode ? _likedEntryForPage(_page).likesLabel : null,
            // Only this pages — the chrome above and below it stays fixed.
            feed: PageView.builder(
              key: ValueKey(mostLikedMode),
              controller: _controller,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, page) => AyahPage(
                key: ValueKey(page),
                verse: _pageVerse(page),
                languageCode: _language,
                showArabic: ArabicVisibilityController.instance.showArabic,
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
