import 'package:flutter/material.dart';
import 'package:nexus/cards/switch.dart';

class HumidifierCard extends SwitchCard {
  HumidifierCard({required super.stateProvider, required super.room})
      : super(
          onIcon: Icons.wind_power,
          offIcon: Icons.mode_fan_off,
          onColor: const Color.fromARGB(255, 2, 82, 128),
        );
}
