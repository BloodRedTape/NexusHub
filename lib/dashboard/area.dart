import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/cards/ha/air_quality.dart';
import 'package:nexus/cards/ha/climate.dart';
import 'package:nexus/cards/ha/image.dart';
import 'package:nexus/cards/ha/light.dart';
import 'package:nexus/cards/ha/motion.dart';
import 'package:nexus/cards/ha/outlet.dart';
import 'package:nexus/cards/ha/sensor.dart';
import 'package:nexus/cards/ha/system.dart';
import 'package:nexus/cards/ha/vacuum.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/dashboard/grid.dart';
import 'package:provider/provider.dart';

/// A card that can represent a device, provided the device exposes [requires].
class CardMatcher {
  /// Entity kinds the card needs - see [DeviceEntities.kindOf].
  /// A device matches when it exposes all of them.
  final Set<String> requires;

  final Widget Function(HomeAssistantClient client, DeviceEntities device) build;

  /// Extra condition for devices that [requires] cannot describe, and how many
  /// entities it accounts for when comparing matchers.
  final bool Function(DeviceEntities device)? accepts;
  final int weight;

  const CardMatcher({required this.requires, required this.build, this.accepts, this.weight = 0});

  bool matches(DeviceEntities device) {
    if (!requires.every(device.kinds.contains)) return false;

    return accepts == null || accepts!(device);
  }

  /// How much of a device this matcher covers - richer matches win.
  int get coverage => requires.length + weight;
}

/// Cards we know how to build, matched against a device by its entity kinds.
const List<CardMatcher> cardMatchers = [
  CardMatcher(requires: {'light'}, build: _buildLight),
  CardMatcher(requires: {'sensor.temperature', 'sensor.humidity'}, build: _buildClimate),
  CardMatcher(requires: {'switch', 'sensor.voltage', 'sensor.power', 'sensor.energy'}, build: _buildOutlet),
  CardMatcher(requires: {'sensor.carbon_dioxide'}, build: _buildCarbonDioxide),
  CardMatcher(requires: {'sensor.carbon_dioxide', 'sensor.pm25', 'sensor.pm10'}, build: _buildAirQuality),
  CardMatcher(requires: {'sensor.illuminance'}, build: _buildIlluminance),
  CardMatcher(requires: {'binary_sensor.occupancy', 'sensor.illuminance'}, build: _buildMotion),
  CardMatcher(requires: {'vacuum'}, build: _buildVacuum),
  CardMatcher(requires: {'image'}, build: _buildImage),
  CardMatcher(requires: {}, accepts: _isMachine, weight: 4, build: _buildSystem),
];

/// System Monitor leaves the device class empty, so go by the entity names.
bool _isMachine(DeviceEntities device) => device.entityEndingWith('processor_use') != null;

Widget _buildVacuum(HomeAssistantClient client, DeviceEntities device) {
  return VacuumCard(
    stateProvider: client.vacuumStateProvider(device.entityOf('vacuum')!.entityId),
    name: device.name,
  );
}

Widget _buildImage(HomeAssistantClient client, DeviceEntities device) {
  return ImageCard(
    stateProvider: client.imageStateProvider(device.entityOf('image')!.entityId),
    name: device.name,
  );
}

Widget _buildSystem(HomeAssistantClient client, DeviceEntities device) {
  StateProvider<double>? sensor(String suffix) {
    final entry = device.entityEndingWith(suffix);

    return entry == null ? null : client.sensorStateProvider(entry.entityId);
  }

  return SystemCard(
    processor: sensor('processor_use')!,
    temperature: sensor('processor_temperature'),
    memory: sensor('memory_use_percent'),
    disk: sensor('disk_use_percent'),
    name: device.name,
  );
}

Widget _buildMotion(HomeAssistantClient client, DeviceEntities device) {
  return MotionCard(
    stateProvider: client.switchStateProvider(device.entityOf('binary_sensor.occupancy')!.entityId),
    illuminance: client.sensorStateProvider(device.entityOf('sensor.illuminance')!.entityId),
    name: device.name,
  );
}

Widget _buildIlluminance(HomeAssistantClient client, DeviceEntities device) {
  return SensorCard(
    stateProvider: client.sensorStateProvider(device.entityOf('sensor.illuminance')!.entityId),
    icon: Icons.sunny,
    formatter: Formatter.illuminance,
    room: device.name,
  );
}

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
    if (!matcher.matches(device)) continue;

    if (best == null || matcher.coverage > best.coverage) best = matcher;
  }

  return best;
}

/// Devices of one area, each shown with the card that fits it best.
class AreaTab extends StatelessWidget {
  final Area area;

  const AreaTab({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    final homeAssistantClient = context.read<HomeAssistantClient>();
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
