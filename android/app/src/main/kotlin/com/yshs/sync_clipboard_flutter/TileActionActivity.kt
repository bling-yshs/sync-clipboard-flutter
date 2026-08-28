package com.yshs.sync_clipboard_flutter

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 透明 FlutterActivity
 * 用于处理磁贴点击和分享接收，显示透明背景 + 中间信息卡片
 * 
 * 支持的场景：
 * 1. 磁贴点击：根据 EXTRA_TILE_TYPE 跳转到 /tile/upload 或 /tile/download
 * 2. 分享接收：根据分享类型跳转到 /share/text 或 /share/file
 */
class TileActionActivity : FlutterActivity() {

    companion object {
        const val EXTRA_TILE_TYPE = "tile_type"
        const val TILE_TYPE_UPLOAD = "upload"
        const val TILE_TYPE_DOWNLOAD = "download"
        
        private const val CHANNEL = "com.yshs.sync_clipboard_flutter/share"
    }
    
    // 保存分享数据
    private var sharedText: String? = null
    private var sharedFileUris: List<Uri> = emptyList()

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    /**
     * 根据磁贴或分享 Intent 返回 Flutter 初始路由。
     *
     * @return Flutter 页面路由。
     */
    override fun getInitialRoute(): String {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND_MULTIPLE == action) {
            val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
            if (uris.isNotEmpty()) {
                sharedFileUris = uris
                return "/share/file"
            }
        }

        // 处理单项分享。文件管理器可能把 XML、JSON 等文件声明成 text/*，
        // 因此必须优先根据 EXTRA_STREAM 判断“文件分享”，不能只依赖 MIME 类型。
        if (Intent.ACTION_SEND == action) {
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            if (uri != null) {
                sharedFileUris = listOf(uri)
                return "/share/file"
            }

            if (type?.startsWith("text/") == true) {
                // 只有没有文件流时，才把 text/* 当作纯文本分享。
                sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                return "/share/text"
            }
        }
        
        // 处理磁贴点击
        val tileType = intent.getStringExtra(EXTRA_TILE_TYPE)
        return when (tileType) {
            TILE_TYPE_UPLOAD -> "/tile/upload"
            TILE_TYPE_DOWNLOAD -> "/tile/download"
            else -> "/"
        }
    }

    /**
     * 注册分享数据、下载保存和 Wi-Fi 信息平台通道。
     *
     * @param flutterEngine 当前 Activity 使用的 Flutter 引擎。
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DownloadsSaveChannel.register(flutterEngine, this)
        WifiInfoChannel.register(flutterEngine, this)

        // 注册 MethodChannel 让 Flutter 获取分享数据
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    result.success(sharedText)
                }
                "getSharedFiles" -> {
                    result.success(sharedFileUris.map(::buildSharedFileResult))
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 返回分享文件的 uri 元数据。
     *
     * @param uri 分享文件的 content uri。
     * @return Flutter 可读取的文件名和 uri。
     */
    private fun buildSharedFileResult(uri: Uri): Map<String, Any> {
        return mapOf(
            "filename" to getFileNameFromUri(uri),
            "uri" to uri.toString()
        )
    }

    /**
     * 从 content uri 获取展示文件名。
     *
     * @param uri 分享文件的 content uri。
     * @return content provider 提供的文件名，无法获取时返回兜底名称。
     */
    private fun getFileNameFromUri(uri: Uri): String {
        var name = "shared_file"
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    name = it.getString(nameIndex)
                }
            }
        }
        return name
    }
}
