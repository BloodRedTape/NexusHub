import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/providers/alarm.dart';

class AlarmCard extends StateCard<AlarmState> {
  const AlarmCard({required super.stateProvider});

  @override
  Widget build(BuildContext context, AlarmState? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    final color = const Color.fromARGB(255, 38, 82, 158);
    final icon = Icons.alarm;

    if (state.alarms.isEmpty)
      return PlainCard(color: color, icon: icon, text: 'None');

    final AlarmInfo nearest = state.alarms.first;
    final AlarmInfo? next = state.alarms.length > 1 ? state.alarms[1] : null;

    return PlainCard(
      color: color,
      icon: icon,
      text: _formatDateTime(nearest.fire),
      subText: next != null ? _formatDateTime(next.fire) : null,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
