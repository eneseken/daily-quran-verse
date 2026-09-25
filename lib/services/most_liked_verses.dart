import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/quran_verse.dart';

/// "12.4K", "84K", "382" — the same shorthand people expect from any
/// like/follower counter. Shared so [LikedVerse] and [LikedSurah] can never
/// drift into formatting the same number two different ways.
String _formatLikes(int likes) {
  if (likes >= 1000000) {
    return '${(likes / 1000000).toStringAsFixed(likes % 1000000 == 0 ? 0 : 1)}M';
  }
  if (likes >= 1000) {
    return '${(likes / 1000).toStringAsFixed(likes % 1000 == 0 ? 0 : 1)}K';
  }
  return '$likes';
}

/// A verse paired with the like count curated for it — the count is a
/// fixed editorial number (not a live tally), used purely to give the
/// "Most Liked" feed the same social-proof feel a "12.4K likes" badge
/// gives elsewhere.
class LikedVerse {
  const LikedVerse({required this.verse, required this.likes});

  final QuranVerse verse;
  final int likes;

  String get likesLabel => _formatLikes(likes);
}


/// A curated, pre-ranked list of ~1,000 (surah, ayah, likes) references —
/// the "Most Liked" alternative to the normal sequential feed.
///
/// Stores only references and a like count, never verse text: the actual
/// Arabic/translations always come from [QuranService]'s Supabase-backed
/// list, so this automatically renders in whatever language the user has
/// picked, with no per-language copy of this file to keep in sync.
class MostLikedVerses {
  MostLikedVerses._();

  static const _assetPath = 'assets/most_liked_verses.json';

  static List<(int surah, int ayah, int likes)>? _entries;

  static Future<List<(int surah, int ayah, int likes)>> _loadEntries() async {
    final cached = _entries;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List;
    final entries = decoded
        .map((e) => e as Map<String, dynamic>)
        .map(
          (e) =>
              (e['surah'] as int, e['ayah'] as int, e['likes'] as int),
        )
        .toList();

    _entries = entries;
    return entries;
  }

  /// Resolves the curated list against the full verse set already loaded by
  /// QuranService, dropping any reference that doesn't match, and keeping
  /// the list's own descending-likes order (the JSON is pre-sorted, so no
  /// re-sort is needed here — resolving never reorders it).
  static Future<List<LikedVerse>> resolve(List<QuranVerse> allVerses) async {
    final entries = await _loadEntries();
    final bySurahAyah = {
      for (final v in allVerses) (v.surahNumber, v.ayahNumber): v,
    };

    final resolved = <LikedVerse>[];
    for (final (surah, ayah, likes) in entries) {
      final verse = bySurahAyah[(surah, ayah)];
      if (verse != null) resolved.add(LikedVerse(verse: verse, likes: likes));
    }
    return resolved;
  }

}
