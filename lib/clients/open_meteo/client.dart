import 'package:flutter/material.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/open_meteo/provider.dart';
import 'package:nexus/clients/open_meteo/settings.dart';
import 'package:nexus/utils/settings_section.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/shared_preferences_state.dart';
import 'package:nexus/providers/state.dart';
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

    return OpenMeteoConfig(
        lat: double.parse(parts[0]), long: double.parse(parts[1]));
  }
}

class OpenMeteoWeatherClient {
  late StateProvider<OpenMeteoConfig> _configStateProvider;
  late WeatherStateProvider _weatherStateProvider;

  OpenMeteoWeatherClient() {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: OpenMeteoConfig(lat: 50.4375, long: 30.5),
      preferencesKey: 'OPEN_METEO_CONFIG',
      serialize: OpenMeteoConfig.serialize,
      deserialize: OpenMeteoConfig.deserialize,
    );

    _configStateProvider.init();

    _weatherStateProvider = OpenMeteoWeatherStateProvider(
        configStateProvider: _configStateProvider);

    _weatherStateProvider.init();
  }

  WeatherStateProvider getStateProvider() {
    return _weatherStateProvider;
  }

  final GlobalKey<State> _settingsKey = GlobalKey<State>();

  SettingsItem makeSettings() {
    return SettingsItem.details(
        icon: GenericIcon.fromIcon(icon: Icons.cloud),
        name: 'Open Meteo',
        details: DetailsPage(
            title: Text('Open Meteo Settings'),
            actions: [SettingsSaveButton(_settingsKey)],
            body: OpenMeteoConfigWidget(
              key: _settingsKey,
              stateProvider: _configStateProvider,
            )));
  }
}
