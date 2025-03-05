class CalendarStateProvider extends StateProvider<CalendarState> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final Future<ServiceResponse?> Function(String, DateTime, DateTime) getCalendarEvents;
  final Duration rangeFromNow;

  CalendarStateProvider({required this.entityId, required this.entitiesStateProvider, required this.getCalendarEvents, required this.rangeFromNow});

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
    List<Entity> filtered = (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

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
      DateTime startDateTime = DateTime.parse(event['start']);
      DateTime endDateTime = DateTime.parse(event['end']);

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
