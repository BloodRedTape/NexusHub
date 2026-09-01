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

  static String serialize(AndroidConfig? config) {
    if (config == null) return '';

    final intervals =
        config.screenOnIntervals.map((i) => '${i.startMinutes}:${i.endMinutes}:${i.blocking ? '1' : '0'}').join(',');

    return '${config.autoBrightnessEnabled ? '1' : '0'}~${config.brightnessThreshold}~$intervals~${config.screenOnSensors.join(',')}';
  }

  static AndroidConfig? deserialize(String string) {
    if (string.isEmpty) return AndroidConfig();

    final parts = string.split('~');

    if (parts.length < 2) return AndroidConfig();

    return AndroidConfig(
      autoBrightnessEnabled: parts[0] == '1',
      brightnessThreshold: double.tryParse(parts[1]) ?? 70.0,
      screenOnIntervals: parts.length < 3 ? const [] : _deserializeIntervals(parts[2]),
      screenOnSensors: parts.length < 4 ? const [] : _deserializeSensors(parts[3]),
    );
  }

  static List<String> _deserializeSensors(String string) {
    if (string.isEmpty) return const [];

    return string.split(',').where((id) => id.isNotEmpty).toList();
  }

  static List<ScreenOnInterval> _deserializeIntervals(String string) {
    if (string.isEmpty) return const [];

    return string.split(',').map((part) {
      final bounds = part.split(':');

      if (bounds.length < 2) return null;

      final start = int.tryParse(bounds[0]);
      final end = int.tryParse(bounds[1]);

      if (start == null || end == null) return null;

      return ScreenOnInterval(
        startMinutes: start,
        endMinutes: end,
        blocking: bounds.length > 2 && bounds[2] == '1',
      );
    }).whereType<ScreenOnInterval>().toList();
  }
}
