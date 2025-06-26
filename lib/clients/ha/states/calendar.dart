import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/calendar.dart';

class CalendarStateProvider extends StateProvider<CalendarState> {
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
        print('CalendarStateProvider: Null Reseponse');

        return;
      }

      dynamic responseForEntity = response.serviceResponse[entityId];

      setValue(parseStateFromJson(responseForEntity, endDate));
    } catch (e) {
      print('CalendarStateProvider: $e');
      return;
    }
  }

  CalendarState? parseStateFromJson(dynamic json, DateTime endDate) {
    Map<DateTime, List<CalendarEventState>> groupedEvents = extractEvents(json);
    List<CalendarDayState> days = createCalendarDayStates(groupedEvents, endDate);

    return CalendarState(days: days);
  }

  Map<DateTime, List<CalendarEventState>> extractEvents(Map<String, dynamic> parsedJson) {
    List<dynamic> eventsJson = parsedJson['events'];

    Map<DateTime, List<CalendarEventState>> result = {};

    for (dynamic event in eventsJson) {
      DateTime startDateTime = DateTime.parse(event['start']).add(timeZone);
      DateTime endDateTime = DateTime.parse(event['end']).add(timeZone);

      String description = event['summary'];

      List<CalendarEventState> events = _sliceEvent(startDateTime, endDateTime, description);

      DateTime insertDate = _withoutTime(startDateTime);
      for (int i = 0; i < events.length; i++) {
        var event = events[i];

        if (events.length > 1) {
          event = CalendarEventState(
            start: event.start,
            end: event.end,
            description: event.description + ' (Day ${i + 1}/${events.length})',
          );
        }
        result.putIfAbsent(insertDate, () => []).add(event);
        insertDate = insertDate.add(Duration(days: 1));
      }
    }

    return result;
  }

  DateTime _withoutTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  TimeOfDay _withoutDate(DateTime date) {
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  List<CalendarEventState> _sliceEvent(DateTime start, DateTime end, String description) {
    final difference = _withoutTime(end).difference(_withoutTime(start)).inDays;

    List<CalendarEventState> result = [];

    var startNoDate = _withoutDate(start);
    final endNoDate = _withoutDate(end);

    for (int i = 0; i < difference; i++) {
      result.add(
        CalendarEventState(
          start: startNoDate,
          end: TimeOfDay(hour: 24, minute: 0),
          description: description,
        ),
      );

      startNoDate = TimeOfDay(hour: 0, minute: 0);
    }

    result.add(
      CalendarEventState(
        start: startNoDate,
        end: endNoDate,
        description: description,
      ),
    );

    return result;
  }

  List<CalendarDayState> createCalendarDayStates(Map<DateTime, List<CalendarEventState>> groupedEvents, DateTime endDate) {
    return groupedEvents.entries.where((entry) => entry.key.isBefore(endDate) || entry.key.isAtSameMomentAs(endDate)).map((entry) {
      return CalendarDayState(date: entry.key, events: entry.value);
    }).toList();
  }
}
