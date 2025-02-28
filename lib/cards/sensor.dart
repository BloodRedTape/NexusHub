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
    return '${state.toInt()} h';
  }
}

class SensorCard extends StateCard<double> {
  final IconData icon;
  final String Function(double) formatter;
  final String? room;

  const SensorCard(
      {required super.stateProvider,
      required this.icon,
      required this.formatter,
      this.room});

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
