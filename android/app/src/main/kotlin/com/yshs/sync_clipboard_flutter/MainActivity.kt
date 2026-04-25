package com.yshs.sync_clipboard_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BackgroundClipboardSyncChannel.register(flutterEngine, this)
        DownloadsSaveChannel.register(flutterEngine, this)
        ShizukuClipboardChannel.register(flutterEngine, this)
        WifiInfoChannel.register(flutterEngine, this)
    }
}
