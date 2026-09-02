import 'dart:ui';

class LimitedValue {
  double value;
  double min;
  double max;

  LimitedValue({required this.value, required this.min, required this.max});

  /// Where [value] sits between [min] and [max], as 0..1.
  double get fraction {
    final range = max - min;
    return range <= 0 ? 0 : ((value - min) / range).clamp(0.0, 1.0);
  }
}

class LightColor {
  Color value;

  LightColor({required this.value});
}

class Light {
  bool isOn;
  LimitedValue? brightness;
  LimitedValue? temperature;
  LightColor? color;

  Light({required this.isOn, this.brightness, this.color, this.temperature});
}
