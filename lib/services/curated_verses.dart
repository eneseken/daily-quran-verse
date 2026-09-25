import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/quran_verse.dart';

/// A hand-picked list of well-known, widely quoted ayahs — short and
/// self-contained enough to read well on their own outside the full
/// chapter context (unlike, say, an inheritance-law verse deep in Surah
/// An-Nisa). Used to pick the home screen widget's daily verse instead of
/// a plain index into the whole 6,236-ayah Quran.
///
/// Stores only (surah, ayah) references, not verse text — the actual
/// Arabic/translations always come from [QuranService]'s Supabase-backed
/// list, so there's exactly one source of truth for verse content and this
/// stays in sync with whatever language the user has picked automatically.
class CuratedVerses {
  CuratedVerses._();

  static const _assetPath = 'assets/curated_verses.json';

  static List<(int surah, int ayah)>? _references;

  static Future<List<(int surah, int ayah)>> _loadReferences() async {
    final cached = _references;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List;
    final refs = decoded
        .map((e) => e as Map<String, dynamic>)
        .map((e) => (e['surah'] as int, e['ayah'] as int))
        .toList();

    _references = refs;
    return refs;
  }

  /// Resolves the curated list against the full verse set already loaded
  /// by QuranService, dropping any reference that doesn't match (a typo'd
  /// surah/ayah pair, or a translation gap) rather than crashing on it.
  /// Falls back to [allVerses] itself if every reference somehow fails to
  /// resolve, so the widget never ends up with nothing to show.
  static Future<List<QuranVerse>> resolve(List<QuranVerse> allVerses) async {
    final refs = await _loadReferences();
    final bySurahAyah = {
      for (final v in allVerses) (v.surahNumber, v.ayahNumber): v,
    };

    final resolved = refs
        .map((ref) => bySurahAyah[ref])
        .whereType<QuranVerse>()
        .toList();

    return resolved.isEmpty ? allVerses : resolved;
  }
}
