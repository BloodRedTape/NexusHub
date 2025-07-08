import 'package:flutter/material.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/humidifier.dart';
import 'package:nexus/cards/light.dart';
import 'package:nexus/cards/light_switch.dart';
import 'package:nexus/cards/printer.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/providers/dummy_state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nexus/utils/tint.dart';

class MasterTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;

  MasterTab({required this.homeAssistantClient});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ExpandedRow(children: [
            ExpandedColumn(children: [
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.temp_ht_master'),
                icon: Icons.thermostat,
                formatter: Formatter.tempearture,
                compact: true,
              ),
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.time_ventilation_master'),
                icon: MdiIcons.windowOpenVariant,
                formatter: Formatter.time,
                compact: true,
              ),
            ]),
            ExpandedColumn(children: [
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.humidity_ht_master'),
                icon: Icons.water_drop_outlined,
                formatter: Formatter.humidity,
                compact: true,
              ),
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.co2_custom0_master'),
                icon: Icons.co2,
                formatter: Formatter.carbonDioxide,
                iconPainter: Painter.carbonDioxide,
                compact: true,
              ),
            ]),
          ]),
          ExpandedRow(
            children: [
              ExpandedColumn(children: [
                SensorCard(
                  stateProvider: homeAssistantClient.sensorStateProvider('sensor.illuminance_motion_nowhere'),
                  icon: Icons.sunny,
                  formatter: Formatter.illuminance,
                  compact: true,
                ),
                SensorCard(
                  stateProvider: homeAssistantClient.sensorStateProvider('sensor.u_s_air_quality_index'),
                  icon: Icons.air_sharp,
                  formatter: Formatter.aqi,
                  iconPainter: Painter.aqi,
                  compact: true,
                ),
              ]),
              Printer(
                bedTemperature: homeAssistantClient.sensorStateProvider('sensor.bed_temp_ttb_master'),
                targetBedTemperature: homeAssistantClient.sensorStateProvider('number.target_bed_temp_ttb_master'),
                extruderTemperature: homeAssistantClient.sensorStateProvider('sensor.extruder_temp_ttb_master'),
                targetExtruderTemperature: homeAssistantClient.sensorStateProvider('number.target_extruder_temp_ttb_master'),
                progress: homeAssistantClient.sensorStateProvider('sensor.print_progress_ttb_master'),
                power: homeAssistantClient.switchStateProvider('switch.power_print3d_master'),
                status: homeAssistantClient.entityStateProvider('sensor.print_status_ttb_master'),
                connection: homeAssistantClient.entityStateProvider('sensor.connection_ttb_master'),
              ),
            ],
          )
        ]),
        ExpandedColumn(children: [
          ExpandedRow(
            children: [
              LightCard(
                  stateProvider: homeAssistantClient.lightStateProvider('light.light_bulbs_master'),
                  onIcon: Icons.lightbulb,
                  offIcon: Icons.lightbulb_outline,
                  name: 'Bulbs'),
              LightCard(
                stateProvider: homeAssistantClient.lightStateProvider('light.light_led_master'),
                onIcon: MdiIcons.lightbulbSpot,
                offIcon: MdiIcons.lightbulbSpotOff,
                name: 'Led Strip',
              ),
            ],
          ),
          ExpandedRow(children: [
            HumidifierCard(
              stateProvider: homeAssistantClient.switchStateProvider('fan.xiaomi_mi_smart_humidifier_2'),
              room: 'Mi Humidifier',
            ),
            SwitchCard(
              stateProvider: homeAssistantClient.switchStateProvider('switch.power_plug1_nowhere'),
              onIcon: MdiIcons.powerPlug,
              offIcon: MdiIcons.powerPlugOff,
              room: 'Heater',
              onColor: Tint.color(color: const Color.fromARGB(255, 255, 94, 0)),
            ),
          ]),
        ])
      ],
    );
  }
}
