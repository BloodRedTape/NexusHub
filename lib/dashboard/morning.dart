import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/providers/calendar.dart';
import 'package:nexus/providers/impls/open_meteo.dart';
import 'package:nexus/providers/impls/open_weather.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/expanded_row.dart';
import 'package:nexus/utils/expanded_column.dart';

import 'package:nexus/cards/weather.dart';

class MorningTab extends StatelessWidget {
  const MorningTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ClockCard(),
          ExpandedRow(children: [
            WeatherCard(stateProvider: OpenMeteo(lat: 50.4375, long: 30.5)),
            AlarmCard()
          ])
        ]),
        ExpandedColumn(children: [
          CalendarCard(
              stateProvider: DummyStateProvider<CalendarState>(
                  initialValue: CalendarState(days: [
            CalendarDayState(date: DateTime(2024, 2, 21), events: [
              CalendarEventState(
                  start: TimeOfDay(hour: 16, minute: 0),
                  end: TimeOfDay(hour: 17, minute: 0),
                  description: 'Alarm android integration'),
              CalendarEventState(
                  start: TimeOfDay(hour: 9, minute: 0),
                  end: TimeOfDay(hour: 10, minute: 0),
                  description: 'Curtains UI'),
              CalendarEventState(
                  start: TimeOfDay(hour: 14, minute: 0),
                  end: TimeOfDay(hour: 15, minute: 0),
                  description: 'HomeAssistant state provider'),
              CalendarEventState(
                  start: TimeOfDay(hour: 16, minute: 0),
                  end: TimeOfDay(hour: 17, minute: 0),
                  description: 'Google calendar state provider'),
            ]),
            CalendarDayState(date: DateTime(2024, 2, 22), events: [
              CalendarEventState(
                  start: TimeOfDay(hour: 10, minute: 0),
                  end: TimeOfDay(hour: 10, minute: 15),
                  description: 'Daily meeting'),
              CalendarEventState(
                  start: TimeOfDay(hour: 14, minute: 0),
                  end: TimeOfDay(hour: 15, minute: 0),
                  description: 'Driving')
            ])
          ]))),
        ])
      ],
    );
  }
}
