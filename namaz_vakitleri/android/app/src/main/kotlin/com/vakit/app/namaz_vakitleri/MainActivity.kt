package com.vakit.app.namaz_vakitleri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vakit.app.namaz_vakitleri/adhan"
    private var currentlyPlayingAdhan = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Track whether adhan is currently playing.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
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
}
