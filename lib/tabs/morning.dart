import 'package:flutter/material.dart';
import 'package:nexus/cards/alarm.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/core/base_card.dart';
import 'package:nexus/core/expanded_row.dart';
import 'package:nexus/core/expanded_column.dart';

import 'package:nexus/cards/weather.dart';
import 'package:nexus/core/value_card.dart';

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
          CalendarCard(),
          ExpandedRow(
            children: [AlarmCard()],
          )
        ])
      ],
    );
  }
}
