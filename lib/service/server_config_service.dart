// 服务器配置管理服务
// 负责配置的 CRUD 操作和数据迁移

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config_list.dart';

/// 服务器配置管理服务
class ServerConfigService {
  static const String _oldKey = 'server_config';
  static const String _newKey = 'server_config_list';
  static const _uuid = Uuid();

  /// 获取配置列表（包含迁移逻辑）
  static Future<ServerConfigList> getConfigList() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查是否已有新格式数据
    final newJson = prefs.getString(_newKey);
    if (newJson != null && newJson.isNotEmpty) {
      try {
        return serverConfigListFromJson(newJson);
      } catch (e) {
        // 解析失败，返回空列表
        return const ServerConfigList();
      }
    }

    // 检查是否有旧格式数据需要迁移
    final oldJson = prefs.getString(_oldKey);
    if (oldJson != null && oldJson.isNotEmpty) {
      try {
        // 解析旧配置
        final oldData = json.decode(oldJson) as Map<String, dynamic>;

        // 创建新配置（生成 ID）
        final newConfig = ServerConfig(
          id: _uuid.v4(),
          name: null,
          url: oldData['url'] as String? ?? '',
          username: oldData['username'] as String? ?? '',
          password: oldData['password'] as String? ?? '',
        );

        // 创建配置列表
        final configList = ServerConfigList(
          configs: [newConfig],
          activeConfigId: newConfig.id,
        );

        // 保存新格式
        await prefs.setString(_newKey, serverConfigListToJson(configList));

        // 删除旧格式数据
        await prefs.remove(_oldKey);

        return configList;
      } catch (e) {
        // 迁移失败，返回空列表
        return const ServerConfigList();
      }
    }

    // 无数据，返回空列表
    return const ServerConfigList();
  }

  /// 获取当前激活的配置
  static Future<ServerConfig?> getActiveConfig() async {
    final configList = await getConfigList();
    if (configList.activeConfigId == null || configList.configs.isEmpty) {
      return null;
    }

    // 查找激活的配置
    for (final config in configList.configs) {
      if (config.id == configList.activeConfigId) {
        return config;
      }
    }

    // 如果找不到激活的配置，返回第一个
    return configList.configs.first;
  }

  /// 保存配置列表
  static Future<void> saveConfigList(ServerConfigList configList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_newKey, serverConfigListToJson(configList));
  }

  /// 添加新配置
  /// 新配置会自动成为激活配置
  static Future<ServerConfigList> addConfig(ServerConfig config) async {
    final configList = await getConfigList();
    final newList = configList.copyWith(
      configs: [...configList.configs, config],
      activeConfigId: config.id,
    );
    await saveConfigList(newList);
    return newList;
  }

  /// 更新配置
  static Future<ServerConfigList> updateConfig(ServerConfig config) async {
    final configList = await getConfigList();
    final newConfigs = configList.configs.map((c) {
      return c.id == config.id ? config : c;
    }).toList();
    final newList = configList.copyWith(configs: newConfigs);
    await saveConfigList(newList);
    return newList;
  }

  /// 删除配置
  static Future<ServerConfigList> deleteConfig(String configId) async {
    final configList = await getConfigList();
    final newConfigs =
        configList.configs.where((c) => c.id != configId).toList();

    // 如果删除的是当前激活配置，切换到第一个
    String? newActiveId = configList.activeConfigId;
    if (configId == configList.activeConfigId) {
      newActiveId = newConfigs.isNotEmpty ? newConfigs.first.id : null;
    }

    final newList = ServerConfigList(
      configs: newConfigs,
      activeConfigId: newActiveId,
    );
    await saveConfigList(newList);
    return newList;
  }

  /// 设置激活配置
  static Future<ServerConfigList> setActiveConfig(String configId) async {
    final configList = await getConfigList();
    final newList = configList.copyWith(activeConfigId: configId);
    await saveConfigList(newList);
    return newList;
  }

  /// 生成新的配置 ID
  static String generateId() {
    return _uuid.v4();
  }
}
