package com.vakit.app.ezanlar

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val adhanChannel = "com.vakit.app.ezanlar/adhan"
    private val widgetChannel = "com.vakit.app.ezanlar/widget"
    private val hapticChannel = "com.vakit.app.ezanlar/haptics"
    private var currentlyPlayingAdhan = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Track whether adhan is currently playing.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            adhanChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdhanPlayback" -> {
                    currentlyPlayingAdhan = true
                    volumeControlStream = AudioManager.STREAM_MUSIC
                    result.success(true)
                }
                "stopAdhanPlayback" -> {
                    currentlyPlayingAdhan = false
                    volumeControlStream = AudioManager.USE_DEFAULT_STREAM_TYPE
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            widgetChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePrayerWidget" -> {
                    updatePrayerWidget(call.arguments as? Map<*, *>)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            hapticChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    vibrate(call.argument<String>("mode"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // While adhan is playing, let volume keys behave like normal media volume keys
    // so the user can lower the sound instead of the app force-stopping playback.
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (currentlyPlayingAdhan) {
                    volumeControlStream = AudioManager.STREAM_MUSIC
                }
                super.onKeyDown(keyCode, event)
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    private fun updatePrayerWidget(arguments: Map<*, *>?) {
        if (arguments == null) return

        val prefs = applicationContext.getSharedPreferences("prayer_widget", Context.MODE_PRIVATE)
        val prayers = arguments["prayers"] as? List<*>
        val prayersJson = JSONArray()

        prayers?.forEach { item ->
            val prayer = item as? Map<*, *> ?: return@forEach
            val jsonObject = JSONObject().apply {
                put("name", prayer["name"]?.toString() ?: "")
                put("time", prayer["time"]?.toString() ?: "")
                put("displayLabel", prayer["displayLabel"]?.toString() ?: "")
                put("shortLabel", prayer["shortLabel"]?.toString() ?: "")
            }
            prayersJson.put(jsonObject)
        }

        prefs.edit()
            .putString("city", arguments["city"]?.toString() ?: "Ezanlar")
            .putString("language", arguments["language"]?.toString() ?: "tr")
            .putString("date_label", arguments["dateLabel"]?.toString() ?: "")
            .putString("active_prayer_name", arguments["activePrayerName"]?.toString() ?: "")
            .putString("prayers_json", prayersJson.toString())
            .apply()

        PrayerTimesWidgetProvider.updateAllWidgets(applicationContext)
    }

    private fun vibrate(mode: String?) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return

        if (!vibrator.hasVibrator()) return

        val duration = when (mode) {
            "target" -> 140L
            "milestone" -> 90L
            else -> 35L
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitude = when (mode) {
                "target" -> 220
                "milestone" -> 180
                else -> 120
            }
            vibrator.vibrate(
                VibrationEffect.createOneShot(duration, amplitude)
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }
}
