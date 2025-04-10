import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/curtain.dart';
import 'package:nexus/cards/humidifier.dart';
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
            ExpandedColumn(children: [
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.temperature_qingping_bedroom'),
                icon: Icons.thermostat,
                formatter: Formatter.tempearture,
              ),
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.time_ventilation_bedroom'),
                icon: MdiIcons.windowOpenVariant,
                formatter: Formatter.time,
              ),
            ]),
            ExpandedColumn(children: [
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.humidity_qingping_bedroom'),
                icon: Icons.water_drop_outlined,
                formatter: Formatter.humidity,
              ),
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.co2_qingping_bedroom'),
                icon: Icons.co2,
                formatter: Formatter.carbonDioxide,
                iconPainter: Painter.carbonDioxide,
              ),
            ]),
          ]),
          ExpandedRow(children: [
            ExpandedColumn(children: [
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.illuminance_mi_bedroom'),
                icon: Icons.sunny,
                formatter: Formatter.illuminance,
              ),
              SmallSensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.u_s_air_quality_index'),
                icon: Icons.air_sharp,
                formatter: Formatter.aqi,
                iconPainter: Painter.aqi,
              ),
            ]),
            ActionCard(name: 'Action', icon: MdiIcons.openInApp)
          ]),
        ]),
        ExpandedColumn(children: [
          ExpandedRow(
            children: [
              ActionCard(name: 'Sleep', icon: MdiIcons.sleep),
              HumidifierCard(
                stateProvider: homeAssistantClient.switchStateProvider('fan.xiaomi_mi_smart_humidifier_2_bedroom'),
                room: 'Humidifier',
              ),
            ],
          ),
          ExpandedRow(children: [
            CurtainCard(stateProvider: homeAssistantClient.curtainStateProvider('cover.driver_curtain0_bedroom'), name: 'Left'),
            CurtainCard(stateProvider: homeAssistantClient.curtainStateProvider('cover.driver_curtain1_bedroom'), name: 'Right'),
          ]),
        ])
      ],
    );
  }
}
