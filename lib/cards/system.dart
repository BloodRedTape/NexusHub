import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';

/// A machine's vitals: load on top, memory and disk under it.
class SystemCard extends StatelessWidget {
  final StateProvider<double> processor;
  final StateProvider<double>? temperature;
  final StateProvider<double>? memory;
  final StateProvider<double>? disk;
  final String? name;

  const SystemCard({
    super.key,
    required this.processor,
    this.temperature,
    this.memory,
    this.disk,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return PlainCardBase(
      icon: Icon(Icons.memory, size: iconSize),
      children: [
        StackedLayout(
          primary: Reading(stateProvider: processor, formatter: Formatter.percent, primary: true),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: _details(),
          ),
          name: name,
        ),
      ],
    );
  }

  List<Widget> _details() {
    final parts = <Widget>[];

    void add(StateProvider<double>? provider, IconData icon) {
      if (provider == null) return;

      if (parts.isNotEmpty) parts.add(Text('  ', style: TextStyle(fontSize: secondaryTextSize)));

      parts.add(Icon(icon, size: secondaryTextSize));
      parts.add(const SizedBox(width: 4));
      parts.add(Reading(stateProvider: provider, formatter: Formatter.percent));
    }

    add(memory, Icons.developer_board);
    add(disk, Icons.storage);

    if (temperature != null) {
      if (parts.isNotEmpty) parts.add(Text('  ', style: TextStyle(fontSize: secondaryTextSize)));

      parts.add(Reading(stateProvider: temperature!, formatter: Formatter.tempearture));
    }

    return parts;
  }
}
