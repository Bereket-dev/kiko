package com.bereket.kiko.call

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CallLog
import android.util.Log

private const val TAG = "CallLogApiImpl"

/**
 * Implements the CallLogApi Pigeon contract by querying the Android system
 * call log via ContentResolver.
 *
 * NOTE: Pigeon setup call (CallLogApi.setUp) is wired in
 * KikoApplication.registerActivityHandlers once codegen runs.
 */
class CallLogApiImpl(private val context: Context) {

    // ── CallLogApi implementation ─────────────────────────────────────────────

    /**
     * Return up to [limit] call-log entries whose timestamp is strictly
     * greater than [sinceTimestampMs], ordered newest-first.
     *
     * Requires READ_CALL_LOG permission; returns an empty list if the
     * permission has not been granted rather than crashing.
     */
    fun getRecentCalls(sinceTimestampMs: Long, limit: Long): List<CallLogEntry> {
        val uri: Uri = CallLog.Calls.CONTENT_URI

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.CACHED_NAME,
        )

        // Filter: only calls after sinceTimestampMs
        val selection = "${CallLog.Calls.DATE} > ?"
        val selectionArgs = arrayOf(sinceTimestampMs.toString())

        // Newest-first; then cap at limit in code (LIMIT clause via URI param)
        val sortOrder = "${CallLog.Calls.DATE} DESC"

        // Use the Android LIMIT parameter supported on API 21+
        val queryUri = uri.buildUpon()
            .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, limit.toString())
            .build()

        val cursor: Cursor? = try {
            context.contentResolver.query(queryUri, projection, selection, selectionArgs, sortOrder)
        } catch (e: SecurityException) {
            Log.w(TAG, "READ_CALL_LOG permission not granted: ${e.message}")
            return emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Call log query failed: ${e.message}")
            return emptyList()
        }

        val results = mutableListOf<CallLogEntry>()
        cursor?.use {
            val numberCol = it.getColumnIndexOrThrow(CallLog.Calls.NUMBER)
            val typeCol = it.getColumnIndexOrThrow(CallLog.Calls.TYPE)
            val dateCol = it.getColumnIndexOrThrow(CallLog.Calls.DATE)
            val durationCol = it.getColumnIndexOrThrow(CallLog.Calls.DURATION)
            val nameCol = it.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME)

            while (it.moveToNext()) {
                val rawNumber = it.getString(numberCol) ?: ""
                val typeInt = it.getInt(typeCol)
                val date = it.getLong(dateCol)
                val duration = it.getInt(durationCol)
                val cachedName = it.getString(nameCol)?.takeIf { n -> n.isNotBlank() }

                results.add(
                    CallLogEntry(
                        e164 = normalizeToE164(rawNumber),
                        name = cachedName,
                        callType = mapCallType(typeInt),
                        timestampMs = date,
                        durationSec = duration,
                    )
                )
            }
        }

        Log.d(TAG, "Returning ${results.size} call log entries since $sinceTimestampMs")
        return results
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun mapCallType(type: Int): String = when (type) {
        CallLog.Calls.INCOMING_TYPE -> "INCOMING"
        CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
        CallLog.Calls.MISSED_TYPE -> "MISSED"
        else -> "INCOMING"
    }

    /**
     * Best-effort normalisation to E.164 (Ethiopian number conventions).
     *
     *  - "+251XXXXXXXXX" (13 chars)  → kept as-is
     *  - "251XXXXXXXXX"  (12 digits) → "+251XXXXXXXXX"
     *  - "09XXXXXXXX"   (10 digits) → "+2519XXXXXXXX"
     *  - "07XXXXXXXX"   (10 digits) → "+2517XXXXXXXX"
     *  - "9XXXXXXXX"    ( 9 digits) → "+2519XXXXXXXX"
     *  - "7XXXXXXXX"    ( 9 digits) → "+2517XXXXXXXX"
     *  - Anything else  → stripped digits (best-effort)
     */
    private fun normalizeToE164(raw: String): String {
        if (raw.isBlank()) return ""
        val hasPlus = raw.startsWith("+")
        val digits = raw.filter { it.isDigit() }

        return when {
            hasPlus && digits.startsWith("251") && digits.length >= 12 -> "+$digits"
            !hasPlus && digits.startsWith("251") && digits.length == 12 -> "+$digits"
            digits.length == 10 && (digits.startsWith("09") || digits.startsWith("07")) ->
                "+251${digits.substring(1)}"
            digits.length == 9 && (digits.startsWith("9") || digits.startsWith("7")) ->
                "+251$digits"
            hasPlus -> "+$digits"
            else -> digits
        }
    }
}

/**
 * Mirrors the Pigeon-generated [CallLogEntry] data class.
 *
 * Once Pigeon codegen runs (`dart run pigeon --input pigeons/call_log_api.dart`),
 * replace this with the generated class from
 * com.bereket.kiko.pigeon.CallLogEntry and update the return type above.
 */
data class CallLogEntry(
    val e164: String,
    val name: String?,
    val callType: String,
    val timestampMs: Long,
    val durationSec: Int,
)
