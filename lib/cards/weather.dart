import 'package:flutter/material.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/providers/weather.dart';
import 'package:nexus/utils/token_input_widget.dart';
import 'package:open_weather_client/open_weather.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherCard extends StateCard<WeatherState> {
  WeatherCard() : super(stateProvider: OpenWeatherMap(city: 'kyiv'));

  @override
  Widget build(BuildContext context, WeatherState? state) {
    final details = DetailsPage(
        body:
            const TokenInputWidget(preferencesKey: OpenWeatherMap.apiTokenKey),
        title: Text('Weather Settings'));

    if (state == null)
      return PlainCard(
        icon: Icons.error,
        text: 'Unavailable',
        action: () => details.navigateTo(context),
      );

    return DetailsCard(
        details: details,
        child: buildGradient(Padding(
            padding: EdgeInsets.all(30),
            child: buildCardContent(context, state))));
  }

  Widget buildGradient(Widget child) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.7),
              const Color.fromARGB(255, 122, 213, 255).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child);
  }

  Widget buildCardContent(BuildContext context, WeatherState state) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(state.icon, size: 48),
        ),
        SizedBox(height: 10),
        Text(
          '${state.temperature.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${state.minimalTemperature.toStringAsFixed(1)}° ${state.maximumTemperature.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 28,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

class OpenWeatherMap extends WeatherStateProvider {
  static const String apiTokenKey = 'OPEN_WEATHER_MAP_TOKEN';
  final String city;
  Timer? _timer;

  OpenWeatherMap({required this.city});

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
