import 'package:shared_preferences/shared_preferences.dart';

/// Where one kind of settings is kept. Each cubit holds its own, bound to the
/// preferences key it owns, so nothing else has to know that key exists.
class ConfigStorage {
  final String key;

  const ConfigStorage(this.key);

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
