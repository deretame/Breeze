import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:zephyr/type/enum.dart';

part 'jm_setting.freezed.dart';
part 'jm_setting.g.dart';

@freezed
abstract class JmSettingState with _$JmSettingState {
  const factory JmSettingState({
    @Default('') String account,
    @Default('') String password,
    @Default('') String userInfo,
    @Default(LoginStatus.logout) LoginStatus loginStatus,
  }) = _JmSettingState;

  factory JmSettingState.fromJson(Map<String, dynamic> json) =>
      _$JmSettingStateFromJson(json);
}

class JmSettingCubit extends Cubit<JmSettingState> {
  late final Box<dynamic> _box;

  JmSettingCubit() : super(const JmSettingState());

  static const _defaults = JmSettingState();

  Future<void> initBox() async {
    _box = await Hive.openBox(JmSettingBoxKeys.jmSettingBox);

    emit(
      state.copyWith(
        account: _box.get(
          JmSettingBoxKeys.account,
          defaultValue: _defaults.account,
        ),
        password: _box.get(
          JmSettingBoxKeys.password,
          defaultValue: _defaults.password,
        ),
      ),
    );
  }

  // --- 持久化状态 (Account / Password) ---

  void updateAccount(String value) {
    _box.put(JmSettingBoxKeys.account, value);
    emit(state.copyWith(account: value));
  }

  void resetAccount() {
    _box.delete(JmSettingBoxKeys.account);
    emit(state.copyWith(account: _defaults.account));
  }

  void updatePassword(String value) {
    _box.put(JmSettingBoxKeys.password, value);
    emit(state.copyWith(password: value));
  }

  void resetPassword() {
    _box.delete(JmSettingBoxKeys.password);
    emit(state.copyWith(password: _defaults.password));
  }

  void updateUserInfo(String value) {
    emit(state.copyWith(userInfo: value));
  }

  void resetUserInfo() {
    emit(state.copyWith(userInfo: _defaults.userInfo));
  }

  void updateLoginStatus(LoginStatus value) {
    emit(state.copyWith(loginStatus: value));
  }

  void resetLoginStatus() {
    emit(state.copyWith(loginStatus: _defaults.loginStatus));
  }
}

class JmSettingBoxKeys {
  static const String jmSettingBox = 'jmSettingBox';
  static const String account = 'account';
  static const String password = 'password';
  static const String userInfo = 'userInfo';
  static const String loginStatus = 'loginStatus';
}
