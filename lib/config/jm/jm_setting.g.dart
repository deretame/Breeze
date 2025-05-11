// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jm_setting.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$JmSetting on _JmSetting, Store {
  late final _$accountAtom = Atom(name: '_JmSetting.account', context: context);

  @override
  String get account {
    _$accountAtom.reportRead();
    return super.account;
  }

  @override
  set account(String value) {
    _$accountAtom.reportWrite(value, super.account, () {
      super.account = value;
    });
  }

  late final _$passwordAtom = Atom(
    name: '_JmSetting.password',
    context: context,
  );

  @override
  String get password {
    _$passwordAtom.reportRead();
    return super.password;
  }

  @override
  set password(String value) {
    _$passwordAtom.reportWrite(value, super.password, () {
      super.password = value;
    });
  }

  late final _$_JmSettingActionController = ActionController(
    name: '_JmSetting',
    context: context,
  );

  @override
  void setAccount(String value) {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.setAccount',
    );
    try {
      return super.setAccount(value);
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String getAccount() {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.getAccount',
    );
    try {
      return super.getAccount();
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteAccount() {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.deleteAccount',
    );
    try {
      return super.deleteAccount();
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String getPassword() {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.getPassword',
    );
    try {
      return super.getPassword();
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deletePassword() {
    final _$actionInfo = _$_JmSettingActionController.startAction(
      name: '_JmSetting.deletePassword',
    );
    try {
      return super.deletePassword();
    } finally {
      _$_JmSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
account: ${account},
password: ${password}
    ''';
  }
}
