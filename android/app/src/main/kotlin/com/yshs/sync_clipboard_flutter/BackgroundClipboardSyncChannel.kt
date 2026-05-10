package com.yshs.sync_clipboard_flutter

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import androidx.core.net.toUri
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
                    "setExcludeFromRecents" -> {
                        val args = call.arguments as? Map<*, *>
                        result.success(setExcludeFromRecents(context, args))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 启动后台剪贴板同步前台服务。
     */
    private fun startService(context: Context, args: Map<*, *>): Boolean {
        val config = BackgroundSyncConfig.fromArgs(args) ?: return false
        val intent = Intent(context, BackgroundClipboardSyncService::class.java).apply {
            action = BackgroundClipboardSyncService.ACTION_START
            config.writeToIntent(this)
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
            val action = if (!powerManager.isIgnoringBatteryOptimizations(appContext.packageName)
            ) {
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            } else {
                Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            }
            val intent = Intent(action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (action == Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
                    data = "package:${appContext.packageName}".toUri()
                }
            }
            appContext.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    data = "package:${context.applicationContext.packageName}".toUri()
                }
                context.applicationContext.startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    /**
     * 设置当前 Activity 所在任务是否从最近任务列表中隐藏。
     */
    private fun setExcludeFromRecents(context: Context, args: Map<*, *>?): Boolean {
        return try {
            val activity = context as? Activity ?: return false
            val activityManager = activity.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val appTask = activityManager.appTasks.firstOrNull() ?: return false
            appTask.setExcludeFromRecents(args?.get("exclude") as? Boolean ?: false)
            true
        } catch (_: Exception) {
            false
        }
    }

}
