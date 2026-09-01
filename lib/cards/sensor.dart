import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';

class Formatter {
  static String tempearture(double state) {
    return '${state}°';
  }

  static String humidity(double state) {
    return '${state.toInt()}%';
  }

  static String illuminance(double state) {
    return '${state.toInt()}lx';
  }

  static String aqi(double state) {
    return '${state.toInt()} AQI';
  }

  static String time(double state) {
    int minutes = ((state % 1) * 60).toInt();
    int hours = state.toInt();

    if (hours == 0) return '${minutes}m';

    if (minutes == 0) return '${hours}h';

    return '${hours}h ${minutes}m';
  }

  static String percent(double state) {
    return '${state.toInt()}%';
  }

  static String particulate(double state) {
    return '${state.toInt()}µg';
  }

  static String carbonDioxide(double state) {
    return '${state.toInt()}';
  }
}

class SensorCard extends StateCard<double> {
  final IconData icon;
  final String Function(double) formatter;
  final String? room;

  const SensorCard({required super.stateProvider, required this.icon, required this.formatter, this.room});

  @override
  Widget build(BuildContext context, double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return PlainCard(
      icon: icon,
      text: formatter(state),
      subText: room,
    );
  }
}
