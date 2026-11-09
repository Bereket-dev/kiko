package com.bereket.kiko.call

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import com.bereket.kiko.bridge.LookupEntry
import com.bereket.kiko.bridge.OverlaySettingsMirror
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private const val TAG = "OverlayWindowService"
private const val EXTRA_CALLER_NUMBER = "caller_number"
private const val EXTRA_ENTRY_NAME = "entry_name"
private const val EXTRA_ENTRY_STATUS = "entry_status"
private const val EXTRA_ENTRY_LAST_NOTE = "entry_last_note"
private const val EXTRA_ENTRY_LAST_CALL_AT = "entry_last_call_at"
private const val EXTRA_SHOW_HISTORY = "show_history"
private const val EXTRA_IS_UNKNOWN = "is_unknown"
private const val AUTO_DISMISS_DELAY_MS = 8_000L

/**
 * Foreground-less overlay service that renders a TYPE_APPLICATION_OVERLAY
 * window during an incoming call.
 *
 * Start via [showOverlay]; dismiss via [dismissOverlay].
 * The overlay auto-dismisses after [AUTO_DISMISS_DELAY_MS] milliseconds.
 */
class OverlayWindowService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val dismissHandler = Handler(Looper.getMainLooper())

    // ── Service lifecycle ─────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        when (intent.action) {
            ACTION_SHOW -> handleShow(intent)
            ACTION_DISMISS -> handleDismiss()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handleDismiss()
        super.onDestroy()
    }

    // ── Show overlay ──────────────────────────────────────────────────────────

    private fun handleShow(intent: Intent) {
        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "SYSTEM_ALERT_WINDOW not granted — cannot show overlay.")
            stopSelf()
            return
        }

        // Dismiss any existing overlay first.
        handleDismiss()

        val callerNumber = intent.getStringExtra(EXTRA_CALLER_NUMBER) ?: ""
        val entryName = intent.getStringExtra(EXTRA_ENTRY_NAME)
        val entryStatus = intent.getStringExtra(EXTRA_ENTRY_STATUS)
        val entryLastNote = intent.getStringExtra(EXTRA_ENTRY_LAST_NOTE)
        val entryLastCallAt = intent.getLongExtra(EXTRA_ENTRY_LAST_CALL_AT, -1L)
            .takeIf { it >= 0 }
        val showHistory = intent.getBooleanExtra(EXTRA_SHOW_HISTORY, true)
        val isUnknown = intent.getBooleanExtra(EXTRA_IS_UNKNOWN, false)

        val view = buildOverlayView(
            callerNumber = callerNumber,
            name = entryName,
            statusCode = entryStatus,
            lastNote = entryLastNote,
            lastCallAt = entryLastCallAt,
            showHistory = showHistory,
            isUnknown = isUnknown,
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            x = 0
            y = 120   // small top margin so it clears the status bar
        }

        windowManager?.addView(view, params)
        overlayView = view
        Log.d(TAG, "Overlay shown for $callerNumber (unknown=$isUnknown)")

        // Schedule auto-dismiss.
        dismissHandler.postDelayed({ handleDismiss() }, AUTO_DISMISS_DELAY_MS)
    }

    // ── Dismiss overlay ───────────────────────────────────────────────────────

    private fun handleDismiss() {
        dismissHandler.removeCallbacksAndMessages(null)
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view: ${e.message}")
            }
            overlayView = null
        }
        stopSelf()
    }

    // ── Build overlay view (programmatic layout) ──────────────────────────────

    private fun buildOverlayView(
        callerNumber: String,
        name: String?,
        statusCode: String?,
        lastNote: String?,
        lastCallAt: Long?,
        showHistory: Boolean,
        isUnknown: Boolean,
    ): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 24, 32, 24)
            background = createRoundedBackground()
        }

        // ── Name / unknown label ─────────────────────────────────────────────
        val displayName = when {
            isUnknown -> "Unknown caller"
            !name.isNullOrBlank() -> name
            else -> callerNumber
        }
        container.addView(TextView(this).apply {
            text = displayName
            textSize = 22f
            setTextColor(Color.WHITE)
            setPadding(0, 0, 0, 8)
        })

        // ── Number (when name is shown) ───────────────────────────────────────
        if (!isUnknown && !name.isNullOrBlank()) {
            container.addView(TextView(this).apply {
                text = callerNumber
                textSize = 14f
                setTextColor(Color.parseColor("#BBBBBB"))
                setPadding(0, 0, 0, 8)
            })
        }

        // ── Status chip ───────────────────────────────────────────────────────
        if (!statusCode.isNullOrBlank() && !isUnknown) {
            container.addView(TextView(this).apply {
                text = statusCode
                textSize = 12f
                setTextColor(Color.WHITE)
                setBackgroundColor(statusChipColor(statusCode))
                setPadding(16, 6, 16, 6)
            })
        }

        // ── History section ───────────────────────────────────────────────────
        if (showHistory && !isUnknown) {
            if (!lastNote.isNullOrBlank()) {
                container.addView(TextView(this).apply {
                    text = "📝 ${lastNote.take(80)}${if (lastNote.length > 80) "…" else ""}"
                    textSize = 13f
                    setTextColor(Color.parseColor("#DDDDDD"))
                    setPadding(0, 12, 0, 4)
                })
            }

            if (lastCallAt != null) {
                val formatted = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
                    .format(Date(lastCallAt))
                container.addView(TextView(this).apply {
                    text = "📞 Last call: $formatted"
                    textSize = 12f
                    setTextColor(Color.parseColor("#AAAAAA"))
                    setPadding(0, 4, 0, 0)
                })
            }
        }

        return container
    }

    /** Returns a simple dark rounded background drawable. */
    private fun createRoundedBackground(): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            setColor(Color.parseColor("#CC1A1A2E"))  // semi-transparent dark blue
            cornerRadius = 24f
        }
    }

    /** Maps a status code to a chip background color. */
    private fun statusChipColor(statusCode: String): Int = when (statusCode.uppercase()) {
        "NEW" -> Color.parseColor("#1565C0")
        "CONTACTED" -> Color.parseColor("#6A1B9A")
        "INTERESTED" -> Color.parseColor("#00695C")
        "NEGOTIATING" -> Color.parseColor("#E65100")
        "WON" -> Color.parseColor("#1B5E20")
        "LOST" -> Color.parseColor("#B71C1C")
        "FOLLOW_UP" -> Color.parseColor("#F57F17")
        else -> Color.parseColor("#37474F")
    }

    // ── Companion — static helpers called from other classes ──────────────────

    companion object {
        private const val ACTION_SHOW = "com.bereket.kiko.SHOW_OVERLAY"
        private const val ACTION_DISMISS = "com.bereket.kiko.DISMISS_OVERLAY"

        /**
         * Start the overlay service to display caller info.
         *
         * @param context   Application context.
         * @param entry     Lookup entry for the caller, or null for unknown callers.
         * @param settings  Current overlay settings mirror.
         * @param callerNumber  E.164 number (or raw number as fallback).
         */
        fun showOverlay(
            context: Context,
            entry: LookupEntry?,
            settings: OverlaySettingsMirror,
            callerNumber: String,
        ) {
            val intent = Intent(context, OverlayWindowService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_CALLER_NUMBER, callerNumber)
                putExtra(EXTRA_SHOW_HISTORY, settings.showHistory)
                putExtra(EXTRA_IS_UNKNOWN, entry == null)
                entry?.let {
                    putExtra(EXTRA_ENTRY_NAME, it.name)
                    putExtra(EXTRA_ENTRY_STATUS, it.statusCode)
                    putExtra(EXTRA_ENTRY_LAST_NOTE, it.lastNote)
                    putExtra(EXTRA_ENTRY_LAST_CALL_AT, it.lastCallAt ?: -1L)
                }
            }
            context.startService(intent)
        }

        /**
         * Dismiss any currently displayed overlay.
         */
        fun dismissOverlay(context: Context) {
            val intent = Intent(context, OverlayWindowService::class.java).apply {
                action = ACTION_DISMISS
            }
            context.startService(intent)
        }
    }
}
