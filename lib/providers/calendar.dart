import 'package:flutter/material.dart';
import 'package:nexus/providers/value.dart';

class CalendarEventState {
  final TimeOfDay start;
  final TimeOfDay end;
  final String description;

  const CalendarEventState({
    required this.start,
    required this.end,
    required this.description,
  });
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

typedef CalendarStateProvider = StateProvider<CalendarState>;
