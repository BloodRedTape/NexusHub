import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where one kind of settings is kept. Each cubit holds its own, bound to the
/// preferences key it owns, so nothing else has to know that key exists.
class ConfigStorage {
  final String key;

  const ConfigStorage(this.key);

  Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);

    if (stored == null || stored.isEmpty) return null;

    try {
      final decoded = jsonDecode(stored);

      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }
}
