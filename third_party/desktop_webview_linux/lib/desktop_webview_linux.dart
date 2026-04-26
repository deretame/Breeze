import 'dart:async';
import 'dart:developer' show log;

import 'package:desktop_webview_linux/src/create_configuration.dart';
import 'package:desktop_webview_linux/src/message_channel.dart';
import 'package:desktop_webview_linux/src/webview.dart';
import 'package:desktop_webview_linux/src/webview_impl.dart';
import 'package:flutter/services.dart';

export 'src/create_configuration.dart';
export 'src/title_bar.dart';
export 'src/webview.dart';

final List<WebviewImpl> _webviews = [];

class WebviewWindow {
  static const MethodChannel _channel = MethodChannel(
    'desktop_webview_linux.webview_window',
  );

  static const _otherIsolateMessageHandler = ClientMessageChannel();

  static bool _initialized = false;

  static void _init() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      try {
        return await _handleMethodCall(call);
      } on Object catch (e, s) {
        log(
          'method: ${call.method} args: ${call.arguments}',
          name: 'desktop_webview_linux',
        );
        log(
          'handleMethodCall error',
          name: 'desktop_webview_linux',
          error: e,
          stackTrace: s,
        );
      }
    });
    _otherIsolateMessageHandler.setMessageHandler((call) async {
      try {
        return await _handleOtherIsolateMethodCall(call);
      } on Object catch (e, s) {
        log(
          '_handleOtherIsolateMethodCall error',
          name: 'desktop_webview_linux',
          error: e,
          stackTrace: s,
        );
      }
    });
  }

  /// Check if WebView runtime is available on the current devices.
  static Future<bool> isWebviewAvailable() async => true;

  static Future<Webview> create({CreateConfiguration? configuration}) async {
    configuration ??= CreateConfiguration.platform();
    _init();
    final viewId =
        await _channel.invokeMethod('create', configuration.toMap()) as int;
    final webview = WebviewImpl(viewId, _channel);
    _webviews.add(webview);
    return webview;
  }

  static Future<dynamic> _handleOtherIsolateMethodCall(MethodCall call) async {
    final args = Map<String, dynamic>.from(
      call.arguments as Map<Object?, Object?>,
    );
    final webViewId = args['webViewId'] as int;
    final WebviewImpl? webView = _webviews.cast<WebviewImpl?>().firstWhere(
      (w) => w?.viewId == webViewId,
      orElse: () => null,
    );
    if (webView == null) {
      return;
    }
    switch (call.method) {
      case 'onBackPressed':
        await webView.back();
      case 'onForwardPressed':
        await webView.forward();
      case 'onRefreshPressed':
        await webView.reload();
      case 'onStopPressed':
        await webView.stop();
      case 'onClosePressed':
        webView.close();
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    final args = Map<String, dynamic>.from(
      call.arguments as Map<Object?, Object?>,
    );
    final viewId = args['id'] as int;
    final WebviewImpl? webview = _webviews.cast<WebviewImpl?>().firstWhere(
      (e) => e?.viewId == viewId,
      orElse: () => null,
    );
    assert(webview != null);
    if (webview == null) {
      return;
    }
    switch (call.method) {
      case 'onWindowClose':
        _webviews.remove(webview);
        webview.onClosed();
      case 'onJavaScriptMessage':
        webview.onJavaScriptMessage(args['name'] as String, args['body']);
      case 'runJavaScriptTextInputPanelWithPrompt':
        return webview.onRunJavaScriptTextInputPanelWithPrompt(
          args['prompt'] as String,
          args['defaultText'] as String,
        );
      case 'onHistoryChanged':
        webview.onHistoryChanged(
          canGoBack: args['canGoBack'] as bool,
          canGoForward: args['canGoForward'] as bool,
        );
        await _otherIsolateMessageHandler.invokeMethod('onHistoryChanged', {
          'webViewId': viewId,
          'canGoBack': args['canGoBack'] as bool,
          'canGoForward': args['canGoForward'] as bool,
        });
      case 'onNavigationStarted':
        webview.onNavigationStarted();
        await _otherIsolateMessageHandler.invokeMethod('onNavigationStarted', {
          'webViewId': viewId,
        });
      case 'onUrlRequested':
        final url = args['url'] as String;
        final bool ret = webview.notifyUrlChanged(url);
        await _otherIsolateMessageHandler.invokeMethod('onUrlRequested', {
          'webViewId': viewId,
          'url': url,
        });
        return ret;
      case 'onWebMessageReceived':
        final message = args['message'] as String;
        webview.notifyWebMessageReceived(message);
        await _otherIsolateMessageHandler.invokeMethod('onWebMessageReceived', {
          'webViewId': viewId,
          'message': message,
        });
      case 'onNavigationCompleted':
        webview.onNavigationCompleted();
        await _otherIsolateMessageHandler.invokeMethod(
          'onNavigationCompleted',
          {'webViewId': viewId},
        );
      default:
        return;
    }
  }

  /// Clear all cookies and storage.
  static Future<void> clearAll({
    String userDataFolderWindows = 'webview_window_WebView2',
  }) async {
    await _channel.invokeMethod('clearAll');
  }
}
