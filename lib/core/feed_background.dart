import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const feedBackgroundPreferenceKey = 'feed_background_theme_id';

/// Which of the Customize screen's background photos (if any) currently
/// replaces the feed's plain background. Mirrors AppThemeController's shape:
/// an in-memory current value, persisted to SharedPreferences, notifying
/// listeners on change.
class FeedBackgroundController extends ChangeNotifier {
  FeedBackgroundController._();

  static final instance = FeedBackgroundController._();

  /// Theme ids whose photo reads light overall, so verse text needs to sit
  /// in dark ink rather than the usual light-on-photo white. Kept as the one
  /// source of truth CustomizeScreen's tile preview also reads, so the
  /// picker always shows the same contrast the feed will actually use.
  static const darkTextThemeIds = {'2', '5', '9', '12', '14'};

  String? _themeId;

  /// Null when the feed is on its plain background rather than a photo.
  String? get themeId => _themeId;

  String? get imagePath =>
      _themeId == null ? null : 'assets/themes/$_themeId.png';

  bool get usesDarkText =>
      _themeId != null && darkTextThemeIds.contains(_themeId);

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(feedBackgroundPreferenceKey);
  }

  Future<void> select(String? themeId) async {
    if (_themeId == themeId) return;
    _themeId = themeId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (themeId == null) {
      await prefs.remove(feedBackgroundPreferenceKey);
    } else {
      await prefs.setString(feedBackgroundPreferenceKey, themeId);
    }
  }
}
