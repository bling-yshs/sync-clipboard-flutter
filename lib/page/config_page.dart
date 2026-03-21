import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/page/log_view_page.dart';
import 'package:sync_clipboard_flutter/service/downloads_save_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  static const String _settingsStorageKey = 'app_settings';

  final TextEditingController _downloadPathController = TextEditingController();

  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  String _downloadPathDraft = '';
  String? _downloadPathError;
  String _version = '';
  Future<void> _settingsWriteQueue = Future.value();

  @override
  void dispose() {
    _downloadPathController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 并行加载设置和版本信息
    await Future.wait([_loadSettings(), _loadVersion()]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_settingsStorageKey);

    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final settings = appSettingsFromJson(savedJson);
        _settings = settings;
      } catch (e) {
        _settings = const AppSettings();
      }
    }

    _downloadPathDraft = _settings.downloadRelativePath;
    _downloadPathController.text = _settings.downloadRelativePath;
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _version = packageInfo.version;
  }

  Future<void> _saveSettings(AppSettings newSettings) async {
    _settingsWriteQueue = _settingsWriteQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsStorageKey, appSettingsToJson(newSettings));
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = newSettings;
      });
    });
    await _settingsWriteQueue;
  }

  Future<void> _toggleTrustInsecureCert(bool value) async {
    final newSettings = _settings.copyWith(trustInsecureCert: value);
    await _saveSettings(newSettings);
  }

  Future<void> _toggleAutoCheckUpdate(bool value) async {
    final newSettings = _settings.copyWith(autoCheckUpdate: value);
    await _saveSettings(newSettings);
  }

  String get _downloadPathLabel {
    if (_downloadPathError != null) {
      return '路径格式无效';
    }
    return DownloadsSaveService.buildDownloadPathFromRelativePath(
      _downloadPathDraft,
    );
  }

  String? _validateDownloadPath(String value) {
    try {
      DownloadsSaveService.normalizeRelativePath(value);
      return null;
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? '目录格式无效';
    }
  }

  void _updateDownloadPath(String value) {
    final error = _validateDownloadPath(value);
    setState(() {
      _downloadPathDraft = value;
      _downloadPathError = error;
    });

    if (error != null) {
      return;
    }

    final safeRelativePath = DownloadsSaveService.normalizeRelativePath(value);
    final newSettings = _settings.copyWith(downloadRelativePath: safeRelativePath);
    unawaited(_saveSettings(newSettings));
  }

  void _openLogPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LogViewPage()));
  }

  /// 构建分类标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        // ===== 常规 =====
        _buildSectionHeader('常规'),

        // 信任不安全的 HTTPS 证书
        SwitchListTile(
          secondary: const Icon(Icons.gpp_maybe),
          title: const Text('信任不安全的 HTTPS 证书'),
          subtitle: const Text('开启后将跳过 HTTPS 证书校验'),
          value: _settings.trustInsecureCert,
          onChanged: _toggleTrustInsecureCert,
        ),

        // 启动时自动检查更新
        SwitchListTile(
          secondary: const Icon(Icons.system_update),
          title: const Text('启动时检查更新'),
          subtitle: const Text('关闭后将不会在启动时自动检查更新'),
          value: _settings.autoCheckUpdate,
          onChanged: _toggleAutoCheckUpdate,
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: const Text('下载目录'),
          subtitle: Text('当前：$_downloadPathLabel'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _downloadPathController,
            decoration: InputDecoration(
              labelText: '子目录',
              border: const OutlineInputBorder(),
              errorText: _downloadPathError,
            ),
            textInputAction: TextInputAction.done,
            onChanged: _updateDownloadPath,
          ),
        ),
        // ===== 调试 =====
        _buildSectionHeader('调试'),

        // 运行日志
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('运行日志'),
          subtitle: const Text('查看应用运行时日志'),
          trailing: IconButton(
            tooltip: '查看日志',
            icon: const Icon(Icons.chevron_right),
            onPressed: _openLogPage,
          ),
          onTap: _openLogPage,
        ),
        // ===== 其它 =====
        _buildSectionHeader('关于'),

        // 软件版本
        ListTile(
          leading: const Icon(Icons.memory),
          title: const Text('软件版本'),
          subtitle: Text(_version),
        ),
      ],
    );
  }
}
