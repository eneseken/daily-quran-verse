import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoService extends ChangeNotifier {
  ProfilePhotoService._();

  static final instance = ProfilePhotoService._();

  static const _pathKey = 'profile_photo_path';

  final ImagePicker _picker = ImagePicker();
  String? _path;
  bool _restored = false;

  String? get path => _path;

  Future<void> restore() async {
    if (_restored) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pathKey);
    if (stored != null && await File(stored).exists()) {
      _path = stored;
    } else if (stored != null) {
      await prefs.remove(_pathKey);
    }
    _restored = true;
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 88,
      );
      if (picked == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final extension = p.extension(picked.path).isNotEmpty
          ? p.extension(picked.path)
          : '.jpg';
      final target = File(
        p.join(
          directory.path,
          'profile_photo_${DateTime.now().millisecondsSinceEpoch}$extension',
        ),
      );

      final saved = await File(picked.path).copy(target.path);
      final oldPath = _path;
      _path = saved.path;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pathKey, saved.path);

      if (oldPath != null && oldPath != saved.path) {
        unawaited(_deleteOldPhoto(oldPath));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Profile photo pick failed: $e');
    }
  }

  Future<void> _deleteOldPhoto(String oldPath) async {
    try {
      final file = File(oldPath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
