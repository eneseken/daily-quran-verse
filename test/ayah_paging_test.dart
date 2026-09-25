import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/models/quran_verse.dart';
import 'package:muslim/models/surah.dart';
import 'package:muslim/screens/home/verse_card.dart';
import 'package:muslim/services/recitation_service.dart';

QuranVerse _ayah({
  required int surahNumber,
  required int ayahNumber,
  required String surahName,
}) =>
    QuranVerse(
      id: surahNumber * 1000 + ayahNumber,
      globalAyahNumber: surahNumber * 1000 + ayahNumber,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahNameArabic: 'الكوثر',
      surahNameEnglish: surahName,
      surahNameTranslation: surahName,
      revelationType: 'Meccan',
      arabicText: 'ARABIC $surahNumber:$ayahNumber',
      translations: {'en': 'Translation $surahNumber:$ayahNumber'},
    );

Surah _surah(int number, String name, int ayahCount) => Surah(
      number: number,
      nameArabic: 'سورة',
      nameEnglish: name,
      nameTranslation: name,
      revelationType: 'Meccan',
      verses: [
        for (var n = 1; n <= ayahCount; n++)
          _ayah(surahNumber: number, ayahNumber: n, surahName: name),
      ],
    );

/// Two short surahs back to back — enough to cross the boundary between
/// them, which is the behaviour under test.
final _kawthar = _surah(108, 'Abundance', 3);
final _kafirun = _surah(109, 'Disbelievers', 6);
final _verses = [..._kawthar.verses, ..._kafirun.verses];

/// A miniature of HomeScreen's feed: one flat PageView over consecutive
/// ayahs, with the surah title pinned above it and following whichever ayah
/// is on screen.
class _Feed extends StatefulWidget {
  const _Feed();

  @override
  State<_Feed> createState() => _FeedState();
}

class _FeedState extends State<_Feed> {
  int _page = 0;

  Surah _surahOf(QuranVerse verse) =>
      verse.surahNumber == 108 ? _kawthar : _kafirun;

  @override
  Widget build(BuildContext context) {
    final current = _verses[_page];
    return MaterialApp(
      home: VerseFeedShell(
        verse: current,
        surah: _surahOf(current),
        ayahCountInSurah: _surahOf(current).ayahCount,
        liked: false,
        recitation: RecitationState.idle,
        onToggleLike: () {},
        onShare: () {},
        onOpenSettings: () {},
        onTogglePlayback: () {},
        feed: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: _verses.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (context, page) => AyahPage(
            verse: _verses[page],
            languageCode: 'en',
          ),
        ),
      ),
    );
  }
}

Future<void> _swipeUp(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, -400), 1500);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one ayah at a time, advancing on each swipe', (tester) async {
    tester.view.physicalSize =
        const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Feed());
    await tester.pumpAndSettle();

    // Only the current ayah is on screen — its neighbours are built by the
    // PageView but sit offscreen, so exactly one is hit-testable at a time.
    expect(find.text('Translation 108:1'), findsOneWidget);

    await _swipeUp(tester);
    expect(find.text('Translation 108:2'), findsOneWidget);

    await _swipeUp(tester);
    expect(find.text('Translation 108:3'), findsOneWidget);
  });

  testWidgets('swiping past the last ayah lands on the next surah', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Feed());
    await tester.pumpAndSettle();

    // Al-Kawthar's title is up while its ayahs are.
    expect(find.textContaining('Abundance'), findsOneWidget);

    // Three swipes: 108:1 -> 108:2 -> 108:3 -> 109:1.
    await _swipeUp(tester);
    await _swipeUp(tester);
    await _swipeUp(tester);

    expect(find.text('Translation 109:1'), findsOneWidget);
    // The pinned title followed the reader into the next surah.
    expect(find.textContaining('Disbelievers'), findsOneWidget);
    expect(find.textContaining('Abundance'), findsNothing);
  });

  testWidgets('the position readout tracks the ayah within its surah', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Feed());
    await tester.pumpAndSettle();

    expect(find.text('1/3'), findsOneWidget);

    await _swipeUp(tester);
    expect(find.text('2/3'), findsOneWidget);

    // Crossing into Al-Kafirun restarts the count against its own length.
    await _swipeUp(tester);
    await _swipeUp(tester);
    expect(find.text('1/6'), findsOneWidget);
  });
}
