package com.bereket.kiko.call

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.bereket.kiko.alarms.AlarmStore
import com.bereket.kiko.bridge.KikoApplication

private const val TAG = "BootReceiver"

// ─────────────────────────────────────────────────────────────────────────────
// BootReceiver
// ─────────────────────────────────────────────────────────────────────────────
//
// Listens for:
//   BOOT_COMPLETED — device fully booted; AlarmManager lost all alarms.
//   TIME_CHANGED   — user changed clock manually; re-anchor alarms.
//
// Strategy: AlarmStore (SharedPreferences) persists every scheduled alarm's
// full record (id, triggerAtMs, routeUri, title, body, isCallPlan).  On boot
// or time change we read all future-dated records and re-schedule them via
// AlarmsApiImpl without touching the DB.  Records for past alarms are
// automatically skipped by AlarmStore.getPending().
//
// KikoApplication.onCreate() runs before onReceive, so alarmsApi is ready.
// ─────────────────────────────────────────────────────────────────────────────

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_TIME_CHANGED) {
            return
        }

        val app = context.applicationContext as? KikoApplication
        if (app == null) {
            Log.e(TAG, "onReceive: applicationContext is not KikoApplication — aborting.")
            return
        }

        val pending = AlarmStore.getPending(context)
        if (pending.isEmpty()) {
            Log.i(TAG, "onReceive [$action]: no pending alarms to reschedule.")
            return
        }

        Log.i(TAG, "onReceive [$action]: rescheduling ${pending.size} alarm(s).")

        for (record in pending) {
            try {
                app.alarmsApi.scheduleAlarm(
                    alarmId     = record.alarmId,
                    triggerAtMs = record.triggerAtMs,
                    routeUri    = record.routeUri,
                    title       = record.title,
                    body        = record.body,
                    isCallPlan  = record.isCallPlan,
                )
                Log.d(TAG, "  rescheduled: id=${record.alarmId} at=${record.triggerAtMs}")
            } catch (e: Exception) {
                Log.e(TAG, "  failed to reschedule ${record.alarmId}: $e")
            }
        }
    }
}
