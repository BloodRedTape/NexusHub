import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/clients/ha/models/calendar.dart';

class CalendarDayWidget extends StatelessWidget {
  final CalendarDay day;

  const CalendarDayWidget({required this.day});

  static String _time(TimeOfDay time) => '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (day.events.isEmpty) return SizedBox();

    double fontSize = 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.calendar_month, size: 28),
          const SizedBox(width: 8),
          Text(
            DateFormat('d MMMM').format(day.date),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
        ]),
        const SizedBox(height: 4),
        Table(
          columnWidths: {
            0: IntrinsicColumnWidth(),
            1: FixedColumnWidth(20.0),
            2: FlexColumnWidth(),
          },
          children: day.events.map((event) {
            return TableRow(
              children: [
                TableCell(
                    child: Align(
                  alignment: AlignmentDirectional.center,
                  child: Text.rich(
                    TextSpan(
                      text: '${_time(event.start)} - ${_time(event.end)}',
                      children: [
                        if (event.isMultiDay)
                          // day offset rides above the end time, out of the way
                          WidgetSpan(
                            alignment: PlaceholderAlignment.top,
                            child: Text(
                              '+${event.days - 1}',
                              style: TextStyle(fontSize: fontSize * 0.6, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(fontSize: fontSize),
                  ),
                )),
                const TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Icon(
                    Icons.circle,
                    color: Colors.blue,
                    size: 8,
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
    );
  }
}

class CalendarCard extends StateCard<Calendar> {
  const CalendarCard({super.key, required super.stateProvider});

  @override
  Widget build(BuildContext context, Calendar? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return BaseCard(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: ListView.builder(
          itemCount: state.days.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: cardPadding * 0.5),
            child: CalendarDayWidget(day: state.days[index]),
          ),
        ),
      ),
    );
  }
}
