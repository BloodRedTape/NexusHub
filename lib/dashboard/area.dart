import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/cards/curtain.dart';
import 'package:nexus/cards/light.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/cards/switch.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/dashboard/grid.dart';

/// Everything Home Assistant reports for one area, laid out on the tile grid.
class AreaTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;
  final Area area;

  const AreaTab({super.key, required this.homeAssistantClient, required this.area});

  @override
  Widget build(BuildContext context) {
    final entities = homeAssistantClient.entitiesOfArea(area.areaId);
    final tiles = entities.map(_tileFor).whereType<Tile>().toList();

    if (tiles.isEmpty) return Center(child: Text('Nothing to show in ${area.name}'));

    return TileGrid(tiles: tiles);
  }

  /// Picks a card for an entity, or null when we have nothing to show it with.
  Tile? _tileFor(RegistryEntry entry) {
    switch (entry.domain) {
      case 'light':
        return Tile(LightCard(
          stateProvider: homeAssistantClient.lightStateProvider(entry.entityId),
          onIcon: Icons.lightbulb,
          offIcon: Icons.lightbulb_outline,
          name: entry.displayName,
        ));

      case 'switch':
      case 'fan':
      case 'input_boolean':
        return Tile(SwitchCard(
          stateProvider: homeAssistantClient.switchStateProvider(entry.entityId),
          onIcon: _onIcon(entry),
          offIcon: _offIcon(entry),
          room: entry.displayName,
        ));

      case 'cover':
        return Tile(CurtainCard(
          stateProvider: homeAssistantClient.curtainStateProvider(entry.entityId),
          name: entry.displayName,
          control: CurtainControlType.Button,
        ));

      case 'sensor':
        final formatter = _formatterFor(entry.effectiveDeviceClass);

        if (formatter == null) return null;

        return Tile(SensorCard(
          stateProvider: homeAssistantClient.sensorStateProvider(entry.entityId),
          icon: _sensorIcon(entry.effectiveDeviceClass),
          formatter: formatter,
          iconPainter: _sensorPainter(entry.effectiveDeviceClass),
        ));

      default:
        return null;
    }
  }

  IconData _onIcon(RegistryEntry entry) => entry.domain == 'fan' ? Icons.wind_power : Icons.power;

  IconData _offIcon(RegistryEntry entry) => entry.domain == 'fan' ? Icons.mode_fan_off : Icons.power_off;

  /// Only device classes we can actually format get a tile.
  String Function(double)? _formatterFor(String? deviceClass) {
    switch (deviceClass) {
      case 'temperature':
        return Formatter.tempearture;
      case 'humidity':
        return Formatter.humidity;
      case 'illuminance':
        return Formatter.illuminance;
      case 'carbon_dioxide':
        return Formatter.carbonDioxide;
      case 'aqi':
        return Formatter.aqi;
      default:
        return null;
    }
  }

  IconData _sensorIcon(String? deviceClass) {
    switch (deviceClass) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'illuminance':
        return Icons.sunny;
      case 'carbon_dioxide':
        return Icons.co2;
      case 'aqi':
        return Icons.air_sharp;
      default:
        return Icons.sensors;
    }
  }

  Color? Function(double)? _sensorPainter(String? deviceClass) {
    switch (deviceClass) {
      case 'carbon_dioxide':
        return Painter.carbonDioxide;
      case 'aqi':
        return Painter.aqi;
      default:
        return null;
    }
  }
}
