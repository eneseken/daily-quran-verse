import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/models/surah.dart';

/// Guards the bundled Quran asset itself: it ships with the app, so a
/// truncated or mis-shaped file would only surface as an empty feed on a
/// real device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Surah> surahs;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/quran.json');
    surahs = (jsonDecode(raw) as List)
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  test('holds all 114 surahs and 6,236 ayahs', () {
    expect(surahs.length, 114);
    expect(
      surahs.fold<int>(0, (sum, s) => sum + s.ayahCount),
      6236,
    );
  });

  test('surahs are in order and numbered 1..114', () {
    for (var i = 0; i < surahs.length; i++) {
      expect(surahs[i].number, i + 1);
    }
  });

  test('ayahs within a surah are numbered 1..n in order', () {
    for (final surah in surahs) {
      for (var i = 0; i < surah.verses.length; i++) {
        expect(
          surah.verses[i].ayahNumber,
          i + 1,
          reason: 'surah ${surah.number}',
        );
      }
    }
  });

  test('global ayah numbers run 1..6236 without gaps', () {
    final global = [
      for (final surah in surahs)
        for (final verse in surah.verses) verse.globalAyahNumber,
    ];
    expect(global.first, 1);
    expect(global.last, 6236);
    for (var i = 0; i < global.length; i++) {
      expect(global[i], i + 1);
    }
  });

  test('every ayah carries a translation in each supported language', () {
    // Arabic is deliberately absent: textFor('ar') returns the ayah itself.
    const languages = {'en', 'tr', 'de', 'fr', 'es', 'ur', 'id'};
    for (final surah in surahs) {
      for (final verse in surah.verses) {
        expect(
          verse.translations.keys.toSet(),
          languages,
          reason: 'ayah ${verse.surahNumber}:${verse.ayahNumber}',
        );
        for (final language in languages) {
          expect(
            verse.textFor(language).trim(),
            isNotEmpty,
            reason: '$language at ${verse.surahNumber}:${verse.ayahNumber}',
          );
        }
      }
    }
  });

  test('every ayah has Arabic text, and Arabic reads as the ayah itself', () {
    for (final surah in surahs) {
      for (final verse in surah.verses) {
        expect(verse.arabicText.trim(), isNotEmpty);
        expect(verse.textFor('ar'), verse.arabicText);
      }
    }
  });

  test('surah metadata is present and consistent across its ayahs', () {
    for (final surah in surahs) {
      expect(surah.nameArabic.trim(), isNotEmpty);
      expect(surah.nameTranslation.trim(), isNotEmpty);
      expect(surah.revelationType, anyOf('Meccan', 'Medinan'));
      for (final verse in surah.verses) {
        expect(verse.surahNumber, surah.number);
        expect(verse.surahNameArabic, surah.nameArabic);
      }
    }
  });

  test('spot-checks a known ayah', () {
    // Al-Ikhlaas is 112 and runs four ayahs — a cheap canary that the file
    // is the Quran and not, say, a truncated or reordered copy.
    final ikhlas = surahs[111];
    expect(ikhlas.number, 112);
    expect(ikhlas.ayahCount, 4);
    expect(ikhlas.nameEnglish, 'Al-Ikhlaas');

    // Al-Baqara is by far the longest surah.
    expect(surahs[1].ayahCount, 286);
  });
}
