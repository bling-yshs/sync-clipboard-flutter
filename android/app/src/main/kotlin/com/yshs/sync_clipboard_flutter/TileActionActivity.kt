package com.yshs.sync_clipboard_flutter

import android.content.Intent
import android.os.Build
import android.net.Uri
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
    private var sharedFileUri: Uri? = null
    private var sharedFileName: String? = null

    override fun getTransparencyMode(): TransparencyMode {
        return TransparencyMode.transparent
    }

    override fun getInitialRoute(): String {
        val action = intent.action
        val type = intent.type
        
        // 处理分享 Intent
        if (Intent.ACTION_SEND == action && type != null) {
            if (type.startsWith("text/")) {
                // 文本分享
                sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                return "/share/text"
            } else {
                // 文件分享（包括图片等任意类型）
                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
                }
                if (uri != null) {
                    sharedFileUri = uri
                    sharedFileName = getFileNameFromUri(uri)
                    return "/share/file"
                }
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
                "getSharedFile" -> {
                    if (sharedFileUri != null) {
                        // 读取文件内容并返回
                        try {
                            val inputStream = contentResolver.openInputStream(sharedFileUri!!)
                            val bytes = inputStream?.readBytes()
                            inputStream?.close()
                            result.success(mapOf(
                                "filename" to (sharedFileName ?: "shared_file"),
                                "bytes" to bytes
                            ))
                        } catch (e: Exception) {
                            result.error("READ_ERROR", "无法读取文件: ${e.message}", null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun getFileNameFromUri(uri: Uri): String {
        var name = "shared_file"
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    name = it.getString(nameIndex)
                }
            }
        }
        return name
    }
}
