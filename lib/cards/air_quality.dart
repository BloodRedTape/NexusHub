import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';

/// Carbon dioxide with the particulate readings under it.
class AirQualityCard extends StatelessWidget {
  final StateProvider<double> carbonDioxide;
  final StateProvider<double> pm25;
  final StateProvider<double> pm10;
  final String? name;

  const AirQualityCard({
    super.key,
    required this.carbonDioxide,
    required this.pm25,
    required this.pm10,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return PlainCardBase(
      icon: Icon(Icons.air_sharp, size: iconSize),
      children: [
        StackedLayout(
          primary: Reading(stateProvider: carbonDioxide, formatter: Formatter.carbonDioxide, primary: true),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Reading(stateProvider: pm25, formatter: Formatter.particulate),
              Text(' · ', style: TextStyle(fontSize: secondaryTextSize)),
              Reading(stateProvider: pm10, formatter: Formatter.particulate),
            ],
          ),
          name: name,
        ),
      ],
    );
  }
}
