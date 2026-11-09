package com.bereket.kiko

import android.os.Bundle
import com.bereket.kiko.bridge.EncryptedLookupStore
import com.bereket.kiko.bridge.KikoApplication
import com.bereket.kiko.bridge.PendingEventQueue
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Pigeon handlers are registered in KikoApplication.
        // Activity-level handlers (permissions requiring Activity context)
        // are registered here once the engine is ready.
        val app = application as? KikoApplication ?: return
        app.registerActivityHandlers(this, flutterEngine)
    }
}
