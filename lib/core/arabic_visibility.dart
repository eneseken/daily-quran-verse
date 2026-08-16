import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Arabic ayah text renders on the home feed. Mirrors
/// FeedBackgroundController's shape: in-memory current value, notifies
/// listeners on change, persisted locally via SharedPreferences — this is a
/// per-device display preference (like the feed background), not a
/// per-account one, so it doesn't go through Supabase like
/// QuranLanguageController's language code does.
class ArabicVisibilityController extends ChangeNotifier {
  ArabicVisibilityController._();

  static final instance = ArabicVisibilityController._();

  static const _prefsKey = 'show_arabic_text';

  bool _showArabic = true;

  bool get showArabic => _showArabic;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _showArabic = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setShowArabic(bool value) async {
    if (_showArabic == value) return;
    _showArabic = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
