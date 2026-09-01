import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';
import 'package:provider/provider.dart';

import 'package:nexus/cards/weather.dart';

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
          ExpandedRow(children: [WeatherCard(stateProvider: weatherClient.getStateProvider()), AlarmCard(stateProvider: androidClient.getAlarmProvider())])
        ]),
        ExpandedColumn(children: [
          CalendarCard(stateProvider: homeAssistantClient.calendarStateProvider('calendar.primary')),
        ])
      ],
    );
  }
}
