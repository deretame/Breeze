import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showInfoToast(
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    title: Text(message),
    type: ToastificationType.info,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showSuccessToast(
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    title: Text(message),
    type: ToastificationType.success,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showWarningToast(
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  toastification.show(
    title: Text(message),
    type: ToastificationType.warning,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}

void showErrorToast(
  String message, {
  Duration duration = const Duration(seconds: 5),
}) {
  toastification.show(
    title: Text(message),
    type: ToastificationType.error,
    style: ToastificationStyle.flatColored,
    autoCloseDuration: duration,
  );
}
