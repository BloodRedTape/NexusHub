import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/clients/core/log.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/clients/ha/models/calendar.dart';

class CalendarStateProvider extends StateProvider<Calendar> {
  final StateProvider<Entity> entityProvider;
  final Future<ServiceResponse?> Function(String, DateTime, DateTime) getCalendarEvents;
  final Duration rangeFromNow;
  final Duration timeZone;

  CalendarStateProvider({required this.entityProvider, required this.getCalendarEvents, required this.rangeFromNow, this.timeZone = const Duration(hours: 2)});

  @override
  void init() {
    super.init();
    entityProvider.bindValueChanged(_onEntityChanged);
  }

  @override
  void dispose() {
    entityProvider.unbind(_onEntityChanged);
    super.dispose();
  }

  void _onEntityChanged(Entity? entity) async {
    if (entity == null || entity.state == null) {
      setValue(null);
      return;
    }

    final entityId = entity.entityId;

    final DateTime now = _withoutTime(DateTime.now());

    final DateTime endDate = now.add(rangeFromNow);

    try {
      ServiceResponse? response = await getCalendarEvents(entityId, now, endDate);

      if (response == null) {
        logCalendar.warning('Null response for $entityId');

        return;
      }

      dynamic responseForEntity = response.serviceResponse[entityId];

      setValue(parseStateFromJson(responseForEntity, endDate));
    } catch (e) {
      logCalendar.severe('Failed to load $entityId', e);
      return;
    }
  }

  Calendar? parseStateFromJson(dynamic json, DateTime endDate) {
    Map<DateTime, List<CalendarEvent>> groupedEvents = extractEvents(json);
    List<CalendarDay> days = createCalendarDayStates(groupedEvents, endDate);

    return Calendar(days: days);
  }

  Map<DateTime, List<CalendarEvent>> extractEvents(Map<String, dynamic> parsedJson) {
    List<dynamic> eventsJson = parsedJson['events'];

    Map<DateTime, List<CalendarEvent>> result = {};

    for (dynamic event in eventsJson) {
      DateTime startDateTime = DateTime.parse(event['start']).add(timeZone);
      DateTime endDateTime = DateTime.parse(event['end']).add(timeZone);

      String description = event['summary'];

      // an event is listed once, on the day it starts - repeating it for every
      // day it covers buried the rest of the schedule
      result.putIfAbsent(_withoutTime(startDateTime), () => []).add(
            CalendarEvent(
              start: _withoutDate(startDateTime),
              end: _withoutDate(endDateTime),
              description: description,
              days: _spannedDays(startDateTime, endDateTime),
            ),
          );
    }

    return result;
  }

  DateTime _withoutTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  TimeOfDay _withoutDate(DateTime date) {
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  /// How many calendar days an event covers, counted from midnight to midnight.
  /// An event that ends exactly at midnight belongs to the day it started on.
  int _spannedDays(DateTime start, DateTime end) {
    final days = _withoutTime(end).difference(_withoutTime(start)).inDays;

    final endsAtMidnight = end.hour == 0 && end.minute == 0;

    return (endsAtMidnight ? days : days + 1).clamp(1, 999);
  }

  List<CalendarDay> createCalendarDayStates(Map<DateTime, List<CalendarEvent>> groupedEvents, DateTime endDate) {
    return groupedEvents.entries.where((entry) => entry.key.isBefore(endDate) || entry.key.isAtSameMomentAs(endDate)).map((entry) {
      return CalendarDay(date: entry.key, events: entry.value);
    }).toList();
  }
}
