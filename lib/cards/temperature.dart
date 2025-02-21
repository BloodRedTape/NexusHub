import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/cards/value.dart';
import 'package:nexus/providers/state.dart';

class TemperatureCard extends StateCard<double> {
  final String? room;
  const TemperatureCard({required super.stateProvider, this.room});

  @override
  Widget build(BuildContext context, double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return PlainCard(
      icon: Icons.thermostat,
      text: '$state°C',
      subText: room,
    );
  }
}
