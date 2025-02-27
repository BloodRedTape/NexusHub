import 'package:flutter/material.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';

class TemperatureCard extends StateCard<double> {
  final String? room;
  final DetailsPage? details;
  const TemperatureCard(
      {required super.stateProvider, this.room, this.details});

  @override
  Widget build(BuildContext context, double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    final subAction = details != null
        ? PlainAction(
            icon: Icons.settings,
            onTap: () => details?.navigateTo(context),
          )
        : null;

    return PlainCard(
      icon: Icons.thermostat,
      text: '$state°C',
      subText: room,
      subAction: subAction,
    );
  }
}
