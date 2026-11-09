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
// EncryptedLookupStore
// ─────────────────────────────────────────────────────────────────────────────
//
// Stores a mapping of E.164 → LookupEntry using AES-256-GCM, with the key
// managed by Android Keystore (never leaves secure hardware / StrongBox).
//
// Storage backend: EncryptedSharedPreferences-style file (plain SharedPrefs
// with each value encrypted individually under the Keystore key).
//
// Called from: CallScreeningService, overlay window, post-call dialogs.
// Updated from: Dart via Pigeon (LookupIndexApi).
// ─────────────────────────────────────────────────────────────────────────────

private const val TAG = "EncryptedLookupStore"
private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
private const val KEY_ALIAS = "kiko_lookup_key_v1"
private const val PREFS_NAME = "kiko_lookup_store"
private const val ALL_ENTRIES_KEY = "entries_v1"

data class LookupEntry(
    val e164: String,
    val name: String,
    val statusCode: String,
    val lastNote: String?,
    val lastCallAt: Long?,
)

class EncryptedLookupStore(private val context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    init {
        ensureKeystoreKey()
    }

    // ── Public API ────────────────────────────────────────────────────────────

    fun upsertEntry(entry: LookupEntry) {
        val map = readAll().toMutableMap()
        map[entry.e164] = entry
        writeAll(map)
    }

    fun removeEntry(e164: String) {
        val map = readAll().toMutableMap()
        if (map.remove(e164) != null) writeAll(map)
    }

    fun rebuildIndex(entries: List<LookupEntry>) {
        val map = entries.associateBy { it.e164 }
        writeAll(map)
    }

    fun lookup(e164: String): LookupEntry? = readAll()[e164]

    fun getAll(): List<LookupEntry> = readAll().values.toList()

    fun clear() {
        prefs.edit().remove(ALL_ENTRIES_KEY).apply()
    }

    // ── Internal serialisation ────────────────────────────────────────────────

    private fun readAll(): Map<String, LookupEntry> {
        val encrypted = prefs.getString(ALL_ENTRIES_KEY, null) ?: return emptyMap()
        return try {
            val json = decrypt(encrypted)
            val array = JSONArray(json)
            val result = mutableMapOf<String, LookupEntry>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val entry = LookupEntry(
                    e164 = obj.getString("e164"),
                    name = obj.getString("name"),
                    statusCode = obj.getString("statusCode"),
                    lastNote = obj.optString("lastNote").ifEmpty { null },
                    lastCallAt = if (obj.has("lastCallAt")) obj.getLong("lastCallAt") else null,
                )
                result[entry.e164] = entry
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to read lookup store; resetting.", e)
            emptyMap()
        }
    }

    private fun writeAll(map: Map<String, LookupEntry>) {
        val array = JSONArray()
        for (entry in map.values) {
            val obj = JSONObject().apply {
                put("e164", entry.e164)
                put("name", entry.name)
                put("statusCode", entry.statusCode)
                entry.lastNote?.let { put("lastNote", it) }
                entry.lastCallAt?.let { put("lastCallAt", it) }
            }
            array.put(obj)
        }
        val encrypted = encrypt(array.toString())
        prefs.edit().putString(ALL_ENTRIES_KEY, encrypted).apply()
    }

    // ── AES-256-GCM encryption ────────────────────────────────────────────────

    private fun encrypt(plaintext: String): String {
        val key = getOrCreateKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        // Encode as Base64(iv_12_bytes || ciphertext)
        val combined = iv + ciphertext
        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    private fun decrypt(encoded: String): String {
        val key = getOrCreateKey()
        val combined = Base64.decode(encoded, Base64.NO_WRAP)
        val iv = combined.copyOfRange(0, 12)
        val ciphertext = combined.copyOfRange(12, combined.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        val plaintext = cipher.doFinal(ciphertext)
        return String(plaintext, Charsets.UTF_8)
    }

    // ── Keystore key management ───────────────────────────────────────────────

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
