package com.vakit.app.namaz_vakitleri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import android.media.AudioManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vakit.app.namaz_vakitleri/adhan"
    private var audioManager: AudioManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize audio manager
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        
        // Set up method channel for volume button handling
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getVolumeState" -> {
                    val musicVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
                    val maxVolume = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: 15
                    result.success(mapOf("current" to musicVolume, "max" to maxVolume))
                }
                "stopAdhan" -> {
                    // This will trigger via Dart when volume button pressed
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Intercept volume button presses
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                // Notify Dart that volume button was pressed
                notifyVolumeButtonPressed(keyCode)
                true // Consume the event
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    private fun notifyVolumeButtonPressed(keyCode: Int) {
        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
            .invokeMethod("onVolumeButtonPressed", mapOf("key" to keyCode))
    }
}
