import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class PageCountWidget extends StatefulWidget {
  final int pageIndex;
  final String epPages;

  const PageCountWidget({
    super.key,
    required this.pageIndex,
    required this.epPages,
  });

  @override
  State<PageCountWidget> createState() => _PageCountWidgetState();
}

class _PageCountWidgetState extends State<PageCountWidget> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      setState(() => _currentTime = formattedTime);

      _startTimer();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // 初始化网络状态监听
  void _initConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectivityResult(results); // 传入完整结果列表
    }
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (mounted && results.isNotEmpty) {
        _updateConnectivityResult(results);
      }
    });
  }

  void _updateConnectivityResult(List<ConnectivityResult> results) {
    final highestPriority = _getHighestPriorityResult(results);
    if (mounted && highestPriority != _connectivityResult) {
      setState(() {
        _connectivityResult = highestPriority;
      });
    }
  }

  ConnectivityResult _getHighestPriorityResult(
    List<ConnectivityResult> results,
  ) {
    const priorityOrder = [
      ConnectivityResult.wifi,
      ConnectivityResult.mobile,
      ConnectivityResult.none,
      ConnectivityResult.ethernet,
      ConnectivityResult.bluetooth,
      ConnectivityResult.vpn,
      ConnectivityResult.other,
    ];

    for (var type in priorityOrder) {
      if (results.contains(type)) {
        return type;
      }
    }
    return ConnectivityResult.none;
  }

  // 启动定时器，每秒更新时间
  void _startTimer() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final formattedTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        if (formattedTime != _currentTime) {
          setState(() {
            _currentTime = formattedTime;
          });
        }
      }
    });
  }

  // 获取网络状态图标
  IconData _getNetworkStatusIcon(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth; // 蓝牙图标
      case ConnectivityResult.wifi:
        return Icons.wifi; // Wi-Fi 图标
      case ConnectivityResult.ethernet:
        return Icons.router; // 以太网图标
      case ConnectivityResult.mobile:
        return Icons.network_cell; // 移动数据图标
      case ConnectivityResult.none:
        return Icons.signal_wifi_off; // 无网络图标
      case ConnectivityResult.vpn:
        return Icons.vpn_key; // vpn图标
      case ConnectivityResult.other:
        return Icons.signal_cellular_off; // 未知网络图标
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, // 离底部的间距
      left: 0, // 离左边的间距
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10), // 右上角设置圆角
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black,
            // 半透明背景
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0), // 左上角保持直角
              topRight: Radius.circular(10), // 右上角设置圆角
              bottomLeft: Radius.circular(0), // 左下角保持直角
              bottomRight: Radius.circular(0), // 右下角保持直角
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 显示当前页数
              Text(
                "${widget.pageIndex - 1}/${widget.epPages}",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              SizedBox(width: 5), // 添加间距
              // 显示网络状态
              Icon(
                _getNetworkStatusIcon(_connectivityResult), // 使用网络状态图标
                color: Colors.white,
                size: 12,
              ),
              SizedBox(width: 5), // 添加间距
              Text(
                _currentTime,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
