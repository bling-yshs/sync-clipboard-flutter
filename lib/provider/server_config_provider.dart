import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config_state.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';

part 'server_config_provider.g.dart';

@riverpod
class ServerConfigNotifier extends _$ServerConfigNotifier {
  @override
  Future<ServerConfigState> build() async {
    final configList = await ServerConfigService.getConfigList();

    // 如果有激活配置，填充表单字段
    if (configList.activeConfigId != null && configList.configs.isNotEmpty) {
      final activeConfig = configList.configs.firstWhere(
        (c) => c.id == configList.activeConfigId,
        orElse: () => configList.configs.first,
      );
      return ServerConfigState(
        configList: configList,
        editingConfigId: activeConfig.id,
        name: activeConfig.name ?? '',
        url: activeConfig.url,
        username: activeConfig.username,
        password: activeConfig.password,
      );
    }

    return ServerConfigState(configList: configList);
  }

  /// 切换配置
  Future<void> switchConfig(String configId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final newList = await ServerConfigService.setActiveConfig(configId);
    final config = newList.configs.firstWhere((c) => c.id == configId);

    state = AsyncData(currentState.copyWith(
      configList: newList,
      editingConfigId: configId,
      name: config.name ?? '',
      url: config.url,
      username: config.username,
      password: config.password,
    ));
  }

  /// 新建配置
  void createNewConfig() {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(
      editingConfigId: null,
      name: '',
      url: '',
      username: '',
      password: '',
    ));
  }

  /// 更新表单字段并自动保存
  Future<void> updateField({
    String? name,
    String? url,
    String? username,
    String? password,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    // 更新状态
    final newState = currentState.copyWith(
      name: name ?? currentState.name,
      url: url ?? currentState.url,
      username: username ?? currentState.username,
      password: password ?? currentState.password,
    );
    state = AsyncData(newState);

    // 自动保存
    await _saveConfig(newState);
  }

  /// 保存配置
  Future<void> _saveConfig(ServerConfigState currentState) async {
    if (currentState.isSaving) return;

    // 如果所有字段都为空，不保存
    if (currentState.url.isEmpty &&
        currentState.username.isEmpty &&
        currentState.password.isEmpty) {
      return;
    }

    state = AsyncData(currentState.copyWith(isSaving: true));

    try {
      final name = currentState.name.isEmpty ? null : currentState.name;

      if (currentState.editingConfigId != null) {
        // 编辑模式：更新现有配置
        final config = ServerConfig(
          id: currentState.editingConfigId!,
          name: name,
          url: currentState.url,
          username: currentState.username,
          password: currentState.password,
        );
        final newList = await ServerConfigService.updateConfig(config);
        state = AsyncData(currentState.copyWith(
          configList: newList,
          isSaving: false,
        ));
      } else {
        // 新建模式：创建新配置
        final newId = ServerConfigService.generateId();
        final config = ServerConfig(
          id: newId,
          name: name,
          url: currentState.url,
          username: currentState.username,
          password: currentState.password,
        );
        final newList = await ServerConfigService.addConfig(config);
        state = AsyncData(currentState.copyWith(
          configList: newList,
          editingConfigId: newId,
          isSaving: false,
        ));
      }
    } catch (e) {
      state = AsyncData(currentState.copyWith(isSaving: false));
    }
  }

  /// 删除配置
  Future<void> deleteConfig(String configId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final newList = await ServerConfigService.deleteConfig(configId);

    // 如果删除的是当前编辑的配置
    if (configId == currentState.editingConfigId) {
      if (newList.configs.isNotEmpty) {
        // 切换到新的激活配置
        final activeConfig = newList.configs.firstWhere(
          (c) => c.id == newList.activeConfigId,
          orElse: () => newList.configs.first,
        );
        state = AsyncData(currentState.copyWith(
          configList: newList,
          editingConfigId: activeConfig.id,
          name: activeConfig.name ?? '',
          url: activeConfig.url,
          username: activeConfig.username,
          password: activeConfig.password,
        ));
      } else {
        // 没有配置了，清空表单
        state = AsyncData(currentState.copyWith(
          configList: newList,
          editingConfigId: null,
          name: '',
          url: '',
          username: '',
          password: '',
        ));
      }
    } else {
      state = AsyncData(currentState.copyWith(configList: newList));
    }
  }
}
