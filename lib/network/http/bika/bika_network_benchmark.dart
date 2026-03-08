import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:zephyr/src/rust/api/bika.dart';

class BikaNetworkBenchmarkResult {
  const BikaNetworkBenchmarkResult({
    required this.url,
    required this.totalRequests,
    required this.dartNativeSuccess,
    required this.dartNativeFailed,
    required this.rustQjsSuccess,
    required this.rustQjsFailed,
    required this.dartNativeElapsed,
    required this.rustQjsElapsed,
  });

  final String url;
  final int totalRequests;

  final int dartNativeSuccess;
  final int dartNativeFailed;
  final int rustQjsSuccess;
  final int rustQjsFailed;

  final Duration dartNativeElapsed;
  final Duration rustQjsElapsed;

  double get dartNativeAvgMs =>
      dartNativeElapsed.inMicroseconds / 1000 / totalRequests;
  double get rustQjsAvgMs =>
      rustQjsElapsed.inMicroseconds / 1000 / totalRequests;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'totalRequests': totalRequests,
      'dartNative': {
        'success': dartNativeSuccess,
        'failed': dartNativeFailed,
        'elapsedMs': dartNativeElapsed.inMilliseconds,
        'avgMs': dartNativeAvgMs,
      },
      'rustQjs': {
        'success': rustQjsSuccess,
        'failed': rustQjsFailed,
        'elapsedMs': rustQjsElapsed.inMilliseconds,
        'avgMs': rustQjsAvgMs,
      },
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

Future<BikaNetworkBenchmarkResult> runBikaNativeVsRustBenchmark({
  int totalRequests = 1000,
  String url = 'https://httpbin.org/get',
}) async {
  if (kIsWeb) {
    throw UnsupportedError('该测试依赖 dart:io，Web 平台不支持');
  }
  if (totalRequests <= 0) {
    throw ArgumentError.value(totalRequests, 'totalRequests', '必须大于 0');
  }

  final dartNativeResult = await _runDartNativeRequests(
    url: url,
    totalRequests: totalRequests,
  );
  final rustQjsResult = await _runRustQjsRequests(
    url: url,
    totalRequests: totalRequests,
  );

  return BikaNetworkBenchmarkResult(
    url: url,
    totalRequests: totalRequests,
    dartNativeSuccess: dartNativeResult.success,
    dartNativeFailed: dartNativeResult.failed,
    rustQjsSuccess: rustQjsResult.success,
    rustQjsFailed: rustQjsResult.failed,
    dartNativeElapsed: dartNativeResult.elapsed,
    rustQjsElapsed: rustQjsResult.elapsed,
  );
}

Future<BikaNetworkBenchmarkResult> runBikaNativeVsRustBenchmarkConcurrent({
  int totalRequests = 1000,
  int concurrency = 50,
  String url = 'https://httpbin.org/get',
}) async {
  if (kIsWeb) {
    throw UnsupportedError('该测试依赖 dart:io，Web 平台不支持');
  }
  if (totalRequests <= 0) {
    throw ArgumentError.value(totalRequests, 'totalRequests', '必须大于 0');
  }
  if (concurrency <= 0) {
    throw ArgumentError.value(concurrency, 'concurrency', '必须大于 0');
  }

  final dartNativeResult = await _runDartNativeRequestsConcurrent(
    url: url,
    totalRequests: totalRequests,
    concurrency: concurrency,
  );
  final rustQjsResult = await _runRustQjsRequestsConcurrent(
    url: url,
    totalRequests: totalRequests,
    concurrency: concurrency,
  );

  return BikaNetworkBenchmarkResult(
    url: url,
    totalRequests: totalRequests,
    dartNativeSuccess: dartNativeResult.success,
    dartNativeFailed: dartNativeResult.failed,
    rustQjsSuccess: rustQjsResult.success,
    rustQjsFailed: rustQjsResult.failed,
    dartNativeElapsed: dartNativeResult.elapsed,
    rustQjsElapsed: rustQjsResult.elapsed,
  );
}

class _RunResult {
  const _RunResult({
    required this.success,
    required this.failed,
    required this.elapsed,
  });

  final int success;
  final int failed;
  final Duration elapsed;
}

Future<_RunResult> _runDartNativeRequests({
  required String url,
  required int totalRequests,
}) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  var success = 0;
  var failed = 0;
  final sw = Stopwatch()..start();

  try {
    for (var i = 0; i < totalRequests; i++) {
      try {
        final req = await client.getUrl(Uri.parse(url));
        final resp = await req.close();
        await resp.drain<void>();

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          success++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
  } finally {
    sw.stop();
    client.close(force: true);
  }

  return _RunResult(success: success, failed: failed, elapsed: sw.elapsed);
}

Future<_RunResult> _runRustQjsRequests({
  required String url,
  required int totalRequests,
}) async {
  var success = 0;
  var failed = 0;
  final sw = Stopwatch()..start();

  for (var i = 0; i < totalRequests; i++) {
    try {
      final raw = await bikaRequestRaw(url: url, method: 'GET');
      final dynamic decoded = jsonDecode(raw);

      if (_isRustQjsResponseSuccess(decoded)) {
        success++;
      } else {
        failed++;
      }
    } catch (_) {
      failed++;
    }
  }

  sw.stop();
  return _RunResult(success: success, failed: failed, elapsed: sw.elapsed);
}

Future<_RunResult> _runDartNativeRequestsConcurrent({
  required String url,
  required int totalRequests,
  required int concurrency,
}) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  var success = 0;
  var failed = 0;
  var nextIndex = 0;

  final sw = Stopwatch()..start();

  try {
    final workers = List.generate(concurrency, (_) async {
      while (true) {
        final current = nextIndex;
        nextIndex++;
        if (current >= totalRequests) {
          return;
        }

        try {
          final req = await client.getUrl(Uri.parse(url));
          final resp = await req.close();
          await resp.drain<void>();

          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            success++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
    });

    await Future.wait(workers);
  } finally {
    sw.stop();
    client.close(force: true);
  }

  return _RunResult(success: success, failed: failed, elapsed: sw.elapsed);
}

Future<_RunResult> _runRustQjsRequestsConcurrent({
  required String url,
  required int totalRequests,
  required int concurrency,
}) async {
  var success = 0;
  var failed = 0;
  var nextIndex = 0;

  final sw = Stopwatch()..start();

  final workers = List.generate(concurrency, (_) async {
    while (true) {
      final current = nextIndex;
      nextIndex++;
      if (current >= totalRequests) {
        return;
      }

      try {
        final raw = await bikaRequestRaw(url: url, method: 'GET');
        final dynamic decoded = jsonDecode(raw);

        if (_isRustQjsResponseSuccess(decoded)) {
          success++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
  });

  await Future.wait(workers);
  sw.stop();

  return _RunResult(success: success, failed: failed, elapsed: sw.elapsed);
}

bool _isRustQjsResponseSuccess(dynamic decoded) {
  if (decoded is! Map) {
    return false;
  }

  final code = decoded['code'];
  if (code is num) {
    return code >= 200 && code < 300;
  }
  if (code is String) {
    final parsed = int.tryParse(code);
    if (parsed != null) {
      return parsed >= 200 && parsed < 300;
    }
  }

  final message = decoded['message'];
  if (message is String && message.trim().isNotEmpty) {
    return false;
  }

  return true;
}
