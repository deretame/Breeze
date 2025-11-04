import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';

import '../util/memory/memory_monitor.dart';

class MemoryMonitorWidget extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final Duration updateInterval;

  const MemoryMonitorWidget({
    super.key,
    required this.child,
    this.showOverlay = kDebugMode,
    this.updateInterval = const Duration(seconds: 2),
  });

  @override
  State<MemoryMonitorWidget> createState() => _MemoryMonitorWidgetState();
}

class _MemoryMonitorWidgetState extends State<MemoryMonitorWidget> {
  MemoryInfo? _currentMemoryInfo;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _updateMemoryInfo();
    // 定期更新内存信息
    Future.delayed(widget.updateInterval, () {
      if (mounted) {
        _startMonitoring();
      }
    });
  }

  Future<void> _updateMemoryInfo() async {
    try {
      final info = await MemoryMonitor.getMemoryInfo();
      if (mounted) {
        setState(() {
          _currentMemoryInfo = info;
        });
      }
    } catch (e) {
      logger.e('Failed to update memory info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && _currentMemoryInfo != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: _buildMemoryOverlay(),
          ),
      ],
    );
  }

  Widget _buildMemoryOverlay() {
    final info = _currentMemoryInfo!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black..withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 简化显示
            Text(
              'Dart: ${MemoryInfoExtension.formatBytes(info.dartHeapUsed)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            if (info.externalMemory > 0)
              Text(
                'Ext: ${MemoryInfoExtension.formatBytes(info.externalMemory)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),

            // 展开显示详细信息
            if (_isExpanded) ...[
              const Divider(color: Colors.grey, height: 8),
              Text(
                'Capacity: ${MemoryInfoExtension.formatBytes(info.dartHeapCapacity)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
              if (info.nativeHeapSize != null)
                Text(
                  'Native: ${MemoryInfoExtension.formatBytes(info.nativeHeapSize!)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              if (info.totalMemory != null && info.availableMemory != null) ...[
                Text(
                  'Sys Total: ${MemoryInfoExtension.formatBytes(info.totalMemory!)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Sys Avail: ${MemoryInfoExtension.formatBytes(info.availableMemory!)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      MemoryMonitor.forceGC();
                      _updateMemoryInfo();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red..withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      MemoryMonitor.logMemoryUsage('Manual Log');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LOG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 扩展 MemoryInfo 类以访问 _formatBytes 方法
extension MemoryInfoExtension on MemoryInfo {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
