package com.bereket.kiko.call

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CallLog
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import com.bereket.kiko.bridge.KikoApplication
import com.bereket.kiko.bridge.LookupEntry
import com.bereket.kiko.bridge.OverlaySettingsMirror
import com.bereket.kiko.bridge.PendingCallEvent

private const val TAG = "KikoCallScreeningService"

/**
 * Intercepts incoming calls to:
 *   1. Look up the caller in the encrypted lookup store.
 *   2. Show an overlay with lead info (or "Unknown caller" when askUnknown=true).
 *   3. Always allow the call — we never block.
 *   4. After the call ends, enqueue a PendingCallEvent for Flutter to drain.
 */
class KikoCallScreeningService : CallScreeningService() {

    private val mainHandler = Handler(Looper.getMainLooper())

    // ── onScreenCall ──────────────────────────────────────────────────────────

    override fun onScreenCall(callDetails: Call.Details) {
        val rawHandle = callDetails.handle?.schemeSpecificPart ?: ""
        val e164 = normalizeToE164(rawHandle)

        Log.d(TAG, "onScreenCall raw=$rawHandle e164=$e164")

        val app = applicationContext as KikoApplication
        val settings = app.pendingQueue.getOverlaySettings()
        val entry = if (e164.isNotEmpty()) app.lookupStore.lookup(e164) else null

        // ── Decision: show overlay? ───────────────────────────────────────────
        val showOverlay = when {
            !settings.masterEnabled -> false
            entry != null -> true
            settings.askUnknown -> true   // unknown but user wants to be asked
            else -> false
        }

        if (showOverlay) {
            OverlayWindowService.showOverlay(this, entry, settings, e164)
        }

        // Always allow the call; we never block.
        respondToCall(
            callDetails,
            CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .setSilenceCall(false)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
        )

        // ── Post-call: read call log after a short delay ──────────────────────
        mainHandler.postDelayed({
            handlePostCall(e164, entry, settings)
        }, POST_CALL_DELAY_MS)
    }

    // ── Post-call processing ──────────────────────────────────────────────────

    private fun handlePostCall(
        e164: String,
        entry: LookupEntry?,
        settings: OverlaySettingsMirror,
    ) {
        OverlayWindowService.dismissOverlay(this)

        if (e164.isEmpty()) return

        val app = applicationContext as KikoApplication
        val callLogEntry = queryCallLog(e164)

        if (entry != null) {
            // Known lead: enqueue call event and trigger post-call status dialog.
            val event = PendingCallEvent(
                e164 = e164,
                callType = callLogEntry?.callType ?: "INCOMING",
                startedAtMs = callLogEntry?.startedAtMs ?: System.currentTimeMillis(),
                durationSec = callLogEntry?.durationSec ?: 0,
                statusCode = null,
                isUnknown = false,
            )
            app.pendingQueue.enqueue(event)

            // Trigger status dialog in the main activity if it is visible;
            // otherwise the event will be processed when Flutter resumes.
            PostCallDialogs.showSetLeadStatusDialog(
                context = this,
                e164 = e164,
                currentStatus = entry.statusCode,
            ) { newStatus ->
                if (newStatus != null) {
                    // Re-enqueue with the chosen status so Flutter can persist it.
                    app.pendingQueue.enqueue(event.copy(statusCode = newStatus))
                }
            }
        } else if (settings.masterEnabled && settings.askUnknown) {
            // Unknown caller — ask whether this is a lead.
            val event = PendingCallEvent(
                e164 = e164,
                callType = callLogEntry?.callType ?: "INCOMING",
                startedAtMs = callLogEntry?.startedAtMs ?: System.currentTimeMillis(),
                durationSec = callLogEntry?.durationSec ?: 0,
                statusCode = null,
                isUnknown = true,
            )
            app.pendingQueue.enqueue(event)

            PostCallDialogs.showIsLeadDialog(context = this, e164 = e164) { isLead ->
                if (!isLead) {
                    // Mark as dismissed so Flutter skips this number in future.
                    app.pendingQueue.enqueue(
                        event.copy(isUnknown = true, statusCode = "DISMISSED")
                    )
                }
                // If isLead == true, Flutter will create the lead on drain.
            }
        }
    }

    // ── Call log helper ───────────────────────────────────────────────────────

    private data class CallLogResult(
        val callType: String,
        val startedAtMs: Long,
        val durationSec: Int,
    )

    private fun queryCallLog(e164: String): CallLogResult? {
        val resolver = applicationContext.contentResolver
        val uri = CallLog.Calls.CONTENT_URI.buildUpon()
            .appendQueryParameter(CallLog.Calls.LIMIT_PARAM_KEY, "1")
            .build()

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
        )

        // Search the most recent call from this number.
        val cursor: Cursor? = try {
            resolver.query(
                uri,
                projection,
                "${CallLog.Calls.NUMBER} = ?",
                arrayOf(e164),
                "${CallLog.Calls.DATE} DESC",
            )
        } catch (e: SecurityException) {
            Log.w(TAG, "READ_CALL_LOG permission not granted: ${e.message}")
            null
        }

        return cursor?.use {
            if (!it.moveToFirst()) return@use null
            val typeInt = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE))
            val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
            val dur = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
            CallLogResult(
                callType = mapCallType(typeInt),
                startedAtMs = date,
                durationSec = dur,
            )
        }
    }

    private fun mapCallType(type: Int): String = when (type) {
        CallLog.Calls.INCOMING_TYPE -> "INCOMING"
        CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
        CallLog.Calls.MISSED_TYPE -> "MISSED"
        else -> "INCOMING"
    }

    // ── Number normalisation ──────────────────────────────────────────────────

    companion object {
        private const val POST_CALL_DELAY_MS = 2_000L

        /**
         * Best-effort normalisation to E.164.
         *
         * Rules (Ethiopian numbers):
         *  - Strip everything that is not a digit or leading '+'.
         *  - If already starts with '+251' and total length ≥ 13 → keep as-is.
         *  - If starts with '251' and length = 12 → prepend '+'.
         *  - If 10 digits starting with '09' or '07' → replace leading '0' with '+251'.
         *  - Otherwise return the stripped string prefixed with '+' as a fallback.
         */
        fun normalizeToE164(raw: String): String {
            if (raw.isBlank()) return ""

            // Keep a leading '+' if present, strip all other non-digits.
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
                else -> digits  // return raw digits if we can't determine country
            }
        }
    }
}
