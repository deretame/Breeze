// ignore_for_file: avoid_positional_boolean_parameters

import 'package:desktop_webview_linux/src/cookie.dart';
import 'package:flutter/foundation.dart';

/// Handle custom message from JavaScript in your app.
typedef JavaScriptMessageHandler = void Function(String name, dynamic body);

typedef PromptHandler = String Function(String prompt, String defaultText);

typedef OnHistoryChangedCallback =
    void Function(bool canGoBack, bool canGoForward);

/// Callback when WebView start to load a URL.
/// [url] is the URL string.
typedef OnUrlRequestCallback = bool Function(String url);

/// Callback when WebView receives a web message
/// [message] contains the web message.
typedef OnWebMessageReceivedCallback = void Function(String message);

abstract class Webview {
  Future<void> get onClose;

  ///  true if the webview is currently loading a page.
  ValueListenable<bool> get isNavigating;

  /// Install a message handler that you can call from your Javascript code.
  ///
  /// available: macOS (10.10+), Linux
  void registerJavaScriptMessageHandler(
    String name,
    JavaScriptMessageHandler handler,
  );

  /// available: macOS (10.10+), Linux
  void unregisterJavaScriptMessageHandler(String name);

  /// available: macOS
  void setPromptHandler(PromptHandler? handler);

  /// Navigates to the given URL.
  void launch(String url, {bool triggerOnUrlRequestEvent = true});

  /// change webview theme.
  ///
  /// available only: macOS (Brightness.dark only 10.14+)
  void setBrightness(Brightness? brightness);

  void addScriptToExecuteOnDocumentCreated(String javaScript);

  /// Append a string to the webview's user-agent.
  Future<void> setApplicationNameForUserAgent(String applicationName);

  /// Navigate to the previous page in the history.
  Future<void> back();

  /// Navigate to the next page in the history.
  Future<void> forward();

  /// Show or hide webview window
  Future<void> setWebviewWindowVisibility(bool visible);

  /// Move and Resize the webview window
  Future<void> moveWebviewWindow(int left, int top, int width, int height);

  /// Activates the webview window (giving it the focus)
  Future<void> bringToForeground({bool maximized = false});

  /// get position, extents and maximization info of the webview window
  Future<Map<Object?, Object?>?> getPositionalParameters();

  /// Reload the current page.
  Future<void> reload();

  /// Stop all navigations and pending resource fetches.
  Future<void> stop();

  /// Opens the Browser DevTools in a separate window
  Future<void> openDevToolsWindow();

  /// Register a callback that will be invoked when the webview history changes.
  void setOnHistoryChangedCallback(OnHistoryChangedCallback? callback);

  void setOnUrlRequestCallback(OnUrlRequestCallback? callback);

  void addOnWebMessageReceivedCallback(OnWebMessageReceivedCallback callback);

  void removeOnWebMessageReceivedCallback(
    OnWebMessageReceivedCallback callback,
  );

  void removeAllWebMessageReceivedCallback();

  /// Close the web view window.
  void close();

  /// evaluate JavaScript in the web view.
  Future<String?> evaluateJavaScript(String javaScript);

  /// post a web message as String to the top level document in this WebView
  Future<void> postWebMessageAsString(String webMessage);

  /// post a web message as JSON to the top level document in this WebView
  Future<void> postWebMessageAsJson(String webMessage);

  Future<List<WebviewCookie>> getAllCookies({bool allDomains = false});
}
