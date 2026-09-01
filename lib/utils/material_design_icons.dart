import 'package:flutter/widgets.dart';

/// Icons from the Material Design Icons font, declared here rather than pulled
/// from the `material_design_icons_flutter` package: that package subclasses
/// `IconData`, which newer Flutter marks `final`, so it no longer builds. Only
/// the font is needed.
///
/// Code points come from the package's `icon_map.dart`; the font ships in
/// `fonts/`.
class MaterialDesignIcons {
  static const _family = 'MaterialDesignIcons';

  static const IconData robotVacuum = IconData(0xf070d, fontFamily: _family);
  static const IconData fan = IconData(0xf0210, fontFamily: _family);
}
