import 'dart:async';

import 'package:nexus/clients/android/api.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/alarm.dart';

class AlarmStateProvider extends StateProvider<AlarmState> {
  Timer? _timer;

  @override
  void init() {
    super.init();

    _timer?.cancel();
    fetchAlarmData().then((_) {
      _timer = Timer.periodic(Duration(seconds: 5), (Timer t) async => await fetchAlarmData());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  Future<void> fetchAlarmData() async {
    DateTime? next = await AndroidClientApi.getNextAlarmClockTriggerTime();
    bool canDismiss = await AndroidClientApi.canDismissAlarm();

    setValue(AlarmState(next: next == null ? null : AlarmInfo(fire: next), canDismiss: canDismiss));
  }

  Future<bool> dismissNextAlarm() async {
    bool result = await AndroidClientApi.dismissNextAlarm();
    if (result) {
      // Refresh alarm data after dismissal
      await fetchAlarmData();
    }
    return result;
  }
}
