import 'dart:async';

import 'package:desktop_webview_linux/src/message_channel.dart';
import 'package:flutter/material.dart';

const _channel = ClientMessageChannel();

/// Runs the title bar.
/// Title bar is a widget that displays the title of the webview window.
/// Returns true if the args match the title bar.
///
/// [builder] custom TitleBar widget builder.
/// Can use [TitleBarWebViewController] to control the WebView.
/// Use [TitleBarWebViewState] to trigger the title bar status.
///
bool runWebViewTitleBarWidget(
  List<String> args, {
  WidgetBuilder? builder,
  Color? backgroundColor,
}) {
  if (args.isEmpty || args[0] != 'web_view_title_bar') {
    return false;
  }
  final int? webViewId = int.tryParse(args[1]);
  if (webViewId == null) {
    return false;
  }
  final int titleBarTopPadding =
      int.tryParse(args.length > 2 ? args[2] : '0') ?? 0;
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    _TitleBarApp(
      webViewId: webViewId,
      titleBarTopPadding: titleBarTopPadding,
      backgroundColor: backgroundColor,
      builder: builder ?? _defaultTitleBar,
    ),
  );
  return true;
}

mixin TitleBarWebViewController {
  static TitleBarWebViewController of(BuildContext context) {
    final _TitleBarAppState? state = context
        .findAncestorStateOfType<_TitleBarAppState>();
    assert(
      state != null,
      'only can find TitleBarWebViewController in widget which run from runWebViewTitleBarWidget',
    );
    return state!;
  }

  int get _webViewId;

  /// navigate back
  void back() {
    unawaited(
      _channel.invokeMethod('onBackPressed', {'webViewId': _webViewId}),
    );
  }

  /// navigate forward
  void forward() {
    unawaited(
      _channel.invokeMethod('onForwardPressed', {'webViewId': _webViewId}),
    );
  }

  /// reload the webview
  void reload() {
    unawaited(
      _channel.invokeMethod('onRefreshPressed', {'webViewId': _webViewId}),
    );
  }

  /// stop loading the webview
  void stop() {
    unawaited(
      _channel.invokeMethod('onStopPressed', {'webViewId': _webViewId}),
    );
  }

  /// close the webview
  void close() {
    unawaited(
      _channel.invokeMethod('onClosePressed', {'webViewId': _webViewId}),
    );
  }
}

class TitleBarWebViewState extends InheritedWidget {
  const TitleBarWebViewState({
    required super.child,
    required this.isLoading,
    required this.canGoBack,
    required this.canGoForward,
    required this.url,
    super.key,
  });

  final bool isLoading;
  final bool canGoBack;
  final bool canGoForward;
  final String? url;

  static TitleBarWebViewState of(BuildContext context) {
    final TitleBarWebViewState? result = context
        .dependOnInheritedWidgetOfExactType<TitleBarWebViewState>();
    assert(result != null, 'No WebViewState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(TitleBarWebViewState oldWidget) {
    return isLoading != oldWidget.isLoading ||
        canGoBack != oldWidget.canGoBack ||
        canGoForward != oldWidget.canGoForward;
  }
}

class _TitleBarApp extends StatefulWidget {
  const _TitleBarApp({
    required this.webViewId,
    required this.titleBarTopPadding,
    required this.builder,
    this.backgroundColor,
  });

  final int webViewId;

  final int titleBarTopPadding;

  final WidgetBuilder builder;

  final Color? backgroundColor;

  @override
  State<_TitleBarApp> createState() => _TitleBarAppState();
}

class _TitleBarAppState extends State<_TitleBarApp>
    with TitleBarWebViewController {
  bool _canGoBack = false;
  bool _canGoForward = false;

  bool _isLoading = false;

  String? _url;

  @override
  int get _webViewId => widget.webViewId;

  @override
  void initState() {
    super.initState();
    _channel.setMessageHandler((call) async {
      final args = Map<String, dynamic>.from(
        call.arguments as Map<Object?, Object?>,
      );
      final webViewId = args['webViewId'] as int;
      if (webViewId != widget.webViewId) {
        return;
      }
      switch (call.method) {
        case 'onHistoryChanged':
          setState(() {
            _canGoBack = args['canGoBack'] as bool;
            _canGoForward = args['canGoForward'] as bool;
          });
        case 'onNavigationStarted':
          setState(() {
            _isLoading = true;
          });
        case 'onNavigationCompleted':
          setState(() {
            _isLoading = false;
          });
        case 'onUrlRequested':
          setState(() {
            _url = args['url'] as String;
          });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color:
            widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: EdgeInsets.only(top: widget.titleBarTopPadding.toDouble()),
          child: TitleBarWebViewState(
            isLoading: _isLoading,
            canGoBack: _canGoBack,
            canGoForward: _canGoForward,
            url: _url,
            child: Builder(builder: widget.builder),
          ),
        ),
      ),
    );
  }
}

Widget _defaultTitleBar(BuildContext context) {
  final TitleBarWebViewState state = TitleBarWebViewState.of(context);
  final TitleBarWebViewController controller = TitleBarWebViewController.of(
    context,
  );
  return Row(
    children: [
      IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 16,
        iconSize: 16,
        onPressed: !state.canGoBack ? null : controller.back,
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 16,
        iconSize: 16,
        onPressed: !state.canGoForward ? null : controller.forward,
        icon: const Icon(Icons.arrow_forward),
      ),
      if (state.isLoading)
        IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 16,
          iconSize: 16,
          onPressed: controller.stop,
          icon: const Icon(Icons.close),
        )
      else
        IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 16,
          iconSize: 16,
          onPressed: controller.reload,
          icon: const Icon(Icons.refresh),
        ),
      const Spacer(),
    ],
  );
}
