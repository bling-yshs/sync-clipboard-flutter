import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiInfoService {
  WifiInfoService._();

  static const MethodChannel _channel = MethodChannel(
    'com.yshs.sync_clipboard_flutter/wifi',
  );

  static Future<String?> getCurrentWifiName() async {
    if (!Platform.isAndroid) {
      return null;
    }

    if (!await canReadWifiName()) {
      return null;
    }

    try {
      final wifiName = await _channel.invokeMethod<String>(
        'getCurrentWifiName',
      );
      return normalizeWifiName(wifiName);
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> canReadWifiName() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final permissionStatus = await Permission.locationWhenInUse.status;
    if (!permissionStatus.isGranted) {
      return false;
    }

    final serviceStatus = await Permission.locationWhenInUse.serviceStatus;
    return serviceStatus == ServiceStatus.enabled;
  }

  static Future<PermissionStatus> getPermissionStatus() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.denied;
    }
    return Permission.locationWhenInUse.status;
  }

  static Future<ServiceStatus> getLocationServiceStatus() async {
    if (!Platform.isAndroid) {
      return ServiceStatus.disabled;
    }
    return Permission.locationWhenInUse.serviceStatus;
  }

  static Future<PermissionStatus> requestLocationPermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.denied;
    }
    return Permission.locationWhenInUse.request();
  }

  static String? normalizeWifiName(String? rawWifiName) {
    final trimmed = rawWifiName?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == '<unknown ssid>' ||
        trimmed == '0x') {
      return null;
    }

    if (trimmed.startsWith('"') &&
        trimmed.endsWith('"') &&
        trimmed.length >= 2) {
      final unquoted = trimmed.substring(1, trimmed.length - 1).trim();
      return unquoted.isEmpty ? null : unquoted;
    }

    return trimmed;
  }
}
