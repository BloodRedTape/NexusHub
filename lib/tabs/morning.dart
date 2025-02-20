import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/core/expanded_row.dart';
import 'package:nexus/core/expanded_column.dart';

import 'package:nexus/cards/weather.dart';
import 'package:nexus/core/switch_card.dart';

class LightSwitchCard extends StatelessWidget {
  final SwitchStateProvider stateProvider;
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

    return Icons.lightbulb;
  }

  Color iconColor(bool? state) {
    if (state == null) {
      return Colors.white;
    }

    return state ? Colors.yellow : Colors.white;
  }
}

class MorningTab extends StatelessWidget {
  const MorningTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ClockCard(),
          WeatherCard(
            city: 'kyiv',
          ),
        ]),
        ExpandedColumn(children: [
          CalendarCard(),
          ExpandedRow(
            children: [
              LightSwitchCard(
                  stateProvider: DummySwitchStateProvider(),
                  name: 'Led',
                  room: 'Master'),
              AlarmCard()
            ],
          )
        ])
      ],
    );
  }
}
