import 'package:nexus/providers/state.dart';

class AlarmInfo {
  final DateTime fire;

  const AlarmInfo({required this.fire});
}

class AlarmState {
  final List<AlarmInfo> alarms;

  const AlarmState({required this.alarms});
}

typedef AlarmStateProvider = StateProvider<AlarmState>;
