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

  static Future<bool> canDismissAlarm() async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('canDismissAlarm');
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> dismissNextAlarm() async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('dismissNextAlarm');
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canModifySystemSettings() async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('canModifySystemSettings');
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setKeepScreenOn(bool on) async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('setKeepScreenOn', {'on': on});
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> wakeScreen() async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('wakeScreen');
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }

  /// Called by the native side when the screen goes off, however that happened.
  static void onScreenOff(void Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenOff') handler();
    });
  }

  static Future<bool> setBrightness(double brightness) async {
    try {
      if (Platform.isAndroid) {
        dynamic result = await _channel.invokeMethod<dynamic>('setBrightness', {'brightness': brightness});
        return result is bool ? result : false;
      } else {
        throw UnimplementedError();
      }
    } catch (_) {
      return false;
    }
  }
}
