import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/cards/light.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/dashboard/grid.dart';

/// A card that can represent a device, provided the device exposes [requires].
class CardMatcher {
  /// Entity domains the card needs. A device matches when it exposes all of them.
  final Set<String> requires;

  final Widget Function(HomeAssistantClient client, DeviceEntities device) build;

  const CardMatcher({required this.requires, required this.build});
}

/// Cards we know how to build, matched against a device by its entity domains.
const List<CardMatcher> cardMatchers = [
  CardMatcher(requires: {'light'}, build: _buildLight),
];

Widget _buildLight(HomeAssistantClient client, DeviceEntities device) {
  return LightCard(
    stateProvider: client.lightStateProvider(device.entityOf('light')!.entityId),
    onIcon: Icons.lightbulb,
    offIcon: Icons.lightbulb_outline,
    name: device.name,
  );
}

/// Best card for a device: the matcher that fits and covers most of its entities.
/// Returns null when nothing fits.
CardMatcher? matchCard(DeviceEntities device) {
  CardMatcher? best;

  for (final matcher in cardMatchers) {
    if (!matcher.requires.every(device.domains.contains)) continue;

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
