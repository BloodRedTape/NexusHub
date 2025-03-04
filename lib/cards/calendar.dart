import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/states/calendar.dart';

class CalendarDayWidget extends StatelessWidget {
  final CalendarDayState day;

  const CalendarDayWidget({required this.day});

  @override
  Widget build(BuildContext context) {
    if (day.events.isEmpty) return SizedBox();

    double fontSize = 24;

    return Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_month, size: 35),
              const SizedBox(width: 8),
              Text(
                DateFormat('d MMMM').format(day.date),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
            ]),
            const SizedBox(height: 8),
            Table(
              columnWidths: {
                0: IntrinsicColumnWidth(),
                1: FixedColumnWidth(40.0),
                2: FlexColumnWidth(),
              },
              children: day.events.map((event) {
                final timeRangeText =
                    '${event.start.hour}:${event.start.minute.toString().padLeft(2, '0')} - ${event.end.hour}:${event.end.minute.toString().padLeft(2, '0')}';

                return TableRow(
                  children: [
                    TableCell(
                        child: Align(
                      alignment: AlignmentDirectional.center,
                      child: Text(timeRangeText, style: TextStyle(fontSize: fontSize)),
                    )),
                    const TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Icon(
                        Icons.circle,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                    TableCell(
                      child: Text(
                        event.description,
                        style: TextStyle(fontSize: fontSize, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ));
  }
}

class CalendarCard extends StateCard<CalendarState> {
  const CalendarCard({required super.stateProvider});

  @override
  Widget build(BuildContext context, CalendarState? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return BaseCard(
      color: Colors.grey[900],
      child: Padding(padding: EdgeInsets.all(8), child: Column(children: state.days.map((day) => CalendarDayWidget(day: day)).toList())),
    );
  }
}
