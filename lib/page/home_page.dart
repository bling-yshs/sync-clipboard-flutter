import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config_list.dart';
import 'package:sync_clipboard_flutter/dio/sync_clipboard_client.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';
import 'package:logger/logger.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Logger _log = Logger();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 配置列表
  ServerConfigList _configList = const ServerConfigList();
  // 当前编辑的配置 ID（null 表示新建模式）
  String? _editingConfigId;
  // 是否正在加载
  bool _isLoading = true;
  // 防止重复保存
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfigList();

    // 监听文本变化，实时保存
    _nameController.addListener(_saveConfig);
    _urlController.addListener(_saveConfig);
    _usernameController.addListener(_saveConfig);
    _passwordController.addListener(_saveConfig);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 加载配置列表
  Future<void> _loadConfigList() async {
    final configList = await ServerConfigService.getConfigList();
    setState(() {
      _configList = configList;
      _isLoading = false;
    });

    // 如果有激活配置，填充表单
    if (configList.activeConfigId != null && configList.configs.isNotEmpty) {
      final activeConfig = configList.configs.firstWhere(
        (c) => c.id == configList.activeConfigId,
        orElse: () => configList.configs.first,
      );
      _fillForm(activeConfig);
      _editingConfigId = activeConfig.id;
    }
  }

  // 填充表单
  void _fillForm(ServerConfig config) {
    // 移除监听器，避免触发保存
    _nameController.removeListener(_saveConfig);
    _urlController.removeListener(_saveConfig);
    _usernameController.removeListener(_saveConfig);
    _passwordController.removeListener(_saveConfig);

    _nameController.text = config.name ?? '';
    _urlController.text = config.url;
    _usernameController.text = config.username;
    _passwordController.text = config.password;

    // 重新添加监听器
    _nameController.addListener(_saveConfig);
    _urlController.addListener(_saveConfig);
    _usernameController.addListener(_saveConfig);
    _passwordController.addListener(_saveConfig);
  }

  // 清空表单
  void _clearForm() {
    // 移除监听器，避免触发保存
    _nameController.removeListener(_saveConfig);
    _urlController.removeListener(_saveConfig);
    _usernameController.removeListener(_saveConfig);
    _passwordController.removeListener(_saveConfig);

    _nameController.clear();
    _urlController.clear();
    _usernameController.clear();
    _passwordController.clear();

    // 重新添加监听器
    _nameController.addListener(_saveConfig);
    _urlController.addListener(_saveConfig);
    _usernameController.addListener(_saveConfig);
    _passwordController.addListener(_saveConfig);
  }

  // 保存配置（实时保存）
  Future<void> _saveConfig() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final name = _nameController.text.isEmpty ? null : _nameController.text;
      final url = _urlController.text;
      final username = _usernameController.text;
      final password = _passwordController.text;

      // 如果所有字段都为空，不保存
      if (url.isEmpty && username.isEmpty && password.isEmpty) {
        _isSaving = false;
        return;
      }

      if (_editingConfigId != null) {
        // 编辑模式：更新现有配置
        final config = ServerConfig(
          id: _editingConfigId!,
          name: name,
          url: url,
          username: username,
          password: password,
        );
        final newList = await ServerConfigService.updateConfig(config);
        setState(() {
          _configList = newList;
        });
      } else {
        // 新建模式：创建新配置
        final newId = ServerConfigService.generateId();
        final config = ServerConfig(
          id: newId,
          name: name,
          url: url,
          username: username,
          password: password,
        );
        final newList = await ServerConfigService.addConfig(config);
        setState(() {
          _configList = newList;
          _editingConfigId = newId;
        });
      }
    } finally {
      _isSaving = false;
    }
  }

  // 切换配置
  Future<void> _switchConfig(String configId) async {
    final newList = await ServerConfigService.setActiveConfig(configId);
    final config = newList.configs.firstWhere((c) => c.id == configId);

    setState(() {
      _configList = newList;
      _editingConfigId = configId;
    });

    // 填充表单
    _fillForm(config);
  }

  // 新建配置
  void _createNewConfig() {
    _clearForm();
    setState(() {
      _editingConfigId = null;
    });
  }

  // 删除配置
  Future<void> _deleteConfig(String configId) async {
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

    if (confirmed != true) return;

    final newList = await ServerConfigService.deleteConfig(configId);
    setState(() {
      _configList = newList;
    });

    // 如果删除的是当前编辑的配置
    if (configId == _editingConfigId) {
      if (newList.configs.isNotEmpty) {
        // 切换到新的激活配置
        final activeConfig = newList.configs.firstWhere(
          (c) => c.id == newList.activeConfigId,
          orElse: () => newList.configs.first,
        );
        _fillForm(activeConfig);
        _editingConfigId = activeConfig.id;
      } else {
        // 没有配置了，清空表单
        _clearForm();
        _editingConfigId = null;
      }
    }

    Fluttertoast.showToast(msg: '配置已删除');
  }

  // 显示编辑对话框
  Future<void> _showEditDialog() async {
    if (_editingConfigId == null) return;

    final currentConfig = _configList.configs.firstWhere(
      (c) => c.id == _editingConfigId,
    );

    final nameController = TextEditingController(text: currentConfig.name ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '配置名称',
                hintText: '留空则显示服务器地址',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteConfig(_editingConfigId!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // 更新名称
              _nameController.text = nameController.text;
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    nameController.dispose();
  }

  // 测试服务器连接
  Future<void> _testConnection() async {
    // 验证配置是否完整
    if (_urlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: '请填写完整的服务器配置');
      return;
    }

    try {
      _log.i('开始连接服务器: ${_urlController.text}');

      final client = await SyncClipboardClient.create();
      final clipboard = await client.getSyncClipboardJson();

      _log.d(
          '成功获取剪贴板数据 - 类型: ${clipboard.type.name}, 内容长度: ${clipboard.clipboard.length}');

      Fluttertoast.showToast(msg: '连接成功');
    } on SyncClipboardException catch (e) {
      if (e.statusCode == 404) {
        _log.w('文件不存在，尝试创建新文件...');

        try {
          final client = await SyncClipboardClient.create();
          final emptyClipboard = const Clipboard(
            file: '',
            clipboard: '',
            type: ClipboardType.text,
          );
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '服务器配置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 配置选择器行
          Row(
            children: [
              Expanded(
                child: _buildConfigDropdown(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _createNewConfig,
                icon: const Icon(Icons.add),
                tooltip: '新建配置',
              ),
              if (_editingConfigId != null)
                IconButton(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit),
                  tooltip: '编辑配置',
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
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _testConnection,
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
  }

  // 构建配置下拉选择器
  Widget _buildConfigDropdown() {
    if (_configList.configs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '请添加服务器配置',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // 获取当前选中配置的显示名称
    final currentDisplayName = _editingConfigId != null
        ? _configList.configs
            .firstWhere(
              (c) => c.id == _editingConfigId,
              orElse: () => _configList.configs.first,
            )
            .displayName
        : '选择配置';

    return PopupMenuButton<String>(
      initialValue: _editingConfigId,
      onSelected: (value) {
        _switchConfig(value);
      },
      itemBuilder: (context) {
        return _configList.configs.map((config) {
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
