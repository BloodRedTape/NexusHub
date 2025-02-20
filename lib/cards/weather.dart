import 'package:flutter/material.dart';
import 'package:nexus/core/details_card.dart';
import 'package:nexus/widgets/token_input_widget.dart';
import 'package:open_weather_client/open_weather.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherWidget extends StatelessWidget {
  final String location;
  final String temperature;
  final String weatherDescription;
  final IconData weatherIcon;

  WeatherWidget({
    required this.location,
    required this.temperature,
    required this.weatherDescription,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          location,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Icon(
          weatherIcon,
          size: 46,
          color: Colors.blue,
        ),
        SizedBox(height: 10),
        Text(
          temperature,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          weatherDescription,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class WeatherCard extends StatefulWidget {
  static const String apiTokenKey = 'OPEN_WEATHER_MAP_TOKEN';
  final String city;

  WeatherCard({required this.city});

  @override
  _WeatherCardState createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late String location;
  late String temperature;
  late String weatherDescription;
  late IconData weatherIcon;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    setErrorState();

    fetchWeatherData();

    _timer = Timer.periodic(
        Duration(seconds: 30), (Timer t) async => await fetchWeatherData());
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  Future<void> fetchWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(WeatherCard.apiTokenKey);

      OpenWeather openWeather = OpenWeather(apiKey: token!);

      WeatherData weatherData = await openWeather.currentWeatherByCityName(
          cityName: widget.city, weatherUnits: WeatherUnits.METRIC);

      setSuccessState(weatherData);
    } catch (e) {
      setErrorState();
    }
  }

  void setSuccessState(WeatherData data) {
    if (!mounted) return;
    setState(() {
      location = widget.city;
      temperature = '${data.temperature.currentTemperature}°C';
      weatherDescription = data.details.first.weatherShortDescription;
      weatherIcon = _mapWeatherConditionToIcon(weatherDescription);
    });
  }

  void setErrorState() {
    if (!mounted) return;
    setState(() {
      location = 'Error';
      temperature = 'N/A';
      weatherDescription = 'Unable to fetch weather';
      weatherIcon = Icons.error;
    });
  }

  IconData _mapWeatherConditionToIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
        details: DetailsPage(
            body:
                const TokenInputWidget(preferencesKey: WeatherCard.apiTokenKey),
            title: Text('Weather Settings')),
        child: Center(
            child: WeatherWidget(
          location: location,
          temperature: temperature,
          weatherDescription: weatherDescription,
          weatherIcon: weatherIcon,
        )));
  }
}
