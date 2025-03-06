class AlarmInfo {
  final DateTime fire;

  const AlarmInfo({required this.fire});
}

class AlarmState {
  final AlarmInfo? next;

  const AlarmState({required this.next});
}
