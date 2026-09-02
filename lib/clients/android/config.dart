/// What should happen to the screen right now.
enum ScreenOnDecision {
  /// A blocking interval - never turn it on by ourselves.
  blocked,

  /// Hold it on, waking it if dark.
  keepOn,

  /// Nothing to say; let the system dim it on its own timeout.
  idle,
}

class ScreenOnInterval {
  final int startMinutes; // minutes since midnight
  final int endMinutes;

  /// Blocking intervals win over enabling ones - the screen stays off no
  /// matter what the schedule or the sensor say.
  final bool blocking;

  ScreenOnInterval({required this.startMinutes, required this.endMinutes, this.blocking = false});

  Map<String, dynamic> toJson() => {'start': startMinutes, 'end': endMinutes, 'blocking': blocking};

  static ScreenOnInterval? fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end = json['end'];

    if (start is! int || end is! int) return null;

    return ScreenOnInterval(startMinutes: start, endMinutes: end, blocking: json['blocking'] as bool? ?? false);
  }

  bool contains(DateTime time) {
    final minutes = time.hour * 60 + time.minute;

    // Interval wrapping over midnight (e.g. 22:00 - 06:00)
    if (endMinutes <= startMinutes) return minutes >= startMinutes || minutes < endMinutes;

    return minutes >= startMinutes && minutes < endMinutes;
  }

  // Config reloads rebuild intervals, so a dismissed one must match by value.
  @override
  bool operator ==(Object other) =>
      other is ScreenOnInterval &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes &&
      other.blocking == blocking;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes, blocking);

  static String format(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');

    return '$h:$m';
  }
}

class AndroidConfig {
  final bool autoBrightnessEnabled;
  final double brightnessThreshold;
  final List<ScreenOnInterval> screenOnIntervals;

  /// Binary sensors deciding whether the screen may turn on; any of them
  /// being on is enough. Empty when the schedule alone decides.
  final List<String> screenOnSensors;

  AndroidConfig({
    this.autoBrightnessEnabled = false,
    this.brightnessThreshold = 70.0,
    this.screenOnIntervals = const [],
    this.screenOnSensors = const [],
  });

  AndroidConfig copyWith({
    bool? autoBrightnessEnabled,
    double? brightnessThreshold,
    List<ScreenOnInterval>? screenOnIntervals,
    List<String>? screenOnSensors,
  }) {
    return AndroidConfig(
      autoBrightnessEnabled: autoBrightnessEnabled ?? this.autoBrightnessEnabled,
      brightnessThreshold: brightnessThreshold ?? this.brightnessThreshold,
      screenOnIntervals: screenOnIntervals ?? this.screenOnIntervals,
      screenOnSensors: screenOnSensors ?? this.screenOnSensors,
    );
  }

  /// Whether the screen should be held on at [time], given the sensor states
  /// by entity id.
  ///
  /// [dismissedInterval] is the keep-on interval the user already dismissed by
  /// switching the screen off; it stays inert until it ends.
  ScreenOnDecision screenOnDecision(
    DateTime time,
    Map<String, bool?> sensorStates, {
    ScreenOnInterval? dismissedInterval,
  }) {
    final matching = screenOnIntervals.where((interval) => interval.contains(time));

    if (matching.any((interval) => interval.blocking)) return ScreenOnDecision.blocked;

    if (screenOnSensors.any((id) => sensorStates[id] == true)) return ScreenOnDecision.keepOn;

    final keepOn = matching.where((interval) => interval != dismissedInterval);

    if (keepOn.isNotEmpty) return ScreenOnDecision.keepOn;

    return ScreenOnDecision.idle;
  }

  /// The keep-on interval covering [time], if any. Identifies which interval a
  /// user's screen-off dismisses.
  ScreenOnInterval? activeKeepOnInterval(DateTime time) {
    for (final interval in screenOnIntervals) {
      if (!interval.blocking && interval.contains(time)) return interval;
    }

    return null;
  }

  Map<String, dynamic> toJson() => {
        'autoBrightnessEnabled': autoBrightnessEnabled,
        'brightnessThreshold': brightnessThreshold,
        'screenOnIntervals': screenOnIntervals.map((i) => i.toJson()).toList(),
        'screenOnSensors': screenOnSensors,
      };

  static AndroidConfig fromJson(Map<String, dynamic> json) {
    return AndroidConfig(
      autoBrightnessEnabled: json['autoBrightnessEnabled'] as bool? ?? false,
      brightnessThreshold: (json['brightnessThreshold'] as num?)?.toDouble() ?? 70.0,
      screenOnIntervals: (json['screenOnIntervals'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ScreenOnInterval.fromJson)
          .whereType<ScreenOnInterval>()
          .toList(),
      screenOnSensors: (json['screenOnSensors'] as List? ?? const []).whereType<String>().toList(),
    );
  }
}
