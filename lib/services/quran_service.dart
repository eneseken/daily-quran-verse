import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quran_verse.dart';

/// Maps the device locale onto one of the languages the Quran text is
/// actually translated into, so a fresh sign-up starts in a sensible
/// language before the user ever opens settings.
String detectDeviceLanguageCode() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return code == 'tr' ? 'tr' : 'en';
}

/// Loads the whole Quran once and keeps it in memory — 6,236 short rows is a
/// small enough payload that this is simpler and snappier than paging, and it
/// lets the feed and language switch work without another round trip.
class QuranService {
  QuranService._();

  static final instance = QuranService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<QuranVerse>? _verses;
  Map<int, int> _ayahCountBySurah = {};
  Set<int>? _likedVerseIds;

  Future<List<QuranVerse>> loadAll() async {
    final cached = _verses;
    if (cached != null) return cached;

    final rows = await _client
        .from('quran_verses')
        .select()
        .order('global_ayah_number');

    final verses = (rows as List)
        .map((row) => QuranVerse.fromRow(row as Map<String, dynamic>))
        .toList();

    final counts = <int, int>{};
    for (final v in verses) {
      counts[v.surahNumber] = (counts[v.surahNumber] ?? 0) + 1;
    }

    _verses = verses;
    _ayahCountBySurah = counts;
    return verses;
  }

  int ayahCountForSurah(int surahNumber) => _ayahCountBySurah[surahNumber] ?? 1;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Set<int>> loadLikedVerseIds() async {
    final cached = _likedVerseIds;
    if (cached != null) return cached;

    final id = _userId;
    if (id == null) return {};

    final rows =
        await _client.from('verse_likes').select('verse_id').eq('user_id', id);
    final ids = (rows as List).map((r) => r['verse_id'] as int).toSet();
    _likedVerseIds = ids;
    return ids;
  }

  Future<void> setLiked(QuranVerse verse, bool liked) async {
    final id = _userId;
    if (id == null) return;

    _likedVerseIds ??= {};
    if (liked) {
      _likedVerseIds!.add(verse.id);
      await _client.from('verse_likes').upsert({
        'user_id': id,
        'verse_id': verse.id,
      });
    } else {
      _likedVerseIds!.remove(verse.id);
      await _client
          .from('verse_likes')
          .delete()
          .eq('user_id', id)
          .eq('verse_id', verse.id);
    }
  }

  Future<String> loadPreferredLanguage() async {
    final id = _userId;
    if (id == null) return 'en';
    final row = await _client
        .from('profiles')
        .select('preferred_language')
        .eq('id', id)
        .maybeSingle();
    return (row?['preferred_language'] as String?) ?? 'en';
  }

  Future<void> setPreferredLanguage(String languageCode) async {
    final id = _userId;
    if (id == null) return;
    await _client
        .from('profiles')
        .upsert({'id': id, 'preferred_language': languageCode});
  }

  /// Clears the in-memory cache — called on sign-out so the next sign-in
  /// starts fresh rather than showing a stale user's likes.
  void reset() {
    _verses = null;
    _ayahCountBySurah = {};
    _likedVerseIds = null;
  }
}
