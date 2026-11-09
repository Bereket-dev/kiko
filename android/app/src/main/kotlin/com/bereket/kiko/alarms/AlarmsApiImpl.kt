package com.bereket.kiko.alarms

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.content.getSystemService
import org.json.JSONObject

private const val TAG         = "AlarmsApiImpl"
private const val PREFS_NAME  = "kiko_alarms"
private const val KEY_IDS     = "alarm_ids"          // JSON array of alarmId strings
private const val REQUEST_BASE = 0x4B494B4F          // 'KIKO' in hex — offset for PendingIntent request codes

// ─────────────────────────────────────────────────────────────────────────────
// AlarmsApiImpl
// ─────────────────────────────────────────────────────────────────────────────
//
// Implements the Pigeon AlarmsApi contract using AlarmManager.
//
// • scheduleAlarm   → setAlarmClock() (exact, survives doze, shows clock icon)
// • cancelAlarm     → cancels the PendingIntent; removes from registry
// • cancelAllAlarms → iterates registered IDs and cancels each
//
// All alarmIds are persisted in SharedPreferences so they survive process
// death and can be iterated on boot to reschedule (see BootReceiver).
//
// Request code → lower 24 bits of alarmId.hashCode() to stay within int range.
// ─────────────────────────────────────────────────────────────────────────────

class AlarmsApiImpl(private val context: Context) {

    private val alarmManager: AlarmManager =
        context.getSystemService<AlarmManager>()!!

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Schedule (or replace) the alarm described by the given parameters.
     *
     * Uses [AlarmManager.setAlarmClock] for exact delivery, which:
     *  - is shown in the system clock widget
     *  - fires even in doze mode
     *  - does NOT require SCHEDULE_EXACT_ALARM on API < 31
     *    (the permission is needed only for setExact / setExactAndAllowWhileIdle)
     *
     * On Android 12+ (API 31) [AlarmManager.canScheduleExactAlarms] is checked;
     * if denied we fall back to [AlarmManager.setAndAllowWhileIdle] which may
     * be a few minutes late but still delivers.
     */
    fun scheduleAlarm(
        alarmId: String,
        triggerAtMs: Long,
        routeUri: String,
        title: String,
        body: String,
        isCallPlan: Boolean = false,
    ) {
        val pi = buildPendingIntent(alarmId, routeUri, title, body, isCallPlan)

        val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }

        if (canExact) {
            val clockInfo = AlarmManager.AlarmClockInfo(triggerAtMs, pi)
            alarmManager.setAlarmClock(clockInfo, pi)
            Log.d(TAG, "scheduleAlarm (setAlarmClock): id=$alarmId at=$triggerAtMs")
        } else {
            // Graceful degradation: inexact but still wakes from idle
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMs,
                pi,
            )
            Log.w(TAG, "scheduleAlarm (inexact fallback): id=$alarmId — canScheduleExactAlarms=false")
        }

        registerAlarmId(alarmId)
        AlarmStore.put(context, AlarmRecord(
            alarmId     = alarmId,
            triggerAtMs = triggerAtMs,
            routeUri    = routeUri,
            title       = title,
            body        = body,
            isCallPlan  = isCallPlan,
        ))
    }

    /** Cancel the alarm with [alarmId], if it exists. */
    fun cancelAlarm(alarmId: String) {
        val pi = buildCancelIntent(alarmId)
        alarmManager.cancel(pi)
        pi.cancel()
        unregisterAlarmId(alarmId)
        AlarmStore.remove(context, alarmId)
        Log.d(TAG, "cancelAlarm: id=$alarmId")
    }

    /** Cancel all alarms registered by Kiko. */
    fun cancelAllAlarms() {
        val ids = getRegisteredIds()
        for (id in ids) {
            val pi = buildCancelIntent(id)
            alarmManager.cancel(pi)
            pi.cancel()
        }
        prefs.edit().remove(KEY_IDS).apply()
        AlarmStore.clear(context)
        Log.d(TAG, "cancelAllAlarms: cancelled ${ids.size} alarms")
    }

    /** Returns all currently registered alarmIds (for use by BootReceiver). */
    fun getRegisteredIds(): List<String> {
        val raw = prefs.getString(KEY_IDS, null) ?: return emptyList()
        return try {
            val arr = org.json.JSONArray(raw)
            List(arr.length()) { arr.getString(it) }
        } catch (e: Exception) {
            Log.w(TAG, "getRegisteredIds: parse error — $e")
            emptyList()
        }
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    /**
     * Build the PendingIntent that AlarmReceiver will receive.
     * Extras carry all display data so AlarmReceiver never needs DB access.
     */
    private fun buildPendingIntent(
        alarmId: String,
        routeUri: String,
        title: String,
        body: String,
        isCallPlan: Boolean,
    ): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.bereket.kiko.ALARM"
            putExtra(EXTRA_ALARM_ID,    alarmId)
            putExtra(EXTRA_ROUTE_URI,   routeUri)
            putExtra(EXTRA_TITLE,       title)
            putExtra(EXTRA_BODY,        body)
            putExtra(EXTRA_IS_CALL_PLAN, isCallPlan)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(alarmId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Build a matching PendingIntent for cancellation.
     * The extras don't matter for matching — only action + request code do.
     */
    private fun buildCancelIntent(alarmId: String): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.bereket.kiko.ALARM"
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode(alarmId),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: PendingIntent.getBroadcast(
            context,
            requestCode(alarmId),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestCode(alarmId: String): Int =
        (REQUEST_BASE + (alarmId.hashCode() and 0xFF_FFFF)) and 0x7FFF_FFFF

    private fun registerAlarmId(alarmId: String) {
        val ids = getRegisteredIds().toMutableSet()
        ids.add(alarmId)
        prefs.edit()
            .putString(KEY_IDS, org.json.JSONArray(ids.toList()).toString())
            .apply()
    }

    private fun unregisterAlarmId(alarmId: String) {
        val ids = getRegisteredIds().toMutableSet()
        if (ids.remove(alarmId)) {
            prefs.edit()
                .putString(KEY_IDS, org.json.JSONArray(ids.toList()).toString())
                .apply()
        }
    }
}
