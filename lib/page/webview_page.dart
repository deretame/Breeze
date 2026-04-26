import 'dart:async';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:desktop_webview_linux/desktop_webview_linux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/event/webview_observe_bus.dart';

@RoutePage()
class WebViewPage extends StatefulWidget {
  final List<String> info;

  const WebViewPage({super.key, required this.info});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const Set<String> _inAppSchemes = {
    'about',
    'data',
    'file',
    'http',
    'https',
    'javascript',
  };

  Webview? _linuxWebview;
  bool _isWebviewClosed = false;

  InAppWebViewController? _controller;
  int _progress = 0;
  String? _mainFrameError;
  String? _lastObservedUrl;

  String get _title => widget.info.isNotEmpty ? widget.info[0] : '网页';

  String get _url => widget.info.length > 1 ? widget.info[1].trim() : '';

  Uri? get _uri {
    if (_url.isEmpty) {
      return null;
    }
    return Uri.tryParse(_url);
  }

  bool get _isValidUrl {
    final uri = _uri;
    if (uri == null) {
      return false;
    }
    return uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux && _isValidUrl) {
      _openLinuxWebView();
    }
  }

  Future<void> _openLinuxWebView() async {
    final url = _url;
    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(title: _title, titleBarHeight: 0),
    );

    webview.setOnUrlRequestCallback((nextUrl) {
      unawaited(
        _reportUrlChangeAndCookies(nextUrl, trigger: 'linux_url_request'),
      );
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 800), () async {
          await _reportUrlChangeAndCookies(
            nextUrl,
            trigger: 'linux_url_settled',
            force: true,
          );
        }),
      );
      return true;
    });

    _linuxWebview = webview;
    webview.launch(url);
    unawaited(
      _reportUrlChangeAndCookies(url, trigger: 'linux_launch', force: true),
    );

    webview.onClose.then((_) {
      if (mounted) {
        setState(() => _isWebviewClosed = true);
      }
    });
  }

  @override
  void dispose() {
    if (Platform.isLinux && !_isWebviewClosed && _linuxWebview != null) {
      _linuxWebview!.close();
    }
    super.dispose();
  }

  Future<void> _openExternal(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开链接: $uri')));
    }
  }

  Future<void> _openExternalFromRaw(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    await _openExternal(uri);
  }

  String get _platformTag => Platform.isLinux ? 'linux' : 'inappwebview';

  Future<void> _reportUrlChangeAndCookies(
    String? rawUrl, {
    required String trigger,
    bool force = false,
    int? statusCode,
    String? errorDescription,
  }) async {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      return;
    }
    if (!force && _lastObservedUrl == url) {
      return;
    }
    _lastObservedUrl = url;

    final cookies = await _collectAllCookieSnapshots(url);
    final event = WebViewObserveEvent(
      url: url,
      trigger: trigger,
      platform: _platformTag,
      observedAt: DateTime.now(),
      cookies: cookies,
      statusCode: statusCode,
      errorDescription: errorDescription,
    );
    WebViewObserveBus.emit(event);
    debugPrint(
      '[WebViewObserve] platform=${event.platform} trigger=${event.trigger} '
      'url=${event.url} cookies=${event.cookies.length}',
    );
  }

  Future<List<WebViewCookieSnapshot>> _collectAllCookieSnapshots(
    String currentUrl,
  ) async {
    if (Platform.isLinux) {
      final webview = _linuxWebview;
      if (webview == null) {
        return const [];
      }
      try {
        final cookies = await webview.getAllCookies(allDomains: true);
        return cookies
            .map(
              (cookie) => WebViewCookieSnapshot(
                name: cookie.name,
                value: cookie.value,
                domain: cookie.domain,
                path: cookie.path,
                expiresDate: cookie.expires?.millisecondsSinceEpoch,
                isSecure: cookie.secure,
                isHttpOnly: cookie.httpOnly,
                isSessionOnly: cookie.sessionOnly,
              ),
            )
            .toList(growable: false);
      } catch (e) {
        debugPrint('[WebViewObserve] linux getAllCookies failed: $e');
        return const [];
      }
    }

    return _collectMobileCookies(currentUrl);
  }

  Future<List<WebViewCookieSnapshot>> _collectMobileCookies(
    String currentUrl,
  ) async {
    final manager = CookieManager.instance();
    try {
      final cookies = await manager.getAllCookies();
      if (cookies.isNotEmpty) {
        return cookies
            .map(
              (cookie) => WebViewCookieSnapshot(
                name: cookie.name,
                value: '${cookie.value ?? ''}',
                domain: cookie.domain,
                path: cookie.path,
                expiresDate: cookie.expiresDate,
                isSecure: cookie.isSecure,
                isHttpOnly: cookie.isHttpOnly,
                isSessionOnly: cookie.isSessionOnly,
              ),
            )
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('[WebViewObserve] getAllCookies failed: $e');
    }

    final uri = Uri.tryParse(currentUrl);
    if (uri == null || !uri.hasScheme) {
      return const [];
    }

    try {
      final cookies = await manager.getCookies(
        url: WebUri(uri.toString()),
        webViewController: _controller,
      );
      return cookies
          .map(
            (cookie) => WebViewCookieSnapshot(
              name: cookie.name,
              value: '${cookie.value ?? ''}',
              domain: cookie.domain,
              path: cookie.path,
              expiresDate: cookie.expiresDate,
              isSecure: cookie.isSecure,
              isHttpOnly: cookie.isHttpOnly,
              isSessionOnly: cookie.isSessionOnly,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      debugPrint('[WebViewObserve] getCookies(url) failed: $e');
      return const [];
    }
  }

  Widget _buildInvalidUrlView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 44, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('链接无效，无法打开网页'),
            const SizedBox(height: 8),
            Text(
              _url.isEmpty ? '(空链接)' : _url,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFrameError(BuildContext context) {
    final uri = _uri;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.orange),
            const SizedBox(height: 12),
            Text(_mainFrameError ?? '网页加载失败'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _mainFrameError = null;
                      _progress = 0;
                    });
                    _controller?.reload();
                  },
                  child: const Text('重试'),
                ),
                if (uri != null)
                  FilledButton.tonalIcon(
                    onPressed: () => _openExternal(uri),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('外部浏览器打开'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinuxBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isWebviewClosed ? Icons.check_circle_outline : Icons.open_in_new,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _isWebviewClosed ? 'WebView 窗口已关闭' : '网页已在独立窗口中打开',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _url,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (_isWebviewClosed) ...[
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    if (!_isValidUrl) {
      return _buildInvalidUrlView(context);
    }

    if (_mainFrameError != null) {
      return _buildMainFrameError(context);
    }

    final webUri = WebUri(_url);

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: webUri),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            isInspectable: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            cacheEnabled: true,
            transparentBackground: false,
            mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
            // Android 15/16 + 部分机型使用 Hybrid Composition 可能出现白屏。
            useHybridComposition: false,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          onLoadStart: (_, url) {
            if (mounted) {
              setState(() {
                _mainFrameError = null;
              });
            }
            unawaited(
              _reportUrlChangeAndCookies(
                url?.toString(),
                trigger: 'load_start',
              ),
            );
          },
          onLoadStop: (_, url) {
            unawaited(
              _reportUrlChangeAndCookies(
                url?.toString(),
                trigger: 'load_stop',
                force: true,
              ),
            );
          },
          onUpdateVisitedHistory: (_, url, _) {
            unawaited(
              _reportUrlChangeAndCookies(
                url?.toString(),
                trigger: 'history_changed',
              ),
            );
          },
          onProgressChanged: (_, progress) {
            if (mounted) {
              setState(() {
                _progress = progress.clamp(0, 100).toInt();
              });
            }
          },
          shouldOverrideUrlLoading: (_, navigationAction) async {
            final uri = navigationAction.request.url;
            if (uri == null) {
              return NavigationActionPolicy.ALLOW;
            }
            if (!_inAppSchemes.contains(uri.scheme)) {
              await _openExternalFromRaw(uri.toString());
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onReceivedError: (_, request, error) {
            if (request.isForMainFrame != true) {
              return;
            }
            unawaited(
              _reportUrlChangeAndCookies(
                request.url.toString(),
                trigger: 'load_error',
                force: true,
                errorDescription: '${error.type}: ${error.description}',
              ),
            );
            if (mounted) {
              setState(() {
                _mainFrameError = '加载失败（${error.type} / ${error.description}）';
              });
            }
          },
          onReceivedHttpError: (_, request, response) {
            if (request.isForMainFrame != true) {
              return;
            }
            unawaited(
              _reportUrlChangeAndCookies(
                request.url.toString(),
                trigger: 'http_error',
                force: true,
                statusCode: response.statusCode,
                errorDescription: response.reasonPhrase,
              ),
            );
            if (mounted) {
              setState(() {
                _mainFrameError = '服务器返回异常状态码：${response.statusCode}';
              });
            }
          },
        ),
        if (_progress < 100)
          Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(value: _progress / 100),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = _uri;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          if (Platform.isLinux && !_isWebviewClosed)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '关闭 WebView 窗口',
              onPressed: () {
                _linuxWebview?.close();
                if (mounted) {
                  setState(() => _isWebviewClosed = true);
                }
              },
            ),
          if (uri != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => _openExternal(uri),
            ),
        ],
      ),
      body: Platform.isLinux
          ? _buildLinuxBody(context)
          : _buildMobileBody(context),
    );
  }
}
