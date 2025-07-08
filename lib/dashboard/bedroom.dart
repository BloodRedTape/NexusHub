import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nexus/cards/action.dart';
import 'package:nexus/cards/curtain.dart';
import 'package:nexus/cards/humidifier.dart';
import 'package:nexus/cards/light.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/providers/dummy_state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';
import 'package:nexus/utils/tint.dart';

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
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.temperature_qingping_bedroom'),
                icon: Icons.thermostat,
                formatter: Formatter.tempearture,
                compact: true,
              ),
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.time_ventilation_bedroom'),
                icon: MdiIcons.windowOpenVariant,
                formatter: Formatter.time,
                compact: true,
              ),
            ]),
            ExpandedColumn(children: [
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.humidity_qingping_bedroom'),
                icon: Icons.water_drop_outlined,
                formatter: Formatter.humidity,
                compact: true,
              ),
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.co2_qingping_bedroom'),
                icon: Icons.co2,
                formatter: Formatter.carbonDioxide,
                iconPainter: Painter.carbonDioxide,
                compact: true,
              ),
            ]),
          ]),
          ExpandedRow(children: [
            ExpandedColumn(children: [
              SensorCard(
                stateProvider: homeAssistantClient.sensorStateProvider('sensor.illuminance_mi_bedroom'),
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
            HumidifierCard(
              stateProvider: homeAssistantClient.switchStateProvider('fan.xiaomi_mi_smart_humidifier_2_bedroom'),
              room: 'Mi Humidifier',
            ),
          ]),
        ]),
        ExpandedColumn(children: [
          ExpandedRow(children: [
            CurtainCard(
              stateProvider: homeAssistantClient.curtainStateProvider('cover.driver_curtains_bedroom'),
              name: 'Curtains',
              control: CurtainControlType.Button,
            ),
            SwitchCard(
              stateProvider: homeAssistantClient.switchStateProvider('automation.open_curtains'),
              onIcon: Icons.curtains,
              offIcon: Icons.curtains_closed,
              room: 'Open Curtains',
              onColor: Tint.color(color: const Color.fromARGB(255, 42, 71, 233)),
            ),
          ]),
          ExpandedRow(
            children: [
              SwitchCard(
                stateProvider: homeAssistantClient.switchStateProvider('fan.fan_rztk_nowhere'),
                onIcon: MdiIcons.fan,
                offIcon: MdiIcons.fanOff,
                room: 'Rztk Smart Fan',
                onColor: const Color.fromARGB(255, 47, 107, 49),
              ),
              ExpandedColumn(children: [
                LightCard(
                  stateProvider: homeAssistantClient.lightStateProvider('light.led_custom0_bedroom'),
                  onIcon: MdiIcons.ledStripVariant,
                  offIcon: MdiIcons.ledStripVariantOff,
                  name: 'Bed Led',
                  compact: true,
                ),
                LightCard(
                  stateProvider: homeAssistantClient.lightStateProvider('light.chestnut_led'),
                  onIcon: MdiIcons.leafMaple,
                  offIcon: MdiIcons.leafMapleOff,
                  name: 'Chestnut',
                  compact: true,
                ),
              ]),
            ],
          ),
        ])
      ],
    );
  }
}
