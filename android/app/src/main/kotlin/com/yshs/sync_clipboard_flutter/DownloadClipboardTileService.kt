package com.yshs.sync_clipboard_flutter

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService
import android.util.Log

/**
 * 下载剪贴板磁贴服务
 * 用户点击磁贴时会启动 TileActionActivity
 * 
 * 按照 Google 官方文档推荐的方式实现：
 * - Android 14+ 使用 PendingIntent 版本的 startActivityAndCollapse()
 * - 旧版本使用 Intent 版本并加 FLAG_ACTIVITY_NEW_TASK
 */
class DownloadClipboardTileService : TileService() {

    companion object {
        private const val TAG = "DownloadTileService"
    }

    /**
     * 当磁贴被添加到快速设置面板时调用
     */
    override fun onTileAdded() {
        super.onTileAdded()
        updateTileState()
    }

    /**
     * 当快速设置面板展开时调用
     */
    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    /**
     * 更新磁贴状态为非激活状态
     */
    private fun updateTileState() {
        qsTile?.let { tile ->
            tile.state = android.service.quicksettings.Tile.STATE_INACTIVE
            tile.updateTile()
        }
    }

    /**
     * 当用户在 ACTIVE/INACTIVE 状态下点击磁贴时调用
     * 官方文档：https://developer.android.com/develop/ui/views/notifications/custom-quick-settings
     */
    override fun onClick() {
        super.onClick()
        Log.d(TAG, "Tile clicked!")

        // 1. 构建要打开的 Activity Intent
        val intent = Intent(this, TileActionActivity::class.java).apply {
            // 传递磁贴类型信息
            putExtra(TileActionActivity.EXTRA_TILE_TYPE, TileActionActivity.TILE_TYPE_DOWNLOAD)
        }

        // 2. 按照官方推荐的方式处理不同 Android 版本
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+：使用 PendingIntent 版本（官方最新推荐）
            val pendingIntent = PendingIntent.getActivity(
                this,
                2, // 使用唯一的 requestCode（上传=1, 下载=2）避免 PendingIntent 被复用
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT // 添加 UPDATE_CURRENT
            )
            startActivityAndCollapse(pendingIntent)
            Log.d(TAG, "Started activity with PendingIntent (Android 14+)")
        } else {
            // 旧版本：使用 Intent 版本，必须加 FLAG_ACTIVITY_NEW_TASK
            // （从 Service 启动 Activity 的要求）
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
            startActivityAndCollapse(intent)
            Log.d(TAG, "Started activity with Intent + NEW_TASK flag")
        }
    }
}
