import 'package:flutter/material.dart';
import 'package:nexus/clients/open_meteo/provider.dart';
import 'package:nexus/clients/open_meteo/settings.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/clients/config_storage.dart';
import 'package:nexus/states/weather.dart';
import 'package:nexus/utils/generic_icon.dart';

class OpenMeteoConfig {
  final double lat;
  final double long;

  OpenMeteoConfig({required this.lat, required this.long});

  static String serialize(OpenMeteoConfig? config) {
    if (config == null) return '';

    return '${config.lat}:${config.long}';
  }

  static OpenMeteoConfig? deserialize(String string) {
    final parts = string.split(':');

    if (parts.length != 2) return null;

    if (parts[0].isEmpty || parts[1].isEmpty) return null;

    return OpenMeteoConfig(lat: double.parse(parts[0]), long: double.parse(parts[1]));
  }
}

class OpenMeteoWeatherClient {
  static final _fallback = OpenMeteoConfig(lat: 50.4375, long: 30.5);

  final _storage = const ConfigStorage('OPEN_METEO_CONFIG');
  final _weatherStateProvider = OpenMeteoWeatherStateProvider();

  OpenMeteoConfig _config = _fallback;

  OpenMeteoConfig get config => _config;

  OpenMeteoWeatherClient() {
    _weatherStateProvider.init();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final stored = await _storage.read();

    // Settings written by an older build can stop parsing; the default stands.
    final loaded = stored == null ? null : OpenMeteoConfig.deserialize(stored);

    if (loaded != null) _config = loaded;

    _weatherStateProvider.setConfig(_config);
  }

  void saveConfig(OpenMeteoConfig config) {
    _config = config;

    _storage.write(OpenMeteoConfig.serialize(config));
    _weatherStateProvider.setConfig(config);
  }

  WeatherStateProvider getStateProvider() {
    return _weatherStateProvider;
  }

  void dispose() {
    _weatherStateProvider.dispose();
  }

  SettingsItem makeSettings() {
    return SettingsItem.action(
      icon: GenericIcon.fromIcon(icon: Icons.cloud),
      name: 'Open Meteo',
      action: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OpenMeteoSettingsPage()),
      ),
    );
  }
}
