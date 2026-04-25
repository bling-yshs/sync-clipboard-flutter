import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/service/app_logger.dart';
import 'package:sync_clipboard_flutter/service/downloads_save_service.dart';

class LogViewPage extends StatefulWidget {
  const LogViewPage({super.key});

  @override
  State<LogViewPage> createState() => _LogViewPageState();
}

class _LogViewPageState extends State<LogViewPage>
    with WidgetsBindingObserver {
  static const String _settingsStorageKey = 'app_settings';

  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  List<_ParsedLogEntry> _allLogs = [];
  bool _isLoading = true;
  _LogLevelFilter _selectedLevel = _LogLevelFilter.info;
  StreamSubscription<FileSystemEvent>? _logFileSubscription;
  Timer? _reloadDebounceTimer;

  /// 初始化日志数据和文件监听。
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPageData());
    unawaited(_startLogFileWatch());
  }

  /// 释放日志文件监听和刷新防抖计时器。
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reloadDebounceTimer?.cancel();
    unawaited(_logFileSubscription?.cancel());
    super.dispose();
  }

  /// 应用回到前台时强制重读日志文件。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleLogReload(Duration.zero);
    }
  }

  Future<void> _loadPageData() async {
    final selectedLevel = await _loadSelectedLevel();
    final logs = await AppLogger.instance.readLogsFromFile();
    if (!mounted) {
      return;
    }

    final parsedLogs = <_ParsedLogEntry>[];
    for (int i = 0; i < logs.length; i++) {
      parsedLogs.add(_parseLogLine(logs[i], i));
    }
    parsedLogs.sort((a, b) {
      final timeCompare = b.timestamp.compareTo(a.timestamp);
      if (timeCompare != 0) {
        return timeCompare;
      }
      return b.order.compareTo(a.order);
    });

    setState(() {
      _allLogs = parsedLogs;
      _selectedLevel = selectedLevel;
      _isLoading = false;
    });
  }

  /// 监听日志文件变化并刷新页面数据。
  Future<void> _startLogFileWatch() async {
    final logFilePath = AppLogger.instance.logFilePath;
    if (logFilePath == null || logFilePath.isEmpty) {
      return;
    }

    await _logFileSubscription?.cancel();
    _logFileSubscription = File(logFilePath).watch().listen(
      (_) {
        _scheduleLogReload();
      },
      onError: (_) {},
    );
  }

  /// 防抖触发日志文件重读。
  void _scheduleLogReload([Duration delay = const Duration(milliseconds: 300)]) {
    _reloadDebounceTimer?.cancel();
    _reloadDebounceTimer = Timer(delay, () {
      unawaited(_loadPageData());
    });
  }

  Future<_LogLevelFilter> _loadSelectedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsStorageKey);

    if (settingsJson == null || settingsJson.isEmpty) {
      return _LogLevelFilter.info;
    }

    try {
      final settings = appSettingsFromJson(settingsJson);
      return _logLevelFilterFromStorageValue(settings.logViewLevelFilter);
    } catch (_) {
      return _LogLevelFilter.info;
    }
  }

  Future<void> _saveSelectedLevel(_LogLevelFilter level) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsStorageKey);

    AppSettings settings;
    if (settingsJson != null && settingsJson.isNotEmpty) {
      try {
        settings = appSettingsFromJson(settingsJson);
      } catch (_) {
        settings = const AppSettings();
      }
    } else {
      settings = const AppSettings();
    }

    final updatedSettings = settings.copyWith(logViewLevelFilter: level.name);
    await prefs.setString(
      _settingsStorageKey,
      appSettingsToJson(updatedSettings),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }

  _ParsedLogEntry _parseLogLine(String line, int order) {
    final reg = RegExp(r'^(\S+) \[([A-Z]+)] (.*)$');
    final match = reg.firstMatch(line);

    if (match == null) {
      return _ParsedLogEntry(
        raw: line,
        order: order,
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        level: 'LOG',
        severity: _severityByLevel('LOG'),
        message: line,
      );
    }

    final timestampText = match.group(1)!;
    final level = match.group(2)!;
    final content = match.group(3)!;

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(timestampText);
    } catch (_) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final atMarker = ' | at: ';
    final errorMarker = ' | error: ';

    String message = content;
    String? error;
    String? location;

    final atIndex = content.indexOf(atMarker);
    final errorIndex = content.indexOf(errorMarker);

    if (errorIndex >= 0) {
      final end = atIndex >= 0 && atIndex > errorIndex
          ? atIndex
          : content.length;
      message = content.substring(0, errorIndex).trim();
      error = content.substring(errorIndex + errorMarker.length, end).trim();
    }

    if (atIndex >= 0) {
      final msgEnd = errorIndex >= 0 && errorIndex < atIndex
          ? errorIndex
          : atIndex;
      message = content.substring(0, msgEnd).trim();
      location = content.substring(atIndex + atMarker.length).trim();
    }

    message = message.trim();
    if (message.isEmpty) {
      message = content;
    }

    return _ParsedLogEntry(
      raw: line,
      order: order,
      timestamp: timestamp,
      level: level,
      severity: _severityByLevel(level),
      message: message,
      error: error?.isEmpty == true ? null : error,
      location: location?.isEmpty == true ? null : location,
    );
  }

  int _severityByLevel(String level) {
    switch (level) {
      case 'TRACE':
        return 1;
      case 'DEBUG':
        return 2;
      case 'INFO':
        return 3;
      case 'WARN':
        return 4;
      case 'ERROR':
        return 5;
      case 'FATAL':
        return 6;
      default:
        return 3;
    }
  }

  int _thresholdByFilter(_LogLevelFilter filter) {
    switch (filter) {
      case _LogLevelFilter.trace:
        return 1;
      case _LogLevelFilter.debug:
        return 2;
      case _LogLevelFilter.info:
        return 3;
      case _LogLevelFilter.warn:
        return 4;
      case _LogLevelFilter.error:
        return 5;
      case _LogLevelFilter.fatal:
        return 6;
    }
  }

  String _filterLabel(_LogLevelFilter filter) {
    switch (filter) {
      case _LogLevelFilter.trace:
        return 'TRACE+';
      case _LogLevelFilter.debug:
        return 'DEBUG+';
      case _LogLevelFilter.info:
        return 'INFO+';
      case _LogLevelFilter.warn:
        return 'WARN+';
      case _LogLevelFilter.error:
        return 'ERROR+';
      case _LogLevelFilter.fatal:
        return 'FATAL';
    }
  }

  Future<void> _showLevelMenu(BuildContext tileContext) async {
    final RenderBox button = tileContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(tileContext).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<_LogLevelFilter>(
      context: tileContext,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _LogLevelFilter.values.map((level) {
        final isSelected = level == _selectedLevel;
        return PopupMenuItem<_LogLevelFilter>(
          value: level,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: Theme.of(tileContext).colorScheme.primary,
            ),
            title: Text(_filterLabel(level)),
          ),
        );
      }).toList(),
    );

    if (selected == null) {
      return;
    }

    await _saveSelectedLevel(selected);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedLevel = selected;
    });
  }

  _LogLevelFilter _logLevelFilterFromStorageValue(String value) {
    for (final filter in _LogLevelFilter.values) {
      if (filter.name == value) {
        return filter;
      }
    }
    return _LogLevelFilter.info;
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'TRACE':
        return Colors.grey;
      case 'DEBUG':
        return Colors.blueGrey;
      case 'INFO':
        return Colors.blue;
      case 'WARN':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      case 'FATAL':
        return Colors.red.shade900;
      default:
        return Colors.blueGrey;
    }
  }

  List<_ParsedLogEntry> get _visibleLogs {
    final threshold = _thresholdByFilter(_selectedLevel);
    return _allLogs.where((entry) => entry.severity >= threshold).toList();
  }

  Future<void> _exportLogs() async {
    final visibleLogs = _visibleLogs;
    if (visibleLogs.isEmpty) {
      _showToast('暂无日志可导出');
      return;
    }

    final fileName =
        'sync-clipboard-log-${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';

    try {
      final result = await DownloadsSaveService.saveBytesToDownloads(
        bytes: utf8.encode(visibleLogs.map((e) => e.raw).join('\n')),
        fileName: fileName,
      );
      if (!mounted) {
        return;
      }
      final displayName = result.displayName ?? fileName;
      _showToast('已导出到 ${result.path}/$displayName');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showToast('导出失败：$e');
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('确认清空所有日志吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await AppLogger.instance.clearLogs();
    if (!mounted) {
      return;
    }

    _showToast('日志已清空');
    await _loadPageData();
  }

  @override
  Widget build(BuildContext context) {
    final visibleLogs = _visibleLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        actions: [
          IconButton(
            tooltip: '导出日志',
            onPressed: _exportLogs,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: '清空日志',
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allLogs.isEmpty
          ? const Center(child: Text('暂无日志'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      const Text('日志级别'),
                      const SizedBox(width: 10),
                      Builder(
                        builder: (tileContext) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showLevelMenu(tileContext),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.55),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _filterLabel(_selectedLevel),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.expand_more, size: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      Text('最新在上 · 共 ${visibleLogs.length} 条'),
                    ],
                  ),
                ),
                Expanded(
                  child: visibleLogs.isEmpty
                      ? const Center(child: Text('当前筛选条件下暂无日志'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: visibleLogs.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final log = visibleLogs[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '#${log.order + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.schedule, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        _timeFormat.format(log.timestamp),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _levelColor(
                                            log.level,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          log.level,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _levelColor(log.level),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    log.message,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                  if (log.error != null &&
                                      log.error!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      '错误：${log.error!}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                  if (log.location != null &&
                                      log.location!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      '打印位置：${log.location!}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

enum _LogLevelFilter { trace, debug, info, warn, error, fatal }

class _ParsedLogEntry {
  final String raw;
  final int order;
  final DateTime timestamp;
  final String level;
  final int severity;
  final String message;
  final String? error;
  final String? location;

  const _ParsedLogEntry({
    required this.raw,
    required this.order,
    required this.timestamp,
    required this.level,
    required this.severity,
    required this.message,
    this.error,
    this.location,
  });
}
