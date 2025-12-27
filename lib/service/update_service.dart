// 更新服务
// 负责检查更新、下载 APK 和触发安装

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:android_package_installer/android_package_installer.dart';
import 'package:sync_clipboard_flutter/model/update_info/update_info.dart';

/// 更新检查结果
class UpdateCheckResult {
  final UpdateInfo updateInfo;
  final bool isForced;
  /// 已缓存的 APK 路径（如果 SHA256 校验通过）
  final String? cachedApkPath;

  UpdateCheckResult({
    required this.updateInfo,
    required this.isForced,
    this.cachedApkPath,
  });

  /// 是否有可用的缓存 APK
  bool get hasCachedApk => cachedApkPath != null;
}

/// 更新服务
class UpdateService {
  static const List<String> _updateUrls = [
    'https://github.com/bling-yshs/sync-clipboard-flutter/releases/latest/download/update.json',
    'https://cnb.cool/bling-team/sync-clipboard-flutter-action/-/releases/latest/download/update.json',
  ];

  /// 获取 APK 保存路径
  static Future<String> getApkPath() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('无法获取存储目录');
    }
    return '${dir.path}/update.apk';
  }

  /// 计算文件的 SHA256
  static Future<String> calculateSha256(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 检查更新
  /// 返回 null 表示无需更新或检查失败
  static Future<UpdateCheckResult?> checkForUpdate() async {
    try {
      // 1. 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      // 2. 竞速获取更新信息
      final updateInfo = await _fetchUpdateInfo();
      if (updateInfo == null) return null;

      // 3. 比较版本
      final latestVersion = Version.parse(updateInfo.version);
      if (latestVersion <= currentVersion) return null;

      // 4. 判断是否强制更新
      final minVersion = Version.parse(updateInfo.minSupportedVersion);
      final isForced = currentVersion < minVersion;

      // 5. 检查是否有缓存的 APK
      String? cachedApkPath;
      try {
        final apkPath = await getApkPath();
        final apkFile = File(apkPath);
        if (await apkFile.exists()) {
          // 计算已下载文件的 SHA256
          final localSha256 = await calculateSha256(apkPath);
          // 比较 SHA256（忽略大小写）
          if (localSha256.toLowerCase() == updateInfo.sha256.toLowerCase()) {
            cachedApkPath = apkPath;
          }
        }
      } catch (e) {
        // 缓存检查失败，忽略
      }

      return UpdateCheckResult(
        updateInfo: updateInfo,
        isForced: isForced,
        cachedApkPath: cachedApkPath,
      );
    } catch (e) {
      // 检查更新失败，静默处理
      return null;
    }
  }

  /// 竞速获取更新信息（先成功的胜出，失败的忽略）
  static Future<UpdateInfo?> _fetchUpdateInfo() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // 使用 Completer 实现"先成功的胜出"逻辑
    final completer = Completer<UpdateInfo?>();
    int failedCount = 0;
    final totalCount = _updateUrls.length;

    for (final url in _updateUrls) {
      dio.get(url).then((response) {
        // 如果已经有结果了，忽略后续响应
        if (completer.isCompleted) return;

        if (response.statusCode == 200) {
          UpdateInfo? info;
          if (response.data is Map<String, dynamic>) {
            info = UpdateInfo.fromJson(response.data as Map<String, dynamic>);
          } else if (response.data is String) {
            info = updateInfoFromJson(response.data as String);
          }
          if (info != null && !completer.isCompleted) {
            completer.complete(info);
          }
        }
      }).catchError((e) {
        // 请求失败，增加失败计数
        failedCount++;
        // 如果所有请求都失败了，返回 null
        if (failedCount >= totalCount && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// 下载 APK
  /// [url] 下载地址
  /// [onProgress] 进度回调 (已下载字节, 总字节)
  /// 返回下载后的文件路径
  static Future<String> downloadApk(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ));

    final savePath = await getApkPath();

    // 如果文件已存在，先删除
    final file = File(savePath);
    if (await file.exists()) {
      await file.delete();
    }

    // 下载文件
    await dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
    );

    return savePath;
  }

  /// 安装 APK
  /// [filePath] APK 文件路径
  static Future<void> installApk(String filePath) async {
    await AndroidPackageInstaller.installApk(apkFilePath: filePath);
  }
}

