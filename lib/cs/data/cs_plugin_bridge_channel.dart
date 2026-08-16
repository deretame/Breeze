import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:zephyr/plugin/bridge/dart_tools_bridge.dart';

/// Exposes the Flutter-only plugin callbacks to a CS server runtime.
///
/// The server sends `bridge.request` messages after a plugin calls one of the
/// registered Dart bridge functions. Keeping this protocol outside the HTTP
/// client also lets a future browser client implement the same callbacks.
class CsPluginBridgeChannel {
  WebSocket? _socket;
  StreamSubscription<Object?>? _subscription;

  Future<void> connect({
    required String serverUrl,
    required String accessToken,
  }) async {
    await close();
    try {
      final uri = _webSocketUri(serverUrl, accessToken);
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      socket.pingInterval = const Duration(seconds: 20);
      _socket = socket;
      _subscription = socket.listen(
        (message) => unawaited(_handleMessage(socket, message)),
        onError: (_, _) {},
        onDone: () {
          if (identical(_socket, socket)) {
            _socket = null;
          }
        },
        cancelOnError: false,
      );
    } on Object {
      // CS HTTP requests remain usable if the optional callback channel is
      // temporarily unavailable. The next settings update reconnects it.
      _socket = null;
    }
  }

  Future<void> close() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();

    final socket = _socket;
    _socket = null;
    await socket?.close(WebSocketStatus.normalClosure, 'CS bridge closed');
  }

  Future<void> _handleMessage(WebSocket socket, Object? message) async {
    if (message is! String) return;

    Map<String, dynamic> request;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) return;
      request = Map<String, dynamic>.from(decoded);
    } on Object {
      return;
    }
    if (request['type'] != 'bridge.request') return;

    final requestId = request['requestId'] ?? request['id'];
    final method = request['method'];
    final rawArgs = request['args'];
    if (requestId is! String || method is! String || rawArgs is! List) {
      return;
    }

    try {
      final argsJson = jsonEncode(rawArgs);
      final result = switch (method) {
        'dart.getAppVersion' => await getDartAppVersionPayload(),
        'dart.getLocaleInfo' => await getDartLocaleInfoPayload(),
        'flutter.showToast' => await handleFlutterShowToastPayload(argsJson),
        _ => throw UnsupportedError('Unsupported CS bridge method: $method'),
      };
      _send(socket, {
        'type': 'bridge.response',
        'requestId': requestId,
        'ok': true,
        'result': result,
      });
    } on Object catch (error) {
      _send(socket, {
        'type': 'bridge.response',
        'requestId': requestId,
        'ok': false,
        'error': error.toString(),
      });
    }
  }

  void _send(WebSocket socket, Map<String, dynamic> message) {
    if (identical(_socket, socket)) {
      socket.add(jsonEncode(message));
    }
  }

  Uri _webSocketUri(String serverUrl, String accessToken) {
    final base = Uri.parse(serverUrl.trim());
    final scheme = switch (base.scheme.toLowerCase()) {
      'https' => 'wss',
      _ => 'ws',
    };
    return base.replace(
      scheme: scheme,
      path: '/api/v1/ws',
      queryParameters: {'access_token': accessToken},
    );
  }
}
