import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quran_verse.dart';
import '../services/quran_service.dart';
import '../services/recitation_service.dart';
import '../widgets/breathing_loader.dart';
import 'home/feed_theme.dart';
import 'home/settings_sheet.dart';
import 'home/verse_card.dart';

/// The main feed: one ayah per screen, scroll down for the next — an endless
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
        text: '${verse.textFor(_language)}\n\n'
            '${verse.arabicText}\n\n'
            '— ${verse.reference}',
      ),
    );
  }

  Future<void> _openSettings() async {
    await SettingsSheet.show(
      context,
      currentLanguage: _language,
      onLanguageChanged: (code) {
        setState(() => _language = code);
        QuranService.instance.setPreferredLanguage(code);
      },
    );
  }

  /// Swiping to another verse always resets playback — the new verse never
  /// starts reciting on its own.
  void _onPageChanged(int page) {
    _recitation.stop();
    setState(() => _page = page);
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
    final verses = _verses;

    if (_loading) {
      return const Scaffold(
        backgroundColor: FeedColors.bg,
        body: _CenteredSpinner(),
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
      body: VerseFeedShell(
        verse: current,
        ayahCountInSurah:
            QuranService.instance.ayahCountForSurah(current.surahNumber),
        liked: _liked.contains(current.id),
        recitation:
            isCurrentAudio ? _recitation.state : RecitationState.idle,
        onToggleLike: () => _toggleLike(current),
        onShare: () => _share(current),
        onOpenSettings: _openSettings,
        onTogglePlayback: () => _togglePlayback(current),
        // Only this pages — the chrome above and below it stays fixed.
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
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BreathingLoader(glow: FeedColors.gold),
    );
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
              style: FeedText.label(color: FeedColors.inkSoft).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry', style: FeedText.label(color: FeedColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}
