package com.bereket.kiko.recordings

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.util.Log
import androidx.annotation.RequiresApi

private const val TAG = "RecordingFilesApiImpl"
private const val PREFS_NAME = "kiko_recording_prefs"
private const val KEY_FOLDER_URI = "recordings_folder_uri"

/**
 * Implements the RecordingFilesApi Pigeon contract using the Storage Access
 * Framework (SAF / DocumentsContract).
 *
 * URI persistence: plain SharedPreferences (unencrypted — a folder URI is not
 * a secret and needs to survive across process deaths with zero overhead).
 *
 * NOTE: Pigeon setup call (RecordingFilesApi.setUp) is wired in
 * KikoApplication.registerActivityHandlers once codegen runs.
 */
class RecordingFilesApiImpl(private val context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    // ── RecordingFilesApi implementation ──────────────────────────────────────

    /**
     * Persist the SAF folder URI.
     *
     * The caller must have already taken a persistable URI permission before
     * calling this (typically inside the Activity's SAF result handler via
     * contentResolver.takePersistableUriPermission).
     */
    fun setRecordingsFolderUri(uri: String) {
        prefs.edit().putString(KEY_FOLDER_URI, uri).apply()
        Log.d(TAG, "Recordings folder URI saved: $uri")
    }

    /**
     * Return the stored folder URI, or null if none has been configured.
     */
    fun getRecordingsFolderUri(): String? = prefs.getString(KEY_FOLDER_URI, null)

    /**
     * List audio files in the persisted SAF folder whose last-modified
     * timestamp is strictly greater than [sinceTimestampMs].
     *
     * Returns an empty list if:
     *  - No folder URI has been configured.
     *  - The URI permission was revoked (SecurityException).
     *  - The folder is empty or has no matching files.
     */
    @RequiresApi(Build.VERSION_CODES.Q)   // minSdk 29, so this is always satisfied
    fun getRecordingsSince(sinceTimestampMs: Long): List<RecordingFile> {
        val uriString = prefs.getString(KEY_FOLDER_URI, null)
        if (uriString.isNullOrBlank()) {
            Log.d(TAG, "No recordings folder configured.")
            return emptyList()
        }

        val treeUri = Uri.parse(uriString)
        val childrenUri = try {
            DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )
        } catch (e: Exception) {
            Log.w(TAG, "Invalid tree URI: $uriString — ${e.message}")
            return emptyList()
        }

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )

        val cursor: Cursor? = try {
            context.contentResolver.query(childrenUri, projection, null, null, null)
        } catch (e: SecurityException) {
            Log.w(TAG, "URI permission revoked for $uriString: ${e.message}")
            // Clear the stale URI so the UI can prompt the user to re-select.
            prefs.edit().remove(KEY_FOLDER_URI).apply()
            return emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Query failed for $uriString: ${e.message}")
            return emptyList()
        }

        val results = mutableListOf<RecordingFile>()
        cursor?.use {
            val idCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val nameCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val sizeCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_SIZE)
            val modCol = it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

            while (it.moveToNext()) {
                val mimeType = it.getString(mimeCol) ?: continue
                if (!mimeType.startsWith("audio/")) continue

                val lastModified = it.getLong(modCol)
                if (lastModified <= sinceTimestampMs) continue

                val docId = it.getString(idCol) ?: continue
                val fileUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)

                results.add(
                    RecordingFile(
                        uri = fileUri.toString(),
                        displayName = it.getString(nameCol) ?: docId,
                        durationMs = 0L,   // SAF doesn't expose duration; Flutter can use MediaMetadataRetriever
                        sizeBytes = it.getLong(sizeCol),
                        lastModifiedMs = lastModified,
                    )
                )
            }
        }

        Log.d(TAG, "Found ${results.size} new recording(s) since $sinceTimestampMs")
        return results
    }
}

/**
 * Mirrors the Pigeon-generated [RecordingFile] data class.
 *
 * Once Pigeon codegen runs (`dart run pigeon --input pigeons/recording_files_api.dart`),
 * replace this with the generated class from
 * com.bereket.kiko.pigeon.RecordingFile and update the return types above.
 */
data class RecordingFile(
    val uri: String,
    val displayName: String,
    val durationMs: Long,
    val sizeBytes: Long,
    val lastModifiedMs: Long,
)
