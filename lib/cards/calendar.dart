import 'package:flutter/material.dart';
import 'package:nexus/core/base_card.dart';

class CalendarEvent {
  final TimeOfDay start;
  final TimeOfDay end;
  final String description;

  const CalendarEvent({
    required this.start,
    required this.end,
    required this.description,
  });
}

class CalendarDay extends StatelessWidget {
  final String dayName;
  final String date;
  final List<CalendarEvent> events;

  const CalendarDay({
    required this.dayName,
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.length == 0) return SizedBox();

    double fontSize = 24;

    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.calendar_month, size: 35),
              const SizedBox(width: 8),
              Text(
                '$dayName',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                size: 10,
              ),
              const SizedBox(width: 8),
              Text(
                '$date',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
            ]),
            const SizedBox(height: 8),
            Table(
              columnWidths: {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
                3: FixedColumnWidth(40.0),
                4: FlexColumnWidth(),
              },
              children: events.map((event) {
                return TableRow(
                  children: [
                    TableCell(
                        child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                          '${event.start.hour}:${event.start.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: fontSize)),
                    )),
                    TableCell(
                      child: Text(' - ', style: TextStyle(fontSize: fontSize)),
                    ),
                    TableCell(
                        child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                          '${event.end.hour}:${event.end.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: fontSize)),
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
                        style: TextStyle(fontSize: fontSize),
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

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Column(children: [
          CalendarDay(dayName: 'Tuesday', date: '15 February', events: [
            CalendarEvent(
                start: TimeOfDay(hour: 13, minute: 00),
                end: TimeOfDay(hour: 14, minute: 00),
                description: 'Driving'),
            CalendarEvent(
                start: TimeOfDay(hour: 9, minute: 00),
                end: TimeOfDay(hour: 10, minute: 00),
                description: 'Pay for house'),
          ]),
          const SizedBox(height: 16),
          CalendarDay(dayName: 'Wensday', date: '16 February', events: [
            CalendarEvent(
                start: TimeOfDay(hour: 13, minute: 00),
                end: TimeOfDay(hour: 14, minute: 00),
                description: 'Something'),
            CalendarEvent(
                start: TimeOfDay(hour: 8, minute: 00),
                end: TimeOfDay(hour: 9, minute: 00),
                description: 'Stuff'),
          ])
        ]));
  }
}

class CalendarCard extends StatelessWidget {
  const CalendarCard();

  @override
  Widget build(BuildContext context) {
    return BaseCard(child: Calendar(), color: Colors.grey[900]);
  }
}
