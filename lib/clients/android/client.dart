import 'package:nexus/clients/android/provider.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/alarm.dart';

class AndroidClient {
  AlarmStateProvider _alarmStateProvider = AlarmStateProvider();

  AndroidClient() {
    _alarmStateProvider.init();
  }

  StateProvider<AlarmState> getAlarmProvider() {
    return _alarmStateProvider;
  }
}
