package com.yshs.sync_clipboard_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Base64
import android.util.Log
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import org.json.JSONObject

/**
 * 使用 Shizuku 在后台轮询文本剪贴板并自动上传到 SyncClipboard 服务端。
 */
class BackgroundClipboardSyncService : Service() {

    companion object {
        const val ACTION_START = "com.yshs.sync_clipboard_flutter.action.START_BACKGROUND_SYNC"
        const val ACTION_STOP = "com.yshs.sync_clipboard_flutter.action.STOP_BACKGROUND_SYNC"
        const val EXTRA_URL = "url"
        const val EXTRA_USERNAME = "username"
        const val EXTRA_PASSWORD = "password"
        const val EXTRA_TRUST_INSECURE_CERT = "trustInsecureCert"
        const val EXTRA_CLIPBOARD_CHECK_INTERVAL_MS = "clipboardCheckIntervalMs"
        const val EXTRA_SERVER_CONTENT_CHECK_INTERVAL_MS = "serverContentCheckIntervalMs"
        const val EXTRA_ENABLE_LOGGING = "enableLogging"

        private const val TAG = "BackgroundClipboardSync"
        private const val CHANNEL_ID = "background_clipboard_sync"
        private const val NOTIFICATION_ID = 1327
        private const val DEFAULT_POLL_INTERVAL_MS = 3000L
        private const val TEXT_TRANSFER_DATA_THRESHOLD = 10240
    }

    private var workerThread: Thread? = null
    private var running = false
    private var lastUploadedHash: String? = null
    private var lastRemoteHash: String? = null
    private var lastClipboardCheckAt = 0L
    private var lastServerCheckAt = 0L
    private var config = SyncConfig()

    /**
     * 接收服务启动和停止命令。
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSync()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                config = SyncConfig(
                    url = intent.getStringExtra(EXTRA_URL).orEmpty(),
                    username = intent.getStringExtra(EXTRA_USERNAME).orEmpty(),
                    password = intent.getStringExtra(EXTRA_PASSWORD).orEmpty(),
                    trustInsecureCert = intent.getBooleanExtra(EXTRA_TRUST_INSECURE_CERT, false),
                    clipboardCheckIntervalMs = intent.getLongExtra(
                        EXTRA_CLIPBOARD_CHECK_INTERVAL_MS,
                        DEFAULT_POLL_INTERVAL_MS,
                    ).coerceAtLeast(200L),
                    serverContentCheckIntervalMs = intent.getLongExtra(
                        EXTRA_SERVER_CONTENT_CHECK_INTERVAL_MS,
                        DEFAULT_POLL_INTERVAL_MS,
                    ).coerceAtLeast(200L),
                    enableLogging = intent.getBooleanExtra(EXTRA_ENABLE_LOGGING, false),
                )
                startForeground(NOTIFICATION_ID, buildNotification())
                logInfo("后台剪贴板服务器检查启动，检查间隔=${config.serverContentCheckIntervalMs}ms")
                startSync()
                return START_STICKY
            }
        }

        return START_NOT_STICKY
    }

    /**
     * 前台服务不提供绑定接口。
     */
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    /**
     * 服务销毁时停止后台轮询线程。
     */
    override fun onDestroy() {
        stopSync()
        super.onDestroy()
    }

    /**
     * 启动后台轮询线程。
     */
    private fun startSync() {
        if (running) {
            return
        }

        running = true
        workerThread = Thread {
            while (running) {
                try {
                    syncOnce()
                    if (!sleepQuietly(200L)) {
                        return@Thread
                    }
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return@Thread
                } catch (e: Exception) {
                    logError(e)
                    if (!sleepQuietly(1000L)) {
                        return@Thread
                    }
                }
            }
        }.apply {
            name = "BackgroundClipboardSync"
            start()
        }
    }

