import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quran_verse.dart';
import '../models/surah.dart';

/// Maps the device locale onto one of the languages the Quran text is
/// actually translated into, so a fresh sign-up starts in a sensible
/// language before the user ever opens settings.
String detectDeviceLanguageCode() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return quranAssetLanguages.contains(code) ? code : 'en';
}

/// Language codes `assets/quran.json` actually carries a translation for.
/// Arabic is in there too, as the ayah text itself rather than a
/// translation entry — see [QuranVerse.textFor].
const quranAssetLanguages = {'en', 'tr', 'de', 'fr', 'es', 'ur', 'id', 'ar'};

/// Loads the Quran from the bundled asset once and keeps it in memory.
///
/// The text ships with the app rather than coming from Supabase: it never
/// changes, so a network round trip on every cold start only bought a
/// slower launch and a feed that broke offline. Supabase still backs the
/// things that are actually per-user — likes and the language preference.
class QuranService {
  QuranService._();

  static final instance = QuranService._();

  static const _assetPath = 'assets/quran.json';

  SupabaseClient get _client => Supabase.instance.client;

  List<Surah>? _surahs;
  List<QuranVerse>? _verses;
  Set<int>? _likedVerseIds;

  /// Every surah in order, each holding its own ayahs — what the feed pages
  /// through.
  Future<List<Surah>> loadSurahs() async {
    final cached = _surahs;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List;
    final surahs = decoded
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();

    _surahs = surahs;
    _verses = [for (final surah in surahs) ...surah.verses];
    return surahs;
  }

  /// Every ayah in the Quran, flattened out of [loadSurahs] — for the
  /// curated lists, which address ayahs individually.
  Future<List<QuranVerse>> loadAll() async {
    await loadSurahs();
    return _verses!;
  }

  int ayahCountForSurah(int surahNumber) {
    final surahs = _surahs;
    if (surahs == null) return 1;
    // Surahs are numbered 1..114 and stored in that order, so the number
    // indexes straight into the list.
    if (surahNumber < 1 || surahNumber > surahs.length) return 1;
    return surahs[surahNumber - 1].ayahCount;
  }

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
    if (id == null) return detectDeviceLanguageCode();
    final row = await _client
        .from('profiles')
        .select('preferred_language')
        .eq('id', id)
        .maybeSingle();
    return (row?['preferred_language'] as String?) ?? detectDeviceLanguageCode();
  }

  Future<void> setPreferredLanguage(String languageCode) async {
    final id = _userId;
    if (id == null) return;
    await _client
        .from('profiles')
        .upsert({'id': id, 'preferred_language': languageCode});
  }

  /// Clears the per-user cache — called on sign-out so the next sign-in
  /// starts fresh rather than showing a stale user's likes. The Quran text
  /// itself is the same for everyone, so it stays loaded.
  void reset() {
    _likedVerseIds = null;
  }
}
