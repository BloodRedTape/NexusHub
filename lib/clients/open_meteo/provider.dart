import 'dart:async';

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
          hourly: {
            WeatherHourly.temperature_2m,
            WeatherHourly.weather_code
          },
          daily: {
            WeatherDaily.temperature_2m_min,
            WeatherDaily.temperature_2m_max,
            WeatherDaily.weather_code,
            WeatherDaily.precipitation_probability_max
          });

      final forecast = _buildForecast(response);
      final hourly = _buildHourly(response);

      setValue(WeatherState(
        kind: WeatherKind.fromWmo(
            response.currentData[WeatherCurrent.weather_code]?.value),
        temperature:
            response.currentData[WeatherCurrent.temperature_2m]?.value ?? 0,
        maximumTemperature:
            forecast.isEmpty ? 0 : forecast.first.maximumTemperature,
        minimalTemperature:
            forecast.isEmpty ? 0 : forecast.first.minimalTemperature,
        forecast: forecast,
        hourly: hourly,
      ));
    } catch (e) {
      setValue(null);
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
    final rain =
        response.dailyData[WeatherDaily.precipitation_probability_max]?.values;

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
}
