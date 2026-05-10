import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class PluginWebLoginFlowConfig {
  const PluginWebLoginFlowConfig({
    required this.openTitle,
    required this.openUrl,
    required this.openUri,
    required this.redirectWatchUrl,
    required this.redirectWatchUri,
    required this.setCookieFnPath,
    required this.cookiePollIntervalMs,
    required this.ignoreCookieNames,
  });

  final String openTitle;
  final String openUrl;
  final Uri openUri;
  final String redirectWatchUrl;
  final Uri? redirectWatchUri;
  final String setCookieFnPath;
  final int cookiePollIntervalMs;
  final Set<String> ignoreCookieNames;
}

class ExternalChromiumLoginSession {
  ExternalChromiumLoginSession._({
    required this.browserName,
    required this.browserExecutable,
    required this.useHostSpawn,
    required this.debugPort,
    required this.openUrl,
  });

  static const String chromeDownloadUrl = 'https://www.google.com/chrome/';
  static const List<String> _linuxCandidates = <String>[
    'google-chrome',
    'microsoft-edge',
    'brave-browser',
    'chromium',
    'chromium-browser',
  ];
  static const List<String> _windowsCandidates = <String>[
    'chrome.exe',
    'brave.exe',
    'msedge.exe',
    'chromium.exe',
  ];
  static const List<WindowsPathCandidate>
  _windowsPathCandidates = <WindowsPathCandidate>[
    WindowsPathCandidate(
      name: 'Google Chrome',
      relativePath: <String>['Google', 'Chrome', 'Application', 'chrome.exe'],
    ),
    WindowsPathCandidate(
      name: 'Brave',
      relativePath: <String>[
        'BraveSoftware',
        'Brave-Browser',
        'Application',
        'brave.exe',
      ],
    ),
    WindowsPathCandidate(
      name: 'Microsoft Edge',
      relativePath: <String>['Microsoft', 'Edge', 'Application', 'msedge.exe'],
    ),
    WindowsPathCandidate(
      name: 'Chromium',
      relativePath: <String>['Chromium', 'Application', 'chrome.exe'],
    ),
  ];
  static const List<String> _macCandidates = <String>[
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];

  final String browserName;
  final String browserExecutable;
  final bool useHostSpawn;
  final int debugPort;
  final String openUrl;

  static bool get _isFlatpakLinux {
    if (!Platform.isLinux) {
      return false;
    }
    final flatpakId = Platform.environment['FLATPAK_ID'] ?? '';
    return flatpakId.trim().isNotEmpty;
  }

  static Future<ExternalChromiumLoginSession?> start({
    required String openUrl,
  }) async {
    debugPrint('[WebLoginFallback] start requested url=$openUrl');
    final browser = await _detectBrowser();
    if (browser == null) {
      debugPrint('[WebLoginFallback] no chromium browser detected');
      return null;
    }
    debugPrint(
      '[WebLoginFallback] browser detected: ${browser.name} -> ${browser.executable}',
    );
    final debugPort = await _allocateFreePort();
    final userDataDir = await _resolveUserDataDir(
      debugPort,
      browser.useHostSpawn,
    );
    final args = <String>[
      '--remote-debugging-port=$debugPort',
      '--new-window',
      '--no-first-run',
      '--no-default-browser-check',
      '--user-data-dir=$userDataDir',
      openUrl,
    ];

    final started = await _startProcess(
      executable: browser.executable,
      args: args,
      useHostSpawn: browser.useHostSpawn,
    );
    if (!started) {
      debugPrint(
        '[WebLoginFallback] failed to start browser: ${browser.executable}',
      );
      return null;
    }
    debugPrint('[WebLoginFallback] browser launched, debugPort=$debugPort');
    return ExternalChromiumLoginSession._(
      browserName: browser.name,
      browserExecutable: browser.executable,
      useHostSpawn: browser.useHostSpawn,
      debugPort: debugPort,
      openUrl: openUrl,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCookies() async {
    final wsUrl = await _fetchBrowserWsUrl(debugPort);
    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint(
        '[WebLoginFallback] cdp ws endpoint unavailable on port=$debugPort',
      );
      return const [];
    }
    try {
      final ws = await WebSocket.connect(wsUrl);
      ws.add(jsonEncode({'id': 1, 'method': 'Storage.getCookies'}));
      final completer = Completer<List<Map<String, dynamic>>>();
      final timeout = Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(const <Map<String, dynamic>>[]);
        }
      });

