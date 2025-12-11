import 'dart:async';

import 'package:flutter/material.dart';

import 'simple_memory_monitor.dart';

/// 内存监控悬浮窗组件
///
/// 使用方式：
/// ```dart
/// MemoryOverlayWidget(
///   enabled: kDebugMode, // 条件显示
///   child: Scaffold(...),
/// )
/// ```
class MemoryOverlayWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration updateInterval;

  const MemoryOverlayWidget({
    super.key,
    required this.child,
    this.enabled = false,
    this.updateInterval = const Duration(seconds: 2),
  });

  @override
  State<MemoryOverlayWidget> createState() => _MemoryOverlayWidgetState();
}

class _MemoryOverlayWidgetState extends State<MemoryOverlayWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  SimpleMemoryInfo? _memoryInfo;
  Offset _position = const Offset(10, 100);
  bool _isDragging = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.enabled) {
      _startMonitoring();
      // 延迟插入 Overlay 以确保 context 可用
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _insertOverlay();
      });
    }
  }

  @override
  void didUpdateWidget(MemoryOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startMonitoring();
        // 延迟插入 Overlay 以避免在构建阶段修改状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _insertOverlay();
        });
      } else {
        _stopMonitoring();
        // 延迟移除 Overlay 以避免在构建阶段修改状态
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _removeOverlay();
        });
      }
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _insertOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlayContent());

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _startMonitoring() {
    _updateMemoryInfo();
    _timer = Timer.periodic(widget.updateInterval, (_) => _updateMemoryInfo());
  }

  void _stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateMemoryInfo() async {
    try {
      final info = await SimpleMemoryMonitor.getMemoryInfo();
      if (mounted) {
        setState(() => _memoryInfo = info);
        _updateOverlay();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    _updateOverlay();
  }

  String _formatBytes(int bytes) {
    if (bytes < 0) return 'N/A';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  double _getPercentage(int used, int total) {
    if (total <= 0) return 0;
    return (used / total * 100).clamp(0, 100);
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 75) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // 只返回 child，内存监控 UI 通过 Overlay 显示在最上层
    return widget.child;
  }

  // 构建 Overlay 内容
  Widget _buildOverlayContent() {
    if (!widget.enabled || _memoryInfo == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          _updateOverlay();
        },
        onPanUpdate: (details) {
          setState(() {
            final maxWidth = _isExpanded ? 320.0 : 150.0;
            final maxHeight = _isExpanded ? 400.0 : 100.0;
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(
                0,
                MediaQuery.of(context).size.width - maxWidth,
              ),
              (_position.dy + details.delta.dy).clamp(
                0,
                MediaQuery.of(context).size.height - maxHeight,
              ),
            );
          });
          _updateOverlay();
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _updateOverlay();
        },
        child: Material(
          elevation: _isDragging ? 8 : 4,
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.85),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isExpanded ? 300 : null,
            constraints: BoxConstraints(
              minWidth: _isExpanded ? 300 : 140,
              maxWidth: _isExpanded ? 300 : 160,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_isExpanded)
                  _buildExpandedContent()
                else
                  _buildCompactContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.memory, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Memory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    final info = _memoryInfo!;
    final totalUsed = info.runtimeUsed > 0
        ? info.runtimeUsed
        : info.dartHeapUsed;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactRow('App', totalUsed, Colors.blue),
          if (info.nativeHeapAllocated > 0)
            _buildCompactRow('Native', info.nativeHeapAllocated, Colors.purple),
          if (info.systemTotal > 0 && info.systemAvailable > 0)
            _buildCompactRow(
              'System',
              info.systemTotal - info.systemAvailable,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String label, int bytes, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ${_formatBytes(bytes)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final info = _memoryInfo!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dart Heap
            _buildSection(
              'Dart Heap',
              info.dartHeapUsed,
              info.dartHeapCapacity > 0
                  ? info.dartHeapCapacity
                  : info.dartHeapCommitted,
              Colors.blue,
              [
                ('Used', info.dartHeapUsed),
                ('Capacity', info.dartHeapCapacity),
                ('Committed', info.dartHeapCommitted),
              ],
            ),

            // Runtime Memory
            if (info.runtimeUsed > 0) ...[
              const SizedBox(height: 12),
              _buildSection(
                'Runtime',
                info.runtimeUsed,
                info.runtimeMax > 0 ? info.runtimeMax : info.runtimeTotal,
                Colors.cyan,
                [
                  ('Used', info.runtimeUsed),
                  ('Total', info.runtimeTotal),
                  ('Free', info.runtimeFree),
                  ('Max', info.runtimeMax),
                ],
              ),
            ],

            // Native Heap
            if (info.nativeHeapAllocated > 0) ...[
              const SizedBox(height: 12),
              _buildSection(
                'Native Heap',
                info.nativeHeapAllocated,
                info.nativeHeapSize > 0
                    ? info.nativeHeapSize
                    : info.nativeHeapAllocated,
                Colors.purple,
                [
                  ('Allocated', info.nativeHeapAllocated),
                  ('Size', info.nativeHeapSize),
                ],
              ),
            ],

            // System Memory
            if (info.systemTotal > 0 && info.systemAvailable > 0) ...[
              const SizedBox(height: 12),
              _buildSection(
                'System',
                info.systemTotal - info.systemAvailable,
                info.systemTotal,
                Colors.orange,
                [
                  ('Used', info.systemTotal - info.systemAvailable),
                  ('Available', info.systemAvailable),
                  ('Total', info.systemTotal),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    int used,
    int total,
    Color color,
    List<(String, int)> details,
  ) {
    final percentage = _getPercentage(used, total);
    final progressColor = _getProgressColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (total > 0)
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),

        // Progress Bar
        if (total > 0) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],

        // Details
        const SizedBox(height: 6),
        ...details.map((detail) {
          final (label, value) = detail;
          if (value <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Row(
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatBytes(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
