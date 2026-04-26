class WebviewCookie {
  const WebviewCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.path,
    required this.expires,
    required this.secure,
    required this.httpOnly,
    required this.sessionOnly,
  });

  factory WebviewCookie.fromJson(Map<String, dynamic> json) {
    return WebviewCookie(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: json['domain'] as String,
      expires: json['expires'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              ((json['expires'] as num) * 1000).toInt(),
            ),
      httpOnly: json['httpOnly'] as bool? ?? false,
      path: json['path'] as String,
      secure: json['secure'] as bool? ?? false,
      sessionOnly: json['sessionOnly'] as bool? ?? false,
    );
  }

  final String name;
  final String value;
  final String domain;
  final String path;
  final DateTime? expires;
  final bool secure;
  final bool httpOnly;
  final bool sessionOnly;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expires': expires == null
          ? null
          : expires!.millisecondsSinceEpoch ~/ 1000,
      'secure': secure,
      'httpOnly': httpOnly,
      'sessionOnly': sessionOnly,
    };
  }
}
