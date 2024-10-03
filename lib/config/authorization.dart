import 'package:mmkv/mmkv.dart';

var mmkv = MMKV.defaultMMKV();

// 授权设置
String? getAuthorization() {
  return mmkv.decodeString("authorization");
}

bool setAuthorization(String authorization) {
  return mmkv.encodeString("authorization", authorization);
}

void deleteAuthorization() {
  return mmkv.removeValue("authorization");
}

// 账号密码设置
String? getAccount() {
  return mmkv.decodeString("account");
}

bool setAccount(String account) {
  return mmkv.encodeString("account", account);
}

void deleteAccount() {
  return mmkv.removeValue("account");
}

String? getPassword() {
  return mmkv.decodeString("password");
}

bool setPassword(String password) {
  return mmkv.encodeString("password", password);
}

void deletePassword() {
  return mmkv.removeValue("password");
}
