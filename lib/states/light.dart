import 'dart:ui';

class LimitedValueState {
  double value;
  double min;
  double max;

  LimitedValueState({required this.value, required this.min, required this.max});

  /// Where [value] sits between [min] and [max], as 0..1.
  double get fraction {
    final range = max - min;
    return range <= 0 ? 0 : ((value - min) / range).clamp(0.0, 1.0);
  }
}

class ColorState {
  Color value;

  ColorState({required this.value});
}

class LightState {
  bool isOn;
  LimitedValueState? brightness;
  LimitedValueState? temperature;
  ColorState? color;

  LightState({required this.isOn, this.brightness, this.color, this.temperature});
}
