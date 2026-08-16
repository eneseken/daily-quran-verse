import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppIconService {
  const AppIconService._();

  static const _channel = MethodChannel('com.muslim.pro/app_icon');
  static const _prefKey = 'selected_app_icon';

  static Future<String> currentIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? '1';
  }

  static Future<void> setIcon(String id) async {
    await _channel.invokeMethod<void>('setIcon', {'id': id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }
}
