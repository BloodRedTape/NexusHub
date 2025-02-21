import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/providers/calendar.dart';
import 'package:nexus/providers/value.dart';
import 'package:nexus/widgets/expanded_row.dart';
import 'package:nexus/widgets/expanded_column.dart';

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
            WeatherCard(
              city: 'kyiv',
            ),
          ])
        ]),
        ExpandedColumn(children: [
          CalendarCard(
              stateProvider: DummyValueStateProvider<CalendarState>(
                  initialValue: CalendarState(days: [
            CalendarDayState(date: DateTime(2024, 2, 21), events: [
              CalendarEventState(
                  start: TimeOfDay(hour: 9, minute: 0),
                  end: TimeOfDay(hour: 10, minute: 0),
                  description: 'Clean your house'),
              CalendarEventState(
                  start: TimeOfDay(hour: 14, minute: 0),
                  end: TimeOfDay(hour: 15, minute: 0),
                  description: 'Driving')
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
          ExpandedRow(
            children: [AlarmCard()],
          )
        ])
      ],
    );
  }
}
