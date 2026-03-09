import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config_list.dart';

part 'server_config_state.freezed.dart';

@freezed
abstract class ServerConfigState with _$ServerConfigState {
  const factory ServerConfigState({
    required ServerConfigList configList,
    String? editingConfigId,
    @Default('') String name,
    @Default('') String url,
    @Default('') String username,
    @Default('') String password,
    @Default([]) List<String> autoSwitchWifiNames,
    @Default(false) bool isSaving,
  }) = _ServerConfigState;
}
