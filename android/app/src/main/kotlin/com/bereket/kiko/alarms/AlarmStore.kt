package com.bereket.kiko.alarms

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

private const val TAG        = "AlarmStore"
private const val PREFS_NAME = "kiko_alarm_store"

// ─────────────────────────────────────────────────────────────────────────────
// AlarmRecord — all data needed to re-fire a pending alarm after reboot
// ─────────────────────────────────────────────────────────────────────────────

data class AlarmRecord(
    val alarmId:    String,
    val triggerAtMs: Long,
    val routeUri:   String,
    val title:      String,
    val body:       String,
    val isCallPlan: Boolean,
)

// ─────────────────────────────────────────────────────────────────────────────
// AlarmStore
// ─────────────────────────────────────────────────────────────────────────────
//
// Simple JSON-backed SharedPreferences store that persists every scheduled
// alarm record so BootReceiver can reschedule them without a DB query.
//
// Key = alarmId; Value = JSON object.
// ─────────────────────────────────────────────────────────────────────────────

object AlarmStore {

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** Persist an alarm record. Call this every time an alarm is scheduled. */
    fun put(context: Context, record: AlarmRecord) {
        val obj = JSONObject().apply {
            put("alarmId",     record.alarmId)
            put("triggerAtMs", record.triggerAtMs)
            put("routeUri",    record.routeUri)
            put("title",       record.title)
            put("body",        record.body)
            put("isCallPlan",  record.isCallPlan)
        }
        prefs(context).edit()
            .putString(record.alarmId, obj.toString())
            .apply()
        Log.v(TAG, "put: ${record.alarmId}")
    }

    /** Remove a record by alarmId. */
    fun remove(context: Context, alarmId: String) {
        prefs(context).edit().remove(alarmId).apply()
        Log.v(TAG, "remove: $alarmId")
    }

    /** Remove all records. */
    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
        Log.d(TAG, "clear")
    }

    /** Return all stored records whose [AlarmRecord.triggerAtMs] > now. */
    fun getPending(context: Context): List<AlarmRecord> {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        return p.all.values
            .filterIsInstance<String>()
            .mapNotNull { json ->
                try {
                    val o = JSONObject(json)
                    val triggerAtMs = o.getLong("triggerAtMs")
                    if (triggerAtMs <= now) return@mapNotNull null   // already past
                    AlarmRecord(
                        alarmId     = o.getString("alarmId"),
                        triggerAtMs = triggerAtMs,
                        routeUri    = o.getString("routeUri"),
                        title       = o.getString("title"),
                        body        = o.getString("body"),
                        isCallPlan  = o.optBoolean("isCallPlan", false),
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "getPending: parse error — $e")
                    null
                }
            }
            .sortedBy { it.triggerAtMs }
    }
}
