package com.vakit.app.namaz_vakitleri

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device boot completed - notifications should be active")
            // Android's alarm manager will automatically restore scheduled alarms/notifications
            // on device boot if they were scheduled with exactAllowWhileIdle
        }
    }
}
