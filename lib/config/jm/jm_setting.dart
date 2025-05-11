import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

part 'jm_setting.g.dart';

// ignore: library_private_types_in_public_api
class JmSetting = _JmSetting with _$JmSetting;

abstract class _JmSetting with Store {
  late final Box<dynamic> _box;

  @observable
  String account = '';
  @observable
  String password = '';

  Future<void> initBox() async {
    _box = await Hive.openBox(JmSettingBoxKeys.jmSettingBox);
    account = getAccount();
    password = getPassword();
  }

  @action
  void setAccount(String value) {
    account = value;
    _box.put(JmSettingBoxKeys.account, value);
  }

  @action
  String getAccount() {
    account = _box.get(JmSettingBoxKeys.account, defaultValue: '');
    return account;
  }

  @action
  void deleteAccount() {
    account = '';
    _box.delete(JmSettingBoxKeys.account);
  }

  @action
  void setPassword(String value) {
    password = value;
    _box.put(JmSettingBoxKeys.password, value);
  }

  @action
  String getPassword() {
    password = _box.get(JmSettingBoxKeys.password, defaultValue: '');
    return password;
  }

  @action
  void deletePassword() {
    password = '';
    _box.delete(JmSettingBoxKeys.password);
  }
}

class JmSettingBoxKeys {
  static const String jmSettingBox = 'jmSettingBox'; // 禁漫设置存储盒
  static const String account = 'account'; // 账号
  static const String password = 'password'; // 密码
}
