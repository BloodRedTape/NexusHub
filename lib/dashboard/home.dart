import 'package:flutter/material.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/cards/light_switch.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/temperature.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';

import 'package:nexus/cards/curtain.dart';
import 'package:nexus/providers/state.dart';

void MakeSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ExpandedRow(children: [
            TemperatureCard(
                stateProvider: DummyStateProvider(initialValue: 21.3),
                room: 'Master'),
            TemperatureCard(
                stateProvider: DummyStateProvider(initialValue: 20.1),
                room: 'Bedroom'),
          ]),
          ExpandedRow(children: [
            CurtainCard(
                name: 'Left Curtain',
                stateProvider: DummyStateProvider(initialValue: 0.5)),
            CurtainCard(
                name: 'RightCurtain',
                stateProvider: DummyStateProvider(initialValue: 0.5)),
          ])
        ]),
        ExpandedColumn(children: [
          ExpandedRow(children: [
            ActionCard(
              name: 'Find My',
              icon: Icons.phone_iphone,
              action: () => MakeSnackBar(context, 'Pinged anna'),
            ),
            ActionCard(
              name: 'Scene',
              icon: Icons.movie,
              action: () => MakeSnackBar(context, 'Set scenario to movie'),
            )
          ]),
          ExpandedRow(
            children: [
              LightSwitchCard(
                  stateProvider: DummyStateProvider<bool>(initialValue: true),
                  name: 'Bulbs',
                  room: 'Master'),
              LightSwitchCard(
                  stateProvider: DummyStateProvider<bool>(initialValue: true),
                  name: 'Bulb',
                  room: 'Toilet'),
            ],
          )
        ])
      ],
    );
  }
}
