import 'package:flutter/widgets.dart';

/// Icons from the Weather Icons font, declared here rather than pulled from the
/// `weather_icons` package: that package subclasses `IconData`, which newer
/// Flutter marks `final`, so it no longer builds. Only the font is needed.
///
/// Code points come from `weather_icons_g.dart`; the font ships in `fonts/`.
class WeatherIcons {
  static const _family = 'WeatherIcons';

  static const IconData day_sunny = IconData(0xf00d, fontFamily: _family);
  static const IconData day_cloudy = IconData(0xf002, fontFamily: _family);
  static const IconData cloud = IconData(0xf041, fontFamily: _family);
  static const IconData cloudy = IconData(0xf013, fontFamily: _family);
  static const IconData showers = IconData(0xf01a, fontFamily: _family);
  static const IconData rain = IconData(0xf019, fontFamily: _family);
  static const IconData snow = IconData(0xf01b, fontFamily: _family);
  static const IconData thunderstorm = IconData(0xf01e, fontFamily: _family);
  static const IconData fog = IconData(0xf014, fontFamily: _family);
}
