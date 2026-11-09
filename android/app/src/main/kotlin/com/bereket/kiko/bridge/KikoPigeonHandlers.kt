package com.bereket.kiko.bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.telecom.TelecomManager
import androidx.activity.result.ActivityResultLauncher
import androidx.core.app.ActivityCompat
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log

// ─────────────────────────────────────────────────────────────────────────────
// KikoPigeonHandlers
// ─────────────────────────────────────────────────────────────────────────────
//
// Implements the Pigeon HostApi contracts:
//  • LookupIndexApiImpl     — delegates to EncryptedLookupStore
//  • PendingEventsApiImpl   — delegates to PendingEventQueue
//  • SettingsSyncApiImpl    — delegates to PendingEventQueue (overlay mirror)
//  • PermissionsApiImpl     — Android permission / role checks
//
// These are registered in MainActivity via the generated Pigeon setup methods.
// The generated Pigeon source is in android/.../pigeon/ (dartOut / kotlinOut).
// ─────────────────────────────────────────────────────────────────────────────

private const val TAG = "KikoPigeonHandlers"

// ── LookupIndex ──────────────────────────────────────────────────────────────

class LookupIndexApiImpl(private val store: EncryptedLookupStore) {

    fun upsertEntry(e164: String, name: String, statusCode: String,
                    lastNote: String?, lastCallAt: Long?) {
        store.upsertEntry(LookupEntry(e164, name, statusCode, lastNote, lastCallAt))
    }

    fun removeEntry(e164: String) {
        store.removeEntry(e164)
    }

    fun rebuildIndex(entries: List<Map<String, Any?>>) {
        val parsed = entries.map { m ->
            LookupEntry(
                e164 = m["e164"] as String,
                name = m["name"] as String,
                statusCode = m["statusCode"] as String,
                lastNote = m["lastNote"] as? String,
                lastCallAt = m["lastCallAt"] as? Long,
            )
        }
        store.rebuildIndex(parsed)
    }

    fun lookupByE164(e164: String): LookupEntry? = store.lookup(e164)
}

// ── PendingEvents ─────────────────────────────────────────────────────────────

class PendingEventsApiImpl(private val queue: PendingEventQueue) {

    fun drainPendingEvents(): List<PendingCallEvent> = queue.peek()

    fun clearPendingEvents() = queue.clear()
}

// ── SettingsSync ─────────────────────────────────────────────────────────────

class SettingsSyncApiImpl(private val queue: PendingEventQueue) {

    fun syncOverlaySettings(masterEnabled: Boolean, showHistory: Boolean, askUnknown: Boolean) {
        queue.updateOverlaySettings(
            OverlaySettingsMirror(masterEnabled, showHistory, askUnknown)
        )
    }

    fun getOverlaySettings(): OverlaySettingsMirror = queue.getOverlaySettings()
}

// ── PermissionsApi ────────────────────────────────────────────────────────────

class PermissionsApiImpl(
    private val context: Context,
    private val activity: Activity,
) {

    data class PermissionSnapshot(
        val hasCallScreening: Boolean,
        val hasOverlay: Boolean,
        val hasCallLog: Boolean,
        val hasPhoneState: Boolean,
        val hasNotifications: Boolean,
        val hasBatteryOptimizationExempt: Boolean,
    )

    fun checkPermissions(): PermissionSnapshot {
        val pm = context.packageManager
        val pkg = context.packageName

        val hasCallScreening = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            telecom.defaultDialerPackage == pkg
        } else false

        val hasOverlay = Settings.canDrawOverlays(context)

        val hasCallLog = ActivityCompat.checkSelfPermission(
            context, Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED

        val hasPhoneState = ActivityCompat.checkSelfPermission(
            context, Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

        val hasNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else true

        val hasBatteryExempt = run {
            val pm2 = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm2.isIgnoringBatteryOptimizations(pkg)
        }

        return PermissionSnapshot(
            hasCallScreening = hasCallScreening,
            hasOverlay = hasOverlay,
            hasCallLog = hasCallLog,
            hasPhoneState = hasPhoneState,
            hasNotifications = hasNotifications,
            hasBatteryOptimizationExempt = hasBatteryExempt,
        )
    }

    fun requestOverlayPermission() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun requestBatteryOptimizationExemption() {
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.w(TAG, "Cannot open battery optimization settings: ${e.message}")
            // Fallback to general settings
            context.startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }
}
