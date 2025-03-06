import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/states/alarm.dart';
import 'package:nexus/states/calendar.dart';
import 'package:nexus/providers/dummy_state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';

import 'package:nexus/cards/weather.dart';

class MorningTab extends StatelessWidget {
  final OpenMeteoWeatherClient weatherClient;
  final HomeAssistantClient homeAssistantClient;
  final AndroidClient androidClient;

  const MorningTab({super.key, required this.weatherClient, required this.homeAssistantClient, required this.androidClient});

  @override
  Widget build(BuildContext context) {
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
