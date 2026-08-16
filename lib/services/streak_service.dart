import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Current consecutive-day streak and this week's Mon..Sun read booleans.
/// Both are computed server-side from the raw `reading_activity` log, never
/// stored as a counter — see the `my_streak` migration for why.
class StreakSummary {
  const StreakSummary({required this.currentStreak, required this.week});

  static const zero = StreakSummary(
    currentStreak: 0,
    week: [false, false, false, false, false, false, false],
  );

  final int currentStreak;

  /// Monday through Sunday, matching the profile screen's day row order.
  final List<bool> week;
}

/// Wraps the `reading_activity` backend: logging today as read, and reading
/// back the derived streak. Mirrors SubscriptionService's shape — a thin
/// service so the RPC names live in exactly one place.
class StreakService {
  StreakService._();

  static final instance = StreakService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Marks the caller's local "today" as read, at most once per calendar
  /// day — cheap to call on every app open, since the SharedPreferences
  /// check skips the network round trip on every open after the first.
  Future<void> logTodayIfNeeded() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final today = _localToday();
    final prefs = await SharedPreferences.getInstance();
    final key = 'reading_activity_logged_$userId';
    if (prefs.getString(key) == today) return;

    try {
      await _client.rpc('log_reading_activity', params: {'p_local_date': today});
      await prefs.setString(key, today);
    } catch (_) {
      // Best-effort — a failed log here just means no streak credit for
      // today, not something worth surfacing to the user. Retried
      // automatically on the next app open since the pref was never set.
    }
  }

  Future<StreakSummary> fetchStreak() async {
    if (_client.auth.currentUser == null) return StreakSummary.zero;

    try {
      final rows = await _client.rpc(
        'my_streak',
        params: {'p_local_date': _localToday()},
      ) as List;
      if (rows.isEmpty) return StreakSummary.zero;

      final row = rows.first as Map<String, dynamic>;
      final week = (row['week'] as List).cast<bool>();
      return StreakSummary(
        currentStreak: row['current_streak'] as int,
        week: week,
      );
    } catch (_) {
      return StreakSummary.zero;
    }
  }

  /// YYYY-MM-DD in the device's local calendar — the whole point is that
  /// this must NOT be UTC, or a user reading right around midnight would
  /// have their day misattributed on the server.
  String _localToday() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}
