import 'package:flutter/widgets.dart';

class LauncherApp {
  final String name;
  final Future<ImageProvider> icon;
  final void Function(BuildContext context) launch;

  const LauncherApp({required this.name, required this.icon, required this.launch});
}

class AlarmInfo {
  final DateTime fire;

  const AlarmInfo({required this.fire});
}

class Alarm {
  final AlarmInfo? next;
  final bool canDismiss;

  const Alarm({required this.next, this.canDismiss = false});
}
