package com.bereket.kiko.call

import android.app.AlertDialog
import android.content.Context
import android.view.WindowManager
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView
import android.widget.LinearLayout
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.bereket.kiko.bridge.KikoApplication
import com.bereket.kiko.bridge.PendingCallEvent

private const val TAG = "PostCallDialogs"

/**
 * Dialogs shown after a call ends.
 *
 * Both dialogs use TYPE_APPLICATION_OVERLAY so they can appear even when the
 * main activity is not in the foreground.
 */
object PostCallDialogs {

    /** All valid lead status codes (kept in sync with the Dart domain model). */
    private val LEAD_STATUSES = listOf(
        "NEW",
        "CONTACTED",
        "INTERESTED",
        "NEGOTIATING",
        "WON",
        "LOST",
        "FOLLOW_UP",
    )

    // ── Set Lead Status dialog ────────────────────────────────────────────────

    /**
     * Show a dialog with radio buttons for each [LeadStatus] value.
     *
     * @param context       Must be an application or service context (overlay).
     * @param e164          E.164 number being updated.
     * @param currentStatus Currently assigned status code (pre-selects the matching radio).
     * @param onResult      Called with the chosen status code, or null if dismissed.
     */
    fun showSetLeadStatusDialog(
        context: Context,
        e164: String,
        currentStatus: String?,
        onResult: (String?) -> Unit,
    ) {
        runOnMain {
            val radioGroup = RadioGroup(context).apply {
                orientation = RadioGroup.VERTICAL
                setPadding(16, 8, 16, 8)
            }

            LEAD_STATUSES.forEach { status ->
                radioGroup.addView(RadioButton(context).apply {
                    text = status.replace("_", " ")
                    tag = status
                    isChecked = status == currentStatus
                })
            }

            val scrollView = ScrollView(context).apply { addView(radioGroup) }

            val dialog = AlertDialog.Builder(context)
                .setTitle("Update lead status\n$e164")
                .setView(scrollView)
                .setPositiveButton("Confirm") { _, _ ->
                    val selectedId = radioGroup.checkedRadioButtonId
                    val selected = if (selectedId != -1) {
                        radioGroup.findViewById<RadioButton>(selectedId)?.tag as? String
                    } else null
                    enqueueStatusEvent(context, e164, selected)
                    onResult(selected)
                }
                .setNegativeButton("Skip") { dlg, _ ->
                    dlg.dismiss()
                    onResult(null)
                }
                .create()

            applyOverlayWindowType(dialog)
            dialog.show()
        }
    }

    // ── Is Lead dialog ────────────────────────────────────────────────────────

    /**
     * Ask whether an unknown caller is a lead.
     *
     * @param context   Application/service context.
     * @param e164      The caller's E.164 number.
     * @param onResult  Called with true ("Yes, add as lead") or false ("No").
     */
    fun showIsLeadDialog(
        context: Context,
        e164: String,
        onResult: (Boolean) -> Unit,
    ) {
        runOnMain {
            val dialog = AlertDialog.Builder(context)
                .setTitle("Unknown caller")
                .setMessage("Is $e164 a lead?")
                .setPositiveButton("Yes, add as lead") { _, _ ->
                    onResult(true)
                }
                .setNegativeButton("No") { dlg, _ ->
                    dlg.dismiss()
                    // Write a DISMISSED event so Flutter knows to skip this number.
                    enqueueDismissedEvent(context, e164)
                    onResult(false)
                }
                .create()

            applyOverlayWindowType(dialog)
            dialog.show()
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Enqueue a PendingCallEvent carrying the newly chosen status so Flutter
     * can persist it on next drain.
     */
    private fun enqueueStatusEvent(context: Context, e164: String, statusCode: String?) {
        if (statusCode == null) return
        val app = context.applicationContext as? KikoApplication ?: return
        app.pendingQueue.enqueue(
            PendingCallEvent(
                e164 = e164,
                callType = "INCOMING",
                startedAtMs = System.currentTimeMillis(),
                durationSec = 0,
                statusCode = statusCode,
                isUnknown = false,
            )
        )
        Log.d(TAG, "Enqueued status event: e164=$e164 status=$statusCode")
    }

    /**
     * Enqueue a DISMISSED event for an unknown caller who the user declined to
     * add as a lead.
     */
    private fun enqueueDismissedEvent(context: Context, e164: String) {
        val app = context.applicationContext as? KikoApplication ?: return
        app.pendingQueue.enqueue(
            PendingCallEvent(
                e164 = e164,
                callType = "INCOMING",
                startedAtMs = System.currentTimeMillis(),
                durationSec = 0,
                statusCode = "DISMISSED",
                isUnknown = true,
            )
        )
        Log.d(TAG, "Enqueued DISMISSED event for unknown caller: $e164")
    }

    /**
     * Set the dialog window type to TYPE_APPLICATION_OVERLAY so the dialog
     * can appear over the lock screen / when the app is in the background.
     */
    private fun applyOverlayWindowType(dialog: AlertDialog) {
        dialog.window?.setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY)
    }

    /** Ensures the dialog is created and shown on the main thread. */
    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            Handler(Looper.getMainLooper()).post(block)
        }
    }
}
