package com.bereket.kiko.bridge

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

// ─────────────────────────────────────────────────────────────────────────────
// PendingEventQueue
// ─────────────────────────────────────────────────────────────────────────────
//
// Durable queue for call events that occur while the Flutter app is closed.
// When Flutter starts, it drains this queue via PendingEventsApi (Pigeon).
//
// Also stores overlay settings mirror so Kotlin code can read them without
// IPC while the app is in the background.
// ─────────────────────────────────────────────────────────────────────────────

private const val TAG = "PendingEventQueue"
private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
private const val KEY_ALIAS = "kiko_pending_key_v1"
private const val PREFS_NAME = "kiko_pending_store"
private const val QUEUE_KEY = "pending_queue_v1"
private const val OVERLAY_SETTINGS_KEY = "overlay_settings_v1"

data class PendingCallEvent(
    val e164: String,
    val callType: String,       // INCOMING | OUTGOING | MISSED
    val startedAtMs: Long,
    val durationSec: Int,
    val statusCode: String?,    // New status set by post-call dialog; null = unchanged
    val isUnknown: Boolean,
)

data class OverlaySettingsMirror(
    val masterEnabled: Boolean = true,
    val showHistory: Boolean = true,
    val askUnknown: Boolean = true,
)

class PendingEventQueue(private val context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    init {
        ensureKeystoreKey()
    }

    // ── Queue operations ──────────────────────────────────────────────────────

    fun enqueue(event: PendingCallEvent) {
        val list = readQueue().toMutableList()
        list.add(event)
        writeQueue(list)
    }

    /**
     * Returns all pending events and atomically clears the queue.
     * Idempotent: safe to call multiple times (second call returns empty list).
     */
    fun drainAndClear(): List<PendingCallEvent> {
        val list = readQueue()
        if (list.isNotEmpty()) {
            writeQueue(emptyList())
        }
        return list
    }

    fun peek(): List<PendingCallEvent> = readQueue()

    fun clear() {
        prefs.edit().remove(QUEUE_KEY).apply()
    }

    // ── Overlay settings mirror ───────────────────────────────────────────────

    fun updateOverlaySettings(settings: OverlaySettingsMirror) {
        val json = JSONObject().apply {
            put("masterEnabled", settings.masterEnabled)
            put("showHistory", settings.showHistory)
            put("askUnknown", settings.askUnknown)
        }
        val encrypted = encrypt(json.toString())
        prefs.edit().putString(OVERLAY_SETTINGS_KEY, encrypted).apply()
    }

    fun getOverlaySettings(): OverlaySettingsMirror {
        val encrypted = prefs.getString(OVERLAY_SETTINGS_KEY, null)
            ?: return OverlaySettingsMirror()
        return try {
            val obj = JSONObject(decrypt(encrypted))
            OverlaySettingsMirror(
                masterEnabled = obj.optBoolean("masterEnabled", true),
                showHistory = obj.optBoolean("showHistory", true),
                askUnknown = obj.optBoolean("askUnknown", true),
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read overlay settings; using defaults.", e)
            OverlaySettingsMirror()
        }
    }

    // ── Internal serialisation ────────────────────────────────────────────────

    private fun readQueue(): List<PendingCallEvent> {
        val encrypted = prefs.getString(QUEUE_KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(decrypt(encrypted))
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                PendingCallEvent(
                    e164 = obj.getString("e164"),
                    callType = obj.getString("callType"),
                    startedAtMs = obj.getLong("startedAtMs"),
                    durationSec = obj.getInt("durationSec"),
                    statusCode = obj.optString("statusCode").ifEmpty { null },
                    isUnknown = obj.optBoolean("isUnknown", false),
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read queue; returning empty.", e)
            emptyList()
        }
    }

    private fun writeQueue(events: List<PendingCallEvent>) {
        val array = JSONArray()
        for (ev in events) {
            val obj = JSONObject().apply {
                put("e164", ev.e164)
                put("callType", ev.callType)
                put("startedAtMs", ev.startedAtMs)
                put("durationSec", ev.durationSec)
                ev.statusCode?.let { put("statusCode", it) }
                put("isUnknown", ev.isUnknown)
            }
            array.put(obj)
        }
        val encrypted = encrypt(array.toString())
        prefs.edit().putString(QUEUE_KEY, encrypted).apply()
    }

    // ── AES-256-GCM ───────────────────────────────────────────────────────────

    private fun encrypt(plaintext: String): String {
        val key = getOrCreateKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val iv = cipher.iv
        val ct = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(iv + ct, Base64.NO_WRAP)
    }

    private fun decrypt(encoded: String): String {
        val key = getOrCreateKey()
        val combined = Base64.decode(encoded, Base64.NO_WRAP)
        val iv = combined.copyOfRange(0, 12)
        val ct = combined.copyOfRange(12, combined.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        return String(cipher.doFinal(ct), Charsets.UTF_8)
    }

    // ── Keystore key ──────────────────────────────────────────────────────────

    private fun ensureKeystoreKey() {
        val ks = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        if (ks.containsAlias(KEY_ALIAS)) return
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(false)
            .build()
        KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE_PROVIDER).apply {
            init(spec)
            generateKey()
        }
    }

    private fun getOrCreateKey(): SecretKey {
        ensureKeystoreKey()
        val ks = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        return (ks.getEntry(KEY_ALIAS, null) as KeyStore.SecretKeyEntry).secretKey
    }
}
