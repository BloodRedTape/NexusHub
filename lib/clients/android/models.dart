class AlarmInfo {
  final DateTime fire;

  const AlarmInfo({required this.fire});
}

class Alarm {
  final AlarmInfo? next;
  final bool canDismiss;

  const Alarm({required this.next, this.canDismiss = false});
}
