import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/states/alarm.dart';

class AlarmCard extends StateCard<AlarmState> {
  const AlarmCard({required super.stateProvider});

  @override
  Widget build(BuildContext context, AlarmState? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    final icon = Icons.alarm;
    final action = () => InstalledApps.startApp('com.google.android.deskclock');

    if (state.next == null) return PlainCard(color: null, icon: icon, text: 'None', action: action);

    final color = const Color.fromARGB(255, 23, 59, 121);

    return PlainCard(
      color: color,
      icon: icon,
      text: _formatDateTime(state.next!.fire),
      action: action,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
