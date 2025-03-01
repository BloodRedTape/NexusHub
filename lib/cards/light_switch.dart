import 'package:flutter/material.dart';
import 'package:nexus/cards/switch.dart';

class LightSwitchCard extends SwitchCard {
  LightSwitchCard(
      {required super.stateProvider,
      super.onIcon = Icons.lightbulb,
      super.offIcon = Icons.lightbulb_outline,
      super.onIconColor = Colors.yellow,
      super.offIconColor = Colors.white,
      super.onColor = const Color.fromARGB(255, 99, 78, 4),
      super.offColor,
      super.room});
}
