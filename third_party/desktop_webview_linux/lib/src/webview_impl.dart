import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_linux/src/cookie.dart';
import 'package:desktop_webview_linux/src/webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WebviewImpl extends Webview {
  WebviewImpl(this.viewId, this.channel);

  final int viewId;

  final MethodChannel channel;

  final Map<String, JavaScriptMessageHandler> _javaScriptMessageHandlers = {};

  bool _closed = false;

  PromptHandler? _promptHandler;

  final _closeCompleter = Completer<void>();

  OnHistoryChangedCallback? _onHistoryChanged;

  final ValueNotifier<bool> _isNavigating = ValueNotifier<bool>(false);

  OnUrlRequestCallback? _onUrlRequestCallback;

  final Set<OnWebMessageReceivedCallback> _onWebMessageReceivedCallbacks = {};

  @override
  Future<void> get onClose => _closeCompleter.future;

  void onClosed() {
    _closed = true;
    _closeCompleter.complete();
  }

  void onJavaScriptMessage(String name, dynamic body) {
    assert(!_closed);
    final JavaScriptMessageHandler? handler = _javaScriptMessageHandlers[name];
    assert(handler != null, 'handler $name is not registered.');
    handler?.call(name, body);
  }

  String onRunJavaScriptTextInputPanelWithPrompt(
    String prompt,
    String defaultText,
  ) {
    assert(!_closed);
    return _promptHandler?.call(prompt, defaultText) ?? defaultText;
  }

  void onHistoryChanged({required bool canGoBack, required bool canGoForward}) {
    assert(!_closed);
    _onHistoryChanged?.call(canGoBack, canGoForward);
  }

  void onNavigationStarted() {
    _isNavigating.value = true;
  }

  bool notifyUrlChanged(String url) {
    if (_onUrlRequestCallback != null) {
      return _onUrlRequestCallback!(url);
    } else {
      return true;
    }
  }

  void notifyWebMessageReceived(String message) {
    for (final OnWebMessageReceivedCallback callback
        in _onWebMessageReceivedCallbacks) {
      callback(message);
    }
  }

  void onNavigationCompleted() {
    _isNavigating.value = false;
  }

  @override
  ValueListenable<bool> get isNavigating => _isNavigating;

  @override
  void registerJavaScriptMessageHandler(
    String name,
    JavaScriptMessageHandler handler,
  ) {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    assert(!_closed);
    if (_closed) {
      return;
    }
    assert(name.isNotEmpty);
    assert(!_javaScriptMessageHandlers.containsKey(name));
    _javaScriptMessageHandlers[name] = handler;
    unawaited(
      channel.invokeMethod('registerJavaScriptInterface', {
        'viewId': viewId,
        'name': name,
      }),
    );
  }

  @override
  void unregisterJavaScriptMessageHandler(String name) {
    if (!Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    if (_closed) {
      return;
    }
    unawaited(
      channel.invokeMethod('unregisterJavaScriptInterface', {
        'viewId': viewId,
        'name': name,
      }),
    );
  }

  @override
  void setPromptHandler(PromptHandler? handler) {
    if (!Platform.isMacOS) {
      return;
    }
    _promptHandler = handler;
  }

  @override
  Future<void> launch(
    String url, {
    bool triggerOnUrlRequestEvent = true,
  }) async {
    await channel.invokeMethod('launch', {
      'url': url,
      'viewId': viewId,
      'triggerOnUrlRequestEvent': triggerOnUrlRequestEvent,
    });
  }

  @override
  void setBrightness(Brightness? brightness) {
    /// -1 : system default
    /// 0 : dark
    /// 1 : light
    if (!Platform.isMacOS) {
      return;
    }
    unawaited(
      channel.invokeMethod('setBrightness', {
        'viewId': viewId,
        'brightness': brightness?.index ?? -1,
      }),
    );
  }

  @override
  void addScriptToExecuteOnDocumentCreated(String javaScript) {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    assert(javaScript.trim().isNotEmpty);
    unawaited(
      channel.invokeMethod('addScriptToExecuteOnDocumentCreated', {
        'viewId': viewId,
        'javaScript': javaScript,
      }),
    );
  }

  @override
  Future<void> setApplicationNameForUserAgent(String applicationName) async {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return;
    }
    await channel.invokeMethod('setApplicationNameForUserAgent', {
      'viewId': viewId,
      'applicationName': applicationName,
    });
  }

  @override
  Future<void> forward() {
    return channel.invokeMethod('forward', {'viewId': viewId});
  }

  @override
  Future<void> setWebviewWindowVisibility(bool visible) {
    return channel.invokeMethod('setWebviewWindowVisibility', {
      'viewId': viewId,
      'visible': visible,
    });
  }

  @override
  Future<void> moveWebviewWindow(int left, int top, int width, int height) {
    return channel.invokeMethod('moveWebviewWindow', {
      'viewId': viewId,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    });
  }

  @override
  Future<void> bringToForeground({bool maximized = false}) {
    return channel.invokeMethod('bringToForeground', {
      'viewId': viewId,
      'maximized': maximized,
    });
  }

  @override
  Future<Map<Object?, Object?>?> getPositionalParameters() {
    return channel.invokeMapMethod<Object?, Object?>(
      'getPositionalParameters',
      {'viewId': viewId},
    );
  }

  @override
  Future<void> back() {
    return channel.invokeMethod('back', {'viewId': viewId});
  }

  @override
  Future<void> reload() {
    return channel.invokeMethod('reload', {'viewId': viewId});
  }

  @override
  Future<void> stop() {
    return channel.invokeMethod('stop', {'viewId': viewId});
  }

  @override
  Future<void> openDevToolsWindow() {
    return channel.invokeMethod('openDevToolsWindow', {'viewId': viewId});
  }

  @override
  void setOnHistoryChangedCallback(OnHistoryChangedCallback? callback) {
    _onHistoryChanged = callback;
  }

  @override
  void setOnUrlRequestCallback(OnUrlRequestCallback? callback) {
    _onUrlRequestCallback = callback;
  }

  @override
  void addOnWebMessageReceivedCallback(OnWebMessageReceivedCallback callback) {
    _onWebMessageReceivedCallbacks.add(callback);
  }

  @override
  void removeOnWebMessageReceivedCallback(
    OnWebMessageReceivedCallback callback,
  ) {
    _onWebMessageReceivedCallbacks.remove(callback);
  }

  @override
  void removeAllWebMessageReceivedCallback() {
    _onWebMessageReceivedCallbacks.clear();
  }

  @override
  void close() {
    if (_closed) {
      return;
    }
    unawaited(channel.invokeMethod('close', {'viewId': viewId}));
  }

  @override
  Future<String?> evaluateJavaScript(String javaScript) async {
    final dynamic result = await channel.invokeMethod('evaluateJavaScript', {
      'viewId': viewId,
      'javaScriptString': javaScript,
    });
    if (result == null) {
      return null;
    }
    if (result is String) {
      return result;
    }
    return json.encode(result);
  }

  @override
  Future<void> postWebMessageAsString(String webMessage) async {
    return channel.invokeMethod('postWebMessageAsString', {
      'viewId': viewId,
      'webMessage': webMessage,
    });
  }

  @override
  Future<void> postWebMessageAsJson(String webMessage) async {
    return channel.invokeMethod('postWebMessageAsJson', {
      'viewId': viewId,
      'webMessage': webMessage,
    });
  }

  @override
  Future<List<WebviewCookie>> getAllCookies({bool allDomains = false}) async {
    final List<Map<Object?, Object?>>? result = await channel
        .invokeListMethod<Map<Object?, Object?>>('getAllCookies', {
          'viewId': viewId,
          'allDomains': allDomains,
        });

    return result
            ?.map((e) => WebviewCookie.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
  }
}
