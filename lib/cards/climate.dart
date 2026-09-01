import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';

/// Temperature and humidity of one device on a single card.
class ClimateCard extends StatelessWidget {
  final StateProvider<double> temperature;
  final StateProvider<double> humidity;
  final String? name;

  const ClimateCard({super.key, required this.temperature, required this.humidity, this.name});

  @override
  Widget build(BuildContext context) {
    return PlainCardBase(
      icon: Icon(Icons.thermostat, size: iconSize),
      children: [
        StackedLayout(
          primary: Reading(stateProvider: temperature, formatter: Formatter.tempearture, primary: true),
          secondary: Reading(stateProvider: humidity, formatter: Formatter.humidity),
          name: name,
        ),
      ],
    );
  }
}
