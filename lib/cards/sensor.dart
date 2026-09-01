import 'package:flutter/foundation.dart';
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

  static String particulate(double state) {
    return '${state.toInt()}µg';
  }

  static String carbonDioxide(double state) {
    return '${state.toInt()}';
  }
}

class Painter {
  static Color? none(double state) {
    return null;
  }

  static Color? Function(double) color(Color color) {
    return (_) => color;
  }

  static Color? carbonDioxide(double state) {
    if (state < 1000) return Colors.green;
    if (state < 1500) return const Color.fromARGB(255, 255, 210, 73);
    return Colors.red;
  }

  static Color? illuminance(double state) {
    double maxIlluminance = 1000;
    return HSVColor.fromAHSV(1.0, (clampDouble(state, 0, maxIlluminance) / maxIlluminance * 55.0) / 255.0, 0.5, 1.0).toColor();
  }

  static Color? aqi(double state) {
    if (state < 50) return Colors.green;
    if (state < 100.0) return Color.fromARGB(255, 255, 210, 73);
    if (state < 150.0) return Colors.orange;
    if (state < 200.0) return Colors.red;
    return Colors.purple;
  }
}

class SensorCard extends StateCard<double> {
  final IconData icon;
  final String Function(double) formatter;
  final Color? Function(double)? iconPainter;
  final String? room;
  final bool compact;

  const SensorCard({required super.stateProvider, required this.icon, required this.formatter, this.iconPainter, this.room, this.compact = false});

  @override
  Widget build(BuildContext context, double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return PlainCard(
      icon: icon,
      iconColor: iconPainter?.call(state),
      text: formatter(state),
      subText: room,
      compact: compact,
    );
  }
}
