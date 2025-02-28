import 'package:flutter/material.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/cards/light_switch.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/temperature.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/ha/state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';

import 'package:nexus/cards/curtain.dart';
import 'package:nexus/providers/dummy_state.dart';

void MakeSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

class HomeTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;

  late TemperatureStateProvider bedroomTemp;
  late TemperatureStateProvider masterTemp;

  HomeTab({required this.homeAssistantClient}) {
    bedroomTemp = TemperatureStateProvider(
        entitiesStateProvider: homeAssistantClient.entitiesStateProvider(),
        entityId: 'sensor.temp_ht_bedroom');

    bedroomTemp.init();

    masterTemp = TemperatureStateProvider(
        entitiesStateProvider: homeAssistantClient.entitiesStateProvider(),
        entityId: 'sensor.temp_ht_master');

    masterTemp.init();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ExpandedRow(children: [
            TemperatureCard(stateProvider: masterTemp, room: 'Master'),
            TemperatureCard(stateProvider: bedroomTemp, room: 'Bedroom'),
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
