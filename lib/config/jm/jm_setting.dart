import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/type/enum.dart';

part 'jm_setting.freezed.dart';
part 'jm_setting.g.dart';

@Deprecated("不再使用，仅作为迁移时作为参考数据结构")
@freezed
abstract class JmSettingState with _$JmSettingState {
  const factory JmSettingState({
    @Default('') String account,
    @Default('') String password,
    @Default('') String userInfo,
    @Default(LoginStatus.logout) LoginStatus loginStatus,
    @Default(0) int favoriteSet,
  }) = _JmSettingState;

  factory JmSettingState.fromJson(Map<String, dynamic> json) =>
      _$JmSettingStateFromJson(json);
}
