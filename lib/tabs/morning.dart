import 'package:flutter/material.dart';
import 'package:nexus/cards/clock.dart';
import 'package:nexus/core/dashboard_card.dart';
import 'package:nexus/core/expanded_row.dart';
import 'package:nexus/core/expanded_column.dart';

import 'package:nexus/cards/weather.dart';

class MorningTab extends StatelessWidget {
  const MorningTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandedRow(
      children: [
        ExpandedColumn(children: [
          ClockCard(),
          WeatherCard(
            city: 'kyiv',
          ),
        ]),
        ExpandedColumn(children: [
          DashboardCard(
            color: Color.fromARGB(255, 240, 173, 85),
            child: Center(
              child: Text(
                'On · 80%\nLamp\nLiving Room',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ExpandedRow(
            children: [
              DashboardCard(
                child: Center(
                  child: Text(
                    '68°\n76° 65°',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              DashboardCard(
                color: Color.fromARGB(255, 69, 131, 240),
                child: Center(
                  child: Text(
                    '8:44\nTimer',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          )
        ])
      ],
    );
  }
}
