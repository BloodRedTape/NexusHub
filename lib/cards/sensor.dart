import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';

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

class SmallSensorCard extends StateCard<double> {
  final IconData icon;
  final String Function(double) formatter;

  const SmallSensorCard({required super.stateProvider, required this.icon, required this.formatter});

  @override
  Widget build(BuildContext context, double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return BaseCard(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: cardPadding * 0.25),
            Text(formatter(state), style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
