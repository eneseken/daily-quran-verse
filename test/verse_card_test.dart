import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim/models/quran_verse.dart';
import 'package:muslim/screens/home/verse_card.dart';
import 'package:muslim/services/recitation_service.dart';

/// Ayat al-Kursi (2:255) — one of the longest single ayahs in the Quran, so a
/// layout that survives this survives everything shorter.
final _longVerse = QuranVerse(
  id: 262,
  globalAyahNumber: 262,
  surahNumber: 2,
  ayahNumber: 255,
  surahNameArabic: 'البقرة',
  surahNameEnglish: 'Al-Baqara',
  surahNameTranslation: 'The Cow',
  revelationType: 'Medinan',
  arabicText:
      'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ '
      'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
  translations: {
    'en':
        'Allah - there is no deity except Him, the Ever-Living, the Sustainer '
        'of existence. Neither drowsiness overtakes Him nor sleep. To Him '
        'belongs whatever is in the heavens and whatever is on the earth.',
    'tr':
        'Allah, kendisinden başka hiçbir ilâh olmayandır. Diridir, kayyumdur. '
        'Onu ne bir uyuklama tutabilir, ne de bir uyku.',
  },
);

Widget _shell(
  QuranVerse verse, {
  String language = 'en',
  Size? size,
  RecitationState recitation = RecitationState.idle,
  VoidCallback? onToggleLike,
  VoidCallback? onShare,
  VoidCallback? onOpenSettings,
  VoidCallback? onTogglePlayback,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size ?? const Size(360, 640)),
    child: MaterialApp(
      home: VerseFeedShell(
        verse: verse,
        ayahCountInSurah: 286,
        liked: false,
        recitation: recitation,
        onToggleLike: onToggleLike ?? () {},
        onShare: onShare ?? () {},
        onOpenSettings: onOpenSettings ?? () {},
        onTogglePlayback: onTogglePlayback ?? () {},
        feed: VersePage(verse: verse, languageCode: language),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the longest ayah without overflow on a small phone',
      (tester) async {
    await tester.pumpWidget(_shell(_longVerse));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Al-Baqara'), findsOneWidget);
  });

  testWidgets('renders the Turkish translation when that language is selected',
      (tester) async {
    await tester.pumpWidget(_shell(_longVerse, language: 'tr'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kayyumdur', findRichText: true), findsNothing);
    expect(find.textContaining('kayyumdur'), findsOneWidget);
  });

  testWidgets('like, share, settings and play taps fire their callbacks',
      (tester) async {
    var liked = false;
    var shared = false;
    var settingsOpened = false;
    var playbackToggled = false;

    await tester.pumpWidget(
      _shell(
        _longVerse,
        onToggleLike: () => liked = true,
        onShare: () => shared = true,
        onOpenSettings: () => settingsOpened = true,
        onTogglePlayback: () => playbackToggled = true,
      ),
    );
    await tester.pumpAndSettle();

    // The top indicator also draws an outlined heart, so target the last one
    // — the actual like button in the action row.
    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.tap(find.byIcon(Icons.play_arrow));

    expect(liked, isTrue);
    expect(shared, isTrue);
    expect(settingsOpened, isTrue);
    expect(playbackToggled, isTrue);
  });

  testWidgets('play button shows a spinner while the recitation buffers',
      (tester) async {
    await tester.pumpWidget(
      _shell(_longVerse, recitation: RecitationState.loading),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('play button shows pause while the recitation plays',
      (tester) async {
    await tester.pumpWidget(
      _shell(_longVerse, recitation: RecitationState.playing),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });
}
