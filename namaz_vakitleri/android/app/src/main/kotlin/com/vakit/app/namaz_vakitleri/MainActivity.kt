package com.vakit.app.namaz_vakitleri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.KeyEvent
import android.media.AudioManager
import android.os.Handler
import android.os.Looper

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vakit.app.namaz_vakitleri/adhan"
    private var audioManager: AudioManager? = null
    private var lastVolumeLevel = 0
    private var volumeCheckHandler: Handler? = null
    private var currentlyPlayingAdhan = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize audio manager
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        lastVolumeLevel = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
        
        // Set up method channel for volume button handling
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAdhanPlayback" -> {
                    currentlyPlayingAdhan = true
                    startVolumeMonitoring()
                    result.success(true)
                }
                "stopAdhanPlayback" -> {
                    currentlyPlayingAdhan = false
                    stopVolumeMonitoring()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Intercept volume button presses - faster response
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                if (currentlyPlayingAdhan) {
                    // Stop adhan immediately when any volume button is pressed
                    notifyAdhanStop()
                    true // Consume the event to prevent volume change
                } else {
                    super.onKeyDown(keyCode, event) // Normal volume control
                }
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    private fun notifyAdhanStop() {
        try {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                .invokeMethod("stopAdhan", null)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startVolumeMonitoring() {
        stopVolumeMonitoring()
        
        volumeCheckHandler = Handler(Looper.getMainLooper())
        val runnable = object : Runnable {
            override fun run() {
                if (currentlyPlayingAdhan) {
                    val currentVolume = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: 0
                    if (currentVolume != lastVolumeLevel) {
                        // Volume changed - stop adhan
                        notifyAdhanStop()
                        stopVolumeMonitoring()
                    } else {
                        // Continue monitoring
                        volumeCheckHandler?.postDelayed(this, 100)
                    }
                }
            }
        }
        volumeCheckHandler?.post(runnable)
    }

    private fun stopVolumeMonitoring() {
        volumeCheckHandler?.removeCallbacksAndMessages(null)
        volumeCheckHandler = null
    }
}
