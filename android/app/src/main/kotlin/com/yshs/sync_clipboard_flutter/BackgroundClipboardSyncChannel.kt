package com.yshs.sync_clipboard_flutter

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter 与后台剪贴板同步前台服务之间的 MethodChannel。
 */
object BackgroundClipboardSyncChannel {
    private const val CHANNEL = "com.yshs.sync_clipboard_flutter/background_clipboard_sync"

    /**
     * 注册后台同步服务控制通道。
     */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val args = call.arguments as? Map<*, *>
                        if (args == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(startService(context, args))
                    }
                    "stop" -> {
                        stopService(context)
                        result.success(true)
                    }
                    "openBatteryOptimizationSettings" -> {
                        result.success(openBatteryOptimizationSettings(context))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 启动后台剪贴板同步前台服务。
     */
    private fun startService(context: Context, args: Map<*, *>): Boolean {
        val intent = Intent(context, BackgroundClipboardSyncService::class.java).apply {
            action = BackgroundClipboardSyncService.ACTION_START
            putExtra(BackgroundClipboardSyncService.EXTRA_URL, args["url"] as? String ?: "")
            putExtra(BackgroundClipboardSyncService.EXTRA_USERNAME, args["username"] as? String ?: "")
            putExtra(BackgroundClipboardSyncService.EXTRA_PASSWORD, args["password"] as? String ?: "")
            putExtra(
                BackgroundClipboardSyncService.EXTRA_TRUST_INSECURE_CERT,
                args["trustInsecureCert"] as? Boolean ?: false,
            )
            putExtra(
                BackgroundClipboardSyncService.EXTRA_CLIPBOARD_CHECK_INTERVAL_MS,
                secondsToMillis(args["clipboardCheckIntervalSeconds"]),
            )
            putExtra(
                BackgroundClipboardSyncService.EXTRA_SERVER_CONTENT_CHECK_INTERVAL_MS,
                secondsToMillis(args["serverContentCheckIntervalSeconds"]),
            )
            putExtra(
                BackgroundClipboardSyncService.EXTRA_ENABLE_LOGGING,
                args["enableBackgroundAutoSyncLog"] as? Boolean ?: false,
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.applicationContext.startForegroundService(intent)
        } else {
            context.applicationContext.startService(intent)
        }
        return true
    }

    /**
     * 停止后台剪贴板同步前台服务。
     */
    private fun stopService(context: Context) {
        val intent = Intent(context, BackgroundClipboardSyncService::class.java).apply {
            action = BackgroundClipboardSyncService.ACTION_STOP
        }
        context.applicationContext.startService(intent)
    }

    /**
     * 打开 Android 忽略电池优化设置。
     */
    private fun openBatteryOptimizationSettings(context: Context): Boolean {
        return try {
            val appContext = context.applicationContext
            val powerManager = appContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                !powerManager.isIgnoringBatteryOptimizations(appContext.packageName)
            ) {
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            } else {
                Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            }
            val intent = Intent(action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (action == Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
                    data = Uri.parse("package:${appContext.packageName}")
                }
            }
            appContext.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    data = Uri.parse("package:${context.applicationContext.packageName}")
                }
                context.applicationContext.startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    /**
     * 将 Dart 传入的秒级小数转换成毫秒间隔。
     */
    private fun secondsToMillis(value: Any?): Long {
        val seconds = when (value) {
            is Double -> value
            is Float -> value.toDouble()
            is Int -> value.toDouble()
            is Long -> value.toDouble()
            else -> 3.0
        }
        return (seconds.coerceAtLeast(0.2) * 1000).toLong()
    }
}
