class AlarmInfo {
  final DateTime fire;

  const AlarmInfo({required this.fire});
}

class AlarmState {
  final AlarmInfo? next;
  final bool canDismiss;

  const AlarmState({required this.next, this.canDismiss = false});
}
