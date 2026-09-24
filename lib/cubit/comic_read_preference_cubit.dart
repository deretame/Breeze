import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

/// 当前打开漫画的独立阅读设置（最小版：仅 `readMode`）。
///
/// 有记录且 `deleted=false` 时 [overrideReadMode] 非空，表示启用了本漫特定设置；
/// 为空时一律跟随全局 `readSetting.readMode`。
/// 停用时写入 `deleted=true` 的 tombstone，保证 WebDAV 能把删除同步出去。
/// 合并规则：unix 时间戳（`updatedAt`）更大的保留。
class ComicReadPreferenceState {
  final String source;
  final String comicId;
  final String uniqueKey;
  final int? overrideReadMode;

  const ComicReadPreferenceState({
    this.source = '',
    this.comicId = '',
    this.uniqueKey = '',
    this.overrideReadMode,
  });

  bool get hasOverride => overrideReadMode != null;

  bool matches(String source, String comicId) =>
      uniqueKey == ComicReadPreferenceService.keyFor(source, comicId);

  ComicReadPreferenceState copyWith({
    String? source,
    String? comicId,
    String? uniqueKey,
    int? overrideReadMode,
    bool clearOverride = false,
  }) {
    return ComicReadPreferenceState(
      source: source ?? this.source,
      comicId: comicId ?? this.comicId,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      overrideReadMode: clearOverride
          ? null
          : (overrideReadMode ?? this.overrideReadMode),
    );
  }
}

class ComicReadPreferenceCubit extends Cubit<ComicReadPreferenceState> {
  ComicReadPreferenceCubit() : super(const ComicReadPreferenceState());

  /// 进入阅读页时绑定当前漫画，加载本地独立设置。
  void bind(String source, String comicId) {
    final key = ComicReadPreferenceService.keyFor(source, comicId);
    if (state.uniqueKey == key) {
      refresh();
      return;
    }
    final mode = ComicReadPreferenceService.findOverrideReadMode(
      source,
      comicId,
    );
    emit(
      ComicReadPreferenceState(
        source: source,
        comicId: comicId,
        uniqueKey: key,
        overrideReadMode: mode,
      ),
    );
  }

  /// 离开阅读页时解绑，避免旧漫画的覆盖值泄漏到别处。
  void unbind() {
    if (state.uniqueKey.isEmpty && !state.hasOverride) return;
    emit(const ComicReadPreferenceState());
  }

  /// 重新从数据库加载（同步完成后调用）。
  void refresh() {
    if (state.uniqueKey.isEmpty) return;
    final mode = ComicReadPreferenceService.findOverrideReadMode(
      state.source,
      state.comicId,
    );
    if (mode != state.overrideReadMode) {
      emit(state.copyWith(overrideReadMode: mode, clearOverride: mode == null));
    }
  }

  /// 启用/更新本漫特定 `readMode`。
  Future<void> setOverride(int readMode) async {
    if (state.uniqueKey.isEmpty) return;
    final normalized = readMode.clamp(0, 2);
    await ComicReadPreferenceService.upsertReadMode(
      state.source,
      state.comicId,
      normalized,
    );
    emit(state.copyWith(overrideReadMode: normalized));
  }

  /// 停用本漫特定设置（写 tombstone，用于同步删除）。
  Future<void> clearOverride() async {
    if (state.uniqueKey.isEmpty) return;
    await ComicReadPreferenceService.clearPreference(
      state.source,
      state.comicId,
    );
    emit(state.copyWith(clearOverride: true));
  }
}

class ComicReadPreferenceService {
  static String keyFor(String source, String comicId) =>
      '${source.trim()}:${comicId.trim()}';

  static int normalizeReadMode(int value) => value.clamp(0, 2);

  /// 返回本漫启用的 `readMode`，未启用/已删除时返回 null。
  static int? findOverrideReadMode(String source, String comicId) {
    final key = keyFor(source, comicId);
    if (key == ':') return null;
    final query = objectbox.comicReadPreferenceBox
        .query(ComicReadPreference_.uniqueKey.equals(key))
        .build();
    try {
      final entity = query.findFirst();
      if (entity == null || entity.deleted) return null;
      return normalizeReadMode(entity.readMode);
    } finally {
      query.close();
    }
  }

  /// 启用/更新本漫 `readMode`，`updatedAt` 取当前 unix 时间。
  static Future<void> upsertReadMode(
    String source,
    String comicId,
    int readMode,
  ) async {
    final key = keyFor(source, comicId);
    if (key == ':') return;
    final now = DateTime.now().toUtc();
    final box = objectbox.comicReadPreferenceBox;
    final query = box.query(ComicReadPreference_.uniqueKey.equals(key)).build();
    try {
      final existing = query.findFirst();
      if (existing == null) {
        box.put(
          ComicReadPreference(
            uniqueKey: key,
            source: source,
            comicId: comicId,
            readMode: normalizeReadMode(readMode),
            updatedAt: now,
            deleted: false,
          ),
        );
      } else {
        existing
          ..source = source
          ..comicId = comicId
          ..readMode = normalizeReadMode(readMode)
          ..updatedAt = now
          ..deleted = false;
        box.put(existing);
      }
    } finally {
      query.close();
    }
  }

  /// 停用本漫特定设置：保留 tombstone 并刷新时间戳，保证同步时删除能赢。
  static Future<void> clearPreference(String source, String comicId) async {
    final key = keyFor(source, comicId);
    if (key == ':') return;
    final now = DateTime.now().toUtc();
    final box = objectbox.comicReadPreferenceBox;
    final query = box.query(ComicReadPreference_.uniqueKey.equals(key)).build();
    try {
      final existing = query.findFirst();
      if (existing == null) return;
      existing
        ..updatedAt = now
        ..deleted = true;
      box.put(existing);
    } finally {
      query.close();
    }
  }
}

/// 阅读页内计算有效阅读设置的便捷方法。
///
/// 只覆盖 `readMode`，其余字段一律走全局，符合最小版约定。
extension ComicReadPreferenceContextX on BuildContext {
  /// 监听全局 + 本漫覆盖，`readMode` 有覆盖用覆盖值。
  ReadSettingState watchEffectiveReadSetting() {
    final global = watch<GlobalSettingCubit>().state.readSetting;
    final override = watch<ComicReadPreferenceCubit>().state.overrideReadMode;
    if (override == null) return global;
    return global.copyWith(readMode: override);
  }

  /// 不建立监听的一次性读取，适合事件回调/跳转逻辑。
  ReadSettingState readEffectiveReadSetting() {
    final global = read<GlobalSettingCubit>().state.readSetting;
    final override = read<ComicReadPreferenceCubit>().state.overrideReadMode;
    if (override == null) return global;
    return global.copyWith(readMode: override);
  }

  /// 只取有效 `readMode`（监听）。
  int watchEffectiveReadMode() => watchEffectiveReadSetting().readMode;

  /// 只取有效 `readMode`（一次性）。
  int readEffectiveReadMode() => readEffectiveReadSetting().readMode;
}
