import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const feedBackgroundPreferenceKey = 'feed_background_theme_id';
const feedBackgroundTextOverridesKey = 'feed_background_text_overrides';

/// Which of the Customize screen's background photos (if any) currently
/// replaces the feed's plain background. Mirrors AppThemeController's shape:
/// an in-memory current value, persisted to SharedPreferences, notifying
/// listeners on change.
class FeedBackgroundController extends ChangeNotifier {
  FeedBackgroundController._();

  static final instance = FeedBackgroundController._();

  /// Theme ids whose photo reads light overall, so verse text needs to sit
  /// in dark ink rather than the usual light-on-photo white by default. Kept
  /// as the one source of truth CustomizeScreen's tile preview also reads,
  /// so the picker always shows the same contrast the feed will actually
  /// use. Per-theme, per-user overrides (see [textOverrideFor]) always win
  /// over this default.
  static const darkTextThemeIds = {'3', '5', '9', '12', '14'};

  String? _themeId;

  /// User-picked text color per theme id, keyed by theme id, value is
  /// `true` for dark text / `false` for light text. A theme with no entry
  /// here falls back to [darkTextThemeIds].
  Map<String, bool> _textOverrides = {};

  /// Null when the feed is on its plain background rather than a photo.
  String? get themeId => _themeId;

  String? get imagePath =>
      _themeId == null ? null : 'assets/themes/$_themeId.png';

  bool get usesDarkText => _themeId != null && darkTextFor(_themeId!);

  /// Whether [id] renders dark verse text, honoring a manual override if
  /// the user set one on the Customize screen, else the built-in default.
  bool darkTextFor(String id) =>
      _textOverrides[id] ?? darkTextThemeIds.contains(id);

  /// The manual override for [id], if any. Null means "use the default".
  bool? textOverrideFor(String id) => _textOverrides[id];

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString(feedBackgroundPreferenceKey);

    final rawOverrides = prefs.getString(feedBackgroundTextOverridesKey);
    if (rawOverrides != null) {
      try {
        final decoded = jsonDecode(rawOverrides) as Map<String, dynamic>;
        _textOverrides = decoded.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {
        _textOverrides = {};
      }
    }
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

  /// Sets (or clears, when [darkText] is null) the manual verse-text color
  /// for theme [id] — the two dots on the selected Customize tile.
  Future<void> setTextOverride(String id, bool? darkText) async {
    if (darkText == null) {
      _textOverrides.remove(id);
    } else {
      _textOverrides[id] = darkText;
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      feedBackgroundTextOverridesKey,
      jsonEncode(_textOverrides),
    );
  }
}
