import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/service/background_clipboard_sync_service.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';
import 'package:sync_clipboard_flutter/service/shizuku_clipboard_service.dart';

class BackgroundAutoSyncPage extends StatefulWidget {
  const BackgroundAutoSyncPage({super.key});

  @override
  State<BackgroundAutoSyncPage> createState() => _BackgroundAutoSyncPageState();
}

class _BackgroundAutoSyncPageState extends State<BackgroundAutoSyncPage> {
  static const String _settingsStorageKey = 'app_settings';
  static const double _minimumIntervalSeconds = 0.2;

  final TextEditingController _clipboardIntervalController =
      TextEditingController();
  final TextEditingController _serverIntervalController =
      TextEditingController();

  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  bool _isSaving = false;
  Future<void> _settingsWriteQueue = Future.value();

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  @override
  void dispose() {
    _clipboardIntervalController.dispose();
    _serverIntervalController.dispose();
    super.dispose();
  }

  /// 加载后台自动同步设置。
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_settingsStorageKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        _settings = appSettingsFromJson(savedJson);
      } catch (_) {
        _settings = const AppSettings();
      }
    }

    _clipboardIntervalController.text = _formatSeconds(
      _settings.clipboardCheckIntervalSeconds,
    );
    _serverIntervalController.text = _formatSeconds(
      _settings.serverContentCheckIntervalSeconds,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  /// 保存后台自动同步设置。
  Future<void> _saveSettings(AppSettings newSettings) async {
    _settingsWriteQueue = _settingsWriteQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _settingsStorageKey,
        appSettingsToJson(newSettings),
      );
      _settings = newSettings;
    });
    await _settingsWriteQueue;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  /// 切换后台自动同步。
  Future<void> _toggleBackgroundAutoSync(bool value) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!value) {
        final newSettings = _settings.copyWith(enableShizukuClipboard: false);
        await _saveSettings(newSettings);
        await BackgroundClipboardSyncService.stop();
        return;
      }

      if (!await ShizukuClipboardService.isAvailable()) {
        _showSnackBar('Shizuku 未运行，请先安装并启动 Shizuku');
        return;
      }

      if (!await ShizukuClipboardService.hasPermission()) {
        final requested = await ShizukuClipboardService.requestPermission();
        if (!requested) {
          _showSnackBar('无法发起 Shizuku 权限请求');
          return;
        }

        final granted = await _waitForShizukuPermission();
        if (!granted) {
          _showSnackBar('未获得 Shizuku 权限');
          return;
        }
      }

      await _enableBackgroundAutoSync();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 等待 Shizuku 权限请求结果生效。
  Future<bool> _waitForShizukuPermission() async {
    const maxAttempts = 30;
    for (var i = 0; i < maxAttempts; i++) {
      if (await ShizukuClipboardService.hasPermission()) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// 保存开启状态并启动后台同步服务。
  Future<void> _enableBackgroundAutoSync() async {
    final activeConfig = await ServerConfigService.getActiveConfig();
    if (activeConfig == null) {
      _showSnackBar('后台服务启动失败，请检查服务器配置');
      return;
    }

    final newSettings = _settings.copyWith(enableShizukuClipboard: true);
    await _saveSettings(newSettings);
    final started = await BackgroundClipboardSyncService.startWithConfig(
      activeConfig,
      newSettings,
    );
    if (!started) {
      await _saveSettings(_settings.copyWith(enableShizukuClipboard: false));
      _showSnackBar('后台服务启动失败，请检查服务器配置');
    }
  }

  /// 保存剪贴板检查间隔。
  Future<void> _saveClipboardInterval(String value) async {
    final seconds = _parseInterval(value);
    if (seconds == null) {
      return;
    }

    final newSettings = _settings.copyWith(
      clipboardCheckIntervalSeconds: seconds,
    );
    await _saveSettings(newSettings);
    await _restartServiceIfEnabled(newSettings);
  }

  /// 保存服务器内容检查间隔。
  Future<void> _saveServerInterval(String value) async {
    final seconds = _parseInterval(value);
    if (seconds == null) {
      return;
    }

    final newSettings = _settings.copyWith(
      serverContentCheckIntervalSeconds: seconds,
    );
    await _saveSettings(newSettings);
    await _restartServiceIfEnabled(newSettings);
  }

  /// 保存后台自动同步日志开关。
  Future<void> _saveBackgroundAutoSyncLog(bool value) async {
    final newSettings = _settings.copyWith(enableBackgroundAutoSyncLog: value);
    await _saveSettings(newSettings);
    await _restartServiceIfEnabled(newSettings);
  }

  /// 已启用时按新设置重启后台同步服务。
  Future<void> _restartServiceIfEnabled(AppSettings settings) async {
    if (!settings.enableShizukuClipboard) {
      return;
    }

    await BackgroundClipboardSyncService.start();
  }

  /// 打开 Android 忽略电池优化设置。
  Future<void> _openBatteryOptimizationSettings() async {
    final opened =
        await BackgroundClipboardSyncService.openBatteryOptimizationSettings();
    if (!opened) {
      _showSnackBar('无法打开电池优化设置');
    }
  }

  /// 将当前任务从最近任务列表中隐藏。
  Future<void> _hideFromRecents() async {
    final hidden = await BackgroundClipboardSyncService.hideFromRecents();
    if (hidden) {
      _showSnackBar('已从最近任务列表中隐藏');
      return;
    }

    _showSnackBar('无法隐藏最近任务列表');
  }

  /// 解析并规范化秒级小数间隔。
  double? _parseInterval(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < _minimumIntervalSeconds) {
      _showSnackBar('间隔不能小于 ${_formatSeconds(_minimumIntervalSeconds)} 秒');
      return null;
    }
    return parsed;
  }

  /// 格式化秒数显示文本。
  String _formatSeconds(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// 隐藏输入焦点。
  void _dismissFocus(PointerDownEvent _) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// 展示页面提示。
  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('后台自动同步')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('后台自动同步'),
            subtitle: const Text('使用 Shizuku 读取剪贴板'),
            value: _settings.enableShizukuClipboard,
            onChanged: _isSaving ? null : _toggleBackgroundAutoSync,
          ),
          _buildIntervalField(
            controller: _clipboardIntervalController,
            icon: Icons.content_paste_search,
            title: '剪贴板检查间隔',
            onSubmitted: _saveClipboardInterval,
          ),
          _buildIntervalField(
            controller: _serverIntervalController,
            icon: Icons.cloud_sync,
            title: '服务器内容检查间隔',
            onSubmitted: _saveServerInterval,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.receipt_long),
            title: const Text('自动同步日志'),
            subtitle: const Text('记录后台自动同步运行日志'),
            value: _settings.enableBackgroundAutoSyncLog,
            onChanged: _saveBackgroundAutoSyncLog,
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('在最近任务列表中隐藏'),
            subtitle: const Text('记得先锁定此App，防止被一键清理'),
            trailing: IconButton(
              tooltip: '隐藏',
              icon: const Icon(Icons.chevron_right),
              onPressed: _hideFromRecents,
            ),
            onTap: _hideFromRecents,
          ),
          ListTile(
            leading: const Icon(Icons.battery_saver),
            title: const Text('忽略电池优化'),
            trailing: IconButton(
              tooltip: '打开设置',
              icon: const Icon(Icons.chevron_right),
              onPressed: _openBatteryOptimizationSettings,
            ),
            onTap: _openBatteryOptimizationSettings,
          ),
        ],
      ),
    );
  }

  /// 构建秒级间隔输入项。
  Widget _buildIntervalField({
    required TextEditingController controller,
    required IconData icon,
    required String title,
    required ValueChanged<String> onSubmitted,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: controller,
          onTapOutside: _dismissFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: '秒',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
          onEditingComplete: () {
            onSubmitted(controller.text);
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
      ),
    );
  }
}