    /**
     * 停止后台轮询线程。
     */
    private fun stopSync() {
        logInfo("后台剪贴板服务器检查停止")
        running = false
        workerThread?.interrupt()
        workerThread = null
    }

    /**
     * 写入 INFO 级别日志到系统日志和应用日志文件。
     */
    private fun logInfo(message: String) {
        Log.i(TAG, message)
        writeAppLog("INFO", message)
    }

    /**
     * 写入 WARN 级别日志到系统日志和应用日志文件。
     */
    /**
     * 写入 ERROR 级别日志到系统日志和应用日志文件。
     */
    private fun logError(error: Throwable? = null) {
        val message = "后台剪贴板服务器检查循环异常"
        Log.e(TAG, message, error)
        val suffix = error?.let { " | error: ${it.message ?: it.javaClass.name}" }.orEmpty()
        writeAppLog("ERROR", "$message$suffix")
    }

    /**
     * 将原生后台服务日志追加到 Flutter 日志页读取的同一个文件。
     */
    private fun writeAppLog(level: String, message: String) {
        if (!config.enableLogging) {
            return
        }

        try {
            val logsDir = File(filesDir, "logs")
            if (!logsDir.exists()) {
                logsDir.mkdirs()
            }
            val timestamp = SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                Locale.US,
            ).format(Date())
            File(logsDir, "app.log").appendText("$timestamp [$level] $message\n")
        } catch (_: Exception) {
        }
    }

    /**
     * 等待指定时间，线程被中断时平滑退出同步循环。
     */
    private fun sleepQuietly(durationMs: Long): Boolean {
        return try {
            Thread.sleep(durationMs)
            true
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            false
        }
    }

    /**
     * 按独立间隔执行本地剪贴板和服务器内容检查。
     */
    private fun syncOnce() {
        if (!config.isValid) {
            return
        }

        val now = System.currentTimeMillis()
        if (now - lastClipboardCheckAt >= config.clipboardCheckIntervalMs) {
            lastClipboardCheckAt = now
            syncClipboardOnce()
        }
        if (now - lastServerCheckAt >= config.serverContentCheckIntervalMs) {
            lastServerCheckAt = now
            syncServerContentOnce()
        }
    }

    /**
     * 单次读取并上传变化后的本地剪贴板文本。
     */
    private fun syncClipboardOnce() {
        val snapshot = readLocalClipboardSnapshot() ?: return
        if (snapshot.hash == lastUploadedHash) {
            return
        }

        uploadLocalClipboardSnapshot(snapshot)
    }

    /**
     * 单次读取服务器文本内容并写入系统剪贴板。
     */
    private fun syncServerContentOnce() {
        // val localSnapshot = readLocalClipboardSnapshot()
        // if (
        //     localSnapshot != null &&
        //     localSnapshot.hash != lastUploadedHash &&
        //     localSnapshot.hash != lastRemoteHash
        // ) {
        //     uploadLocalClipboardSnapshot(localSnapshot)
        //     return
        // }

        val remoteClipboard = getRemoteClipboard() ?: return
        logInfo(
            "已请求服务器剪贴板：type=${remoteClipboard.type}, " +
                "hash=${remoteClipboard.hash.orEmpty()}, " +
                "hasData=${remoteClipboard.hasData}, " +
                "dataName=${remoteClipboard.dataName.orEmpty()}, " +
                "textLength=${remoteClipboard.text.length}",
        )
        if (remoteClipboard.type != "Text") {
            return
        }
        val remoteHash = remoteClipboard.hash ?: sha256Upper(remoteClipboard.text.toByteArray(Charsets.UTF_8))
        if (remoteHash == lastRemoteHash || remoteHash == lastUploadedHash) {
            logInfo("服务器文本剪贴板未变化，暂不写入系统剪贴板：hash=$remoteHash")
            return
        }

        val text = if (remoteClipboard.hasData && !remoteClipboard.dataName.isNullOrBlank()) {
            getString("file/${remoteClipboard.dataName}")
        } else {
            remoteClipboard.text
        }
        if (text.isBlank()) {
            return
        }

        writeSystemClipboardText(text)
        lastRemoteHash = remoteHash
        lastUploadedHash = remoteHash
        logInfo("已写入服务器文本到系统剪贴板：hash=$remoteHash, textLength=${text.length}")
    }

    /**
     * 将服务器文本内容写入 Android 系统剪贴板。
     */
    private fun writeSystemClipboardText(text: String) {
        val clipboardManager = getSystemService(ClipboardManager::class.java)
        clipboardManager.setPrimaryClip(ClipData.newPlainText("SyncClipboard", text))
    }

    /**
     * 读取本地剪贴板文本快照。
     */
    private fun readLocalClipboardSnapshot(): LocalClipboardSnapshot? {
        val text = ShizukuClipboardChannel.readClipboardTextBlocking(this) ?: return null
        val hash = sha256Upper(text.toByteArray(Charsets.UTF_8))
        return LocalClipboardSnapshot(text, hash)
    }

    /**
     * 上传本地剪贴板文本快照并记录 hash。
     */
    private fun uploadLocalClipboardSnapshot(snapshot: LocalClipboardSnapshot) {
        uploadTextClipboard(snapshot.text, snapshot.hash)
        lastUploadedHash = snapshot.hash
        logInfo("已通过 Shizuku 上传本地文本剪贴板：hash=${snapshot.hash}, textLength=${snapshot.text.length}")
    }

    /**
     * 按 SyncClipboard 文本协议上传剪贴板内容。
     */
    private fun uploadTextClipboard(text: String, hash: String) {
        val textBytes = text.toByteArray(Charsets.UTF_8)
        val payload = JSONObject()
            .put("type", "Text")
            .put("hash", hash)
            .put("hasData", text.length > TEXT_TRANSFER_DATA_THRESHOLD)
            .put("size", text.length)

        if (text.length > TEXT_TRANSFER_DATA_THRESHOLD) {
            val dataName = "text_$hash.txt"
            putBytes("file/$dataName", textBytes, "text/plain; charset=utf-8")
            payload.put("text", text.substring(0, TEXT_TRANSFER_DATA_THRESHOLD))
            payload.put("dataName", dataName)
        } else {
            payload.put("text", text)
        }

        putBytes(
            "SyncClipboard.json",
            payload.toString().toByteArray(Charsets.UTF_8),
            "application/json; charset=utf-8",
        )
    }

    /**
     * 通过 HTTP PUT 上传二进制内容。
     */
    private fun putBytes(path: String, bytes: ByteArray, contentType: String) {
        val connection = openConnection(path)
        try {
            connection.requestMethod = "PUT"
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", contentType)
            connection.setRequestProperty("Content-Length", bytes.size.toString())
            connection.setRequestProperty("Authorization", buildBasicAuthHeader())
            connection.outputStream.use { output ->
                output.write(bytes)
            }

            val statusCode = connection.responseCode
            if (statusCode !in listOf(200, 201, 204)) {
                throw IllegalStateException("Upload failed: HTTP $statusCode")
            }
        } finally {
            connection.disconnect()
        }
    }

    /**
     * 读取服务器 SyncClipboard.json。
     */
    private fun getRemoteClipboard(): RemoteClipboard? {
        val raw = getString("SyncClipboard.json")
        if (raw.isBlank()) {
            return null
        }

        val json = JSONObject(raw)
        return RemoteClipboard(
            type = json.optString("type"),
            hash = json.optString("hash").takeIf { it.isNotBlank() },
            text = json.optString("text"),
            hasData = json.optBoolean("hasData", false),
            dataName = json.optString("dataName").takeIf { it.isNotBlank() },
        )
    }

    /**
     * 通过 HTTP GET 读取文本内容。
     */
    private fun getString(path: String): String {
        val connection = openConnection(path)
        try {
            connection.requestMethod = "GET"
            connection.setRequestProperty("Authorization", buildBasicAuthHeader())
            val statusCode = connection.responseCode
            if (statusCode != 200) {
                throw IllegalStateException("Download failed: HTTP $statusCode")
            }
            return connection.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
        } finally {
            connection.disconnect()
        }
    }

    /**
     * 打开服务端连接并应用证书策略。
     */
    private fun openConnection(path: String): HttpURLConnection {
        val connection = URL("${config.normalizedUrl}$path").openConnection() as HttpURLConnection
        connection.connectTimeout = 5000
        connection.readTimeout = 30000

        if (connection is HttpsURLConnection && config.trustInsecureCert) {
            connection.sslSocketFactory = insecureSslContext().socketFactory
            connection.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
        }

        return connection
    }

    /**
     * 构建 HTTP Basic Auth 请求头。
     */
    private fun buildBasicAuthHeader(): String {
        val raw = "${config.username}:${config.password}"
        return "Basic ${Base64.encodeToString(raw.toByteArray(Charsets.UTF_8), Base64.NO_WRAP)}"
    }

    /**
     * 构建前台服务通知。
     */
    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "剪贴板自动同步",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        @Suppress("DiscouragedApi")
        val iconId = resources.getIdentifier("ic_launcher_foreground", "drawable", packageName)
            .takeIf { it != 0 } ?: android.R.drawable.stat_notify_sync

        return builder
            .setSmallIcon(iconId)
            .setContentTitle("同步剪贴板")
            .setContentText("正在通过 Shizuku 自动同步文本剪贴板")
            .setOngoing(true)
            .build()
    }

    /**
     * 创建信任所有证书的 SSL 上下文。
     */
    private fun insecureSslContext(): SSLContext {
        val trustManagers = arrayOf<TrustManager>(
            @Suppress("CustomX509TrustManager")
            object : X509TrustManager {
                /**
                 * 跳过客户端证书校验。
                 */
                override fun checkClientTrusted(chain: Array<java.security.cert.X509Certificate>?, authType: String?) = Unit

                /**
                 * 跳过服务端证书校验。
                 */
                override fun checkServerTrusted(chain: Array<java.security.cert.X509Certificate>?, authType: String?) = Unit

                /**
                 * 返回空的受信证书列表。
                 */
                override fun getAcceptedIssuers(): Array<java.security.cert.X509Certificate> = emptyArray()
            },
        )
        return SSLContext.getInstance("TLS").apply {
            init(null, trustManagers, java.security.SecureRandom())
        }
    }

    /**
     * 计算大写 SHA-256 字符串。
     */
    private fun sha256Upper(bytes: ByteArray): String {
        return MessageDigest.getInstance("SHA-256")
            .digest(bytes)
            .joinToString("") { "%02X".format(it) }
    }

    /**
     * 后台同步所需的服务器配置。
     */
    private data class SyncConfig(
        val url: String = "",
        val username: String = "",
        val password: String = "",
        val trustInsecureCert: Boolean = false,
        val clipboardCheckIntervalMs: Long = DEFAULT_POLL_INTERVAL_MS,
        val serverContentCheckIntervalMs: Long = DEFAULT_POLL_INTERVAL_MS,
        val enableLogging: Boolean = false,
    ) {
        val normalizedUrl: String
            get() = url.trim().let { if (it.endsWith("/")) it else "$it/" }

        val isValid: Boolean
            get() = url.isNotBlank()
    }

    /**
     * 服务器剪贴板文本响应。
     */
    private data class RemoteClipboard(
        val type: String,
        val hash: String?,
        val text: String,
        val hasData: Boolean,
        val dataName: String?,
    )

    /**
     * 本地剪贴板文本快照。
     */
    private data class LocalClipboardSnapshot(
        val text: String,
        val hash: String,
    )
}
