import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:zephyr/src/rust/api/qjs.dart';

/// 把 [qjsTaskCall] 返回的 `{ptr, len}` 句柄包装成 Dart 零拷贝视图，并接管
/// Rust 堆缓冲的所有权。
///
/// - [bytes] 是 `Uint8List` 视图，直接映射 Rust 堆缓冲，不复制数据；
/// - 缓冲会随视图被 GC 回收而自动释放（`Finalizer`），也可用 [free] 主动提前释放，
///   两者幂等、不会双重释放；
/// - JSON 等文本结果可用 [utf8Decode] 解码并立即释放。
class QjsTaskBytesHandle {
  final BigInt ptr;
  final BigInt len;
  Uint8List? _view;
  bool _freed = false;

  QjsTaskBytesHandle._(this.ptr, this.len) {
    if (ptr != BigInt.zero && len != BigInt.zero) {
      final view =
          Pointer<Uint8>.fromAddress(ptr.toInt()).asTypedList(len.toInt());
      _view = view;
      _finalizer.attach(view, _FinalizerToken(this), detach: view);
    } else {
      _view = Uint8List(0);
    }
  }

  /// 是否为空结果（无 Rust 堆缓冲）。
  bool get isEmpty => ptr == BigInt.zero;

  /// 零拷贝视图。注意：调用 [free] 之后不能再访问。
  Uint8List get bytes {
    _ensureNotFreed();
    return _view!;
  }

  /// 主动把缓冲所有权归还给 Rust（释放）。
  ///
  /// 幂等；即使不调用，视图被 GC 回收时也会自动释放，不会泄漏。
  void free() {
    if (_freed) return;
    _freed = true;
    final view = _view;
    if (view != null) {
      _finalizer.detach(view);
    }
    _release();
  }

  /// 按 UTF-8 解码文本（JSON 结果场景），解码完成后立即释放缓冲。
  String utf8Decode({bool allowMalformed = true}) {
    final raw = utf8.decode(bytes, allowMalformed: allowMalformed);
    free();
    return raw;
  }

  void _ensureNotFreed() {
    if (_freed) {
      throw StateError('QjsTaskBytesHandle 已释放，不能再访问');
    }
  }

  void _release() {
    if (ptr != BigInt.zero && len != BigInt.zero) {
      qjsFreeTaskBytes(ptr: ptr, len: len);
    }
  }
}

class _FinalizerToken {
  final QjsTaskBytesHandle handle;
  _FinalizerToken(this.handle);
}

final Finalizer<_FinalizerToken> _finalizer = Finalizer<_FinalizerToken>(
  (token) {
    // finalizer 回调内严禁抛异常；释放失败时静默，靠后续 GC 兜底或进程退出回收。
    try {
      if (!token.handle._freed) {
        token.handle._freed = true;
        token.handle._release();
      }
    } catch (_) {
      // ignore: 释放失败不阻断 GC
    }
  },
);

/// 由 [qjsTaskCall] 的返回值构造所有权句柄。
QjsTaskBytesHandle wrapQjsTaskBytes(QjsTaskBytes bytes) =>
    QjsTaskBytesHandle._(bytes.ptr, bytes.len);
