import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

/// 当前打开漫画的独立阅读设置：与全局共用一套 `ReadSettingState` 结构。
///
/// [override] 为 null 表示没设置 = 跟随全局；非 null 即本漫独立设置
/// （`keys` 是精确的覆盖键集合，“有没有”看它，不看值）。
/// 有记录且 `deleted=false` 时非空表示启用了本漫特定设置；
/// 停用时写入 `deleted=true` 的 tombstone，保证 WebDAV 能把删除同步出去。
/// 合并规则：unix 时间戳（`updatedAt`）更大的保留。
class ComicReadPreferenceState {
  final String source;
  final String comicId;
  final String uniqueKey;
  final ({ReadSettingState setting, Set<String> keys})? override;

  const ComicReadPreferenceState({
    this.source = '',
    this.comicId = '',
    this.uniqueKey = '',
    this.override,
  });

  /// 本漫是否有独立设置（是否跟随全局的反面）。
  bool get hasOverride => override != null;

  ComicReadPreferenceState copyWith({
    String? source,
    String? comicId,
    String? uniqueKey,
    ({ReadSettingState setting, Set<String> keys})? override,
    bool clearOverride = false,
  }) {
    return ComicReadPreferenceState(
      source: source ?? this.source,
      comicId: comicId ?? this.comicId,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      override: clearOverride ? null : (override ?? this.override),
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
    final override = ComicReadPreferenceService.findOverrideSetting(
      source,
      comicId,
    );
    emit(
      ComicReadPreferenceState(
        source: source,
        comicId: comicId,
        uniqueKey: key,
        override: override,
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
    final override = ComicReadPreferenceService.findOverrideSetting(
      state.source,
      state.comicId,
    );
    if (!_overrideEquals(override, state.override)) {
      emit(state.copyWith(override: override, clearOverride: override == null));
    }
  }

  /// 通用写入：以调用方看到的目标值（本漫 tab 是有效值）为 diff 基准
  /// 做 `updates`，把变化写进本漫独立设置。
  ///
  /// 加新设置项时 UI 只调这一个方法，不用再为每个字段写路由。
  /// 返回实际变化的 key（为空表示值没变化，什么都没写）。
  Future<Set<String>> updateField(
    ReadSettingState effective,
    ReadSettingState Function(ReadSettingState current) updates,
  ) async {
    if (state.uniqueKey.isEmpty) return const {};
    // 以调用方看到的目标值为 diff 基准：delta 恰好是本次改的键，
    // 直接合并进 patch，不把其它全局偏差拖进来。
    final updated = updates(effective);
    final result = await ComicReadPreferenceService.upsertOverride(
      state.source,
      state.comicId,
      effective,
      updated,
    );
    if (result.changedKeys.isEmpty) return const {};
    emit(state.copyWith(override: result.override));
    return result.changedKeys;
  }

  /// 删整行本漫设置：清空 patch + 立 tombstone，同步把删除传出去。
  Future<void> clearOverride() async {
    if (state.uniqueKey.isEmpty) return;
    await ComicReadPreferenceService.clearPreference(
      state.source,
      state.comicId,
    );
    emit(state.copyWith(clearOverride: true));
  }
}

bool _overrideEquals(
  ({ReadSettingState setting, Set<String> keys})? a,
  ({ReadSettingState setting, Set<String> keys})? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a.setting == b.setting &&
      a.keys.length == b.keys.length &&
      a.keys.containsAll(b.keys);
}

class PerComicUpsertResult {
  /// 写库后的完整覆盖（null 表示无变化未写库）。
  final ({ReadSettingState setting, Set<String> keys})? override;

  /// 本次实际变化的 key。
  final Set<String> changedKeys;

  const PerComicUpsertResult(this.override, this.changedKeys);
}

class ComicReadPreferenceService {
  static String keyFor(String source, String comicId) =>
      '${source.trim()}:${comicId.trim()}';

  /// 返回本漫独立设置，未启用/已删除时返回 null（= 跟随全局）。
  static ({ReadSettingState setting, Set<String> keys})? findOverrideSetting(
    String source,
    String comicId,
  ) {
    final key = keyFor(source, comicId);
    if (key == ':') return null;
    final query = objectbox.comicReadPreferenceBox
        .query(ComicReadPreference_.uniqueKey.equals(key))
        .build();
    try {
      return query.findFirst()?.overrideSetting;
    } finally {
      query.close();
    }
  }

  /// 把 [updated] 相对 [current] 的变化合并进本漫设置并写回。
  ///
  /// 只动变化的 key（外加 [includeKeys] 强制记录的键），其余原样保留；
  /// `updatedAt` 取当前 unix 时间。无变化时不写库。
  static Future<PerComicUpsertResult> upsertOverride(
    String source,
    String comicId,
    ReadSettingState current,
    ReadSettingState updated, {
    Set<String> includeKeys = const {},
  }) async {
    final key = keyFor(source, comicId);
    if (key == ':') return const PerComicUpsertResult(null, {});
    final now = DateTime.now().toUtc();
    final box = objectbox.comicReadPreferenceBox;
    final query = box.query(ComicReadPreference_.uniqueKey.equals(key)).build();
    try {
      final existing = query.findFirst();
      if (existing == null) {
        final entity = ComicReadPreference(
          uniqueKey: key,
          source: source,
          comicId: comicId,
          updatedAt: now,
          deleted: false,
        );
        final changedKeys = entity.applyChanges(
          current,
          updated,
          includeKeys: includeKeys,
        );
        if (changedKeys.isEmpty) {
          return const PerComicUpsertResult(null, {});
        }
        box.put(entity);
        return PerComicUpsertResult(entity.overrideSetting, changedKeys);
      }
      // 有碑先清：墓碑行的 patch 已清空，这里直接复用行对象重记本次变化。
      if (existing.deleted) existing.overridesJson = '{}';
      final changedKeys = existing.applyChanges(
        current,
        updated,
        includeKeys: includeKeys,
      );
      if (changedKeys.isEmpty) {
        return PerComicUpsertResult(existing.overrideSetting, const {});
      }
      existing
        ..source = source
        ..comicId = comicId
        ..updatedAt = now
        ..deleted = false;
      box.put(existing);
      return PerComicUpsertResult(existing.overrideSetting, changedKeys);
    } finally {
      query.close();
    }
  }

  /// 把本漫独立设置合并到全局上，算出有效阅读设置。
  ///
  /// 只盖 [override] 记录里有的 key（稀疏语义）；无覆盖直接返回全局。
  /// “显式设成默认值”的键也在 key 集合里，会正确覆盖——有没有看 key，不看值。
  static ReadSettingState resolveEffective(
    ReadSettingState global,
    ({ReadSettingState setting, Set<String> keys})? override,
  ) {
    if (override == null || override.keys.isEmpty) return global;
    final values = override.setting.toJson();
    final merged = Map<String, dynamic>.from(global.toJson());
    for (final key in override.keys) {
      if (values.containsKey(key)) merged[key] = values[key];
    }
    try {
      return ReadSettingState.fromJson(merged);
    } catch (_) {
      return global;
    }
  }

  /// 删除本漫特定设置：先清空 patch，再立 [deleted] 墓碑并刷新时间戳。
  ///
  /// patch 已空，后续写入必然走“有碑先清”分支重记，不会复活旧值；
  /// 墓碑靠 LWW 同步到其它设备。
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
        ..overridesJson = '{}'
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
/// 全局 `ReadSettingState.toJson()` 全量打底，本漫 patch 只盖有 key 的部分：
/// 没 key = 没设置 = 跟随全局。以后加字段零改动。
extension ComicReadPreferenceContextX on BuildContext {
  /// 监听全局 + 本漫覆盖，有覆盖用覆盖值。
  ReadSettingState watchEffectiveReadSetting() {
    final global = watch<GlobalSettingCubit>().state.readSetting;
    final override = watch<ComicReadPreferenceCubit>().state.override;
    return ComicReadPreferenceService.resolveEffective(global, override);
  }

  /// 不建立监听的一次性读取，适合事件回调/跳转逻辑。
  ReadSettingState readEffectiveReadSetting() {
    final global = read<GlobalSettingCubit>().state.readSetting;
    final override = read<ComicReadPreferenceCubit>().state.override;
    return ComicReadPreferenceService.resolveEffective(global, override);
  }

  /// 只取有效 `readMode`（监听）。
  int watchEffectiveReadMode() => watchEffectiveReadSetting().readMode;

  /// 只取有效 `readMode`（一次性）。
  int readEffectiveReadMode() => readEffectiveReadSetting().readMode;
}
