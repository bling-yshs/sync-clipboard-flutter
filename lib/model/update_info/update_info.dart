// 更新信息模型
// 用于存储从服务器获取的更新信息

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'update_info.freezed.dart';
part 'update_info.g.dart';

UpdateInfo updateInfoFromJson(String str) => UpdateInfo.fromJson(json.decode(str));

String updateInfoToJson(UpdateInfo data) => json.encode(data.toJson());

@freezed
abstract class UpdateInfo with _$UpdateInfo {
  const factory UpdateInfo({
    /// 最新版本号
    required String version,
    /// 最低支持版本号，低于此版本必须更新
    required String minSupportedVersion,
    /// 更新日志
    required String changelog,
    /// 安装包大小（字节）
    required int size,
    /// 安装包 SHA256 校验值
    required String sha256,
    /// 下载源列表
    required List<DownloadSource> sources,
  }) = _UpdateInfo;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => _$UpdateInfoFromJson(json);
}

@freezed
abstract class DownloadSource with _$DownloadSource {
  const factory DownloadSource({
    /// 下载源 ID
    required String id,
    /// 下载源名称（用于显示）
    required String name,
    /// 下载地址
    required String url,
  }) = _DownloadSource;

  factory DownloadSource.fromJson(Map<String, dynamic> json) => _$DownloadSourceFromJson(json);
}
