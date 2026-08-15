/// One ayah, with its Arabic text and every translation the DB has for it.
class QuranVerse {
  const QuranVerse({
    required this.id,
    required this.globalAyahNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.surahNameTranslation,
    required this.revelationType,
    required this.arabicText,
    required this.translations,
  });

  factory QuranVerse.fromRow(Map<String, dynamic> row) {
    final rawTranslations = row['translations'] as Map<String, dynamic>? ?? {};
    return QuranVerse(
      id: row['id'] as int,
      globalAyahNumber: row['global_ayah_number'] as int,
      surahNumber: row['surah_number'] as int,
      ayahNumber: row['ayah_number'] as int,
      surahNameArabic: row['surah_name_arabic'] as String,
      surahNameEnglish: row['surah_name_english'] as String,
      surahNameTranslation: row['surah_name_translation'] as String,
      revelationType: row['revelation_type'] as String,
      arabicText: row['arabic_text'] as String,
      translations: rawTranslations.map((k, v) => MapEntry(k, v as String)),
    );
  }

  final int id;
  final int globalAyahNumber;
  final int surahNumber;
  final int ayahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final String surahNameTranslation;
  final String revelationType;
  final String arabicText;

  /// Keyed by language code, e.g. `{"en": "...", "tr": "..."}`.
  final Map<String, String> translations;

  /// Falls back to English, then to whatever is available, so a missing
  /// translation never renders as an empty card.
  String textFor(String languageCode) {
    return translations[languageCode] ??
        translations['en'] ??
        (translations.isNotEmpty ? translations.values.first : arabicText);
  }

  String get reference => '$surahNameEnglish $surahNumber:$ayahNumber';
}
