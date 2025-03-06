import 'dart:io';

import 'package:flutter/services.dart';

class AndroidClientApi {
  static const MethodChannel _channel = MethodChannel('alarm_manager_plugin');

  static Future<DateTime?> getNextAlarmClockTriggerTime() async {
    try {
      if (Platform.isAndroid) {
        dynamic triggerTime = await _channel.invokeMethod<dynamic>('getNextAlarmClockTriggerTime');

        if (triggerTime is int) return triggerTime == 0 ? null : DateTime.fromMillisecondsSinceEpoch(triggerTime);

        return null;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return null;
    }
  }
}
