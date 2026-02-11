package com.yshs.sync_clipboard_flutter

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipInputStream

object DownloadsSaveChannel {
    private const val CHANNEL = "com.yshs.sync_clipboard_flutter/downloads"

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveBytesToDownloads" -> {
                        try {
                            val bytes = call.argument<ByteArray>("bytes")
                            val fileName = call.argument<String>("fileName")
                            val path = call.argument<String>("path") ?: ""
                            val isZip = call.argument<Boolean>("isZip") ?: false

                            if (bytes == null) {
                                result.error("INVALID_ARGS", "bytes 为空", null)
                                return@setMethodCallHandler
                            }
                            if (!isZip && fileName.isNullOrBlank()) {
                                result.error("INVALID_ARGS", "fileName 为空", null)
                                return@setMethodCallHandler
                            }

                            val saveResult = saveBytesToDownloads(
                                context = context,
                                resolver = context.contentResolver,
                                bytes = bytes,
                                rawFileName = fileName,
                                rawPath = path,
                                isZip = isZip,
                            )
                            result.success(saveResult)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message ?: "保存失败", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun saveBytesToDownloads(
        context: Context,
        resolver: ContentResolver,
        bytes: ByteArray,
        rawFileName: String?,
        rawPath: String,
        isZip: Boolean,
    ): Map<String, Any> {
        val relativePath = parseRelativePath(rawPath)
        return if (isZip) {
            extractZipToDownloads(
                context = context,
                resolver = resolver,
                zipBytes = bytes,
                baseRelativePath = relativePath,
            )
        } else {
            val fileName = sanitizeFileName(rawFileName.orEmpty())
            saveSingleFile(
                context = context,
                resolver = resolver,
                bytes = bytes,
                fileName = fileName,
                relativePath = relativePath,
            )
        }
    }

    private fun saveSingleFile(
        context: Context,
        resolver: ContentResolver,
        bytes: ByteArray,
        fileName: String,
        relativePath: String,
    ): Map<String, Any> {
        val mimeType = guessMimeType(fileName)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveOnApi29OrAbove(
                resolver = resolver,
                bytes = bytes,
                fileName = fileName,
                relativePath = relativePath,
                mimeType = mimeType,
            )
        } else {
            saveOnLegacyAndroid(
                context = context,
                bytes = bytes,
                fileName = fileName,
                relativePath = relativePath,
                mimeType = mimeType,
            )
        }
    }

    private fun extractZipToDownloads(
        context: Context,
        resolver: ContentResolver,
        zipBytes: ByteArray,
        baseRelativePath: String,
    ): Map<String, Any> {
        ZipInputStream(ByteArrayInputStream(zipBytes)).use { zipInput ->
            while (true) {
                val entry = zipInput.nextEntry ?: break
                try {
                    if (entry.isDirectory) {
                        continue
                    }

                    val zipParts = splitZipEntry(entry.name) ?: continue
                    val entryRelativePath = joinRelativePath(baseRelativePath, zipParts.first)
                    val entryBytes = readCurrentZipEntryBytes(zipInput)

                    saveSingleFile(
                        context = context,
                        resolver = resolver,
                        bytes = entryBytes,
                        fileName = zipParts.second,
                        relativePath = entryRelativePath,
                    )
                } finally {
                    zipInput.closeEntry()
                }
            }
        }

        val mediaStorePath = buildMediaStoreRelativePath(baseRelativePath)
        return mapOf(
            "isZip" to true,
            "path" to buildPublicPath(baseRelativePath),
            "relativePath" to mediaStorePath,
        )
    }

    private fun readCurrentZipEntryBytes(zipInput: ZipInputStream): ByteArray {
        val output = ByteArrayOutputStream()
        val buffer = ByteArray(8 * 1024)
        while (true) {
            val read = zipInput.read(buffer)
            if (read == -1) {
                break
            }
            if (read == 0) {
                continue
            }
            output.write(buffer, 0, read)
        }
        return output.toByteArray()
    }

    private fun splitZipEntry(entryName: String): Pair<String, String>? {
        val normalized = entryName.replace('\\', '/')
        if (normalized.startsWith("/")) {
            return null
        }
        val rawSegments = normalized.split('/')
        if (rawSegments.any { it == "." || it == ".." }) {
            return null
        }
        val segments = rawSegments.filter { it.isNotBlank() }
        if (segments.isEmpty()) {
            return null
        }

        val fileName = sanitizeFileName(segments.last())

        val relativePath = if (segments.size == 1) {
            ""
        } else {
            segments.dropLast(1).joinToString("/")
        }
        return Pair(relativePath, fileName)
    }

