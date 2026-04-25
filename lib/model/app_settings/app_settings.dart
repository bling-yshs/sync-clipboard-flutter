// 应用设置模型
// 使用 SharedPreferences 进行持久化存储

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

AppSettings appSettingsFromJson(String str) =>
    AppSettings.fromJson(json.decode(str));

String appSettingsToJson(AppSettings data) => json.encode(data.toJson());

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// 是否信任不安全的 HTTPS 证书
    /// 开启后，Dio 请求将不校验 HTTPS 证书
    /// 注意：这会降低安全性，仅建议在开发/测试环境使用
    @Default(false) bool trustInsecureCert,

    /// 启动时自动检查更新
    @Default(true) bool autoCheckUpdate,

    /// 是否已经显示过手动上传提示对话框
    /// 用户点击"我知道了"后设为 true，后续不再显示
    @Default(false) bool manualUploadDialogShown,

    /// Download 下的相对保存目录
    /// 例如 A/B/C，最终保存到 /Download/A/B/C
    @Default('') String downloadRelativePath,

    /// 日志查看页默认选中的日志级别
    @Default('info') String logViewLevelFilter,

    /// 是否启用 Shizuku 读取后台剪贴板文本
    @Default(false) bool enableShizukuClipboard,

    /// 后台同步读取本地剪贴板的间隔秒数
    @Default(3.0) double clipboardCheckIntervalSeconds,

    /// 后台同步检查服务器剪贴板内容的间隔秒数
    @Default(3.0) double serverContentCheckIntervalSeconds,

    /// 是否记录后台自动同步运行日志
    @Default(false) bool enableBackgroundAutoSyncLog,

    /// 被忽略的更新版本号
    /// 用户点击"忽略该版本"后设置，该版本将不再提示更新
    /// 当有新版本发布时，会自动清除该设置
    String? ignoredVersion,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
