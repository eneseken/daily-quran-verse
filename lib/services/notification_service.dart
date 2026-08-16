import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/quran_language.dart';
import '../models/quran_verse.dart';
import 'quran_service.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const dailyPreferenceKey = 'daily_notifications_enabled';
  static const prayerPreferenceKey = 'prayer_reminders_enabled';
  static const reminderStartHourKey = 'notification_reminder_start_hour';
  static const reminderEndHourKey = 'notification_reminder_end_hour';

  static const _dailyChannelId = 'daily_quran_verses';
  static const _prayerChannelId = 'prayer_reminders';
  static const _daysToSchedule = 14;
  static const _dailySlotsPerDay = 3;
  static const _dailyBaseId = 10000;
  static const _prayerBaseId = 20000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezoneReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _configureTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings: settings);
  }

  Future<void> _configureTimezone() async {
    if (_timezoneReady) return;
    _timezoneReady = true;
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidAllowed = await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosAllowed = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macosAllowed = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidAllowed ?? iosAllowed ?? macosAllowed ?? true;
  }

  Future<({bool daily, bool prayer})> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      daily: prefs.getBool(dailyPreferenceKey) ?? false,
      prayer: prefs.getBool(prayerPreferenceKey) ?? false,
    );
  }

  Future<void> saveReminderWindow({
    required int startHour,
    required int endHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(reminderStartHourKey, startHour.clamp(0, 23));
    await prefs.setInt(reminderEndHourKey, endHour.clamp(0, 23));
    await syncScheduledNotifications();
  }

  Future<({int startHour, int endHour})> loadReminderWindow() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      startHour: prefs.getInt(reminderStartHourKey) ?? 8,
      endHour: prefs.getInt(reminderEndHourKey) ?? 22,
    );
  }

  Future<void> setDailyEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await scheduleDailyVerseNotifications();
    } else {
      await _cancelDaily();
    }
    await prefs.setBool(dailyPreferenceKey, enabled);
  }

  Future<void> setPrayerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await schedulePrayerReminders();
    } else {
      await _cancelPrayer();
    }
    await prefs.setBool(prayerPreferenceKey, enabled);
  }

  Future<void> syncScheduledNotifications() async {
    final settings = await loadSettings();
    if (settings.daily) await scheduleDailyVerseNotifications();
    if (settings.prayer) await schedulePrayerReminders();
  }

  Future<void> cancelScheduledNotifications() async {
    await _cancelDaily();
    await _cancelPrayer();
  }

  Future<void> scheduleDailyVerseNotifications() async {
    await initialize();
    await _cancelDaily();

    final verses = await QuranService.instance.loadAll();
    if (verses.isEmpty) return;

    await QuranLanguageController.instance.restore();
    final languageCode = QuranLanguageController.instance.code;
    final window = await loadReminderWindow();
    final hours = _dailyHours(window.startHour, window.endHour);
    final random = Random(DateTime.now().day + DateTime.now().month * 31);

    for (var day = 0; day < _daysToSchedule; day++) {
      for (var slot = 0; slot < hours.length; slot++) {
        final verse = verses[random.nextInt(verses.length)];
        final when = _nextDate(dayOffset: day, hour: hours[slot]);
        if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          id: _dailyBaseId + day * _dailySlotsPerDay + slot,
          title: 'Daily Quran Verse',
          body: _verseBody(verse, languageCode),
          scheduledDate: when,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _dailyChannelId,
              'Daily Quran verses',
              channelDescription: 'Gentle Quran verse reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  Future<void> schedulePrayerReminders() async {
    await initialize();
    await _cancelPrayer();

    final window = await loadReminderWindow();
    final hour = window.endHour <= 0 ? 20 : window.endHour;
    for (var day = 0; day < _daysToSchedule; day++) {
      final when = _nextDate(dayOffset: day, hour: hour);
      if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: _prayerBaseId + day,
        title: 'Prayer reminder',
        body: 'Take a quiet moment to complete your daily prayer.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _prayerChannelId,
            'Prayer reminders',
            channelDescription: 'Gentle daily prayer reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  List<int> _dailyHours(int startHour, int endHour) {
    final start = startHour.clamp(0, 23);
    final end = endHour.clamp(0, 23);
    if (end <= start) return [start];
    final middle = start + ((end - start) / 2).round();
    return {start, middle, end}.toList()..sort();
  }

  tz.TZDateTime _nextDate({required int dayOffset, required int hour}) {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      0,
    );
  }

  String _verseBody(QuranVerse verse, String languageCode) {
    final text = verse.textFor(languageCode).replaceAll(RegExp(r'\s+'), ' ');
    final clipped = text.length > 170 ? '${text.substring(0, 167)}...' : text;
    return '$clipped - ${verse.reference}';
  }

  Future<void> _cancelDaily() async {
    await initialize();
    for (var i = 0; i < _daysToSchedule * _dailySlotsPerDay; i++) {
      await _plugin.cancel(id: _dailyBaseId + i);
    }
  }

  Future<void> _cancelPrayer() async {
    await initialize();
    for (var i = 0; i < _daysToSchedule; i++) {
      await _plugin.cancel(id: _prayerBaseId + i);
    }
  }
}