    private fun joinRelativePath(basePath: String, childPath: String): String {
        if (basePath.isBlank()) {
            return validateRelativePath(childPath)
        }
        if (childPath.isBlank()) {
            return validateRelativePath(basePath)
        }
        return validateRelativePath("$basePath/$childPath")
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveOnApi29OrAbove(
        resolver: ContentResolver,
        bytes: ByteArray,
        fileName: String,
        relativePath: String,
        mimeType: String,
    ): Map<String, Any> {
        val mediaStorePath = buildMediaStoreRelativePath(relativePath)
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uniqueName = findUniqueDisplayName(resolver, collection, mediaStorePath, fileName)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, uniqueName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, mediaStorePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val itemUri = resolver.insert(collection, values)
            ?: throw IOException("MediaStore 插入失败")

        try {
            resolver.openOutputStream(itemUri, "w")?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IOException("无法打开输出流")

            val done = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(itemUri, done, null, null)

            return mapOf(
                "isZip" to false,
                "uri" to itemUri.toString(),
                "displayName" to uniqueName,
                "path" to buildPublicPath(relativePath),
                "relativePath" to mediaStorePath,
            )
        } catch (e: Exception) {
            resolver.delete(itemUri, null, null)
            throw e
        }
    }

    private fun saveOnLegacyAndroid(
        context: Context,
        bytes: ByteArray,
        fileName: String,
        relativePath: String,
        mimeType: String,
    ): Map<String, Any> {
        val downloadsRoot =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDir = if (relativePath.isBlank()) {
            downloadsRoot
        } else {
            File(downloadsRoot, relativePath)
        }
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            throw IOException("创建目录失败: ${targetDir.absolutePath}")
        }

        val uniqueName = findUniqueFileNameInDirectory(targetDir, fileName)
        val targetFile = File(targetDir, uniqueName)

        FileOutputStream(targetFile).use { output ->
            output.write(bytes)
            output.flush()
        }

        MediaScannerConnection.scanFile(
            context,
            arrayOf(targetFile.absolutePath),
            arrayOf(mimeType),
            null,
        )

        val mediaStorePath = buildMediaStoreRelativePath(relativePath)
        return mapOf(
            "isZip" to false,
            "uri" to Uri.fromFile(targetFile).toString(),
            "displayName" to uniqueName,
            "path" to buildPublicPath(relativePath),
            "relativePath" to mediaStorePath,
        )
    }

    private fun findUniqueDisplayName(
        resolver: ContentResolver,
        collection: Uri,
        mediaStorePath: String,
        originalName: String,
    ): String {
        val (base, ext) = splitName(originalName)
        var index = 0
        while (true) {
            val candidate = if (index == 0) {
                originalName
            } else {
                if (ext.isEmpty()) "${base}_$index" else "${base}_$index.$ext"
            }

            val exists = resolver.query(
                collection,
                arrayOf(MediaStore.MediaColumns._ID),
                "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND ${MediaStore.MediaColumns.DISPLAY_NAME}=?",
                arrayOf(mediaStorePath, candidate),
                null,
            )?.use { cursor -> cursor.moveToFirst() } ?: false

            if (!exists) {
                return candidate
            }
            index++
        }
    }

    private fun findUniqueFileNameInDirectory(directory: File, originalName: String): String {
        val (base, ext) = splitName(originalName)
        var index = 0
        while (true) {
            val candidate = if (index == 0) {
                originalName
            } else {
                if (ext.isEmpty()) "${base}_$index" else "${base}_$index.$ext"
            }
            if (!File(directory, candidate).exists()) {
                return candidate
            }
            index++
        }
    }

    private fun splitName(name: String): Pair<String, String> {
        val dot = name.lastIndexOf('.')
        if (dot <= 0 || dot >= name.length - 1) {
            return name to ""
        }
        return name.take(dot) to name.substring(dot + 1)
    }

    private fun buildMediaStoreRelativePath(relativePath: String): String {
        return if (relativePath.isBlank()) {
            "${Environment.DIRECTORY_DOWNLOADS}/"
        } else {
            "${Environment.DIRECTORY_DOWNLOADS}/${relativePath.trim('/')}/"
        }
    }

    private fun buildPublicPath(relativePath: String): String {
        return if (relativePath.isBlank()) {
            "/Download"
        } else {
            "/Download/${relativePath.trim('/')}"
        }
    }

    private fun parseRelativePath(rawPath: String): String {
        val normalized = rawPath.trim().replace('\\', '/')
        if (normalized.isEmpty()) {
            throw IllegalArgumentException("path 不能为空，必须以 /Download 开头")
        }
        val validPrefix = normalized == "/Download" || normalized.startsWith("/Download/")
        if (!validPrefix) {
            throw IllegalArgumentException("path 必须以 /Download 开头")
        }

        val relative = if (normalized == "/Download") {
            ""
        } else {
            normalized.removePrefix("/Download/")
        }
        return validateRelativePath(relative)
    }

    private fun validateRelativePath(raw: String): String {
        if (raw.isBlank()) {
            return ""
        }
        val segments = raw.trim().replace('\\', '/')
            .split('/')
            .filter { it.isNotBlank() }
        if (segments.any { it == "." || it == ".." }) {
            throw IllegalArgumentException("path 不能包含 . 或 ..")
        }
        return segments.joinToString("/")
    }

    private fun sanitizeFileName(raw: String): String {
        val normalized = raw.trim()
        if (normalized.isEmpty()) {
            throw IllegalArgumentException("文件名不能为空")
        }
        if (normalized.contains('/') || normalized.contains('\\')) {
            throw IllegalArgumentException("文件名不能包含路径分隔符")
        }
        return normalized
    }

    private fun guessMimeType(fileName: String): String {
        val extension = fileName.substringAfterLast('.', "").lowercase()
        if (extension.isBlank()) {
            return "application/octet-stream"
        }
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: "application/octet-stream"
    }
}
