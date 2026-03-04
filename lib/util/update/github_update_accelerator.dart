import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String _proxySourceUrl =
    'https://ghproxy.link/js/src_views_home_HomeView_vue.js';

const Duration _networkTimeout = Duration(seconds: 12);

class GithubUpdateAccelerator {
  GithubUpdateAccelerator._();

  static GithubUpdateAccelerationSession createSession({
    required bool enabled,
  }) {
    return GithubUpdateAccelerationSession(enabled: enabled);
  }

  static Future<String?> resolveAvailableProxyDomain() async {
    final client = Dio(
      BaseOptions(
        connectTimeout: _networkTimeout,
        receiveTimeout: _networkTimeout,
      ),
    );

    final response = await client.get<String>(
      _proxySourceUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final source = response.data;
    if (source == null || source.isEmpty) {
      return null;
    }

    final markerIndex = source.indexOf('当前可用');
    final escapedMarkerIndex = source.indexOf(r'\u5f53\u524d\u53ef\u7528');
    final targetIndex = markerIndex >= 0 ? markerIndex : escapedMarkerIndex;
    if (targetIndex < 0) {
      return null;
    }

    final contextStart = (targetIndex - 2000).clamp(0, targetIndex);
    final context = source.substring(contextStart, targetIndex);
    final domainMatcher = RegExp(r'https?://[a-zA-Z0-9.-]+(?::\d+)?');
    final domains = domainMatcher.allMatches(context);
    if (domains.isEmpty) {
      return null;
    }

    return domains.last.group(0);
  }

  static Future<bool> isProxyReachable(String proxyDomain) async {
    final normalized = proxyDomain.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      return false;
    }

    final client = Dio(
      BaseOptions(
        connectTimeout: _networkTimeout,
        receiveTimeout: _networkTimeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final response = await client.get<String>(
      normalized,
      options: Options(responseType: ResponseType.plain),
    );

    return (response.statusCode ?? 500) < 500;
  }

  static bool isGithubUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }

    final host = uri.host.toLowerCase();
    return host == 'github.com' ||
        host == 'www.github.com' ||
        host.endsWith('.github.com') ||
        host.endsWith('githubusercontent.com');
  }

  static String accelerateUrl(String proxyDomain, String originalUrl) {
    final normalizedProxy = proxyDomain.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalizedProxy.isEmpty) {
      return originalUrl;
    }

    return '$normalizedProxy/${originalUrl.trim().replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String replaceGithubLinksInMarkdown(
    String markdown,
    String proxyDomain,
  ) {
    final urlPattern = RegExp(r'https?://[^\s\]\)\}>"]+');
    return markdown.replaceAllMapped(urlPattern, (match) {
      final url = match.group(0)!;
      if (!isGithubUrl(url)) {
        return url;
      }
      return accelerateUrl(proxyDomain, url);
    });
  }

  static Future<String> createGithubUserAgent() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    final version = packageInfo.version;

    final deviceInfo = DeviceInfoPlugin();
    final systemName = Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
        ? 'iOS'
        : Platform.operatingSystem;
    String systemVersion = Platform.operatingSystemVersion;
    String model = 'Unknown';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      systemVersion = androidInfo.version.release;
      model = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      systemVersion = iosInfo.systemVersion;
      model = iosInfo.utsname.machine;
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      model = windowsInfo.computerName;
    } else if (Platform.isMacOS) {
      final macOsInfo = await deviceInfo.macOsInfo;
      model = macOsInfo.model;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      model = linuxInfo.prettyName;
    }

    return '$appName/$version ($systemName $systemVersion; $model)';
  }
}

class GithubUpdateAccelerationSession {
  GithubUpdateAccelerationSession({required this.enabled});

  final bool enabled;
  String? _proxyDomain;
  bool _prepared = false;

  bool get isActive => _proxyDomain != null;

  Future<void> prepare() async {
    if (_prepared) {
      return;
    }
    _prepared = true;

    if (!enabled) {
      return;
    }

    final resolved =
        await GithubUpdateAccelerator.resolveAvailableProxyDomain();
    if (resolved == null) {
      return;
    }

    if (await GithubUpdateAccelerator.isProxyReachable(resolved)) {
      _proxyDomain = resolved;
    }
  }

  List<String> requestCandidates(String url) {
    final accelerated = accelerateIfGithub(url);
    if (accelerated == url) {
      return <String>[url];
    }
    return <String>[accelerated, url];
  }

  String accelerateIfGithub(String url) {
    if (_proxyDomain == null) {
      return url;
    }
    if (!GithubUpdateAccelerator.isGithubUrl(url)) {
      return url;
    }
    return GithubUpdateAccelerator.accelerateUrl(_proxyDomain!, url);
  }

  String accelerateMarkdown(String markdown) {
    if (_proxyDomain == null) {
      return markdown;
    }
    return GithubUpdateAccelerator.replaceGithubLinksInMarkdown(
      markdown,
      _proxyDomain!,
    );
  }
}
