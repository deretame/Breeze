// 存储哔咔的设置和账号信息
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bika_setting.freezed.dart';
part 'bika_setting.g.dart';

@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
@freezed
abstract class BikaSettingState with _$BikaSettingState {
  const factory BikaSettingState({
    @Default('') String account,
    @Default('') String password,
    @Default('') String authorization,
    @Default(0) int level,
    @Default(3) int proxy,
    @Default('original') String imageQuality,
    @Default(<String, bool>{}) Map<String, bool> shieldCategoryMap,
    @Default(<String, bool>{}) Map<String, bool> shieldHomePageCategoriesMap,
    @Default(false) bool signIn,
    @Default(false) bool brevity,
    @Default(false) bool slowDownload,
  }) = _BikaSettingState;

  factory BikaSettingState.fromJson(Map<String, dynamic> json) =>
      _$BikaSettingStateFromJson(json);
}
