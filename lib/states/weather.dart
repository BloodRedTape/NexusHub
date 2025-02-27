import 'package:flutter/material.dart';
import 'package:nexus/providers/state.dart';

class WeatherState {
  final IconData icon;
  final double temperature;
  final double minimalTemperature;
  final double maximumTemperature;

  const WeatherState(
      {required this.icon,
      required this.temperature,
      required this.maximumTemperature,
      required this.minimalTemperature});
}

typedef WeatherStateProvider = StateProvider<WeatherState>;
