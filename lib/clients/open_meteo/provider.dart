import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/weather.dart';
import 'package:open_meteo/open_meteo.dart';

class OpenMeteoWeatherStateProvider extends WeatherStateProvider {
  final StateProvider<OpenMeteoConfig> configStateProvider;
  OpenMeteoConfig? _config;
  Timer? _timer;

  OpenMeteoWeatherStateProvider({required this.configStateProvider});

  void _onConfigChanged(OpenMeteoConfig? config) {
    _config = config;

    _timer?.cancel();
    fetchWeatherData().then((_) {
      _timer = Timer.periodic(
          Duration(seconds: 30), (Timer t) async => await fetchWeatherData());
    });
  }

  @override
  void init() {
    super.init();

    configStateProvider.bindValueChanged(_onConfigChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();

    configStateProvider.unbind(_onConfigChanged);
    super.dispose();
  }

  Future<void> fetchWeatherData() async {
    final config = _config;

    if (config == null) {
      setValue(null);
      return;
    }

    try {
      final weather = WeatherApi();
      final response = await weather.request(
          latitude: config.lat,
          longitude: config.long,
          current: {
            WeatherCurrent.weather_code,
            WeatherCurrent.temperature_2m
          },
          daily: {
            WeatherDaily.temperature_2m_min,
            WeatherDaily.temperature_2m_max
          });

      setValue(WeatherState(
        icon: getWeatherIcon(
            response.currentData[WeatherCurrent.weather_code]?.value),
        temperature:
            response.currentData[WeatherCurrent.temperature_2m]?.value ?? 0,
        maximumTemperature: response.dailyData[WeatherDaily.temperature_2m_max]
                ?.values.entries.first.value
                .toDouble() ??
            0,
        minimalTemperature: response.dailyData[WeatherDaily.temperature_2m_min]
                ?.values.entries.first.value
                .toDouble() ??
            0,
      ));
    } catch (e) {
      setValue(null);
    }
  }

  IconData getWeatherIcon(double? wmo) {
    if (wmo == null) return Icons.error;

    switch (wmo.toInt()) {
      case 0:
        return Icons.wb_sunny; // Clear sky
      case 1:
      case 2:
      case 3:
        return Icons.wb_cloudy; // Partly cloudy
      case 4:
      case 5:
      case 6:
      case 7:
        return Icons.cloud_queue; // Mostly cloudy
      case 8:
        return Icons.cloud; // Overcast
      case 9:
      case 10:
        return Icons.grain; // Light rain showers
      case 11:
        return Icons.umbrella; // Rain showers
      case 12:
      case 13:
        return Icons.ac_unit; // Snow or sleet
      case 14:
      case 15:
      case 16:
      case 17:
        return Icons.flash_on; // Thunderstorms
      case 18:
      case 19:
        return Icons.foggy; // Fog or mist
      default:
        return Icons.error; // Unhandled WMO code
    }
  }
}
