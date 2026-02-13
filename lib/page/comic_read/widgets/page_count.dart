import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';

class PageCountWidget extends StatefulWidget {
  final String epPages;

  const PageCountWidget({super.key, required this.epPages});

  @override
  State<PageCountWidget> createState() => _PageCountWidgetState();
}

class _PageCountWidgetState extends State<PageCountWidget> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  String _currentTime = '';
  late Timer _timer;
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initBattery();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTime();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _connectivitySubscription.cancel();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  void _initBattery() async {
    final level = await _battery.batteryLevel;
    if (mounted) {
      setState(() => _batteryLevel = level);
    }

    final state = await _battery.batteryState;
    if (mounted) {
      setState(() => _batteryState = state);
    }

    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() => _batteryState = state);
      }
    });
  }

  IconData getBatteryIcon() {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full;
    }
    if (_batteryLevel >= 95) return Icons.battery_full;
    if (_batteryLevel >= 80) return Icons.battery_6_bar;
    if (_batteryLevel >= 60) return Icons.battery_5_bar;
    if (_batteryLevel >= 50) return Icons.battery_4_bar;
    if (_batteryLevel >= 30) return Icons.battery_3_bar;
    if (_batteryLevel >= 20) return Icons.battery_2_bar;
    if (_batteryLevel >= 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  void _initConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    if (results.isNotEmpty) {
      _updateConnectivityResult(results);
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
      if (results.contains(type)) return type;
    }
    return ConnectivityResult.none;
  }

  // 获取网络状态图标
  IconData _getNetworkStatusIcon(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.bluetooth:
        return Icons.bluetooth;
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.ethernet:
        return Icons.router;
      case ConnectivityResult.mobile:
        return Icons.network_cell;
      case ConnectivityResult.none:
        return Icons.signal_wifi_off;
      case ConnectivityResult.vpn:
        return Icons.vpn_key;
      case ConnectivityResult.other:
        return Icons.signal_cellular_off;
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (formattedTime != _currentTime) {
      setState(() => _currentTime = formattedTime);

      _battery.batteryLevel.then((level) {
        if (mounted && _batteryLevel != level) {
          setState(() => _batteryLevel = level);
        }
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = context.select<ReaderCubit, int>(
      (value) => value.state.pageIndex,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 页码
              Text(
                "$pageIndex/${widget.epPages}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMonoNL-Regular',
                ),
              ),

              const SizedBox(width: 8),

              // 2. 网络图标
              Icon(
                _getNetworkStatusIcon(_connectivityResult),
                color: Colors.white,
                size: 12,
              ),

              const SizedBox(width: 8),

              // // 3. 电量图标
              // Icon(_getBatteryIcon(), color: Colors.white, size: 12),

              // const SizedBox(width: 8),

              // 4. 时间
              Text(
                _currentTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMonoNL-Regular',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
