import 'package:flutter/material.dart';
import 'package:nexus/providers/state.dart';

class CalendarEventState {
  final TimeOfDay start;
  final TimeOfDay end;
  final String description;

  const CalendarEventState({
    required this.start,
    required this.end,
    required this.description,
  });

  bool get isFullDay => start == TimeOfDay(hour: 0, minute: 00) && end == TimeOfDay(hour: 24, minute: 00);
}

class CalendarDayState {
  final DateTime date;
  final List<CalendarEventState> events;

  CalendarDayState({required this.date, required this.events});
}

class CalendarState {
  final List<CalendarDayState> days;

  CalendarState({required this.days});
}
