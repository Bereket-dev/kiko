package com.bereket.kiko.bridge

import android.app.Activity
import android.app.Application
import android.content.Context
import android.util.Log
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

    override fun onCreate() {
        super.onCreate()
        lookupStore = EncryptedLookupStore(this)
        pendingQueue = PendingEventQueue(this)
        Log.d(TAG, "KikoApplication initialised.")
    }

    /**
     * Registers Pigeon HostApi handlers that only need [Context].
     * Called once from MainActivity.configureFlutterEngine.
     */
    fun registerActivityHandlers(activity: Activity, engine: FlutterEngine) {
        // Pigeon-generated setup methods will be called here once we run
        // `dart run pigeon --input pigeons/...` to generate the stubs.
        // For now this is a placeholder — the generated classes live in
        // android/.../pigeon/ and follow the pattern:
        //   LookupIndexApi.setUp(engine.dartExecutor.binaryMessenger, LookupIndexApiImpl(...))
        //   PendingEventsApi.setUp(engine.dartExecutor.binaryMessenger, PendingEventsApiImpl(...))
        //   SettingsSyncApi.setUp(...)
        //   PermissionsApi.setUp(...)
        Log.d(TAG, "Pigeon handlers placeholder registered. Run pigeon codegen to activate.")
    }
}
