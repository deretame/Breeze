enum CsRunMode { local, cs }

enum CsDownloadMode { client, server }

/// CS 连接与运行模式配置。
///
/// 服务地址、模式和下载归属属于设备级配置；访问令牌只在内存中的
/// [CsModeService] / [CsApiClient] 中保留，不写入普通配置存储。
class CsConnectionSettings {
  const CsConnectionSettings({
    this.mode = CsRunMode.local,
    this.serverUrl = '',
    this.userId,
    this.downloadMode = CsDownloadMode.client,
    this.lastServerRevision,
    this.accessToken,
  });

  final CsRunMode mode;
  final String serverUrl;
  final String? userId;
  final CsDownloadMode downloadMode;
  final int? lastServerRevision;

  /// 运行时会话令牌，不参与 [toJson] 持久化。
  final String? accessToken;

  bool get isCsMode => mode == CsRunMode.cs;

  bool get hasServer => serverUrl.trim().isNotEmpty;

  CsConnectionSettings copyWith({
    CsRunMode? mode,
    String? serverUrl,
    String? userId,
    bool clearUserId = false,
    CsDownloadMode? downloadMode,
    int? lastServerRevision,
    bool clearLastServerRevision = false,
    String? accessToken,
    bool clearAccessToken = false,
  }) {
    return CsConnectionSettings(
      mode: mode ?? this.mode,
      serverUrl: serverUrl ?? this.serverUrl,
      userId: clearUserId ? null : userId ?? this.userId,
      downloadMode: downloadMode ?? this.downloadMode,
      lastServerRevision: clearLastServerRevision
          ? null
          : lastServerRevision ?? this.lastServerRevision,
      accessToken: clearAccessToken ? null : accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'serverUrl': serverUrl,
      'userId': userId,
      'downloadMode': downloadMode.name,
      'lastServerRevision': lastServerRevision,
    };
  }

  factory CsConnectionSettings.fromJson(Map<String, dynamic> json) {
    return CsConnectionSettings(
      mode: _enumValue(json['mode'], CsRunMode.values, CsRunMode.local),
      serverUrl: (json['serverUrl'] as String? ?? '').trim(),
      userId: (json['userId'] as String?)?.trim().nullIfEmpty,
      downloadMode: _enumValue(
        json['downloadMode'],
        CsDownloadMode.values,
        CsDownloadMode.client,
      ),
      lastServerRevision: (json['lastServerRevision'] as num?)?.toInt(),
    );
  }

  static T _enumValue<T extends Enum>(
    Object? value,
    List<T> values,
    T fallback,
  ) {
    final name = value is String ? value : null;
    for (final item in values) {
      if (item.name == name) return item;
    }
    return fallback;
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
