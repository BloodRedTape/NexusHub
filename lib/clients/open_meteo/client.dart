import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/clients/open_meteo/settings.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/clients/config_storage.dart';
import 'package:nexus/clients/open_meteo/models.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/utils/generic_icon.dart';
import 'package:open_meteo/open_meteo.dart';

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
  static const _pollInterval = Duration(seconds: 30);

  final _storage = const ConfigStorage('OPEN_METEO_CONFIG');
  final _weather = WeatherStateProvider();

  OpenMeteoConfig _config = _fallback;
  Timer? _timer;

  OpenMeteoConfig get config => _config;

  OpenMeteoWeatherClient() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final stored = await _storage.read();

    // Settings written by an older build can stop parsing; the default stands.
    final loaded = stored == null ? null : OpenMeteoConfig.deserialize(stored);

    if (loaded != null) _config = loaded;

    _restartPolling();
  }

  void saveConfig(OpenMeteoConfig config) {
    _config = config;

    _storage.write(OpenMeteoConfig.serialize(config));
    _restartPolling();
  }

  /// Every coordinate change restarts the polling so the card does not keep
  /// showing the old location for up to a full interval.
  void _restartPolling() {
    _timer?.cancel();
    _fetch().then((_) {
      _timer = Timer.periodic(_pollInterval, (_) => _fetch());
    });
  }

  Future<void> _fetch() async {
    try {
      final response = await WeatherApi().request(
          latitude: _config.lat,
          longitude: _config.long,
          current: {WeatherCurrent.weather_code, WeatherCurrent.temperature_2m},
          hourly: {WeatherHourly.temperature_2m, WeatherHourly.weather_code},
          daily: {WeatherDaily.temperature_2m_min, WeatherDaily.temperature_2m_max, WeatherDaily.weather_code, WeatherDaily.precipitation_probability_max});

      final forecast = _buildForecast(response);

      _weather.setValue(Weather(
        kind: WeatherKind.fromWmo(response.currentData[WeatherCurrent.weather_code]?.value),
        temperature: response.currentData[WeatherCurrent.temperature_2m]?.value ?? 0,
        maximumTemperature: forecast.isEmpty ? 0 : forecast.first.maximumTemperature,
        minimalTemperature: forecast.isEmpty ? 0 : forecast.first.minimalTemperature,
        forecast: forecast,
        hourly: _buildHourly(response),
      ));
    } catch (e) {
      _weather.setValue(null);
    }
  }

  // Only the hours still ahead are worth showing. The API returns the whole
  // day including hours already past, so the list is cut at the current hour.
  List<WeatherHour> _buildHourly(ApiResponse<WeatherApi> response) {
    final temperature = response.hourlyData[WeatherHourly.temperature_2m]?.values;
    if (temperature == null) return [];

    final codes = response.hourlyData[WeatherHourly.weather_code]?.values;
    final hour = DateTime.now();
    final times = temperature.keys.where((t) => !t.isBefore(hour.subtract(const Duration(hours: 1)))).toList()..sort();

    return [
      for (final time in times)
        WeatherHour(
          time: time,
          kind: WeatherKind.fromWmo(codes?[time]?.toDouble()),
          temperature: temperature[time]!.toDouble(),
        )
    ];
  }

  // The daily rows arrive as separate date->value maps. They are keyed by date
  // rather than zipped by position: a row the API left short would otherwise
  // shift every following day onto the wrong date.
  List<WeatherDay> _buildForecast(ApiResponse<WeatherApi> response) {
    final max = response.dailyData[WeatherDaily.temperature_2m_max]?.values;
    if (max == null) return [];

    final min = response.dailyData[WeatherDaily.temperature_2m_min]?.values;
    final codes = response.dailyData[WeatherDaily.weather_code]?.values;
    final rain = response.dailyData[WeatherDaily.precipitation_probability_max]?.values;

    final days = max.keys.toList()..sort();

    return [
      for (final date in days)
        WeatherDay(
          date: date,
          kind: WeatherKind.fromWmo(codes?[date]?.toDouble()),
          maximumTemperature: max[date]!.toDouble(),
          minimalTemperature: min?[date]?.toDouble() ?? max[date]!.toDouble(),
          precipitationChance: rain?[date]?.toDouble(),
        )
    ];
  }

  WeatherStateProvider getStateProvider() {
    return _weather;
  }

  void dispose() {
    _timer?.cancel();
    _weather.dispose();
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

typedef WeatherStateProvider = StateProvider<Weather>;
