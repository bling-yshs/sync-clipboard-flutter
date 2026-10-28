package com.yshs.sync_clipboard_flutter

import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 调用系统打开链接或文件。
 *
 * 打开成功返回 true；没有应用可以处理时返回 false，由 Flutter 侧决定提示方式。
 */
object ExternalOpenChannel {
    private const val CHANNEL = "com.yshs.sync_clipboard_flutter/external_open"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "url 为空", null)
                            return@setMethodCallHandler
                        }
                        result.success(openUrl(context, url))
                    }

                    "openFile" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "uri 为空", null)
                            return@setMethodCallHandler
                        }
                        result.success(openFile(context, Uri.parse(uri)))
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 用默认浏览器打开链接，已验证 App Links 的应用会直接接管。
     */
    private fun openUrl(context: Context, url: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        return startActivity(context, intent)
    }

    /**
     * 按文件 MIME 类型交给系统选择应用打开。
     *
     * 只支持 content uri；file uri 交给其他应用会触发 FileUriExposedException。
     */
    private fun openFile(context: Context, uri: Uri): Boolean {
        if (uri.scheme != ContentResolver.SCHEME_CONTENT) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, resolveMimeType(context, uri))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return startActivity(context, intent)
    }

    private fun resolveMimeType(context: Context, uri: Uri): String {
        val fromResolver = context.contentResolver.getType(uri)
        if (!fromResolver.isNullOrBlank() && fromResolver != "application/octet-stream") {
            return fromResolver
        }
        val extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString()).lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
    }

    private fun startActivity(context: Context, intent: Intent): Boolean {
        // TileActionActivity 设置了 excludeFromRecents，目标页面需放到独立任务中，
        // 否则关闭磁贴页面后无法从最近任务找回。
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
