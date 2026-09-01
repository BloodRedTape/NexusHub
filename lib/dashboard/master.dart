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
import 'package:nexus/dashboard/grid.dart';
import 'package:nexus/utils/tint.dart';

class MasterTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;

  MasterTab({required this.homeAssistantClient});

  @override
  Widget build(BuildContext context) {
    return TileGrid(tiles: [
      Tile(SplitTile(
        top: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.temp_ht_master'),
          icon: Icons.thermostat,
          formatter: Formatter.tempearture,
          compact: true,
        ),
        bottom: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.time_ventilation_master'),
          icon: Icons.sensor_window,
          formatter: Formatter.time,
          compact: true,
        ),
      )),
      Tile(SplitTile(
        top: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.humidity_ht_master'),
          icon: Icons.water_drop_outlined,
          formatter: Formatter.humidity,
          compact: true,
        ),
        bottom: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.co2_custom0_master'),
          icon: Icons.co2,
          formatter: Formatter.carbonDioxide,
          iconPainter: Painter.carbonDioxide,
          compact: true,
        ),
      )),
      Tile(LightCard(
        stateProvider: homeAssistantClient.lightStateProvider('light.light_bulbs_master'),
        onIcon: Icons.lightbulb,
        offIcon: Icons.lightbulb_outline,
        name: 'Bulbs',
      )),
      Tile(LightCard(
        stateProvider: homeAssistantClient.lightStateProvider('light.light_led_master'),
        onIcon: Icons.lightbulb,
        offIcon: Icons.lightbulb_outline,
        name: 'Led Strip',
      )),
      Tile(SplitTile(
        top: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.illuminance_motion_nowhere'),
          icon: Icons.sunny,
          formatter: Formatter.illuminance,
          compact: true,
        ),
        bottom: SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider('sensor.u_s_air_quality_index'),
          icon: Icons.air_sharp,
          formatter: Formatter.aqi,
          iconPainter: Painter.aqi,
          compact: true,
        ),
      )),
      Tile(Printer(
        bedTemperature: homeAssistantClient.sensorStateProvider('sensor.bed_temp_ttb_master'),
        targetBedTemperature: homeAssistantClient.sensorStateProvider('number.target_bed_temp_ttb_master'),
        extruderTemperature: homeAssistantClient.sensorStateProvider('sensor.extruder_temp_ttb_master'),
        targetExtruderTemperature: homeAssistantClient.sensorStateProvider('number.target_extruder_temp_ttb_master'),
        progress: homeAssistantClient.sensorStateProvider('sensor.print_progress_ttb_master'),
        power: homeAssistantClient.switchStateProvider('switch.power_print3d_master'),
        status: homeAssistantClient.entityStateProvider('sensor.print_status_ttb_master'),
        connection: homeAssistantClient.entityStateProvider('sensor.connection_ttb_master'),
      )),
      Tile(HumidifierCard(
        stateProvider: homeAssistantClient.switchStateProvider('fan.xiaomi_mi_smart_humidifier_2'),
        room: 'Mi Humidifier',
      )),
      Tile(SwitchCard(
        stateProvider: homeAssistantClient.switchStateProvider('switch.power_plug1_nowhere'),
        onIcon: Icons.power,
        offIcon: Icons.power_off,
        room: 'Heater',
        onColor: Tint.color(color: const Color.fromARGB(255, 255, 94, 0)),
      )),
    ]);
  }
}
