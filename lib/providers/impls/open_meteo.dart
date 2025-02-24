import 'dart:async';

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:nexus/providers/weather.dart';
import 'package:open_meteo/open_meteo.dart';

class OpenMeteo extends WeatherStateProvider {
  final double lat;
  final double long;
  Timer? _timer;

  OpenMeteo({required this.lat, required this.long});

  @override
  void onBound() {
    super.onBound();

    fetchWeatherData();

    _timer = Timer.periodic(
        Duration(seconds: 30), (Timer t) async => await fetchWeatherData());
  }

  @override
  void onUnbound() {
    _timer?.cancel();
  }

  Future<void> fetchWeatherData() async {
    try {
      final weather = WeatherApi();
      final response = await weather.request(
          latitude: lat,
          longitude: long,
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
        return WeatherIcons.day_sunny; // Clear sky
      case 1:
      case 2:
      case 3:
        return WeatherIcons.day_cloudy; // Partly cloudy
      case 4:
      case 5:
      case 6:
      case 7:
        return WeatherIcons.cloud; // Mostly cloudy
      case 8:
        return WeatherIcons.cloudy; // Overcast
      case 9:
      case 10:
        return WeatherIcons.showers; // Light rain showers
      case 11:
        return WeatherIcons.rain; // Rain showers
      case 12:
      case 13:
        return WeatherIcons.snow; // Snow or sleet
      case 14:
      case 15:
      case 16:
      case 17:
        return WeatherIcons.thunderstorm; // Thunderstorms
      case 18:
      case 19:
        return WeatherIcons.fog; // Fog or mist
      default:
        return Icons.error; // Unhandled WMO code
    }
  }
}
