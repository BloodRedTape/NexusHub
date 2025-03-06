package com.example.nexus

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.AlarmClock
import android.provider.AlarmClock.ACTION_SHOW_ALARMS
import android.provider.AlarmClock.ACTION_SHOW_TIMERS
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall


class MainActivity : FlutterActivity(){
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "alarm_manager_plugin").setMethodCallHandler {
            call, result ->
            if (call.method == "getNextAlarmClockTriggerTime") {
                result.success(getNextAlarmClockTriggerTime())
            } else {
                result.notImplemented()
            }// This method is invoked on the main thread.
            // TODO
        }
    }

    private fun getNextAlarmClockTriggerTime(): Long{
        try{
            val alarmManager: AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            var alarm = alarmManager.getNextAlarmClock();
            return if (alarm != null) alarm.triggerTime else 0L
        }catch(_: Exception){
            return 0L;
        }
    }
}
