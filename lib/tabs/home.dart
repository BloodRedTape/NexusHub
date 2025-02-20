import 'package:flutter/material.dart';
import 'package:nexus/cards/action_card.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/cards/light_switch_card.dart';
import 'package:nexus/core/expanded_row.dart';
import 'package:nexus/core/expanded_column.dart';

import 'package:nexus/cards/curtain_card.dart';
import 'package:nexus/core/switch_card.dart';
import 'package:nexus/core/value_card.dart';

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
          ClockCard(),
          ExpandedRow(children: [
            CurtainCard(
                name: 'Left Curtain',
                stateProvider: DummyValueStateProvider(initialValue: 0.5)),
            CurtainCard(
                name: 'RightCurtain',
                stateProvider: DummyValueStateProvider(initialValue: 0.5))
          ])
        ]),
        ExpandedColumn(children: [
          ExpandedRow(children: [
            ActionCard(
              name: 'Ping Anna',
              icon: Icons.phone_iphone,
              action: () => MakeSnackBar(context, 'Pinged anna'),
            ),
            ActionCard(
              name: 'Movie Scene',
              icon: Icons.movie,
              action: () => MakeSnackBar(context, 'Set scenario to movie'),
            )
          ]),
          ExpandedRow(
            children: [
              LightSwitchCard(
                  stateProvider: DummySwitchStateProvider(),
                  name: 'Bulbs',
                  room: 'Master'),
              LightSwitchCard(
                  stateProvider: DummySwitchStateProvider(),
                  name: 'Bulb',
                  room: 'Toilet'),
            ],
          )
        ])
      ],
    );
  }
}
