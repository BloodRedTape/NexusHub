import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nexus/cards/switch.dart';

class HumidifierCard extends SwitchCard {
  HumidifierCard({required super.stateProvider, required super.room})
      : super(
          onIcon: MdiIcons.fan,
          offIcon: MdiIcons.fanOff,
          onColor: const Color.fromARGB(255, 2, 82, 128),
        );
}
