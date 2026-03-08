import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sync_clipboard_flutter/service/wifi_info_service.dart';

class ServerConfigAutoSwitchPage extends StatefulWidget {
  final String configDisplayName;
  final List<String> initialWifiNames;
  final Future<void> Function(List<String> wifiNames) onSave;

  const ServerConfigAutoSwitchPage({
    super.key,
    required this.configDisplayName,
    required this.initialWifiNames,
    required this.onSave,
  });

  @override
  State<ServerConfigAutoSwitchPage> createState() =>
      _ServerConfigAutoSwitchPageState();
}

class _ServerConfigAutoSwitchPageState
    extends State<ServerConfigAutoSwitchPage> {
  late final TextEditingController _wifiNamesController;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  String? _currentWifiName;
  bool _isRefreshing = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _wifiNamesController = TextEditingController(
      text: widget.initialWifiNames.join('\n'),
    );
    _refreshWifiState();
  }

  @override
  void dispose() {
    _wifiNamesController.dispose();
    super.dispose();
  }

  Future<void> _refreshWifiState() async {
    setState(() {
      _isRefreshing = true;
    });

    final permissionStatus = await WifiInfoService.getPermissionStatus();
    final currentWifiName = permissionStatus.isGranted
        ? await WifiInfoService.getCurrentWifiName()
        : null;

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = permissionStatus;
      _currentWifiName = currentWifiName;
      _isRefreshing = false;
    });
  }

  Future<void> _requestPermission() async {
    if (_permissionStatus.isPermanentlyDenied) {
      await openAppSettings();
      await _refreshWifiState();
      return;
    }

    final status = await WifiInfoService.requestLocationPermission();
    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = status;
    });
    await _refreshWifiState();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final wifiNames = _parseWifiNames(_wifiNamesController.text);
      await widget.onSave(wifiNames);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      Fluttertoast.showToast(msg: '自动切换设置已保存');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addCurrentWifiName() {
    final currentWifiName = _currentWifiName;
    if (currentWifiName == null) {
      return;
    }

    final names = _parseWifiNames(_wifiNamesController.text);
    if (!names.contains(currentWifiName)) {
      names.add(currentWifiName);
      _wifiNamesController.text = names.join('\n');
    }
  }

  List<String> _parseWifiNames(String rawText) {
    return rawText
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  String _permissionText() {
    if (_permissionStatus.isGranted) {
      return '已授权';
    }
    if (_permissionStatus.isPermanentlyDenied) {
      return '已永久拒绝，请去系统设置开启';
    }
    if (_permissionStatus.isRestricted) {
      return '受系统限制';
    }
    return '未授权';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPermissionPrompt = !_permissionStatus.isGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('自动切换'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              '上传或下载剪贴板时，如果命中下方的匹配规则，则会临时切换到当前配置进行同步',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _buildSectionHeader('当前状态'),
          if (showPermissionPrompt)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('授予位置权限'),
              subtitle: Text(_permissionText()),
              trailing: TextButton(
                onPressed: _requestPermission,
                child: Text(
                  _permissionStatus.isPermanentlyDenied ? '去设置' : '授权',
                ),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('当前 WiFi'),
              subtitle: Text(
                _isRefreshing
                    ? '正在读取...'
                    : (_currentWifiName ?? '未连接 WiFi 或暂时无法读取'),
              ),
              trailing: IconButton(
                onPressed: _refreshWifiState,
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
              ),
            ),
          _buildSectionHeader('匹配规则'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _wifiNamesController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: '匹配 WiFi 名称',
                    hintText: '一行一个，例如：Home_5G',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (!showPermissionPrompt && _currentWifiName != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text('加入当前 WiFi：$_currentWifiName'),
                        onPressed: _addCurrentWifiName,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
