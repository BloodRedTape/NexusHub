import 'package:flutter/material.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/cards/light_switch.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/sensor.dart';
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

  HomeTab({required this.homeAssistantClient});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ExpandedRow(children: [
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.temp_ht_bedroom'),
              icon: Icons.thermostat,
              formatter: Formatter.tempearture,
            ),
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.humidity_ht_bedroom'),
              icon: Icons.water_drop_outlined,
              formatter: Formatter.humidity,
            ),
          ]),
          ExpandedRow(children: [
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.illuminance_motion_nowhere'),
              icon: Icons.sunny,
              formatter: Formatter.illuminance,
            ),
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.u_s_air_quality_index'),
              icon: Icons.air_sharp,
              formatter: Formatter.aqi,
            ),
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
