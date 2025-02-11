import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showInfoToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    context: context,
    description: Text(message),
    type: ToastificationType.info,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showSuccessToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    context: context,
    description: Text(message),
    type: ToastificationType.success,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showWarningToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    context: context,
    description: Text(message),
    type: ToastificationType.warning,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showErrorToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 5),
}) {
  toastification.show(
    context: context,
    description: Text(message),
    type: ToastificationType.error,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}
