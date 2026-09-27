import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:zephyr/config/global/global_setting.dart';

/// 墨水屏阅读器识别。
///
/// 只按厂商标识匹配，普通手机/平板不会命中。结果在进程内缓存，避免每次进入设置页都打一次平台通道。
class EinkDevice {
  const EinkDevice._();

  static const List<String> _markers = <String>[
    'boyue',
    'likebook',
    'byread',
    'boeye',
    'onyx',
    'boox',
    'mornsen',
    'supernote',
    'reinkstone',
    'remarkable',
    'ireader',
  ];

  static Future<bool>? _cached;

  static bool get isDetectable => !kIsWeb && Platform.isAndroid;

  static Future<bool> detect() => _cached ??= _detect();

  static Future<bool> _detect() async {
    if (!isDetectable) return false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final haystack = <String>[
        info.brand,
        info.manufacturer,
        info.model,
        info.device,
      ].map((value) => value.toLowerCase()).join(' ');
      return _markers.any(haystack.contains);
    } catch (_) {
      // 识别失败按“非墨水屏”处理，用户仍可在设置里手动打开。
      return false;
    }
  }
}

/// 首启自动开启墨水屏模式。
///
/// 只在检测未处理过时生效，用户之后手动关掉就不会每次启动都被翻回来。
Future<void> applyEinkAutoDetection(GlobalSettingCubit cubit) async {
  if (cubit.state.eInkSetting.detectionHandled) return;
  final detected = await EinkDevice.detect();
  cubit.updateState(
    (current) => current.copyWith(
      eInkSetting: current.eInkSetting.copyWith(
        enabled: detected,
        detectionHandled: true,
      ),
      readSetting: detected
          ? current.readSetting.copyWith(
              noAnimation: true,
              einkOptimization: true,
            )
          : current.readSetting,
    ),
  );
}
