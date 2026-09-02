import 'package:flutter/material.dart';
import 'package:nexus/utils/weather_icons.dart';

/// What the sky is doing, as far as the card cares. Built from a WMO weather
/// interpretation code - the scale Open-Meteo reports - and the single place
/// that decides how each kind of weather looks.
enum WeatherKind {
  clear(WeatherIcons.day_sunny, 'Clear', [Color(0xFF2C6BB5), Color(0xFF5AAEE8)]),
  partlyCloudy(WeatherIcons.day_cloudy, 'Partly Cloudy', [Color(0xFF3C6D9E), Color(0xFF7BB0DA)]),
  cloudy(WeatherIcons.cloudy, 'Cloudy', [Color(0xFF44525F), Color(0xFF7E8E9C)]),
  fog(WeatherIcons.fog, 'Fog', [Color(0xFF525860), Color(0xFF8E959C)]),
  drizzle(WeatherIcons.sprinkle, 'Drizzle', [Color(0xFF365070), Color(0xFF6A8FB0)]),
  rain(WeatherIcons.rain, 'Rain', [Color(0xFF2A3E52), Color(0xFF57768F)]),
  showers(WeatherIcons.showers, 'Showers', [Color(0xFF2E4763), Color(0xFF5C81A6)]),
  freezingRain(WeatherIcons.rain_mix, 'Freezing Rain', [Color(0xFF35566B), Color(0xFF6D9DB2)]),
  snow(WeatherIcons.snow, 'Snow', [Color(0xFF5E7186), Color(0xFFA9BDCE)]),
  thunderstorm(WeatherIcons.thunderstorm, 'Thunderstorm', [Color(0xFF1F2833), Color(0xFF465569)]),
  hail(WeatherIcons.hail, 'Hail', [Color(0xFF32475C), Color(0xFF7089A2)]),
  unknown(Icons.error, 'Unavailable', [Color(0xFF44525F), Color(0xFF7E8E9C)]);

  final IconData icon;

  /// Names the sky in a word, for anywhere an icon alone is too vague.
  final String label;
  final List<Color> gradient;

  const WeatherKind(this.icon, this.label, this.gradient);

  /// WMO code table as Open-Meteo reports it. Codes outside these groups do not
  /// occur in its forecasts.
  static WeatherKind fromWmo(double? wmo) {
    if (wmo == null) return WeatherKind.unknown;

    switch (wmo.toInt()) {
      case 0:
        return WeatherKind.clear;
      case 1:
      case 2:
        return WeatherKind.partlyCloudy;
      case 3:
        return WeatherKind.cloudy;
      case 45:
      case 48:
        return WeatherKind.fog;
      case 51:
      case 53:
      case 55:
        return WeatherKind.drizzle;
      case 56:
      case 57:
      case 66:
      case 67:
        return WeatherKind.freezingRain;
      case 61:
      case 63:
      case 65:
        return WeatherKind.rain;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return WeatherKind.snow;
      case 80:
      case 81:
      case 82:
        return WeatherKind.showers;
      case 95:
        return WeatherKind.thunderstorm;
      case 96:
      case 99:
        return WeatherKind.hail;
      default:
        return WeatherKind.unknown;
    }
  }
}

/// One hour of the forecast.
class WeatherHour {
  final DateTime time;
  final WeatherKind kind;
  final double temperature;

  const WeatherHour({
    required this.time,
    required this.kind,
    required this.temperature,
  });

  IconData get icon => kind.icon;
}

/// One day of the forecast.
class WeatherDay {
  final DateTime date;
  final WeatherKind kind;
  final double minimalTemperature;
  final double maximumTemperature;
  /// Chance of rain over the day, 0..100. Null when the API did not report it.
  final double? precipitationChance;

  const WeatherDay({
    required this.date,
    required this.kind,
    required this.minimalTemperature,
    required this.maximumTemperature,
    this.precipitationChance,
  });

  IconData get icon => kind.icon;
  String get label => kind.label;
}

class Weather {
  final WeatherKind kind;
  final double temperature;
  final double minimalTemperature;
  final double maximumTemperature;

  /// Today first. Empty when only the current conditions came back.
  final List<WeatherDay> forecast;

  /// The coming hours, earliest first. Hours already past are dropped upstream.
  final List<WeatherHour> hourly;

  const Weather(
      {required this.kind,
      required this.temperature,
      required this.maximumTemperature,
      required this.minimalTemperature,
      this.forecast = const [],
      this.hourly = const []});

  IconData get icon => kind.icon;
  String get label => kind.label;
  List<Color> get gradient => kind.gradient;

  /// Coldest low and warmest high across the forecast - the scale every day's
  /// range bar is drawn against, so the bars are comparable between rows.
  double get forecastMinimum =>
      forecast.map((d) => d.minimalTemperature).reduce((a, b) => a < b ? a : b);
  double get forecastMaximum =>
      forecast.map((d) => d.maximumTemperature).reduce((a, b) => a > b ? a : b);
}

