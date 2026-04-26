class NoticeSync {
  final bool force;

  const NoticeSync({this.force = false});
}

class NeedLogin {
  String from;
  Map<String, dynamic>? scheme;
  Map<String, dynamic>? data;
  String? message;

  NeedLogin({required this.from, this.scheme, this.data, this.message});
}

class WebViewCookieSnapshot {
  final String name;
  final String value;
  final String? domain;
  final String? path;
  final int? expiresDate;
  final bool? isSecure;
  final bool? isHttpOnly;
  final bool? isSessionOnly;

  const WebViewCookieSnapshot({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expiresDate,
    this.isSecure,
    this.isHttpOnly,
    this.isSessionOnly,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expiresDate': expiresDate,
      'isSecure': isSecure,
      'isHttpOnly': isHttpOnly,
      'isSessionOnly': isSessionOnly,
    };
  }
}

class WebViewObserveEvent {
  final String url;
  final String trigger;
  final String platform;
  final DateTime observedAt;
  final List<WebViewCookieSnapshot> cookies;
  final int? statusCode;
  final String? errorDescription;

  WebViewObserveEvent({
    required this.url,
    required this.trigger,
    required this.platform,
    required this.observedAt,
    required this.cookies,
    this.statusCode,
    this.errorDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'trigger': trigger,
      'platform': platform,
      'observedAt': observedAt.toIso8601String(),
      'cookies': cookies.map((e) => e.toJson()).toList(),
      'statusCode': statusCode,
      'errorDescription': errorDescription,
    };
  }
}
