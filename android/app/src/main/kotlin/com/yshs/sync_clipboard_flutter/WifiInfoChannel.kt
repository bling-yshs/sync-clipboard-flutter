package com.yshs.sync_clipboard_flutter

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object WifiInfoChannel {
    private const val CHANNEL = "com.yshs.sync_clipboard_flutter/wifi"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentWifiName" -> result.success(getCurrentWifiName(context))
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getCurrentWifiName(context: Context): String? {
        return try {
            val wifiManager =
                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            sanitizeSsid(wifiManager.connectionInfo?.ssid)
        } catch (_: Exception) {
            null
        }
    }

    private fun sanitizeSsid(rawSsid: String?): String? {
        val trimmed = rawSsid?.trim() ?: return null
        if (trimmed.isEmpty() || trimmed == WifiManager.UNKNOWN_SSID || trimmed == "0x") {
            return null
        }

        return if (trimmed.startsWith("\"") && trimmed.endsWith("\"") && trimmed.length >= 2) {
            trimmed.substring(1, trimmed.length - 1).trim().ifEmpty { null }
        } else {
            trimmed
        }
    }
}
