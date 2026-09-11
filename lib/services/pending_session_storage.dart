import 'package:get_storage/get_storage.dart';

class PendingSessionStorage {
  static const _boxName = 'pending_sessions';
  static GetStorage? _box;

  static Future<void> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
  }

  static GetStorage get _storage {
    _box ??= GetStorage(_boxName);
    return _box!;
  }

  static Future<void> saveDraft(String key, Map<String, dynamic> data) async {
    await _storage.write(key, data);
  }

  static Future<void> removeDraft(String key) async {
    await _storage.remove(key);
  }

  static List<Map<String, dynamic>> getAllDrafts() {
    final keys = _storage.getKeys<Iterable<String>>();
    final result = <Map<String, dynamic>>[];
    for (final k in keys) {
      final v = _storage.read(k);
      if (v != null) {
        result.add(Map<String, dynamic>.from(v as Map));
      }
    }
    return result;
  }
}