import 'dart:async';

extension Pipe<T> on T {
  R pipe<R>(R Function(T) fn) {
    return fn(this);
  }
}

extension FuturePipe<T> on Future<T> {
  Future<R> pipe<R>(FutureOr<R> Function(T) fn) {
    return then(fn);
  }
}
