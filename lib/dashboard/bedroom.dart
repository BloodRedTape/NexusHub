import 'package:flutter/material.dart';
import 'package:nexus/cards/curtain.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/providers/dummy_state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';

class BedroomTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;

  BedroomTab({required this.homeAssistantClient});

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
          ExpandedRow(
            children: [
              SensorCard(
                stateProvider: homeAssistantClient
                    .sensorStateProvider('sensor.time_ventilation_bedroom'),
                icon: Icons.curtains,
                formatter: Formatter.time,
              ),
              SwitchCard(
                  onIcon: Icons.wind_power,
                  offIcon: Icons.wind_power_outlined,
                  onColor: const Color.fromARGB(255, 43, 167, 216),
                  stateProvider: homeAssistantClient.switchStateProvider(
                      'fan.xiaomi_mi_smart_humidifier_2_bedroom'),
                  room: 'Humidifier'),
            ],
          ),
          ExpandedRow(children: [
            CurtainCard(
                stateProvider: homeAssistantClient
                    .curtainStateProvider('cover.driver_curtain0_bedroom'),
                name: 'Left'),
            CurtainCard(
                stateProvider: homeAssistantClient
                    .curtainStateProvider('cover.driver_curtain1_bedroom'),
                name: 'Right'),
          ]),
        ])
      ],
    );
  }
}
