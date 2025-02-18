// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bika_setting.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BikaSetting on _BikaSetting, Store {
  late final _$accountAtom = Atom(
    name: '_BikaSetting.account',
    context: context,
  );

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
    name: '_BikaSetting.password',
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

  late final _$authorizationAtom = Atom(
    name: '_BikaSetting.authorization',
    context: context,
  );

  @override
  String get authorization {
    _$authorizationAtom.reportRead();
    return super.authorization;
  }

  @override
  set authorization(String value) {
    _$authorizationAtom.reportWrite(value, super.authorization, () {
      super.authorization = value;
    });
  }

  late final _$levelAtom = Atom(name: '_BikaSetting.level', context: context);

  @override
  int get level {
    _$levelAtom.reportRead();
    return super.level;
  }

  @override
  set level(int value) {
    _$levelAtom.reportWrite(value, super.level, () {
      super.level = value;
    });
  }

  late final _$checkInAtom = Atom(
    name: '_BikaSetting.checkIn',
    context: context,
  );

  @override
  bool get checkIn {
    _$checkInAtom.reportRead();
    return super.checkIn;
  }

  @override
  set checkIn(bool value) {
    _$checkInAtom.reportWrite(value, super.checkIn, () {
      super.checkIn = value;
    });
  }

  late final _$proxyAtom = Atom(name: '_BikaSetting.proxy', context: context);

  @override
  int get proxy {
    _$proxyAtom.reportRead();
    return super.proxy;
  }

  @override
  set proxy(int value) {
    _$proxyAtom.reportWrite(value, super.proxy, () {
      super.proxy = value;
    });
  }

  late final _$imageQualityAtom = Atom(
    name: '_BikaSetting.imageQuality',
    context: context,
  );

  @override
  String get imageQuality {
    _$imageQualityAtom.reportRead();
    return super.imageQuality;
  }

  @override
  set imageQuality(String value) {
    _$imageQualityAtom.reportWrite(value, super.imageQuality, () {
      super.imageQuality = value;
    });
  }

  late final _$shieldCategoryMapAtom = Atom(
    name: '_BikaSetting.shieldCategoryMap',
    context: context,
  );

  @override
  Map<String, bool> get shieldCategoryMap {
    _$shieldCategoryMapAtom.reportRead();
    return super.shieldCategoryMap;
  }

  @override
  set shieldCategoryMap(Map<String, bool> value) {
    _$shieldCategoryMapAtom.reportWrite(value, super.shieldCategoryMap, () {
      super.shieldCategoryMap = value;
    });
  }

  late final _$shieldHomePageCategoriesMapAtom = Atom(
    name: '_BikaSetting.shieldHomePageCategoriesMap',
    context: context,
  );

  @override
  Map<String, bool> get shieldHomePageCategoriesMap {
    _$shieldHomePageCategoriesMapAtom.reportRead();
    return super.shieldHomePageCategoriesMap;
  }

  @override
  set shieldHomePageCategoriesMap(Map<String, bool> value) {
    _$shieldHomePageCategoriesMapAtom.reportWrite(
      value,
      super.shieldHomePageCategoriesMap,
      () {
        super.shieldHomePageCategoriesMap = value;
      },
    );
  }

  late final _$signInAtom = Atom(name: '_BikaSetting.signIn', context: context);

  @override
  bool get signIn {
    _$signInAtom.reportRead();
    return super.signIn;
  }

  @override
  set signIn(bool value) {
    _$signInAtom.reportWrite(value, super.signIn, () {
      super.signIn = value;
    });
  }

  late final _$signInTimeAtom = Atom(
    name: '_BikaSetting.signInTime',
    context: context,
  );

  @override
  DateTime get signInTime {
    _$signInTimeAtom.reportRead();
    return super.signInTime;
  }

  @override
  set signInTime(DateTime value) {
    _$signInTimeAtom.reportWrite(value, super.signInTime, () {
      super.signInTime = value;
    });
  }

  late final _$_BikaSettingActionController = ActionController(
    name: '_BikaSetting',
    context: context,
  );

  @override
  String getAccount() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getAccount',
    );
    try {
      return super.getAccount();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccount(String value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setAccount',
    );
    try {
      return super.setAccount(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteAccount() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteAccount',
    );
    try {
      return super.deleteAccount();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String getPassword() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getPassword',
    );
    try {
      return super.getPassword();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deletePassword() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deletePassword',
    );
    try {
      return super.deletePassword();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String getAuthorization() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getAuthorization',
    );
    try {
      return super.getAuthorization();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAuthorization(String value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setAuthorization',
    );
    try {
      return super.setAuthorization(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteAuthorization() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteAuthorization',
    );
    try {
      return super.deleteAuthorization();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  int getLevel() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getLevel',
    );
    try {
      return super.getLevel();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLevel(int value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setLevel',
    );
    try {
      return super.setLevel(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteLevel() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteLevel',
    );
    try {
      return super.deleteLevel();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool getCheckIn() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getCheckIn',
    );
    try {
      return super.getCheckIn();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCheckIn(bool value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setCheckIn',
    );
    try {
      return super.setCheckIn(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteCheckIn() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteCheckIn',
    );
    try {
      return super.deleteCheckIn();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  int getProxy() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getProxy',
    );
    try {
      return super.getProxy();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setProxy(int value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setProxy',
    );
    try {
      return super.setProxy(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteProxy() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteProxy',
    );
    try {
      return super.deleteProxy();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String getImageQuality() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getImageQuality',
    );
    try {
      return super.getImageQuality();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setImageQuality(String value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setImageQuality',
    );
    try {
      return super.setImageQuality(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteImageQuality() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteImageQuality',
    );
    try {
      return super.deleteImageQuality();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  Map<String, bool> getShieldCategoryMap() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getShieldCategoryMap',
    );
    try {
      return super.getShieldCategoryMap();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setShieldCategoryMap(Map<String, bool> value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setShieldCategoryMap',
    );
    try {
      return super.setShieldCategoryMap(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteShieldCategoryMap() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteShieldCategoryMap',
    );
    try {
      return super.deleteShieldCategoryMap();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  Map<String, bool> getShieldHomePageCategories() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getShieldHomePageCategories',
    );
    try {
      return super.getShieldHomePageCategories();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setShieldHomeCategories(Map<String, bool> value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setShieldHomeCategories',
    );
    try {
      return super.setShieldHomeCategories(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteShieldHomeCategories() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteShieldHomeCategories',
    );
    try {
      return super.deleteShieldHomeCategories();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool getSignIn() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getSignIn',
    );
    try {
      return super.getSignIn();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteSignIn() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteSignIn',
    );
    try {
      return super.deleteSignIn();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSignIn(bool value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setSignIn',
    );
    try {
      return super.setSignIn(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  DateTime getSignInTime() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.getSignInTime',
    );
    try {
      return super.getSignInTime();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSignInTime(DateTime value) {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.setSignInTime',
    );
    try {
      return super.setSignInTime(value);
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteSignInTime() {
    final _$actionInfo = _$_BikaSettingActionController.startAction(
      name: '_BikaSetting.deleteSignInTime',
    );
    try {
      return super.deleteSignInTime();
    } finally {
      _$_BikaSettingActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
account: ${account},
password: ${password},
authorization: ${authorization},
level: ${level},
checkIn: ${checkIn},
proxy: ${proxy},
imageQuality: ${imageQuality},
shieldCategoryMap: ${shieldCategoryMap},
shieldHomePageCategoriesMap: ${shieldHomePageCategoriesMap},
signIn: ${signIn},
signInTime: ${signInTime}
    ''';
  }
}
