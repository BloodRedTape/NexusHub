import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';

class LightSwitchCard extends StateCard<bool> {
  final String name;
  final String? room;

  LightSwitchCard(
      {required super.stateProvider, required this.name, this.room});

  @override
  Widget build(BuildContext context, bool? state) {
    return PlainCard(
        icon: icon(state),
        iconColor: iconColor(state),
        text: stateToText(state),
        subText: room,
        action: () => switchState(state));
  }

  void switchState(bool? state) {
    if (state == null) return;

    setState(!state);
  }

  String stateToText(bool? state) {
    if (state == null) return 'Unavailable';

    return state ? 'On' : 'Off';
  }

  IconData icon(bool? state) {
    if (state == null) {
      return Icons.info;
    }

    return state ? Icons.lightbulb : Icons.lightbulb_outline;
  }

  Color iconColor(bool? state) {
    if (state == null) {
      return Colors.white;
    }

    return state ? Colors.yellow : Colors.white;
  }
}
