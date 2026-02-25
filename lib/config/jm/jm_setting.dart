import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/main.dart';
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
    @Default(0) int favoriteSet,
  }) = _JmSettingState;

  factory JmSettingState.fromJson(Map<String, dynamic> json) =>
      _$JmSettingStateFromJson(json);
}

class JmSettingCubit extends Cubit<JmSettingState> {
  JmSettingCubit() : super(const JmSettingState());

  static const _defaults = JmSettingState();

  Future<void> initBox() async {
    emit(objectbox.userSettingBox.get(1)!.jmSetting);
  }

  // --- 持久化状态 (Account / Password) ---

  void updateAccount(String value) {
    final temp = state.copyWith(account: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetAccount() {
    final temp = state.copyWith(account: _defaults.account);
    updateDataBase(temp);
    emit(temp);
  }

  void updatePassword(String value) {
    final temp = state.copyWith(password: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetPassword() {
    final temp = state.copyWith(password: _defaults.password);
    updateDataBase(temp);
    emit(temp);
  }

  void updateUserInfo(String value) {
    final temp = state.copyWith(userInfo: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetUserInfo() {
    final temp = state.copyWith(userInfo: _defaults.userInfo);
    updateDataBase(temp);
    emit(temp);
  }

  void updateLoginStatus(LoginStatus value) {
    final temp = state.copyWith(loginStatus: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetLoginStatus() {
    final temp = state.copyWith(loginStatus: _defaults.loginStatus);
    updateDataBase(temp);
    emit(temp);
  }

  void updateFavoriteSet(int value) {
    final temp = state.copyWith(favoriteSet: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetFavoriteSet() {
    final temp = state.copyWith(favoriteSet: _defaults.favoriteSet);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDataBase(JmSettingState state) {
    final userBox = objectbox.userSettingBox;
    var dbSettings = userBox.get(1)!;
    dbSettings.jmSetting = state;
    userBox.put(dbSettings);
  }
}

class JmSettingBoxKeys {
  static const String jmSettingBox = 'jmSettingBox';
  static const String account = 'account';
  static const String password = 'password';
  static const String userInfo = 'userInfo';
  static const String loginStatus = 'loginStatus';
  static const String favoriteSet = 'favoriteSet';
}
