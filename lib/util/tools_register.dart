import 'dart:async';
import 'dart:convert';

import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/update/check_update.dart';
import 'package:zephyr/widgets/toast.dart';

void _register(
  String functionName,
  FutureOr<String> Function(String) dartCallback,
) {
  registerFunction(functionName: functionName, dartCallback: dartCallback);
}

Future<void> registerDartTools() async {
  _register("dart.getAppVersion", (_) async {
    return await getAppVersion();
  });

  _register('flutter.showToast', (String data) async {
    final json = jsonDecode(data) as Map<String, dynamic>;
    final message = json['message'] as String? ?? '';
    final title = json['title'] as String?;
    final level = json['level'] as String? ?? 'info';

    final int? customSeconds = json['seconds'] as int?;
    final Duration duration = Duration(
      seconds: customSeconds ?? (level == 'error' ? 5 : 2),
    );

    switch (level) {
      case 'info':
        showInfoToast(message, title: title, duration: duration);
        break;
      case 'success':
        showSuccessToast(message, title: title, duration: duration);
        break;
      case 'warning':
        showWarningToast(message, title: title, duration: duration);
        break;
      case 'error':
        showErrorToast(message, title: title, duration: duration);
        break;
      default:
        showInfoToast(message, title: title, duration: duration);
        break;
    }

    return '';
  });
}