      ws.listen(
        (event) {
          if (completer.isCompleted) {
            return;
          }
          final map = _safeDecodeMap(event);
          if (map == null || map['id'] != 1) {
            return;
          }
          final result = _asMap(map['result']);
          final rawCookies = _asList(result['cookies']);
          final cookies = rawCookies.map(_asMap).toList(growable: false);
          completer.complete(cookies);
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(const <Map<String, dynamic>>[]);
          }
        },
      );

      final cookies = await completer.future;
      timeout.cancel();
      unawaited(ws.close());
      return cookies;
    } catch (e) {
      debugPrint('[WebLoginFallback] fetchCookies websocket failed: $e');
      return const [];
    }
  }

  Future<List<String>> fetchOpenPageUrls() async {
    final uri = Uri.parse('http://127.0.0.1:$debugPort/json/list');
    final data = await _fetchJsonList(uri);
    return data
        .map(_asMap)
        .map((item) => item['url']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  static Future<BrowserCandidate?> _detectBrowser() async {
    if (Platform.isWindows) {
      final resolvedFromPath = await _detectWindowsBrowserFromKnownPaths();
      if (resolvedFromPath != null) {
        debugPrint(
          '[WebLoginFallback] browser from known paths: ${resolvedFromPath.executable}',
        );
        return resolvedFromPath;
      }
      final resolvedFromRegistry = await _detectWindowsBrowserFromRegistry();
      if (resolvedFromRegistry != null) {
        debugPrint(
          '[WebLoginFallback] browser from registry: ${resolvedFromRegistry.executable}',
        );
        return resolvedFromRegistry;
      }
      for (final candidate in _windowsCandidates) {
        final resolved = await _which(candidate, useHostSpawn: false);
        if (resolved != null && resolved.isNotEmpty) {
          debugPrint('[WebLoginFallback] browser from PATH: $resolved');
          return BrowserCandidate(name: candidate, executable: resolved);
        }
      }
      return null;
    }

    if (Platform.isMacOS) {
      for (final candidate in _macCandidates) {
        if (await File(candidate).exists()) {
          return BrowserCandidate(
            name: _basename(candidate),
            executable: candidate,
          );
        }
      }
      for (final candidate in <String>[
        'google-chrome',
        'microsoft-edge',
        'chromium',
        'brave',
      ]) {
        final resolved = await _which(candidate, useHostSpawn: false);
        if (resolved != null && resolved.isNotEmpty) {
          return BrowserCandidate(name: candidate, executable: resolved);
        }
      }
      return null;
    }

    if (Platform.isLinux) {
      final useHostSpawn = _isFlatpakLinux;
      for (final candidate in _linuxCandidates) {
        final resolved = await _which(candidate, useHostSpawn: useHostSpawn);
        if (resolved != null && resolved.isNotEmpty) {
          return BrowserCandidate(
            name: candidate,
            executable: resolved,
            useHostSpawn: useHostSpawn,
          );
        }
      }
      return null;
    }

    return null;
  }

  static Future<BrowserCandidate?> _detectWindowsBrowserFromKnownPaths() async {
    final env = Platform.environment;
    final roots = <String>[
      env['ProgramFiles'] ?? '',
      env['ProgramFiles(x86)'] ?? '',
      env['LOCALAPPDATA'] ?? '',
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    for (final candidate in _windowsPathCandidates) {
      for (final root in roots) {
        final executable = _joinWindowsPath(root, candidate.relativePath);
        if (await File(executable).exists()) {
          return BrowserCandidate(name: candidate.name, executable: executable);
        }
      }
    }
    return null;
  }

  static Future<BrowserCandidate?> _detectWindowsBrowserFromRegistry() async {
    for (final candidate in _windowsCandidates) {
      final path = await _queryWindowsAppPath(candidate);
      if (path != null && path.isNotEmpty && await File(path).exists()) {
        return BrowserCandidate(name: candidate, executable: path);
      }
    }
    return null;
  }

  static Future<String?> _queryWindowsAppPath(String executableName) async {
    const roots = <String>[
      r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
    ];
    for (final root in roots) {
      final key = '$root\\$executableName';
      try {
        final result = await Process.run('reg', <String>['query', key, '/ve']);
        if (result.exitCode != 0) {
          continue;
        }
        final raw = '${result.stdout}'.trim();
        if (raw.isEmpty) {
          continue;
        }
        final path = _extractRegistryDefaultValue(raw);
        if (path != null && path.isNotEmpty) {
          return path;
        }
      } catch (_) {}
    }
    return null;
  }

  static String? _extractRegistryDefaultValue(String raw) {
    final lines = raw.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      final normalized = line.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final idx = normalized.indexOf('REG_');
      if (idx < 0) {
        continue;
      }
      final value = normalized
          .substring(idx)
          .replaceFirst(RegExp(r'^REG_\w+\s+'), '')
          .trim();
      if (value.isEmpty) {
        continue;
      }
      return value.replaceAll('"', '').trim();
    }
    return null;
  }

  static String _joinWindowsPath(String root, List<String> segments) {
    final normalizedRoot = root.replaceAll(RegExp(r'[\\/]+$'), '');
    if (segments.isEmpty) {
      return normalizedRoot;
    }
    return '$normalizedRoot\\${segments.join('\\')}';
  }

  static Future<bool> _startProcess({
    required String executable,
    required List<String> args,
    required bool useHostSpawn,
  }) async {
    try {
      if (useHostSpawn) {
        await Process.start('flatpak-spawn', <String>[
          '--host',
          executable,
          ...args,
        ], mode: ProcessStartMode.detached);
        return true;
      }
      await Process.start(executable, args, mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> _allocateFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static Future<String> _resolveUserDataDir(int port, bool useHostSpawn) async {
    if (useHostSpawn && Platform.isLinux) {
      return '/tmp/breeze-chromium-cdp-$port';
    }
    final directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}breeze-chromium-cdp-$port',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String?> _which(
    String executable, {
    required bool useHostSpawn,
  }) async {
    try {
      final result = await _runProcess(
        executable: Platform.isWindows ? 'where' : 'which',
        args: <String>[executable],
        useHostSpawn: useHostSpawn,
      );
      if (result.exitCode != 0) {
        return null;
      }
      final output = '${result.stdout}'.trim();
      if (output.isEmpty) {
        return null;
      }
      return output
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    } catch (_) {
      return null;
    }
  }

  static Future<ProcessResult> _runProcess({
    required String executable,
    required List<String> args,
    required bool useHostSpawn,
  }) async {
    if (useHostSpawn) {
      return Process.run('flatpak-spawn', <String>[
        '--host',
        executable,
        ...args,
      ]);
    }
    return Process.run(executable, args);
  }

  static Future<String?> _fetchBrowserWsUrl(int debugPort) async {
    final uri = Uri.parse('http://127.0.0.1:$debugPort/json/version');
    final data = await _fetchJsonMap(uri);
    final ws = data['webSocketDebuggerUrl']?.toString().trim();
    if (ws == null || ws.isEmpty) {
      debugPrint(
        '[WebLoginFallback] /json/version has no webSocketDebuggerUrl',
      );
      return null;
    }
    return ws;
  }

  static Future<Map<String, dynamic>> _fetchJsonMap(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      return _asMap(decoded);
    } catch (_) {
      return const <String, dynamic>{};
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<dynamic>> _fetchJsonList(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      return _asList(decoded);
    } catch (_) {
      return const <dynamic>[];
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return const <dynamic>[];
  }

  static Map<String, dynamic>? _safeDecodeMap(dynamic payload) {
    try {
      if (payload is String) {
        final decoded = jsonDecode(payload);
        return _asMap(decoded);
      }
      return _asMap(payload);
    } catch (_) {
      return null;
    }
  }

  static String _basename(String path) {
    final segments = path
        .split(RegExp(r'[\\/]+'))
        .where((item) => item.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }
}

class BrowserCandidate {
  const BrowserCandidate({
    required this.name,
    required this.executable,
    this.useHostSpawn = false,
  });

  final String name;
  final String executable;
  final bool useHostSpawn;
}

class WindowsPathCandidate {
  const WindowsPathCandidate({required this.name, required this.relativePath});

  final String name;
  final List<String> relativePath;
}

bool matchesHost(String host, String expectedDomain) {
  final normalizedHost = host.trim().toLowerCase();
  final normalizedDomain = expectedDomain.trim().toLowerCase().replaceFirst(
    RegExp(r'^\.+'),
    '',
  );
  if (normalizedHost.isEmpty || normalizedDomain.isEmpty) {
    return false;
  }
  return normalizedHost == normalizedDomain ||
      normalizedHost.endsWith('.$normalizedDomain');
}

bool matchesRedirectWatchUrl(String currentUrl, String watchUrl) {
  final current = currentUrl.trim();
  final watch = watchUrl.trim();
  if (current.isEmpty || watch.isEmpty) {
    return false;
  }
  if (current == watch) {
    return true;
  }
  final currentUri = Uri.tryParse(current);
  final watchUri = Uri.tryParse(watch);
  if (currentUri == null || watchUri == null) {
    return false;
  }
  if (!matchesHost(currentUri.host, watchUri.host)) {
    return false;
  }
  if (currentUri.path != watchUri.path) {
    return false;
  }
  if (watch.contains('?') && watchUri.query.isEmpty) {
    return currentUri.query.isEmpty;
  }
  if (watchUri.query.isNotEmpty) {
    return currentUri.query == watchUri.query;
  }
  return true;
}

String buildCookieHeader(
  List<dynamic> snapshots,
  PluginWebLoginFlowConfig config, {
  required String Function(dynamic snapshot) nameOf,
  required String Function(dynamic snapshot) valueOf,
  required String? Function(dynamic snapshot) domainOf,
}) {
  if (snapshots.isEmpty) {
    return '';
  }
  final targetHost = config.redirectWatchUri?.host.isNotEmpty == true
      ? config.redirectWatchUri!.host
      : config.openUri.host;
  final selected = <String, String>{};
  for (final snapshot in snapshots) {
    final name = nameOf(snapshot).trim();
    if (name.isEmpty) {
      continue;
    }
    if (config.ignoreCookieNames.contains(name.toLowerCase())) {
      continue;
    }
    final domain = (domainOf(snapshot) ?? '').trim();
    if (domain.isNotEmpty && !matchesHost(targetHost, domain)) {
      continue;
    }
    selected[name] = valueOf(snapshot);
  }
  if (selected.isEmpty) {
    return '';
  }
  return selected.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('; ');
}

int toPositiveInt(dynamic value, {required int fallback}) {
  if (value is num) {
    final parsed = value.toInt();
    return parsed > 0 ? parsed : fallback;
  }
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed <= 0) {
    return fallback;
  }
  return parsed;
}

int? toOptionalInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

List<String> extractCookieNames(String cookieHeader) {
  final names = <String>[];
  for (final segment in cookieHeader.split(';')) {
    final trimmed = segment.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final eqIndex = trimmed.indexOf('=');
    if (eqIndex <= 0) {
      continue;
    }
    final name = trimmed.substring(0, eqIndex).trim();
    if (name.isEmpty) {
      continue;
    }
    names.add(name);
  }
  return names;
}
