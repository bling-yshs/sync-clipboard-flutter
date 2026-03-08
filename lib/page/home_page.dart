import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config_state.dart';
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/page/server_config_advanced_page.dart';
import 'package:sync_clipboard_flutter/provider/server_config_provider.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';
import 'package:logger/logger.dart';
import 'package:sync_clipboard_flutter/utils/clipboard_utils.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final Logger _log = Logger();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 同步 controller 与 state
  void _syncControllers(ServerConfigState state) {
    if (_nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (_urlController.text != state.url) {
      _urlController.text = state.url;
    }
    if (_usernameController.text != state.username) {
      _usernameController.text = state.username;
    }
    if (_passwordController.text != state.password) {
      _passwordController.text = state.password;
    }
  }

  Future<void> _openAdvancedSettings(ServerConfigState state) async {
    if (state.editingConfigId == null) return;

    final currentConfig = state.configList.configs.firstWhere(
      (c) => c.id == state.editingConfigId,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ServerConfigAdvancedPage(
          configDisplayName: currentConfig.displayName,
          initialWifiNames: currentConfig.normalizedAutoSwitchWifiNames,
          onSave: (wifiNames) {
            return ref
                .read(serverConfigProvider.notifier)
                .updateField(autoSwitchWifiNames: wifiNames);
          },
          onDelete: () => _deleteConfig(state.editingConfigId!),
        ),
      ),
    );
  }

  // 删除配置
  Future<bool> _deleteConfig(String configId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: const Text('确定要删除这个配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    await ref.read(serverConfigProvider.notifier).deleteConfig(configId);
    Fluttertoast.showToast(msg: '配置已删除');
    return true;
  }

  // 测试服务器连接
  Future<void> _testConnection(ServerConfigState state) async {
    // 验证配置是否完整
    if (_urlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请填写完整的服务器配置');
      return;
    }

    final config = ServerConfig(
      id: state.editingConfigId ?? ServerConfigService.generateId(),
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      url: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      autoSwitchWifiNames: state.autoSwitchWifiNames,
    );

    try {
      _log.i('开始连接服务器: ${_urlController.text}');

      final client = await SyncClipboardClient.createWithConfig(config);
      final clipboard = await client.getSyncClipboardJson();

      _log.d(
        '成功获取剪贴板数据 - 类型: ${clipboard.type.name}, 预览长度: ${clipboard.text.length}',
      );

      Fluttertoast.showToast(msg: '连接成功');
    } on SyncClipboardException catch (e) {
      if (e.statusCode == 404) {
        _log.w('文件不存在，尝试创建新文件...');

        try {
          final client = await SyncClipboardClient.createWithConfig(config);
          final emptyClipboard = buildTextClipboardPayload('').clipboard;
          await client.putSyncClipboardJson(emptyClipboard);

          _log.i('成功创建空的 SyncClipboard.json 文件');
          Fluttertoast.showToast(msg: '首次使用，已自动创建配置文件！');
        } catch (createError) {
          _log.e('创建文件失败', error: createError);
          Fluttertoast.showToast(msg: '创建文件失败：$createError');
        }
      } else {
        _log.w('业务异常: ${e.message}', error: e);
        Fluttertoast.showToast(msg: e.message);
      }
    } catch (e) {
      _log.e('未知错误', error: e);
      Fluttertoast.showToast(msg: '发生错误：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(serverConfigProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
      data: (state) {
        // 同步 controller
        _syncControllers(state);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '服务器配置',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // 配置选择器行
              Row(
                children: [
                  Expanded(child: _buildConfigDropdown(state)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ref.read(serverConfigProvider.notifier).createNewConfig();
                    },
                    icon: const Icon(Icons.add),
                    tooltip: '新建配置',
                  ),
                  if (state.editingConfigId != null)
                    IconButton(
                      onPressed: () => _openAdvancedSettings(state),
                      icon: const Icon(Icons.tune),
                      tooltip: '高级设置',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '配置名称（可选）',
                  hintText: '留空则显示服务器地址',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (value) {
                  ref
                      .read(serverConfigProvider.notifier)
                      .updateField(name: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: '请输入服务器地址',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
                keyboardType: TextInputType.url,
                onChanged: (value) {
                  ref
                      .read(serverConfigProvider.notifier)
                      .updateField(url: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  hintText: '请输入用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (value) {
                  ref
                      .read(serverConfigProvider.notifier)
                      .updateField(username: value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                onChanged: (value) {
                  ref
                      .read(serverConfigProvider.notifier)
                      .updateField(password: value);
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _testConnection(state),
                icon: const Icon(Icons.link),
                label: const Text('尝试连接到服务器'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // 构建配置下拉选择器
  Widget _buildConfigDropdown(ServerConfigState state) {
    if (state.configList.configs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '请添加服务器配置',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 获取当前选中配置的显示名称
    final currentDisplayName = state.editingConfigId != null
        ? state.configList.configs
              .firstWhere(
                (c) => c.id == state.editingConfigId,
                orElse: () => state.configList.configs.first,
              )
              .displayName
        : '选择配置';

    return PopupMenuButton<String>(
      initialValue: state.editingConfigId,
      onSelected: (value) {
        ref.read(serverConfigProvider.notifier).switchConfig(value);
      },
      itemBuilder: (context) {
        return state.configList.configs.map((config) {
          return PopupMenuItem<String>(
            value: config.id,
            child: Text(
              config.displayName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                currentDisplayName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
