import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_weather_client/enums/weather_units.dart';
import 'package:open_weather_client/models/weather_data.dart';
import 'package:open_weather_client/services/open_weather_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:nexus/providers/weather.dart';

class OpenWeatherMap extends WeatherStateProvider {
  static const String apiTokenKey = 'OPEN_WEATHER_MAP_TOKEN';
  final String city;
  Timer? _timer;

  OpenWeatherMap({required this.city});

  @override
  void onBound() {
    super.onBound();

    fetchWeatherData().then((_) => {
          _timer = Timer.periodic(Duration(seconds: 30),
              (Timer t) async => await fetchWeatherData())
        });
  }

  @override
  void onUnbound() {
    _timer?.cancel();
  }

  Future<void> fetchWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(apiTokenKey);

      OpenWeather openWeather = OpenWeather(apiKey: token!);

      WeatherData weatherData = await openWeather.currentWeatherByCityName(
          cityName: city, weatherUnits: WeatherUnits.METRIC);

      setValue(WeatherState(
          icon: getWeatherIcon(weatherData.details.first.icon),
          temperature: weatherData.temperature.currentTemperature,
          maximumTemperature: weatherData.temperature.tempMax,
          minimalTemperature: weatherData.temperature.tempMin));
    } catch (e) {
      setValue(null);
    }
  }

  IconData getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return WeatherIcons.day_sunny;
      case '01n':
        return WeatherIcons.night_clear;
      case '02d':
        return WeatherIcons.day_cloudy;
      case '02n':
        return WeatherIcons.night_alt_cloudy;
      case '03d':
      case '03n':
        return WeatherIcons.cloud;
      case '04d':
      case '04n':
        return WeatherIcons.cloudy;
      case '09d':
      case '09n':
        return WeatherIcons.showers;
      case '10d':
        return WeatherIcons.day_rain;
      case '10n':
        return WeatherIcons.night_alt_rain;
      case '11d':
      case '11n':
        return WeatherIcons.thunderstorm;
      case '13d':
      case '13n':
        return WeatherIcons.snow;
      case '50d':
      case '50n':
        return WeatherIcons.fog;
      default:
        return Icons.error;
    }
  }
}
