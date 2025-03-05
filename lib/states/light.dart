import 'dart:ui';

class LimitedValueState {
  double value;
  double min;
  double max;

  LimitedValueState({required this.value, required this.min, required this.max});
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
