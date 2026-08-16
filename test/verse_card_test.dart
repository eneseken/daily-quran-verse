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

/// 2:282 — the single longest ayah in the Quran (~1,200 Arabic characters).
/// At a fixed font size this would run for several screens' worth of
/// scrolling; the dynamic sizing must shrink it to actually fit one page.
final _longestAyah = QuranVerse(
  id: 313,
  globalAyahNumber: 313,
  surahNumber: 2,
  ayahNumber: 282,
  surahNameArabic: 'البقرة',
  surahNameEnglish: 'Al-Baqara',
  surahNameTranslation: 'The Cow',
  revelationType: 'Medinan',
  arabicText:
      'يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا تَدَايَنتُم بِدَيْنٍ إِلَىٰٓ أَجَلٍۢ مُّسَمًّۭى '
      'فَٱكْتُبُوهُ ۚ وَلْيَكْتُب بَّيْنَكُمْ كَاتِبٌۢ بِٱلْعَدْلِ ۚ وَلَا يَأْبَ كَاتِبٌ أَن '
      'يَكْتُبَ كَمَا عَلَّمَهُ ٱللَّهُ ۚ فَلْيَكْتُبْ وَلْيُمْلِلِ ٱلَّذِى عَلَيْهِ ٱلْحَقُّ '
      'وَلْيَتَّقِ ٱللَّهَ رَبَّهُۥ وَلَا يَبْخَسْ مِنْهُ شَيْـًۭٔا ۚ فَإِن كَانَ ٱلَّذِى عَلَيْهِ '
      'ٱلْحَقُّ سَفِيهًا أَوْ ضَعِيفًا أَوْ لَا يَسْتَطِيعُ أَن يُمِلَّ هُوَ فَلْيُمْلِلْ وَلِيُّهُۥ '
      'بِٱلْعَدْلِ ۚ وَٱسْتَشْهِدُوا۟ شَهِيدَيْنِ مِن رِّجَالِكُمْ ۖ فَإِن لَّمْ يَكُونَا رَجُلَيْنِ '
      'فَرَجُلٌۭ وَٱمْرَأَتَانِ مِمَّن تَرْضَوْنَ مِنَ ٱلشُّهَدَآءِ أَن تَضِلَّ إِحْدَىٰهُمَا فَتُذَكِّرَ '
      'إِحْدَىٰهُمَا ٱلْأُخْرَىٰ ۚ وَلَا يَأْبَ ٱلشُّهَدَآءُ إِذَا مَا دُعُوا۟ ۚ وَلَا تَسْـَٔمُوٓا۟ أَن '
      'تَكْتُبُوهُ صَغِيرًا أَوْ كَبِيرًا إِلَىٰٓ أَجَلِهِۦ ۚ ذَٰلِكُمْ أَقْسَطُ عِندَ ٱللَّهِ وَأَقْوَمُ '
      'لِلشَّهَٰدَةِ وَأَدْنَىٰٓ أَلَّا تَرْتَابُوٓا۟ ۖ إِلَّآ أَن تَكُونَ تِجَٰرَةً حَاضِرَةًۭ '
      'تُدِيرُونَهَا بَيْنَكُمْ فَلَيْسَ عَلَيْكُمْ جُنَاحٌ أَلَّا تَكْتُبُوهَا ۗ وَأَشْهِدُوٓا۟ إِذَا '
      'تَبَايَعْتُمْ ۚ وَلَا يُضَآرَّ كَاتِبٌۭ وَلَا شَهِيدٌۭ ۚ وَإِن تَفْعَلُوا۟ فَإِنَّهُۥ فُسُوقٌۢ '
      'بِكُمْ ۗ وَٱتَّقُوا۟ ٱللَّهَ ۖ وَيُعَلِّمُكُمُ ٱللَّهُ ۗ وَٱللَّهُ بِكُلِّ شَىْءٍ عَلِيمٌۭ',
  translations: {
    'en':
        'O you who have believed, when you contract a debt for a specified '
        'term, write it down. And let a scribe write [it] between you in '
        'justice. Let no scribe refuse to write as Allah has taught him. So '
        'let him write and let the one who has the obligation dictate. And '
        'let him fear Allah, his Lord, and not leave anything out of it. But '
        'if the one who has the obligation is of limited understanding or '
        'weak or unable to dictate himself, then let his guardian dictate in '
        'justice. And bring to witness two witnesses from among your men. '
        'And if there are not two men [available], then a man and two women '
        'from those whom you accept as witnesses - so that if one of the '
        'women errs, then the other can remind her. And let not the '
        'witnesses refuse when they are called upon. And do not be [too] '
        'weary to write it, whether it is small or large, for its '
        '[specified] term. That is more just in the sight of Allah and '
        'stronger as evidence and more likely to prevent doubt between you, '
        'except when it is an immediate transaction which you conduct among '
        'yourselves. For [then] there is no blame upon you if you do not '
        'write it. And take witnesses when you conclude a contract. Let no '
        'scribe be harmed or any witness. For if you do so, indeed, it is '
        '[grave] disobedience in you. And fear Allah. And Allah teaches you. '
        'And Allah is Knowing of all things.',
  },
);

Widget _shell(
  QuranVerse verse, {
  String language = 'en',
  RecitationState recitation = RecitationState.idle,
  VoidCallback? onToggleLike,
  VoidCallback? onShare,
  VoidCallback? onOpenSettings,
  VoidCallback? onTogglePlayback,
}) {
  return MaterialApp(
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
  );
}

