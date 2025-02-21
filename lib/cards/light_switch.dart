import 'package:flutter/material.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/providers/value.dart';

class LightSwitchCard extends StatelessWidget {
  final ValueStateProvider<bool> stateProvider;
  final String? name;
  final String? room;

  LightSwitchCard({required this.stateProvider, this.name, this.room});

  @override
  Widget build(BuildContext context) {
    return SwitchCard(
      childFactory: buildChild,
      stateProvider: stateProvider,
    );
  }

  Widget buildChild(bool? state) {
    List<Widget> widgets = [
      Icon(icon(state), size: 64, color: iconColor(state)),
    ];

    if (name != null) {
      widgets.add(SizedBox(height: 8));
      widgets.add(Text(
        name!,
        style: TextStyle(fontSize: 20),
      ));
    }
    if (room != null) {
      widgets.add(SizedBox(height: 8));
      widgets.add(Text(
        room!,
        style: TextStyle(fontSize: 20),
      ));
    }

    return Center(
      child: Column(
        children: widgets,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
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
