package com.bereket.kiko.bridge

import android.app.Activity
import android.app.Application
import android.content.Context
import android.util.Log
import com.bereket.kiko.call.CallLogApiImpl
import com.bereket.kiko.recordings.RecordingFilesApiImpl
import io.flutter.embedding.engine.FlutterEngine

// ─────────────────────────────────────────────────────────────────────────────
// KikoApplication
// ─────────────────────────────────────────────────────────────────────────────
//
// Application-level singleton that holds the two encrypted native stores so
// they are available to both the Flutter engine (Pigeon) and background
// services (CallScreeningService, overlay) without re-creating them on each
// use.
// ─────────────────────────────────────────────────────────────────────────────

private const val TAG = "KikoApplication"

class KikoApplication : Application() {

    /** Shared singleton lookup store — Kotlin-only read; Dart writes via Pigeon. */
    lateinit var lookupStore: EncryptedLookupStore
        private set

    /** Shared singleton pending-events queue. */
    lateinit var pendingQueue: PendingEventQueue
        private set

    // ── API impl instances (set during registerActivityHandlers) ──────────────
    //
    // Stored here so background services (CallScreeningService, BootReceiver)
    // can access them without re-instantiating.

    /** Call-log reader; available after [registerActivityHandlers] is called. */
    var callLogApi: CallLogApiImpl? = null
        private set

    /** Recording-files SAF accessor; available after [registerActivityHandlers]. */
    var recordingFilesApi: RecordingFilesApiImpl? = null
        private set

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        lookupStore = EncryptedLookupStore(this)
        pendingQueue = PendingEventQueue(this)
        Log.d(TAG, "KikoApplication initialised.")
    }

    // ── Pigeon registration ───────────────────────────────────────────────────

    /**
     * Registers Pigeon HostApi handlers that need an [Activity] + [FlutterEngine].
     *
     * Called once from MainActivity.configureFlutterEngine.
     *
     * TO ACTIVATE FULL PIGEON WIRING:
     *   Run codegen for each IDL file, e.g.:
     *     dart run pigeon --input pigeons/lookup_index.dart
     *     dart run pigeon --input pigeons/pending_events.dart
     *     dart run pigeon --input pigeons/settings_sync.dart
     *     dart run pigeon --input pigeons/permissions_api.dart
     *     dart run pigeon --input pigeons/call_log_api.dart
     *     dart run pigeon --input pigeons/recording_files_api.dart
     *
     *   Then un-comment the setUp calls below.
     */
    fun registerActivityHandlers(activity: Activity, engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger

        // ── Instantiate impl classes and store references ─────────────────────
        callLogApi = CallLogApiImpl(this)
        recordingFilesApi = RecordingFilesApiImpl(this)

        val lookupImpl = LookupIndexApiImpl(lookupStore)
        val pendingImpl = PendingEventsApiImpl(pendingQueue)
        val settingsImpl = SettingsSyncApiImpl(pendingQueue)
        val permissionsImpl = PermissionsApiImpl(this, activity)

        // ── TODO: un-comment after running Pigeon codegen ─────────────────────
        //
        // import com.bereket.kiko.pigeon.LookupIndexApi
        // import com.bereket.kiko.pigeon.PendingEventsApi
        // import com.bereket.kiko.pigeon.SettingsSyncApi
        // import com.bereket.kiko.pigeon.PermissionsApi
        // import com.bereket.kiko.pigeon.CallLogApi
        // import com.bereket.kiko.pigeon.RecordingFilesApi
        //
        // LookupIndexApi.setUp(messenger, lookupImpl)
        // PendingEventsApi.setUp(messenger, pendingImpl)
        // SettingsSyncApi.setUp(messenger, settingsImpl)
        // PermissionsApi.setUp(messenger, permissionsImpl)
        // CallLogApi.setUp(messenger, callLogApi)
        // RecordingFilesApi.setUp(messenger, recordingFilesApi)

        Log.d(TAG, "Pigeon handler instances created. Run pigeon codegen to activate wire-up.")
    }
}
