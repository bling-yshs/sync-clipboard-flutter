// 更新提示对话框
// 支持选择下载源、显示下载进度、触发安装

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/model/update_info/update_info.dart';
import 'package:sync_clipboard_flutter/service/update_service.dart';

/// 更新对话框状态
enum UpdateDialogState {
  /// 选择下载源
  selectSource,
  /// 下载中
  downloading,
  /// 下载完成，正在安装
  installing,
  /// 下载失败
  failed,
}

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final bool isForced;
  /// 已缓存的 APK 路径（如果有）
  final String? cachedApkPath;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.isForced,
    this.cachedApkPath,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateDialogState _state = UpdateDialogState.selectSource;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;

  /// 是否有缓存的 APK
  bool get _hasCachedApk => widget.cachedApkPath != null;

  /// 安装缓存的 APK
  Future<void> _installCachedApk() async {
    setState(() {
      _state = UpdateDialogState.installing;
    });

    try {
      await UpdateService.installApk(widget.cachedApkPath!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = UpdateDialogState.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// 格式化文件大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 开始下载
  Future<void> _startDownload(DownloadSource source) async {
    setState(() {
      _state = UpdateDialogState.downloading;
      _downloadedBytes = 0;
      _totalBytes = widget.updateInfo.size;
    });

    try {
      final filePath = await UpdateService.downloadApk(
        source.url,
        onProgress: (received, total) {
          setState(() {
            _downloadedBytes = received;
            if (total > 0) _totalBytes = total;
          });
        },
      );

      setState(() {
        _state = UpdateDialogState.installing;
      });

      // 调起安装器
      await UpdateService.installApk(filePath);
    } catch (e) {
      setState(() {
        _state = UpdateDialogState.failed;
        _errorMessage = e.toString();
      });
    }
  }

  /// 重试下载
  void _retry() {
    setState(() {
      _state = UpdateDialogState.selectSource;
      _errorMessage = null;
    });
  }

  /// 忽略该版本
  Future<void> _ignoreVersion() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    AppSettings settings;
    if (settingsJson != null) {
      try {
        settings = appSettingsFromJson(settingsJson);
      } catch (e) {
        settings = const AppSettings();
      }
    } else {
      settings = const AppSettings();
    }
    
    // 更新忽略版本
    final updatedSettings = settings.copyWith(
      ignoredVersion: widget.updateInfo.version,
    );
    await prefs.setString('app_settings', appSettingsToJson(updatedSettings));
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 强制更新或下载中时禁止返回
      canPop: !widget.isForced && _state == UpdateDialogState.selectSource,
      child: AlertDialog(
        title: Text('发现新版本 ${widget.updateInfo.version}'),
        content: _buildContent(),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case UpdateDialogState.selectSource:
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 更新日志
              Text(
                '更新内容：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownBody(
                  data: widget.updateInfo.changelog,
                  shrinkWrap: true,
                ),
              ),
              const SizedBox(height: 16),
              // 文件大小
              Text(
                '安装包大小：${_formatBytes(widget.updateInfo.size)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // 根据是否有缓存显示不同按钮
              if (_hasCachedApk) ...[
                // 有缓存，显示立即更新按钮
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _installCachedApk,
                    icon: const Icon(Icons.system_update),
                    label: const Text('立即更新'),
                  ),
                ),
              ] else ...[
                // 无缓存，显示下载源选择
                Text(
                  '选择下载源：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.updateInfo.sources.map((source) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _startDownload(source),
                      icon: const Icon(Icons.download),
                      label: Text(source.name),
                    ),
                  ),
                )),
              ],
            ],
          ),
        );

      case UpdateDialogState.downloading:
        final progress = _totalBytes > 0 ? _downloadedBytes / _totalBytes : 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              '${_formatBytes(_downloadedBytes)} / ${_formatBytes(_totalBytes)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        );

      case UpdateDialogState.installing:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在打开安装程序...'),
          ],
        );

      case UpdateDialogState.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '下载失败',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '未知错误',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_state) {
      case UpdateDialogState.selectSource:
        // 只有非强制更新才显示取消和忽略按钮
        if (!widget.isForced) {
          return [
            TextButton(
              onPressed: _ignoreVersion,
              child: const Text('忽略该版本'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('稍后再说'),
            ),
          ];
        }
        return [];

      case UpdateDialogState.downloading:
        // 下载中不显示任何按钮
        return [];

      case UpdateDialogState.installing:
        // 安装中不显示任何按钮
        return [];

      case UpdateDialogState.failed:
        return [
          TextButton(
            onPressed: _retry,
            child: const Text('重试'),
          ),
          if (!widget.isForced)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
        ];
    }
  }
}
