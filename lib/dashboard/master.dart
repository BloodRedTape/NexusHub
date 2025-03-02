import 'package:flutter/material.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/light_switch.dart';
import 'package:nexus/cards/printer.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/providers/dummy_state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MasterTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;

  MasterTab({required this.homeAssistantClient});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ExpandedRow(children: [
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.temp_ht_master'),
              icon: Icons.thermostat,
              formatter: Formatter.tempearture,
            ),
            SensorCard(
              stateProvider: homeAssistantClient
                  .sensorStateProvider('sensor.humidity_ht_master'),
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
            ActionCard(icon: MdiIcons.testTubeEmpty, name: 'Action 1'),
            ActionCard(icon: MdiIcons.testTube, name: 'Action 2'),
          ]),
          ExpandedRow(
            children: [
              LightSwitchCard(
                  stateProvider: homeAssistantClient
                      .switchStateProvider('light.light_bulbs_master'),
                  room: 'Bulbs'),
              Printer(
                bedTemperature: homeAssistantClient
                    .sensorStateProvider('sensor.bed_temp_shui_master'),
                targetBedTemperature: homeAssistantClient
                    .sensorStateProvider('sensor.target_bed_temp_shui_master'),
                extruderTemperature: homeAssistantClient
                    .sensorStateProvider('sensor.extruder_temp_shui_master'),
                targetExtruderTemperature:
                    homeAssistantClient.sensorStateProvider(
                        'sensor.target_extruder_temp_shui_master'),
                progress: homeAssistantClient
                    .sensorStateProvider('sensor.print_progress_shui_master'),
                power: homeAssistantClient
                    .switchStateProvider('switch.power_print3d_master'),
                status: homeAssistantClient
                    .entityStateProvider('sensor.print_status_shui_master'),
                connection: homeAssistantClient
                    .entityStateProvider('sensor.connection_shui_master'),
              ),
            ],
          )
        ])
      ],
    );
  }
}
