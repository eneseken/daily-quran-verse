import 'quran_verse.dart';

/// One surah with every ayah it contains, in ayah order — the unit the feed
/// pages through, so a verse is always read inside the chapter it belongs
/// to rather than pulled out on its own.
class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameTranslation,
    required this.revelationType,
    required this.verses,
  });

  /// Parses one entry of `assets/quran.json`. The ayah keys are terse
  /// (`n`, `g`, `ar`, `t`) because they repeat 6,236 times — spelling them
  /// out costs roughly a megabyte of asset for no gain.
  factory Surah.fromJson(Map<String, dynamic> json) {
    final number = json['number'] as int;
    final nameArabic = json['nameArabic'] as String;
    final nameEnglish = json['nameEnglish'] as String;
    final nameTranslation = json['nameTranslation'] as String;
    final revelationType = json['revelationType'] as String;

    final verses = (json['ayahs'] as List).map((raw) {
      final ayah = raw as Map<String, dynamic>;
      return QuranVerse(
        // The global ayah number is unique across the whole Quran, so it
        // doubles as the stable id likes and recitation are keyed by.
        id: ayah['g'] as int,
        globalAyahNumber: ayah['g'] as int,
        surahNumber: number,
        ayahNumber: ayah['n'] as int,
        surahNameArabic: nameArabic,
        surahNameEnglish: nameEnglish,
        surahNameTranslation: nameTranslation,
        revelationType: revelationType,
        arabicText: ayah['ar'] as String,
        translations: (ayah['t'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
      );
    }).toList();

    return Surah(
      number: number,
      nameArabic: nameArabic,
      nameEnglish: nameEnglish,
      nameTranslation: nameTranslation,
      revelationType: revelationType,
      verses: verses,
    );
  }

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String nameTranslation;
  final String revelationType;
  final List<QuranVerse> verses;

  int get ayahCount => verses.length;
}
