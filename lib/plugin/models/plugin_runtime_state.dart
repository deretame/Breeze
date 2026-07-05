class PluginRuntimeState {
  const PluginRuntimeState({
    required this.uuid,
    required this.version,
    required this.originScript,
    required this.isEnabled,
    required this.isDeleted,
    required this.debug,
    required this.debugUrl,
    required this.lastLoadSuccess,
    required this.lastLoadError,
    required this.insertedAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String uuid;
  final String version;
  final String originScript;
  final bool isEnabled;
  final bool isDeleted;
  final bool debug;
  final String? debugUrl;
  final bool lastLoadSuccess;
  final String? lastLoadError;
  final DateTime insertedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isActive => isEnabled && !isDeleted;

  PluginRuntimeState copyWith({
    String? version,
    String? originScript,
    bool? isEnabled,
    bool? isDeleted,
    bool? debug,
    String? debugUrl,
    bool? lastLoadSuccess,
    String? lastLoadError,
    DateTime? insertedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PluginRuntimeState(
      uuid: uuid,
      version: version ?? this.version,
      originScript: originScript ?? this.originScript,
      isEnabled: isEnabled ?? this.isEnabled,
      isDeleted: isDeleted ?? this.isDeleted,
      debug: debug ?? this.debug,
      debugUrl: debugUrl ?? this.debugUrl,
      lastLoadSuccess: lastLoadSuccess ?? this.lastLoadSuccess,
      lastLoadError: lastLoadError ?? this.lastLoadError,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
