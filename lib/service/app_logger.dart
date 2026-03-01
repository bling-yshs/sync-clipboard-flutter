import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static Logger get logger => instance._logger;

  final _AppLogOutput _appLogOutput = _AppLogOutput();

  late final Logger _logger = Logger(
    printer: _AppLogPrinter(),
    output: MultiOutput([ConsoleOutput(), _appLogOutput]),
  );

  Future<void> init() async {
    await _appLogOutput.init();
  }

  Future<List<String>> readLogs() async {
    return _appLogOutput.readLogs();
  }

  Future<void> clearLogs() async {
    await _appLogOutput.clearLogs();
  }

  String? get logFilePath => _appLogOutput.logFilePath;
}

class _AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final timestamp = DateTime.now().toIso8601String();
    final level = _formatLevel(event.level);
    final message = '${event.message}';
    final error = event.error != null ? ' | error: ${event.error}' : '';
    final location = _extractLocation(event.stackTrace);
    final at = location != null ? ' | at: $location' : '';
    return ['$timestamp [$level] $message$error$at'];
  }

  String? _extractLocation(StackTrace? stackTrace) {
    if (stackTrace == null) {
      return null;
    }

    final lines = stackTrace.toString().split('\n');
    final bracketPattern = RegExp(r'\(([^()]*\.dart:\d+:\d+)\)');
    final directPattern = RegExp(
      r'([A-Za-z]:\\[^:]+\.dart:\d+:\d+|/[^:\s]+\.dart:\d+:\d+|package:[^:\s]+\.dart:\d+:\d+)',
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final bracketMatch = bracketPattern.firstMatch(trimmed);
      if (bracketMatch != null) {
        final location = bracketMatch.group(1)!;
        if (!location.contains('package:logger/')) {
          return location;
        }
      }

      final directMatch = directPattern.firstMatch(trimmed);
      if (directMatch != null) {
        final location = directMatch.group(1)!;
        if (!location.contains('package:logger/')) {
          return location;
        }
      }
    }

    return null;
  }

  String _formatLevel(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      case Level.off:
        return 'OFF';
      case Level.all:
        return 'ALL';
      default:
        return 'LOG';
    }
  }
}

class _AppLogOutput extends LogOutput {
  static const int _maxLines = 2000;

  final List<String> _logs = [];
  File? _logFile;
  Future<void> _writeQueue = Future.value();
  bool _isInitialized = false;

  String? get logFilePath => _logFile?.path;

  @override
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      final supportDir = await getApplicationSupportDirectory();
      final logsDir = Directory('${supportDir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File('${logsDir.path}/app.log');
      if (await _logFile!.exists()) {
        final existingLines = await _logFile!.readAsLines();
        if (existingLines.length > _maxLines) {
          _logs.addAll(existingLines.sublist(existingLines.length - _maxLines));
        } else {
          _logs.addAll(existingLines);
        }
      } else {
        await _logFile!.create(recursive: true);
      }
    } catch (_) {
      _logFile = null;
    } finally {
      _isInitialized = true;
    }
  }

  @override
  void output(OutputEvent event) {
    if (event.lines.isEmpty) {
      return;
    }

    if (!_isInitialized) {
      unawaited(init());
    }

    _logs.addAll(event.lines);
    if (_logs.length > _maxLines) {
      _logs.removeRange(0, _logs.length - _maxLines);
    }

    final file = _logFile;
    if (file == null) {
      return;
    }

    final content = '${event.lines.join('\n')}\n';
    _writeQueue = _writeQueue.then((_) async {
      try {
        await file.writeAsString(content, mode: FileMode.append);
      } catch (_) {
        // 忽略日志写入异常，避免影响主流程
      }
    });
  }

  Future<List<String>> readLogs() async {
    if (!_isInitialized) {
      await init();
    }
    return List<String>.from(_logs);
  }

  Future<void> clearLogs() async {
    if (!_isInitialized) {
      await init();
    }

    _logs.clear();

    final file = _logFile;
    if (file == null) {
      return;
    }

    _writeQueue = _writeQueue.then((_) async {
      try {
        await file.writeAsString('');
      } catch (_) {
        // 忽略清理异常，避免影响主流程
      }
    });
    await _writeQueue;
  }
}
