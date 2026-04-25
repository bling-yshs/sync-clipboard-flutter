package com.yshs.sync_clipboard_flutter

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Binder
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import rikka.shizuku.Shizuku

/**
 * Flutter 与 Shizuku 剪贴板读取能力之间的 MethodChannel。
 */
object ShizukuClipboardChannel {
    private const val CHANNEL = "com.yshs.sync_clipboard_flutter/shizuku_clipboard"
    private const val TAG = "ShizukuClipboard"
    private const val REQUEST_CODE_PERMISSION = 10086

    private val callerToken = Binder()
    private var permissionGranted = false
    private var clipboardService: IClipboardUserService? = null
    private var serviceConnected = false
    private var isBinding = false
    private var listenersRegistered = false
    private lateinit var appContext: Context

    private val serviceConnection = object : ServiceConnection {
        /**
         * 接收 Shizuku UserService 连接成功回调。
         */
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            isBinding = false
            if (service == null || !service.pingBinder()) {
                Log.e(TAG, "UserService binder is null or dead")
                return
            }

            clipboardService = IClipboardUserService.Stub.asInterface(service)
            serviceConnected = true
            try {
                clipboardService?.init(callerToken)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to init UserService", e)
            }
        }

        /**
         * 接收 Shizuku UserService 断开连接回调。
         */
        override fun onServiceDisconnected(name: ComponentName?) {
            isBinding = false
            clipboardService = null
            serviceConnected = false
        }
    }

    private val permissionResultListener =
        Shizuku.OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode != REQUEST_CODE_PERMISSION) {
                return@OnRequestPermissionResultListener
            }

            permissionGranted = grantResult == PackageManager.PERMISSION_GRANTED
            if (permissionGranted) {
                bindUserService()
            }
        }

    private val binderReceivedListener = Shizuku.OnBinderReceivedListener {
        if (hasPermission()) {
            bindUserService()
        }
    }

    private val binderDeadListener = Shizuku.OnBinderDeadListener {
        permissionGranted = false
        clipboardService = null
        serviceConnected = false
    }

    /**
     * 注册 Flutter MethodChannel 和 Shizuku 监听器。
     */
    fun register(flutterEngine: FlutterEngine, context: Context) {
        initialize(context)
        registerShizukuListeners()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isShizukuAvailable" -> result.success(isShizukuAvailable())
                    "hasShizukuPermission" -> result.success(hasPermission())
                    "requestShizukuPermission" -> result.success(requestPermission())
                    "hasStringViaShizuku" -> readInWorker(result) {
                        ensureServiceConnected()?.hasPrimaryClipText() ?: false
                    }
                    "getStringViaShizuku" -> readInWorker(result) {
                        ensureServiceConnected()?.primaryClipText ?: ""
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 初始化 Shizuku 剪贴板桥接上下文。
     */
    fun initialize(context: Context) {
        appContext = context.applicationContext
        registerShizukuListeners()
    }

    /**
     * 供后台同步服务阻塞读取剪贴板文本。
     */
    fun readClipboardTextBlocking(context: Context): String? {
        initialize(context)
        if (!isShizukuAvailable() || !hasPermission()) {
            return null
        }

        val text = ensureServiceConnected()?.primaryClipText?.trim()
        return text?.takeIf { it.isNotEmpty() }
    }

    /**
     * 注册 Shizuku 生命周期监听器。
     */
    private fun registerShizukuListeners() {
        if (listenersRegistered) {
            return
        }

        try {
            Shizuku.addRequestPermissionResultListener(permissionResultListener)
            Shizuku.addBinderReceivedListenerSticky(binderReceivedListener)
            Shizuku.addBinderDeadListener(binderDeadListener)
            listenersRegistered = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register Shizuku listeners", e)
        }
    }

    /**
     * 检查 Shizuku Binder 是否可用。
     */
    private fun isShizukuAvailable(): Boolean {
        return try {
            Shizuku.pingBinder()
        } catch (_: Exception) {
            false
        }
    }

    /**
     * 检查当前应用是否已有 Shizuku 权限。
     */
    private fun hasPermission(): Boolean {
        return try {
            if (!Shizuku.pingBinder()) {
                false
            } else if (Shizuku.isPreV11()) {
                appContext.checkSelfPermission("moe.shizuku.manager.permission.API_V23") ==
                    PackageManager.PERMISSION_GRANTED
            } else {
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
            }
        } catch (_: Exception) {
            false
        }
    }

    /**
     * 请求 Shizuku 权限并返回请求是否成功发起。
     */
    private fun requestPermission(): Boolean {
        return try {
            if (!Shizuku.pingBinder() || Shizuku.isPreV11()) {
                return false
            }

            Shizuku.requestPermission(REQUEST_CODE_PERMISSION)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request Shizuku permission", e)
            false
        }
    }

    /**
     * 绑定 Shizuku UserService。
     */
    private fun bindUserService() {
        if (serviceConnected || isBinding) {
            return
        }

        isBinding = true
        try {
            val args = Shizuku.UserServiceArgs(
                ComponentName(appContext.packageName, ClipboardUserService::class.java.name),
            )
                .daemon(false)
                .processNameSuffix("clipboard")
                .debuggable(true)
                .version(1)
            Shizuku.bindUserService(args, serviceConnection)
        } catch (e: Exception) {
            isBinding = false
            Log.e(TAG, "Failed to bind UserService", e)
        }
    }

    /**
     * 确保 UserService 已连接并返回服务代理。
     */
    private fun ensureServiceConnected(): IClipboardUserService? {
        if (clipboardService != null && serviceConnected) {
            return clipboardService
        }

        bindUserService()
        val startTime = System.currentTimeMillis()
        while (clipboardService == null && System.currentTimeMillis() - startTime < 3000) {
            Thread.sleep(100)
        }
        return clipboardService
    }

    /**
     * 在后台线程执行可能阻塞的 Binder 读取操作。
     */
    private fun <T> readInWorker(result: MethodChannel.Result, block: () -> T) {
        thread {
            try {
                result.success(block())
            } catch (e: Exception) {
                Log.e(TAG, "Shizuku clipboard operation failed", e)
                result.success(null)
            }
        }
    }
}
