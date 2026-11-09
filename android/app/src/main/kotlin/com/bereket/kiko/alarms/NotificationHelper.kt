package com.bereket.kiko.alarms

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

private const val TAG = "NotificationHelper"

// ─────────────────────────────────────────────────────────────────────────────
// NotificationHelper
// ─────────────────────────────────────────────────────────────────────────────
//
// Creates notification channels and fires the heads-up / fullscreen-intent
// notification when an alarm fires.
//
// Android 14 note: if USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM is denied, the
// alarm fires late; we degrade gracefully by still showing a notification.
// ─────────────────────────────────────────────────────────────────────────────

const val CHANNEL_REMINDERS = "kiko_reminders"
const val CHANNEL_CALL_PLAN  = "kiko_call_plan"

object NotificationHelper {

    /** Must be called once during Application.onCreate(). */
    fun createChannels(context: Context) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager

        nm.createNotificationChannel(NotificationChannel(
            CHANNEL_REMINDERS,
            "Lead Reminders",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Reminders for individual leads"
            enableLights(true)
            enableVibration(true)
        })

        nm.createNotificationChannel(NotificationChannel(
            CHANNEL_CALL_PLAN,
            "Call Plans",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Scheduled call-plan sessions"
            enableLights(true)
            enableVibration(true)
        })

        Log.d(TAG, "Notification channels created.")
    }

    /**
     * Show a high-priority notification for a fired alarm.
     *
     * On Android 14+ with fullscreen-intent permission: show fullscreen activity.
     * On earlier API / without permission: show a heads-up notification.
     *
     * @param context    Application context.
     * @param notifId    Unique notification ID (derived from alarmId hash).
     * @param channelId  [CHANNEL_REMINDERS] or [CHANNEL_CALL_PLAN].
     * @param title      Notification title.
     * @param body       Notification body text.
     * @param routeUri   Deep-link URI ("/leads/abc123" or "/call-plan/xyz456")
     *                   opened when the user taps the notification.
     */
    fun showAlarmNotification(
        context: Context,
        notifId: Int,
        channelId: String,
        title: String,
        body: String,
        routeUri: String,
    ) {
        // Tap intent — launches MainActivity with the deep-link URI as data.
        val tapIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse("kiko:/$routeUri")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            } ?: return

        val tapPi = PendingIntent.getActivity(
            context,
            notifId,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(tapPi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        // Fullscreen intent (Android 14 requires USE_FULL_SCREEN_INTENT).
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
            context.packageManager.checkPermission(
                android.Manifest.permission.USE_FULL_SCREEN_INTENT,
                context.packageName,
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            builder.setFullScreenIntent(tapPi, /* highPriority = */ true)
        }

        try {
            NotificationManagerCompat.from(context).notify(notifId, builder.build())
            Log.d(TAG, "Notification shown: id=$notifId title=$title")
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted — silently swallow.
            Log.w(TAG, "POST_NOTIFICATIONS not granted; notification suppressed.")
        }
    }
}
