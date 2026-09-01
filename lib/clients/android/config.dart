class ScreenOnInterval {
  final int startMinutes; // minutes since midnight
  final int endMinutes;

  ScreenOnInterval({required this.startMinutes, required this.endMinutes});

  bool contains(DateTime time) {
    final minutes = time.hour * 60 + time.minute;

    // Interval wrapping over midnight (e.g. 22:00 - 06:00)
    if (endMinutes <= startMinutes) return minutes >= startMinutes || minutes < endMinutes;

    return minutes >= startMinutes && minutes < endMinutes;
  }

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

  AndroidConfig({
    this.autoBrightnessEnabled = false,
    this.brightnessThreshold = 70.0,
    this.screenOnIntervals = const [],
  });

  AndroidConfig copyWith({
    bool? autoBrightnessEnabled,
    double? brightnessThreshold,
    List<ScreenOnInterval>? screenOnIntervals,
  }) {
    return AndroidConfig(
      autoBrightnessEnabled: autoBrightnessEnabled ?? this.autoBrightnessEnabled,
      brightnessThreshold: brightnessThreshold ?? this.brightnessThreshold,
      screenOnIntervals: screenOnIntervals ?? this.screenOnIntervals,
    );
  }

  static String serialize(AndroidConfig? config) {
    if (config == null) return '';

    final intervals = config.screenOnIntervals.map((i) => '${i.startMinutes}:${i.endMinutes}').join(',');

    return '${config.autoBrightnessEnabled ? '1' : '0'}~${config.brightnessThreshold}~$intervals';
  }

  static AndroidConfig? deserialize(String string) {
    if (string.isEmpty) return AndroidConfig();

    final parts = string.split('~');

    if (parts.length < 2) return AndroidConfig();

    return AndroidConfig(
      autoBrightnessEnabled: parts[0] == '1',
      brightnessThreshold: double.tryParse(parts[1]) ?? 70.0,
      screenOnIntervals: parts.length < 3 ? const [] : _deserializeIntervals(parts[2]),
    );
  }

  static List<ScreenOnInterval> _deserializeIntervals(String string) {
    if (string.isEmpty) return const [];

    return string.split(',').map((part) {
      final bounds = part.split(':');

      if (bounds.length != 2) return null;

      final start = int.tryParse(bounds[0]);
      final end = int.tryParse(bounds[1]);

      if (start == null || end == null) return null;

      return ScreenOnInterval(startMinutes: start, endMinutes: end);
    }).whereType<ScreenOnInterval>().toList();
  }
}
