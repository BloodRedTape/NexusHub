import 'package:nexus/providers/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStateProvider<T> extends StateProvider<T> {
  final T initialValue;
  final String preferencesKey;
  final String Function(T?) serialize;
  final T? Function(String) deserialize;

  SharedPreferencesStateProvider(
      {required this.initialValue,
      required this.preferencesKey,
      required this.serialize,
      required this.deserialize});

  @override
  void init() {
    loadValue().then((value) => setValue(value ?? initialValue));
  }

  @override
  void setValue(T? value) {
    super.setValue(value);
    saveValue(value);
  }

  void saveValue(T? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferencesKey, serialize(value));
  }

  Future<T?> loadValue() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(preferencesKey);

    if (value == null) return null;

    return deserialize(value);
  }
}
