package com.vakit.app.namaz_vakitleri

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val adhanChannel = "com.vakit.app.namaz_vakitleri/adhan"
    private val widgetChannel = "com.vakit.app.namaz_vakitleri/widget"
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
                    result.success(true)
                }
                "stopAdhanPlayback" -> {
                    currentlyPlayingAdhan = false
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
    }

    // While adhan is playing, let volume keys behave like normal media volume keys
    // so the user can lower the sound instead of the app force-stopping playback.
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
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
            }
            prayersJson.put(jsonObject)
        }

        prefs.edit()
            .putString("city", arguments["city"]?.toString() ?: "Namaz Vaktim")
            .putString("date_label", arguments["dateLabel"]?.toString() ?: "")
            .putString("active_prayer_name", arguments["activePrayerName"]?.toString() ?: "")
            .putString("prayers_json", prayersJson.toString())
            .apply()

        PrayerTimesWidgetProvider.updateAllWidgets(applicationContext)
    }
}
