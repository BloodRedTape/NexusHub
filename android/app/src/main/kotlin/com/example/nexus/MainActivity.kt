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
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
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
            when (call.method) {
                "getNextAlarmClockTriggerTime" -> {
                    result.success(getNextAlarmClockTriggerTime())
                }
                "canDismissAlarm" -> {
                    result.success(canDismissAlarm())
                }
                "dismissNextAlarm" -> {
                    result.success(dismissNextAlarm())
                }
                "setBrightness" -> {
                    val brightness = call.argument<Double>("brightness")
                    if (brightness != null) {
                        result.success(setBrightness(brightness))
                    } else {
                        result.error("INVALID_ARGUMENT", "Brightness value is required", null)
                    }
                }
                "canModifySystemSettings" -> {
                    result.success(canModifySystemSettings())
                }
                "setKeepScreenOn" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    result.success(setKeepScreenOn(on))
                }
                else -> {
                    result.notImplemented()
                }
            }
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

    private fun canDismissAlarm(): Boolean {
        try {
            // Check API level
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                return false
            }

            // Check if there's an app that can handle dismiss
            val intent = Intent(AlarmClock.ACTION_DISMISS_ALARM).apply {
                putExtra(AlarmClock.EXTRA_ALARM_SEARCH_MODE, AlarmClock.ALARM_SEARCH_MODE_NEXT)
            }
            return intent.resolveActivity(packageManager) != null
        } catch (_: Exception) {
            return false
        }
    }

    private fun dismissNextAlarm(): Boolean {
        try {
            if (!canDismissAlarm()) {
                return false
            }

            val intent = Intent(AlarmClock.ACTION_DISMISS_ALARM).apply {
                putExtra(AlarmClock.EXTRA_ALARM_SEARCH_MODE, AlarmClock.ALARM_SEARCH_MODE_NEXT)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (_: Exception) {
            return false
        }
    }

    private fun setBrightness(brightness: Double): Boolean {
        try {
            // Check if we have permission to modify system settings
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.System.canWrite(this)) {
                    // Request permission
                    val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                        data = android.net.Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    return false
                }
            }

            // Clamp brightness to 0.0-1.0 range and convert to 0-255
            val clampedBrightness = brightness.coerceIn(0.0, 1.0)
            val brightnessValue = (clampedBrightness * 255).toInt()

            // Set system brightness
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                brightnessValue
            )

            // Also update current window brightness
            val layoutParams = window.attributes
            layoutParams.screenBrightness = clampedBrightness.toFloat()
            window.attributes = layoutParams

            return true
        } catch (_: Exception) {
            return false
        }
    }

    private fun setKeepScreenOn(on: Boolean): Boolean {
        return try {
            val flags = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            runOnUiThread { if (on) window.addFlags(flags) else window.clearFlags(flags) }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun canModifySystemSettings(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.System.canWrite(this)
        } else {
            true
        }
    }
}
