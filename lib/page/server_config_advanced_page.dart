import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sync_clipboard_flutter/page/server_config_auto_switch_page.dart';

class ServerConfigAdvancedPage extends StatelessWidget {
  final String configDisplayName;
  final List<String> initialWifiNames;
  final Future<void> Function(List<String> wifiNames) onSave;
  final Future<bool> Function()? onDelete;

  const ServerConfigAdvancedPage({
    super.key,
    required this.configDisplayName,
    required this.initialWifiNames,
    required this.onSave,
    this.onDelete,
  });

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Future<void> _openAutoSwitchPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ServerConfigAutoSwitchPage(
          configDisplayName: configDisplayName,
          initialWifiNames: initialWifiNames,
          onSave: onSave,
        ),
      ),
    );
  }

  Future<void> _deleteConfig(BuildContext context) async {
    final onDelete = this.onDelete;
    if (onDelete == null) {
      return;
    }

    final deleted = await onDelete();
    if (!context.mounted || !deleted) {
      return;
    }

    Navigator.of(context).pop();
    Fluttertoast.showToast(msg: '配置已删除');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高级设置')),
      body: ListView(
        children: [
          _buildSectionHeader(context, '配置信息'),
          ListTile(
            title: const Text('配置名称'),
            subtitle: Text(configDisplayName),
          ),
          _buildSectionHeader(context, '功能列表'),
          ListTile(
            leading: const Icon(Icons.sync_alt),
            title: const Text('自动切换'),
            subtitle: const Text('根据 WiFi 名称切换到当前配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openAutoSwitchPage(context),
          ),
          if (onDelete != null) ...[
            _buildSectionHeader(context, '其他操作'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => _deleteConfig(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除这个配置'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
