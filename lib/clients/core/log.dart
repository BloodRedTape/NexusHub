import 'package:logging/logging.dart';

/// Log categories, in the Unreal sense: every subsystem logs into its own, and
/// the log page shows which one a line came from.
///
/// Names are dotted paths, so a category can hang off another one.
final logAndroid = Logger('Android');
final logCore = Logger('Core');
final logFlutter = Logger('Flutter');
final logHa = Logger('HA');
final logCalendar = Logger('HA.Calendar');