/// Sets the test surface to [logicalSize] and pumps [_shell] into it.
///
/// MaterialApp derives MediaQuery from `tester.view`, not from an ancestor
/// MediaQuery widget — wrapping the tree in one has no effect on layout, so
/// viewport size has to go through here to actually matter.
Future<void> _pumpAtSize(
  WidgetTester tester,
  QuranVerse verse, {
  required Size logicalSize,
  String language = 'en',
  RecitationState recitation = RecitationState.idle,
}) async {
  tester.view.physicalSize = logicalSize * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _shell(verse, language: language, recitation: recitation),
  );
}

/// The size every non-size-specific test runs at, matching a current iPhone.
const _defaultSize = Size(390, 844);

void main() {
  testWidgets('renders the longest ayah without overflow on a small phone', (
    tester,
  ) async {
    await _pumpAtSize(tester, _longVerse, logicalSize: const Size(360, 640));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Al-Baqara'), findsOneWidget);
  });

  testWidgets('hides the Arabic block entirely when showArabic is false', (
    tester,
  ) async {
    tester.view.physicalSize = _defaultSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: VerseFeedShell(
          verse: _longVerse,
          ayahCountInSurah: 286,
          liked: false,
          recitation: RecitationState.idle,
          onToggleLike: () {},
          onShare: () {},
          onOpenSettings: () {},
          onTogglePlayback: () {},
          feed: VersePage(
            verse: _longVerse,
            languageCode: 'en',
            showArabic: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_longVerse.arabicText), findsNothing);
    expect(find.textContaining('Al-Baqara'), findsOneWidget);
  });

  testWidgets(
    'renders the Turkish translation when that language is selected',
    (tester) async {
      await _pumpAtSize(
        tester,
        _longVerse,
        logicalSize: _defaultSize,
        language: 'tr',
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Kayyumdur', findRichText: true),
        findsNothing,
      );
      expect(find.textContaining('kayyumdur'), findsOneWidget);
    },
  );

  testWidgets('like, share, settings and play taps fire their callbacks', (
    tester,
  ) async {
    var liked = false;
    var shared = false;
    var settingsOpened = false;
    var playbackToggled = false;

    tester.view.physicalSize = _defaultSize * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
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
    await tester.tap(find.byIcon(Icons.person));
    await tester.tap(find.byIcon(Icons.play_arrow));

    expect(liked, isTrue);
    expect(shared, isTrue);
    expect(settingsOpened, isTrue);
    expect(playbackToggled, isTrue);
  });

  testWidgets('play button shows a spinner while the recitation buffers', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      _longVerse,
      logicalSize: _defaultSize,
      recitation: RecitationState.loading,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('play button shows pause while the recitation plays', (
    tester,
  ) async {
    await _pumpAtSize(
      tester,
      _longVerse,
      logicalSize: _defaultSize,
      recitation: RecitationState.playing,
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  group('dynamic font size', () {
    testWidgets(
      'the longest ayah in the Quran renders in full, without overflow',
      (tester) async {
        await _pumpAtSize(
          tester,
          _longestAyah,
          logicalSize: const Size(360, 640),
        );
        await tester.pumpAndSettle();

        // No red-banner overflow, and the whole verse actually reached the
        // tree — the fallback for the rare case that even the readability
        // floor doesn't fit a page is to let that page scroll, not to clip.
        expect(tester.takeException(), isNull);
        expect(find.text(_longestAyah.arabicText), findsOneWidget);
        expect(find.textContaining('Al-Baqara'), findsOneWidget);
      },
    );

    testWidgets('a short ayah renders at full size, unshrunk', (tester) async {
      // Deliberately generous: this asserts scale==1 specifically, so the
      // viewport must be tall enough that no font substitution used when
      // Google Fonts can't reach the network (its measured metrics can be
      // taller than Amiri/Playfair's real ones) can push it below 1 either.
      // No real phone is this tall — the behaviour under test is "short
      // verses don't shrink," not any particular height.
      await _pumpAtSize(tester, _longVerse, logicalSize: const Size(390, 2400));
      await tester.pumpAndSettle();

      final arabic = tester.widget<Text>(find.text(_longVerse.arabicText));
      expect(arabic.style!.fontSize, VersePage.arabicSize);
    });

    testWidgets('the longest ayah renders visibly smaller than a short one', (
      tester,
    ) async {
      await _pumpAtSize(tester, _longestAyah, logicalSize: _defaultSize);
      await tester.pumpAndSettle();

      final arabic = tester.widget<Text>(find.text(_longestAyah.arabicText));
      expect(arabic.style!.fontSize, lessThan(VersePage.arabicSize));
    });

    testWidgets('never shrinks past the readability floor', (tester) async {
      // A viewport far too small for any scale above the floor to fit.
      await _pumpAtSize(
        tester,
        _longestAyah,
        logicalSize: const Size(320, 300),
      );
      await tester.pumpAndSettle();

      final arabic = tester.widget<Text>(find.text(_longestAyah.arabicText));
      expect(
        arabic.style!.fontSize,
        greaterThanOrEqualTo(VersePage.arabicSize * VersePage.minScale - 0.01),
      );
    });

    testWidgets('fits the longest ayah across a range of phone heights', (
      tester,
    ) async {
      for (final size in [
        const Size(320, 568), // iPhone SE
        const Size(360, 640), // small Android
        const Size(390, 844), // iPhone 14
        const Size(428, 926), // iPhone 14 Pro Max
      ]) {
        await _pumpAtSize(tester, _longestAyah, logicalSize: size);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'failed at $size');
      }
    });
  });
}
