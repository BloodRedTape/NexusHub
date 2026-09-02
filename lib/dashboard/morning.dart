import 'package:flutter/material.dart';
import 'package:nexus/cards/os/alarm.dart';
import 'package:nexus/cards/os/clock.dart';
import 'package:nexus/cards/os/calendar.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';
import 'package:provider/provider.dart';

import 'package:nexus/cards/os/weather.dart';

class MorningTab extends StatelessWidget {
  const MorningTab({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherClient = context.read<OpenMeteoWeatherClient>();
    final homeAssistantClient = context.read<HomeAssistantClient>();
    final androidClient = context.read<AndroidClient>();

    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ClockCard(),
          ExpandedRow(children: [WeatherCard(stateProvider: weatherClient.getStateProvider()), AlarmCard(stateProvider: androidClient.alarms.getStateProvider())])
        ]),
        ExpandedColumn(children: [
          _CalendarSlot(homeAssistantClient),
        ])
      ],
    );
  }
}

/// Which calendar to show is a setting, so the card follows the config as it
/// changes instead of being wired once at startup.
class _CalendarSlot extends StateCard<HomeAssistantConfig> {
  final HomeAssistantClient client;

  _CalendarSlot(this.client) : super(stateProvider: client.configState);

  @override
  Widget build(BuildContext context, HomeAssistantConfig? config) {
    final entityId = (config ?? client.config).calendarEntity;

    if (entityId.isEmpty) {
      return PlainCard(
        icon: Icons.event_busy,
        text: 'No calendar',
        subText: 'Pick one in Home Assistant settings',
      );
    }

    // a new entity means a new provider - rebind by rebuilding the card
    return CalendarCard(key: ValueKey(entityId), stateProvider: client.calendarStateProvider(entityId));
  }
}
