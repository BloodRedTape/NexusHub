import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_assistant/home_assistant.dart';
import 'package:intl/intl.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/calendar.dart';

class EntityStateProvider extends StateProvider<String> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;

  EntityStateProvider(
      {required this.entityId, required this.entitiesStateProvider});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    setValue(filtered.first.state);
  }
}

class SensorStateProvider extends StateProvider<double> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;

  SensorStateProvider(
      {required this.entityId, required this.entitiesStateProvider});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      //print("Can't find $entityId from ${entities?.length} entities");
      setValue(null);
      return;
    }

    setValue(double.tryParse(filtered.first.state));
  }
}

class SwitchStateProvider extends StateProvider<bool> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(bool) requestState;

  SwitchStateProvider(
      {required this.entityId,
      required this.entitiesStateProvider,
      required this.requestState});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  @override
  void requestValue(bool value) {
    requestState(value);
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    setValue(_parseState(filtered.first.state));
  }

  bool? _parseState(String state) {
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }
}

class CurtainStateProvider extends StateProvider<double> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(double) requestState;

  CurtainStateProvider(
      {required this.entityId,
      required this.entitiesStateProvider,
      required this.requestState});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  @override
  void requestValue(double newValue) {
    requestState(newValue);
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }
    setValue(filtered.first.attributes.current_position);
  }
}

class CalendarStateProvider extends StateProvider<CalendarState> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final Future<ServiceResponse?> Function(String, DateTime, DateTime)
      getCalendarEvents;

  CalendarStateProvider(
      {required this.entityId,
      required this.entitiesStateProvider,
      required this.getCalendarEvents});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  void _onEntitiesChanged(List<Entity>? entities) async {
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    final DateTime now = DateTime.now();

    final DateTime endDate = now.add(Duration(days: 7));

    try {
      ServiceResponse? response =
          await getCalendarEvents(entityId, now, endDate);

      if (response == null) {
        print('CalendarStateProvider: Null Reseponse');

        return;
      }

      dynamic responseForEntity = response.serviceResponse[entityId];

      setValue(parseStateFromJson(responseForEntity));
    } catch (e) {
      print('CalendarStateProvider: $e');
      return;
    }
  }

  CalendarState? parseStateFromJson(dynamic json) {
    Map<DateTime, List<CalendarEventState>> groupedEvents = extractEvents(json);
    List<CalendarDayState> days = createCalendarDayStates(groupedEvents);

    return CalendarState(days: days);
  }

  Map<DateTime, List<CalendarEventState>> extractEvents(
      Map<String, dynamic> parsedJson) {
    List<dynamic> eventsJson = parsedJson['events'];

    Map<DateTime, List<CalendarEventState>> result = {};

    for (dynamic event in eventsJson) {
      DateTime startDateTime = DateTime.parse(event['start']);
      DateTime endDateTime = DateTime.parse(event['end']);

      TimeOfDay start =
          TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);
      TimeOfDay end =
          TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);
      String description = event['summary'];

      DateTime startDateNoTime =
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day);

      DateTime endDateNoTime =
          DateTime(endDateTime.year, endDateTime.month, endDateTime.day);

      if (startDateNoTime != endDateNoTime) {
        print("Too big of an event");
        continue;
      }
      result.putIfAbsent(startDateNoTime, () => []).add(
          CalendarEventState(start: start, end: end, description: description));
    }

    return result;
  }

  List<CalendarDayState> createCalendarDayStates(
      Map<DateTime, List<CalendarEventState>> groupedEvents) {
    return groupedEvents.entries.map((entry) {
      return CalendarDayState(date: entry.key, events: entry.value);
    }).toList();
  }
}
