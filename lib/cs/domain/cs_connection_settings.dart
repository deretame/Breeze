enum CsRunMode { local, cs }

enum CsDownloadMode { client, server }

/// CS 连接与运行模式配置。
///
/// 服务地址、模式和下载归属属于设备级配置；访问令牌不进入普通 JSON 配置，
/// 由 [CsConnectionStore] 通过系统安全存储恢复到内存中的 [CsModeService]。
class CsConnectionSettings {
  const CsConnectionSettings({
    this.mode = CsRunMode.local,
    this.pendingMode,
    this.serverUrl = '',
    this.userId,
    this.downloadMode = CsDownloadMode.client,
    this.downloadDataMigrated = false,
    this.lastServerRevision,
    this.accessToken,
  });

  final CsRunMode mode;
  final CsRunMode? pendingMode;
  final String serverUrl;
  final String? userId;
  final CsDownloadMode downloadMode;

  /// 进入 CS 时是否把已有本地下载迁移到了服务端。
  ///
  /// 它和 [downloadMode] 不同：[downloadMode] 表示后续新下载放在哪里，
  /// 此字段用于关闭 CS 时决定是否用远端下载覆盖本地文件。
  final bool downloadDataMigrated;
  final int? lastServerRevision;

  /// 运行时会话令牌，不参与普通 [toJson] 持久化。
  final String? accessToken;

  bool get isCsMode => mode == CsRunMode.cs;

  bool get hasPendingMode => pendingMode != null;

  bool get hasServer => serverUrl.trim().isNotEmpty;

  CsConnectionSettings copyWith({
    CsRunMode? mode,
    CsRunMode? pendingMode,
    bool clearPendingMode = false,
    String? serverUrl,
    String? userId,
    bool clearUserId = false,
    CsDownloadMode? downloadMode,
    bool? downloadDataMigrated,
    int? lastServerRevision,
    bool clearLastServerRevision = false,
    String? accessToken,
    bool clearAccessToken = false,
  }) {
    return CsConnectionSettings(
      mode: mode ?? this.mode,
      pendingMode: clearPendingMode ? null : pendingMode ?? this.pendingMode,
      serverUrl: serverUrl ?? this.serverUrl,
      userId: clearUserId ? null : userId ?? this.userId,
      downloadMode: downloadMode ?? this.downloadMode,
      downloadDataMigrated: downloadDataMigrated ?? this.downloadDataMigrated,
      lastServerRevision: clearLastServerRevision
          ? null
          : lastServerRevision ?? this.lastServerRevision,
      accessToken: clearAccessToken ? null : accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'pendingMode': pendingMode?.name,
      'serverUrl': serverUrl,
      'userId': userId,
      'downloadMode': downloadMode.name,
      'downloadDataMigrated': downloadDataMigrated,
      'lastServerRevision': lastServerRevision,
    };
  }

  factory CsConnectionSettings.fromJson(Map<String, dynamic> json) {
    return CsConnectionSettings(
      mode: _enumValue(json['mode'], CsRunMode.values, CsRunMode.local),
      pendingMode: _nullableEnumValue(json['pendingMode'], CsRunMode.values),
      serverUrl: (json['serverUrl'] as String? ?? '').trim(),
      userId: (json['userId'] as String?)?.trim().nullIfEmpty,
      downloadMode: _enumValue(
        json['downloadMode'],
        CsDownloadMode.values,
        CsDownloadMode.client,
      ),
      downloadDataMigrated: json['downloadDataMigrated'] as bool? ?? false,
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

  static T? _nullableEnumValue<T extends Enum>(Object? value, List<T> values) {
    final name = value is String ? value : null;
    for (final item in values) {
      if (item.name == name) return item;
    }
    return null;
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
