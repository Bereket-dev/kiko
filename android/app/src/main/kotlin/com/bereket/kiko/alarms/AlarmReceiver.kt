package com.bereket.kiko.alarms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

private const val TAG = "AlarmReceiver"

const val EXTRA_ALARM_ID    = "alarm_id"
const val EXTRA_ROUTE_URI   = "route_uri"
const val EXTRA_TITLE       = "alarm_title"
const val EXTRA_BODY        = "alarm_body"
const val EXTRA_IS_CALL_PLAN = "is_call_plan"

// ─────────────────────────────────────────────────────────────────────────────
// AlarmReceiver
// ─────────────────────────────────────────────────────────────────────────────
//
// Receives the broadcast from AlarmManager when a scheduled alarm fires.
// Fires a heads-up / fullscreen notification then exits quickly.
//
// Must be fast — no I/O or long work in onReceive.
// ─────────────────────────────────────────────────────────────────────────────

class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId     = intent.getStringExtra(EXTRA_ALARM_ID) ?: return
        val routeUri    = intent.getStringExtra(EXTRA_ROUTE_URI) ?: ""
        val title       = intent.getStringExtra(EXTRA_TITLE) ?: "Kiko Reminder"
        val body        = intent.getStringExtra(EXTRA_BODY) ?: ""
        val isCallPlan  = intent.getBooleanExtra(EXTRA_IS_CALL_PLAN, false)

        Log.i(TAG, "Alarm fired: id=$alarmId route=$routeUri")

        val channelId = if (isCallPlan) CHANNEL_CALL_PLAN else CHANNEL_REMINDERS
        // Use the lower 24 bits of the alarmId hash as notification ID to
        // avoid integer overflow while keeping uniqueness within a session.
        val notifId = alarmId.hashCode() and 0xFF_FFFF

        NotificationHelper.showAlarmNotification(
            context  = context,
            notifId  = notifId,
            channelId = channelId,
            title    = title,
            body     = body,
            routeUri = routeUri,
        )
    }
}
