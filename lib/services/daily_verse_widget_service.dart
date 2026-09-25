import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../core/feed_background.dart';
import 'curated_verses.dart';
import 'quran_service.dart';

/// Pushes "today's verse" into the Android home screen widget.
///
/// The widget has no Dart isolate of its own and Android's
/// AppWidgetProvider can't reach Supabase, so this service pre-computes
/// today's *and* tomorrow's verse (in the caller's language) and writes
/// both across. The native side then picks whichever one matches its own
/// idea of "today" on every periodic refresh — including local-midnight
/// rollovers that happen while the app isn't running. If the app stays
/// closed for more than a day, the widget just holds on the last verse it
/// has until the app is opened again and refills the two-day window.
///
/// The verse itself comes from [CuratedVerses] — a short, hand-picked list
/// of well-known ayahs — rather than a plain index into the whole Quran, so
/// the widget never lands on something like a mid-chapter inheritance-law
/// verse that only makes sense with the surrounding context.
class DailyVerseWidgetService {
  DailyVerseWidgetService._();

  static const _androidProviderName = 'DailyVerseWidgetProvider';

  /// Must match the keys read by
  /// android/.../DailyVerseWidgetProvider.kt.
  static const _keyTodayText = 'daily_verse_today_text';
  static const _keyTodayReference = 'daily_verse_today_reference';
  static const _keyTodayEpochDay = 'daily_verse_today_epoch_day';
  static const _keyTomorrowText = 'daily_verse_tomorrow_text';
  static const _keyTomorrowReference = 'daily_verse_tomorrow_reference';
  static const _keyDarkText = 'daily_verse_dark_text';
  static const _keyBackgroundPath = 'daily_verse_background_path';

  /// The rendered background bitmap's target width — big enough to stay
  /// sharp on the largest widget size the info XML allows, small enough to
  /// comfortably clear Android's binder transaction limit for RemoteViews
  /// bitmaps (the original Customize photos run 1.4-2.4MB).
  static const _backgroundTargetWidth = 720;

  /// Writes today's and tomorrow's verse (in [languageCode]) to the
  /// widget's storage, then asks the home screen widget to redraw. Safe to
  /// call often — e.g. on every app open and whenever the user changes
  /// their translation language or Customize wallpaper — since it's a pure
  /// function of (today, language, the verse list, the Customize
  /// selection).
  static Future<void> updateForToday(String languageCode) async {
    final allVerses = await QuranService.instance.loadAll();
    if (allVerses.isEmpty) return;
    final verses = await CuratedVerses.resolve(allVerses);

    final todayEpochDay = _todayEpochDay();
    final today = verses[todayEpochDay % verses.length];
    final tomorrow = verses[(todayEpochDay + 1) % verses.length];

    await HomeWidget.saveWidgetData<String>(
      _keyTodayText,
      today.textFor(languageCode),
    );
    await HomeWidget.saveWidgetData<String>(
      _keyTodayReference,
      today.reference,
    );
    // Written as a string, not an int: home_widget's platform channel picks
    // Int32 vs Int64 on the Kotlin side depending on the value's magnitude,
    // and SharedPreferences throws ClassCastException if the reader's
    // getInt/getLong doesn't match what was actually stored. A string
    // sidesteps that entirely.
    await HomeWidget.saveWidgetData<String>(
      _keyTodayEpochDay,
      todayEpochDay.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      _keyTomorrowText,
      tomorrow.textFor(languageCode),
    );
    await HomeWidget.saveWidgetData<String>(
      _keyTomorrowReference,
      tomorrow.reference,
    );

    await _syncBackground();

    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }

  /// Mirrors the Customize screen's active wallpaper (and its light/dark
  /// verse-text choice) onto the widget, so the home screen widget always
  /// matches whatever background the user picked in-app. Renders a
  /// downscaled copy rather than handing over the original asset — the
  /// full-resolution Customize photos run 1.4-2.4MB, comfortably past what
  /// RemoteViews can safely push through a binder transaction.
  static Future<void> _syncBackground() async {
    final background = FeedBackgroundController.instance;
    final themeId = background.themeId;

    await HomeWidget.saveWidgetData<String>(
      _keyDarkText,
      themeId != null && background.darkTextFor(themeId) ? '1' : '0',
    );

    if (themeId == null) {
      await HomeWidget.saveWidgetData<String>(_keyBackgroundPath, null);
      return;
    }

    // Skip the re-render (and the file write / decode work it costs) if
    // this theme's downscaled copy is already on disk from a previous call.
    final dir = await getApplicationSupportDirectory();
    final file = _backgroundFile(dir.path, themeId);
    if (!await file.exists()) {
      final resized = await _downscaleAsset(
        'assets/themes/$themeId.png',
        _backgroundTargetWidth,
      );
      await file.create(recursive: true);
      await file.writeAsBytes(resized);
    }
    await HomeWidget.saveWidgetData<String>(_keyBackgroundPath, file.path);
  }

  static File _backgroundFile(String supportDirPath, String themeId) =>
      File('$supportDirPath/home_widget/background_$themeId.png');

  /// Decodes a bundled asset image and re-encodes it as a PNG no wider than
  /// [targetWidth], preserving aspect ratio. Runs entirely through
  /// dart:ui's async codec API rather than the widget-render pipeline
  /// (HomeWidget.renderFlutterWidget), which paints synchronously and can't
  /// be trusted to have a still-loading Image.asset decoded in time.
  static Future<Uint8List> _downscaleAsset(
    String assetPath,
    int targetWidth,
  ) async {
    final bytes = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    codec.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Days since the Unix epoch in the device's local calendar (not UTC),
  /// so the rollover happens at local midnight rather than at 00:00 UTC.
  static int _todayEpochDay() {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    return localMidnight.millisecondsSinceEpoch ~/ 86400000;
  }
}
