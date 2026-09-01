import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/config/config_storage.dart';

class HomeAssistantConfigCubit extends Cubit<HomeAssistantConfig> {
  final _storage = const ConfigStorage('HOME_ASSISTANT_CONFIG');

  HomeAssistantConfigCubit()
      : super(HomeAssistantConfig(token: '', url: 'https://192.168.1.209:8443')) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _storage.read();

    if (stored == null) return;

    // Settings written by an older build can stop parsing; the default stands.
    final config = HomeAssistantConfig.deserialize(stored);

    if (config != null) emit(config);
  }

  void save(HomeAssistantConfig config) {
    emit(config);
    _storage.write(HomeAssistantConfig.serialize(config));
  }
}

class AndroidConfigCubit extends Cubit<AndroidConfig> {
  final _storage = const ConfigStorage('ANDROID_CONFIG');

  AndroidConfigCubit() : super(AndroidConfig()) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _storage.read();

    if (stored == null) return;

    final config = AndroidConfig.deserialize(stored);

    if (config != null) emit(config);
  }

  void save(AndroidConfig config) {
    emit(config);
    _storage.write(AndroidConfig.serialize(config));
  }
}

class OpenMeteoConfigCubit extends Cubit<OpenMeteoConfig> {
  final _storage = const ConfigStorage('OPEN_METEO_CONFIG');

  OpenMeteoConfigCubit() : super(OpenMeteoConfig(lat: 50.4375, long: 30.5)) {
    _load();
  }

  Future<void> _load() async {
    final stored = await _storage.read();

    if (stored == null) return;

    final config = OpenMeteoConfig.deserialize(stored);

    if (config != null) emit(config);
  }

  void save(OpenMeteoConfig config) {
    emit(config);
    _storage.write(OpenMeteoConfig.serialize(config));
  }
}
