import 'package:flutter/material.dart';

class CalendarEvent {
  final TimeOfDay start;
  final TimeOfDay end;
  final String description;

  /// Days the event spans. 1 for an event that ends the day it started.
  final int days;

  const CalendarEvent({
    required this.start,
    required this.end,
    required this.description,
    this.days = 1,
  });

  bool get isFullDay => start == TimeOfDay(hour: 0, minute: 00) && end == TimeOfDay(hour: 24, minute: 00);

  bool get isMultiDay => days > 1;
}

class CalendarDay {
  final DateTime date;
  final List<CalendarEvent> events;

  CalendarDay({required this.date, required this.events});
}

class Calendar {
  final List<CalendarDay> days;

  Calendar({required this.days});
}
