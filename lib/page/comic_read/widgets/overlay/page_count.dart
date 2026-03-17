import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

class PageCountWidget extends StatefulWidget {
  final String epPages;

  const PageCountWidget({super.key, required this.epPages});

  @override
  State<PageCountWidget> createState() => _PageCountWidgetState();
}

class _PageCountWidgetState extends State<PageCountWidget> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  String _currentTime = '';
  Timer? _timer;
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
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }

  void _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() => _batteryLevel = level);
      }

      final state = await _battery.batteryState;
      if (mounted) {
        setState(() => _batteryState = state);
      }

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) {
        if (mounted) {
          setState(() => _batteryState = state);
        }
      });
    } catch (_) {}
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
    try {
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
    } catch (_) {}
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

      _battery.batteryLevel
          .then((level) {
            if (mounted && _batteryLevel != level) {
              setState(() => _batteryLevel = level);
            }
          })
          .catchError((_) {});
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
    final readSetting = context.select<GlobalSettingCubit, ReadSettingState>(
      (cubit) => cubit.state.readSetting,
    );

    final showPage = readSetting.pageInfoShowPage;
    final showNetwork = readSetting.pageInfoShowNetwork;
    final showBattery = readSetting.pageInfoShowBattery;
    final showTime = readSetting.pageInfoShowTime;
    final opacityPercent = readSetting.pageInfoOpacityPercent.clamp(20, 100);
    final fontSize = readSetting.pageInfoFontSize.clamp(10, 20).toDouble();

    if (!showPage && !showNetwork && !showBattery && !showTime) {
      return const Positioned(top: 0, left: 0, child: SizedBox.shrink());
    }

    final mediaPadding = MediaQuery.of(context).padding;
    final edge = readSetting.pageInfoEdgePadding.clamp(0, 48).toDouble();
    final sideExtra =
        readSetting.pageInfoHorizontalPosition ==
            ReaderInfoHorizontalPosition.center
        ? 0.0
        : (Platform.isIOS ? 22.0 : 12.0);
    final verticalExtra = Platform.isIOS ? 6.0 : 2.0;
    final showInStatusBar =
        readSetting.pageInfoVerticalPosition ==
            ReaderInfoVerticalPosition.top &&
        readSetting.pageInfoTopInStatusBar;

    final verticalOffset =
        readSetting.pageInfoVerticalPosition == ReaderInfoVerticalPosition.top
        ? (showInStatusBar ? edge : mediaPadding.top + edge + verticalExtra)
        : mediaPadding.bottom + edge + verticalExtra;

    final parsedEpPages = int.tryParse(widget.epPages);
    final totalPageCount = (parsedEpPages != null && parsedEpPages > 0)
        ? parsedEpPages
        : 1;
    final currentDisplayPage = getDisplayPageNumber(
      slotIndex: pageIndex,
      enableDoublePage: readSetting.doublePageMode,
    ).clamp(1, totalPageCount);

    final panel = _PageInfoPanel(
      pageText: '$currentDisplayPage/$totalPageCount',
      showPage: showPage,
      showNetwork: showNetwork,
      showBattery: showBattery,
      showTime: showTime,
      currentTime: _currentTime,
      batteryLevel: _batteryLevel,
      networkIcon: _getNetworkStatusIcon(_connectivityResult),
      batteryIcon: getBatteryIcon(),
      opacityPercent: opacityPercent,
      fontSize: fontSize,
    );

    final isTop =
        readSetting.pageInfoVerticalPosition == ReaderInfoVerticalPosition.top;
    final horizontalPosition = readSetting.pageInfoHorizontalPosition;

    if (horizontalPosition == ReaderInfoHorizontalPosition.center) {
      return Positioned(
        top: isTop ? verticalOffset : null,
        bottom: isTop ? null : verticalOffset,
        left: 0,
        right: 0,
        child: Align(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: panel,
        ),
      );
    }

    final left = horizontalPosition == ReaderInfoHorizontalPosition.left
        ? mediaPadding.left + edge + sideExtra
        : null;
    final right = horizontalPosition == ReaderInfoHorizontalPosition.right
        ? mediaPadding.right + edge + sideExtra
        : null;

    return Positioned(
      top: isTop ? verticalOffset : null,
      bottom: isTop ? null : verticalOffset,
      left: left,
      right: right,
      child: panel,
    );
  }
}

class _PageInfoPanel extends StatelessWidget {
  final String pageText;
  final bool showPage;
  final bool showNetwork;
  final bool showBattery;
  final bool showTime;
  final String currentTime;
  final int batteryLevel;
  final IconData networkIcon;
  final IconData batteryIcon;
  final int opacityPercent;
  final double fontSize;

  const _PageInfoPanel({
    required this.pageText,
    required this.showPage,
    required this.showNetwork,
    required this.showBattery,
    required this.showTime,
    required this.currentTime,
    required this.batteryLevel,
    required this.networkIcon,
    required this.batteryIcon,
    required this.opacityPercent,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'JetBrainsMonoNL-Regular',
    );

    final items = <Widget>[];
    if (showPage) {
      items.add(Text(pageText, style: textStyle.copyWith(fontSize: fontSize)));
    }
    if (showNetwork) {
      items.add(
        Icon(
          networkIcon,
          color: Colors.white,
          size: (fontSize + 1).clamp(10, 24),
        ),
      );
    }
    if (showBattery) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              batteryIcon,
              color: Colors.white,
              size: (fontSize + 1).clamp(10, 24),
            ),
            const SizedBox(width: 2),
            Text(
              '$batteryLevel%',
              style: textStyle.copyWith(fontSize: fontSize),
            ),
          ],
        ),
      );
    }
    if (showTime) {
      items.add(
        Text(currentTime, style: textStyle.copyWith(fontSize: fontSize)),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: opacityPercent / 100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}


