import 'package:flutter/foundation.dart';

import '../services/quran_service.dart';

/// Languages offered in the picker. `quran_verses.translations` currently
/// only has rows for 'en' and 'tr' — QuranVerse.textFor() falls back to
/// English for the rest, so picking one of them shows the ayah translation
/// in English until that column is populated server-side. The UI copy
/// (AppStrings) is fully translated for all eight regardless, since that
/// doesn't depend on the Supabase data.
const supportedQuranLanguages = {
  'en': 'English',
  'tr': 'Türkçe',
  'ar': 'العربية',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'ur': 'اردو',
  'id': 'Bahasa Indonesia',
};

/// Which language the Arabic's translation renders in on the feed. Mirrors
/// FeedBackgroundController's shape (in-memory current value, notifies
/// listeners on change) but persists through QuranService/Supabase
/// (`profiles.preferred_language`) rather than SharedPreferences, since it
/// was already a per-account setting before this controller existed.
class QuranLanguageController extends ChangeNotifier {
  QuranLanguageController._();

  static final instance = QuranLanguageController._();

  String _code = 'en';

  String get code => _code;

  /// Loads the signed-in user's saved preference. New accounts already have
  /// one written at sign-up (see detectDeviceLanguageCode in
  /// quran_service.dart), so this just reads it back. Safe to call
  /// repeatedly — HomeScreen already calls this as part of its own startup
  /// load.
  Future<void> restore() async {
    _code = await QuranService.instance.loadPreferredLanguage();
  }

  Future<void> select(String code) async {
    if (_code == code) return;
    _code = code;
    notifyListeners();
    await QuranService.instance.setPreferredLanguage(code);
  }
}
