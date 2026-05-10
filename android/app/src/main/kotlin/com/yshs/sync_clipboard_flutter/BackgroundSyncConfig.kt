package com.yshs.sync_clipboard_flutter

import android.content.Intent

private const val DEFAULT_POLL_INTERVAL_MS = 3000L
private const val MIN_POLL_INTERVAL_MS = 200L

/**
 * 后台剪贴板同步启动配置。
 */
internal data class BackgroundSyncConfig(
    val url: String,
    val username: String,
    val password: String,
    val trustInsecureCert: Boolean = false,
    val clipboardCheckIntervalMs: Long = DEFAULT_POLL_INTERVAL_MS,
    val serverContentCheckIntervalMs: Long = DEFAULT_POLL_INTERVAL_MS,
    val enableLogging: Boolean = false,
) {
    /**
     * 末尾带斜杠的服务端地址。
     */
    val normalizedUrl: String
        get() = url.trim().let { if (it.endsWith("/")) it else "$it/" }

    companion object {
        /**
         * 从 Flutter MethodChannel 参数解析后台同步配置。
         */
        fun fromArgs(args: Map<*, *>): BackgroundSyncConfig? {
            val a:String? = null
            val url = (args["url"] as? String)?.takeUnless { it.isBlank() } ?: return null
            val username = (args["username"] as? String)?.takeUnless { it.isBlank() } ?: return null
            val password = (args["password"] as? String)?.takeUnless { it.isBlank() } ?: return null

            return BackgroundSyncConfig(
                url = url,
                username = username,
                password = password,
                trustInsecureCert = args["trustInsecureCert"] as? Boolean ?: false,
                clipboardCheckIntervalMs = secondsToMillis(args["clipboardCheckIntervalSeconds"]),
                serverContentCheckIntervalMs = secondsToMillis(
                    args["serverContentCheckIntervalSeconds"],
                ),
                enableLogging = args["enableBackgroundAutoSyncLog"] as? Boolean ?: false,
            )
        }

        /**
         * 从 Android 服务启动 Intent 解析后台同步配置。
         */
        fun fromIntent(intent: Intent): BackgroundSyncConfig? {
            val url = intent.getStringExtra(BackgroundClipboardSyncService.EXTRA_URL)
                ?.takeUnless { it.isBlank() }
                ?: return null
            val username = intent.getStringExtra(BackgroundClipboardSyncService.EXTRA_USERNAME)
                ?.takeUnless { it.isBlank() }
                ?: return null
            val password = intent.getStringExtra(BackgroundClipboardSyncService.EXTRA_PASSWORD)
                ?.takeUnless { it.isBlank() }
                ?: return null

            return BackgroundSyncConfig(
                url = url,
                username = username,
                password = password,
                trustInsecureCert = intent.getBooleanExtra(
                    BackgroundClipboardSyncService.EXTRA_TRUST_INSECURE_CERT,
                    false,
                ),
                clipboardCheckIntervalMs = intent.getLongExtra(
                    BackgroundClipboardSyncService.EXTRA_CLIPBOARD_CHECK_INTERVAL_MS,
                    DEFAULT_POLL_INTERVAL_MS,
                ).coerceAtLeast(MIN_POLL_INTERVAL_MS),
                serverContentCheckIntervalMs = intent.getLongExtra(
                    BackgroundClipboardSyncService.EXTRA_SERVER_CONTENT_CHECK_INTERVAL_MS,
                    DEFAULT_POLL_INTERVAL_MS,
                ).coerceAtLeast(MIN_POLL_INTERVAL_MS),
                enableLogging = intent.getBooleanExtra(
                    BackgroundClipboardSyncService.EXTRA_ENABLE_LOGGING,
                    false,
                ),
            )
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
                else -> DEFAULT_POLL_INTERVAL_MS / 1000.0
            }
            return (seconds.coerceAtLeast(MIN_POLL_INTERVAL_MS / 1000.0) * 1000).toLong()
        }
    }

    /**
     * 将后台同步配置写入 Android 服务启动 Intent。
     */
    fun writeToIntent(intent: Intent) {
        intent.putExtra(BackgroundClipboardSyncService.EXTRA_URL, url)
        intent.putExtra(BackgroundClipboardSyncService.EXTRA_USERNAME, username)
        intent.putExtra(BackgroundClipboardSyncService.EXTRA_PASSWORD, password)
        intent.putExtra(
            BackgroundClipboardSyncService.EXTRA_TRUST_INSECURE_CERT,
            trustInsecureCert,
        )
        intent.putExtra(
            BackgroundClipboardSyncService.EXTRA_CLIPBOARD_CHECK_INTERVAL_MS,
            clipboardCheckIntervalMs,
        )
        intent.putExtra(
            BackgroundClipboardSyncService.EXTRA_SERVER_CONTENT_CHECK_INTERVAL_MS,
            serverContentCheckIntervalMs,
        )
        intent.putExtra(BackgroundClipboardSyncService.EXTRA_ENABLE_LOGGING, enableLogging)
    }
}
