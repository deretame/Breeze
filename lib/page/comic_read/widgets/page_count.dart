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
    _startTimer();
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
      _updateConnectivityResult(results.first); // 取第一个网络状态
    }
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen((results) {
      if (mounted &&
          results.isNotEmpty &&
          results.first != _connectivityResult) {
        _updateConnectivityResult(results.first); // 更新网络状态
      }
    });
  }

  void _updateConnectivityResult(ConnectivityResult result) {
    setState(() {
      _connectivityResult = result;
    });
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
      case ConnectivityResult.wifi:
        return Icons.wifi; // Wi-Fi 图标
      case ConnectivityResult.mobile:
        return Icons.network_cell; // 移动数据图标
      case ConnectivityResult.none:
        return Icons.signal_wifi_off; // 无网络图标
      default:
        return Icons.error; // 未知状态图标
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
