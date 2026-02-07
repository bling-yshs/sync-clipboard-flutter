import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/server_config/server_config.dart';
import 'package:sync_clipboard_flutter/model/clipboard/clipboard.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/service/server_config_service.dart';

/// SyncClipboard API 客户端
/// 封装了与 SyncClipboard 服务器的所有 HTTP 通信
class SyncClipboardClient {
  late final Dio _dio;
  final ServerConfig config;

  // 私有构造函数
  SyncClipboardClient._(this.config, {bool trustInsecureCert = false}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(config.url),
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(minutes: 10),  // 上传大文件需要更长时间
        receiveTimeout: const Duration(minutes: 5), // 下载大文件需要更长时间
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // 如果开启了信任不安全证书，配置 IOHttpClientAdapter
    if (trustInsecureCert) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // 当证书校验失败时，强行接受所有证书
          // ⚠️ 警告：这会降低安全性，仅建议在开发/测试环境使用
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    // 添加 HTTP Basic Auth 拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final basicAuth = 'Basic ${base64Encode(
            utf8.encode('${config.username}:${config.password}'),
          )}';
          options.headers['Authorization'] = basicAuth;
          return handler.next(options);
        },
      ),
    );
  }

  /// 创建客户端实例（从 SharedPreferences 自动加载配置）
  /// 会自动读取 AppSettings 中的 trustInsecureCert 设置
  static Future<SyncClipboardClient> create() async {
    final prefs = await SharedPreferences.getInstance();

    // 使用新服务获取激活配置
    final config = await ServerConfigService.getActiveConfig();
    if (config == null) {
      throw SyncClipboardException('未配置服务器，请先添加服务器配置');
    }

    // 加载应用设置
    final settingsJson = prefs.getString('app_settings');
    final settings = settingsJson != null
        ? appSettingsFromJson(settingsJson)
        : const AppSettings();

    return SyncClipboardClient._(config, trustInsecureCert: settings.trustInsecureCert);
  }

  /// 规范化 Base URL，确保以 / 结尾
  String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  /// 获取 SyncClipboard.json 的内容
  /// 
  /// 返回值：  
  /// - 成功时返回 Clipboard 对象
  /// - 失败时抛出异常
  /// 
  /// 可能抛出的异常：
  /// - [DioException] 网络请求异常
  /// - [SyncClipboardException] 业务逻辑异常
  Future<Clipboard> getSyncClipboardJson() async {
    try {
      final response = await _dio.get('SyncClipboard.json');

      if (response.statusCode == 200) {
        // 解析 JSON 响应为 Clipboard 对象
        if (response.data is Map<String, dynamic>) {
          return Clipboard.fromJson(response.data as Map<String, dynamic>);
        } else if (response.data is String) {
          return clipboardFromJson(response.data as String);
        } else {
          throw SyncClipboardException(
            '响应数据格式错误',
            statusCode: 200,
          );
        }
      } else if (response.statusCode == 401) {
        throw SyncClipboardException(
          '认证失败：用户名或密码错误',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        throw SyncClipboardException(
          '文件不存在：SyncClipboard.json 未找到',
          statusCode: 404,
        );
      } else {
        throw SyncClipboardException(
          '请求失败：HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 上传/更新 SyncClipboard.json 的内容
  /// 
  /// 参数：
  /// - [clipboard] 要上传的 Clipboard 对象
  /// 
  /// 返回值：
  /// - 成功时返回 true
  /// - 失败时抛出异常
  /// 
  /// 可能抛出的异常：
  /// - [DioException] 网络请求异常
  /// - [SyncClipboardException] 业务逻辑异常
  Future<bool> putSyncClipboardJson(Clipboard clipboard) async {
    try {
      final response = await _dio.put(
        'SyncClipboard.json',
        data: clipboard.toJson(),
        options: Options(
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        // 200 OK, 201 Created, 204 No Content 都表示成功
        return true;
      } else if (response.statusCode == 401) {
        throw SyncClipboardException(
          '认证失败：用户名或密码错误',
          statusCode: 401,
        );
      } else {
        throw SyncClipboardException(
          '上传失败：HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 上传文件到服务器（WebDAV PUT）
  /// 
  /// 参数：
  /// - [filename] 要保存的文件名
  /// - [fileBytes] 文件字节数据
  /// - [onSendProgress] 可选的上传进度回调
  ///   - 参数1：已发送字节数
  ///   - 参数2：总字节数
  /// 
  /// 返回值：
  /// - 成功时返回 true
  /// - 失败时抛出异常
  /// 
  /// 可能抛出的异常：
  /// - [DioException] 网络请求异常
  /// - [SyncClipboardException] 业务逻辑异常
  Future<bool> putSyncClipboardFile(
    String filename,
    List<int> fileBytes, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      // 直接发送字节数组，这样 Dio 才能正确报告上传进度
      final response = await _dio.put(
        'file/$filename',
        data: fileBytes,
        options: Options(
          contentType: 'application/octet-stream',
          headers: {
            'Content-Length': fileBytes.length,
          },
        ),
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw SyncClipboardException(
          '认证失败：用户名或密码错误',
          statusCode: 401,
        );
      } else {
        throw SyncClipboardException(
          '上传失败：HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }
  /// 获取同步剪贴板中的文件数据
  /// 
  /// 参数：
  /// - [filename] 文件名（从 Clipboard 对象的 dataName 字段获取）
  /// - [onReceiveProgress] 可选的下载进度回调
  ///   - 参数1：已接收字节数
  ///   - 参数2：总字节数（-1 表示未知）
  /// 
  /// 返回值：
/// - 成功时返回文件的字节数据 `List<int>`
  /// - 失败时抛出异常
  /// 
  /// 可能抛出的异常：
  /// - [DioException] 网络请求异常
  /// - [SyncClipboardException] 业务逻辑异常
  Future<List<int>> getSyncClipboardFile(
    String filename, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        'file/$filename',
        options: Options(
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: onReceiveProgress,
      );

      if (response.statusCode == 200) {
        return response.data as List<int>;
      } else if (response.statusCode == 401) {
        throw SyncClipboardException(
          '认证失败：用户名或密码错误',
          statusCode: 401,
        );
      } else if (response.statusCode == 404) {
        throw SyncClipboardException(
          '文件不存在：$filename 未找到',
          statusCode: 404,
        );
      } else {
        throw SyncClipboardException(
          '下载失败：HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 处理 Dio 异常，转换为更友好的错误信息
  SyncClipboardException _handleDioException(DioException e) {
    String message;
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时，请检查服务器地址';
        break;
      case DioExceptionType.receiveTimeout:
        message = '接收数据超时';
        break;
      case DioExceptionType.badResponse:
        message = '服务器响应错误：${e.response?.statusCode}';
        break;
      case DioExceptionType.connectionError:
        message = '无法连接到服务器，请检查网络和服务器地址';
        break;
      default:
        message = '请求失败：${e.message}';
    }

    return SyncClipboardException(
      message,
      originalException: e,
      statusCode: e.response?.statusCode,
    );
  }
}

/// SyncClipboard 业务异常
class SyncClipboardException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  SyncClipboardException(
    this.message, {
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => message;
}
