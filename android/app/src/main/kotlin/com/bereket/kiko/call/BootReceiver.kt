package com.bereket.kiko.call

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

private const val TAG = "BootReceiver"

/**
 * Receives BOOT_COMPLETED so the app can re-initialise any state that needs to
 * run after a device reboot (e.g., re-registering alarms or checking the
 * pending event queue).
 *
 * KikoApplication is instantiated automatically when the process starts, so
 * [EncryptedLookupStore] and [PendingEventQueue] are already available by the
 * time [onReceive] runs.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        Log.i(TAG, "Device boot completed — Kiko initialised via Application class.")
        // KikoApplication.onCreate() has already run at this point, so the
        // lookup store and pending queue are ready.  Add any post-boot logic
        // here (e.g., re-scheduling AlarmManager triggers).
    }
}
