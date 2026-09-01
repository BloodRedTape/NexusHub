import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/cards/air_quality.dart';
import 'package:nexus/cards/climate.dart';
import 'package:nexus/cards/light.dart';
import 'package:nexus/cards/outlet.dart';
import 'package:nexus/cards/sensor.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/dashboard/grid.dart';

/// A card that can represent a device, provided the device exposes [requires].
class CardMatcher {
  /// Entity kinds the card needs - see [DeviceEntities.kindOf].
  /// A device matches when it exposes all of them.
  final Set<String> requires;

  final Widget Function(HomeAssistantClient client, DeviceEntities device) build;

  const CardMatcher({required this.requires, required this.build});
}

/// Cards we know how to build, matched against a device by its entity kinds.
const List<CardMatcher> cardMatchers = [
  CardMatcher(requires: {'light'}, build: _buildLight),
  CardMatcher(requires: {'sensor.temperature', 'sensor.humidity'}, build: _buildClimate),
  CardMatcher(requires: {'switch', 'sensor.voltage', 'sensor.power', 'sensor.energy'}, build: _buildOutlet),
  CardMatcher(requires: {'sensor.carbon_dioxide'}, build: _buildCarbonDioxide),
  CardMatcher(requires: {'sensor.carbon_dioxide', 'sensor.pm25', 'sensor.pm10'}, build: _buildAirQuality),
];

Widget _buildAirQuality(HomeAssistantClient client, DeviceEntities device) {
  return AirQualityCard(
    carbonDioxide: client.sensorStateProvider(device.entityOf('sensor.carbon_dioxide')!.entityId),
    pm25: client.sensorStateProvider(device.entityOf('sensor.pm25')!.entityId),
    pm10: client.sensorStateProvider(device.entityOf('sensor.pm10')!.entityId),
    name: device.name,
  );
}

Widget _buildCarbonDioxide(HomeAssistantClient client, DeviceEntities device) {
  return SensorCard(
    stateProvider: client.sensorStateProvider(device.entityOf('sensor.carbon_dioxide')!.entityId),
    icon: Icons.co2,
    formatter: Formatter.carbonDioxide,
    iconPainter: Painter.carbonDioxide,
    room: device.name,
  );
}

Widget _buildLight(HomeAssistantClient client, DeviceEntities device) {
  return LightCard(
    stateProvider: client.lightStateProvider(device.entityOf('light')!.entityId),
    onIcon: Icons.lightbulb,
    offIcon: Icons.lightbulb_outline,
    name: device.name,
  );
}

Widget _buildOutlet(HomeAssistantClient client, DeviceEntities device) {
  return OutletCard(
    stateProvider: client.switchStateProvider(device.entityOf('switch')!.entityId),
    power: client.sensorStateProvider(device.entityOf('sensor.power')!.entityId),
    name: device.name,
  );
}

Widget _buildClimate(HomeAssistantClient client, DeviceEntities device) {
  return ClimateCard(
    temperature: client.sensorStateProvider(device.entityOf('sensor.temperature')!.entityId),
    humidity: client.sensorStateProvider(device.entityOf('sensor.humidity')!.entityId),
    name: device.name,
  );
}

/// Best card for a device: the matcher that fits and covers most of its entities.
/// Returns null when nothing fits.
CardMatcher? matchCard(DeviceEntities device) {
  CardMatcher? best;

  for (final matcher in cardMatchers) {
    if (!matcher.requires.every(device.kinds.contains)) continue;

    if (best == null || matcher.requires.length > best.requires.length) best = matcher;
  }

  return best;
}

/// Devices of one area, each shown with the card that fits it best.
class AreaTab extends StatelessWidget {
  final HomeAssistantClient homeAssistantClient;
  final Area area;

  const AreaTab({super.key, required this.homeAssistantClient, required this.area});

  @override
  Widget build(BuildContext context) {
    final tiles = <Tile>[];

    for (final device in homeAssistantClient.devicesOfArea(area.areaId)) {
      final matcher = matchCard(device);

      if (matcher == null) continue;

      tiles.add(Tile(matcher.build(homeAssistantClient, device)));
    }

    if (tiles.isEmpty) return Center(child: Text('Nothing to show in ${area.name}'));

    return TileGrid(tiles: tiles);
  }
}
