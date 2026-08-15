import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/models/quran_verse.dart';

QuranVerse _verse({Map<String, String> translations = const {}}) => QuranVerse(
      id: 1,
      globalAyahNumber: 1,
      surahNumber: 1,
      ayahNumber: 1,
      surahNameArabic: 'الفاتحة',
      surahNameEnglish: 'Al-Faatiha',
      surahNameTranslation: 'The Opening',
      revelationType: 'Meccan',
      arabicText: 'بِسْمِ اللَّهِ',
      translations: translations,
    );

void main() {
  group('QuranVerse.textFor', () {
    test('returns the exact language when present', () {
      final verse = _verse(translations: {'en': 'In the name of Allah', 'tr': 'Rahman ve Rahim'});
      expect(verse.textFor('tr'), 'Rahman ve Rahim');
    });

    test('falls back to English when the language is missing', () {
      final verse = _verse(translations: {'en': 'In the name of Allah'});
      expect(verse.textFor('fr'), 'In the name of Allah');
    });

    test('falls back to Arabic when no translations exist at all', () {
      final verse = _verse();
      expect(verse.textFor('en'), 'بِسْمِ اللَّهِ');
    });
  });

  test('reference formats as "Surah surah:ayah"', () {
    final verse = _verse();
    expect(verse.reference, 'Al-Faatiha 1:1');
  });

  test('fromRow parses a Supabase-shaped map', () {
    final verse = QuranVerse.fromRow({
      'id': 42,
      'global_ayah_number': 262,
      'surah_number': 2,
      'ayah_number': 255,
      'surah_name_arabic': 'البقرة',
      'surah_name_english': 'Al-Baqara',
      'surah_name_translation': 'The Cow',
      'revelation_type': 'Medinan',
      'arabic_text': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      'translations': {'en': 'Allah - there is no deity except Him'},
    });

    expect(verse.id, 42);
    expect(verse.surahNumber, 2);
    expect(verse.ayahNumber, 255);
    expect(verse.reference, 'Al-Baqara 2:255');
    expect(verse.textFor('en'), 'Allah - there is no deity except Him');
  });
}
