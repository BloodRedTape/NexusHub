import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/ha/sensor.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/clients/state.dart';

/// A motion sensor: whether the room is busy, and how bright it is.
class MotionCard extends StateCard<bool> {
  final StateProvider<double> illuminance;
  final String? name;

  const MotionCard({required super.stateProvider, required this.illuminance, this.name});

  @override
  Widget build(BuildContext context, bool? occupied) {
    return PlainCardBase(
      icon: Icon(occupied == true ? Icons.directions_walk : Icons.sensors, size: iconSize),
      children: [
        StackedLayout(
          primary: FittedBox(
            alignment: Alignment.bottomLeft,
            fit: BoxFit.scaleDown,
            child: Text(_text(occupied), style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)),
          ),
          secondary: Reading(stateProvider: illuminance, formatter: Formatter.illuminance),
          name: name,
        ),
      ],
    );
  }

  String _text(bool? occupied) {
    if (occupied == null) return 'Unavailable';

    return occupied ? 'Occupied' : 'Clear';
  }
}
