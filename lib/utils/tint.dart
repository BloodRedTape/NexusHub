import 'dart:ui';

class Tint {
  static Color? color({Color? color, double fraction = 0.4}) {
    if (color == null) return null;

    return Color.fromARGB(255, (color.r * fraction * 255).toInt(), (color.g * fraction * 255).toInt(), (color.b * fraction * 255).toInt());
  }
}
