// 存储哔咔的设置和账号信息
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'bika_setting.g.dart';

// ignore: library_private_types_in_public_api
class BikaSetting = _BikaSetting with _$BikaSetting;

abstract class _BikaSetting with Store {
  late final Box<dynamic> _box;

  @observable
  String account = ''; // 账号

  @observable
  String password = ''; // 密码

  @observable
  String authorization = ''; // 授权码

  @observable
  int level = 0; // 用户等级

  @observable
  bool checkIn = false; // 签到状态

  @observable
  int proxy = 3; // 分流设置

  @observable
  String imageQuality = 'original'; // 图片质量

  @observable
  Map<String, bool> shieldCategoryMap = Map.of(categoryMap); // 分类设置

  @observable
  Map<String, bool> shieldHomePageCategoriesMap =
      Map.of(homePageCategoriesMap); // 存储首页的屏蔽分类

  @observable
  bool signIn = false; // 签到状态

  @observable
  DateTime signInTime = DateTime.now().subtract(Duration(hours: 24)); // 签到时间

  // _BikaSetting() {
  //   _init();
  // }

  Future<void> initBox() async {
    _box = await Hive.openBox(BikaSettingBoxKeys.bikaSettingBox);
    account = getAccount();
    password = getPassword();
    authorization = getAuthorization();
    level = getLevel();
    checkIn = getCheckIn();
    proxy = getProxy();
    imageQuality = getImageQuality();
    shieldCategoryMap = getShieldCategoryMap();
    shieldHomePageCategoriesMap = getShieldHomePageCategories();
    signIn = getSignIn();
    signInTime = getSignInTime();
  }

  @action
  String getAccount() {
    account = _box.get(BikaSettingBoxKeys.account, defaultValue: '');
    return account;
  }

  @action
  void setAccount(String value) {
    account = value;
    _box.put(BikaSettingBoxKeys.account, value);
  }

  @action
  void deleteAccount() {
    account = '';
    _box.delete(BikaSettingBoxKeys.account);
  }

  @action
  String getPassword() {
    password = _box.get(BikaSettingBoxKeys.password, defaultValue: '');
    return password;
  }

  @action
  void setPassword(String value) {
    password = value;
    _box.put(BikaSettingBoxKeys.password, value);
  }

  @action
  void deletePassword() {
    password = '';
    _box.delete(BikaSettingBoxKeys.password);
  }

  @action
  String getAuthorization() {
    authorization =
        _box.get(BikaSettingBoxKeys.authorization, defaultValue: '');
    return authorization;
  }

  @action
  void setAuthorization(String value) {
    authorization = value;
    _box.put(BikaSettingBoxKeys.authorization, value);
  }

  @action
  void deleteAuthorization() {
    authorization = '';
    _box.delete(BikaSettingBoxKeys.authorization);
  }

  @action
  int getLevel() {
    level = _box.get(BikaSettingBoxKeys.level, defaultValue: 0);
    return level;
  }

  @action
  void setLevel(int value) {
    level = value;
    _box.put(BikaSettingBoxKeys.level, value);
  }

  @action
  void deleteLevel() {
    level = 0;
    _box.delete(BikaSettingBoxKeys.level);
  }

  @action
  bool getCheckIn() {
    checkIn = _box.get(BikaSettingBoxKeys.checkIn, defaultValue: false);
    return checkIn;
  }

  @action
  void setCheckIn(bool value) {
    checkIn = value;
    _box.put(BikaSettingBoxKeys.checkIn, value);
  }

  @action
  void deleteCheckIn() {
    checkIn = false;
    _box.delete(BikaSettingBoxKeys.checkIn);
  }

  @action
  int getProxy() {
    proxy = _box.get(BikaSettingBoxKeys.proxy, defaultValue: 3);
    return proxy;
  }

  @action
  void setProxy(int value) {
    proxy = value;
    _box.put(BikaSettingBoxKeys.proxy, value);
  }

  @action
  void deleteProxy() {
    proxy = 3;
    _box.delete(BikaSettingBoxKeys.proxy);
  }

  @action
  String getImageQuality() {
    imageQuality =
        _box.get(BikaSettingBoxKeys.imageQuality, defaultValue: 'original');
    return imageQuality;
  }

  @action
  void setImageQuality(String value) {
    imageQuality = value;
    _box.put(BikaSettingBoxKeys.imageQuality, value);
  }

  @action
  void deleteImageQuality() {
    imageQuality = 'original';
    _box.delete(BikaSettingBoxKeys.imageQuality);
  }

  @action
  Map<String, bool> getShieldCategoryMap() {
    var map = _box.get(BikaSettingBoxKeys.shieldCategoryMap,
        defaultValue: Map.of(categoryMap));
    shieldCategoryMap = Map<String, bool>.from(map); // 转换为 Map<String, bool>
    return shieldCategoryMap;
  }

  @action
  void setShieldCategoryMap(Map<String, bool> value) {
    shieldCategoryMap = Map<String, bool>.of(value);
    _box.put(BikaSettingBoxKeys.shieldCategoryMap, value);
  }

  @action
  void deleteShieldCategoryMap() {
    shieldCategoryMap = Map<String, bool>.of(categoryMap);
    _box.delete(BikaSettingBoxKeys.shieldCategoryMap);
  }

  @action
  Map<String, bool> getShieldHomePageCategories() {
    var map = _box.get(BikaSettingBoxKeys.shieldHomePageCategories,
        defaultValue: Map.of(homePageCategoriesMap));
    var categories = Map<String, bool>.from(map); // 转换为 Map<String, bool>
    return categories;
  }

  @action
  void setShieldHomeCategories(Map<String, bool> value) {
    shieldHomePageCategoriesMap = Map<String, bool>.of(value);
    _box.put(BikaSettingBoxKeys.shieldHomePageCategories, value);
  }

  @action
  void deleteShieldHomeCategories() {
    shieldHomePageCategoriesMap = Map<String, bool>.of(homePageCategoriesMap);
    _box.delete(BikaSettingBoxKeys.shieldHomePageCategories);
  }

  @action
  bool getSignIn() {
    signIn = _box.get(BikaSettingBoxKeys.signIn, defaultValue: false);
    return signIn;
  }

  @action
  void deleteSignIn() {
    signIn = false;
    _box.delete(BikaSettingBoxKeys.signIn);
  }

  @action
  void setSignIn(bool value) {
    signIn = value;
    _box.put(BikaSettingBoxKeys.signIn, value);
  }

  @action
  DateTime getSignInTime() {
    var dateTime = _box.get(BikaSettingBoxKeys.signInTime,
        defaultValue: DateTime.now().subtract(Duration(hours: 24)));
    signInTime = dateTime;
    return signInTime;
  }

  @action
  void setSignInTime(DateTime value) {
    signInTime = value;
    _box.put(BikaSettingBoxKeys.signInTime, value);
  }

  @action
  void deleteSignInTime() {
    signInTime = DateTime.utc(1970, 1, 1);
    _box.delete(BikaSettingBoxKeys.signInTime);
  }
}

class BikaSettingBoxKeys {
  static const String bikaSettingBox = 'bikaSettingBox'; // 哔咔设置存储盒
  static const String account = 'account'; // 账号
  static const String password = 'password'; // 密码
  static const String authorization = 'authorization'; // 授权码
  static const String level = 'level'; // 用户等级
  static const String checkIn = 'checkIn'; // 签到状态
  static const String shieldList = "shieldList"; // 签到状态
  static const String proxy = 'proxy'; // 分流设置
  static const String imageQuality = 'imageQuality'; // 图片质量
  static const String shieldCategoryMap = 'shieldCategoryMap'; // 屏蔽分类
  static const String shieldHomePageCategories =
      'shieldHomePageCategories'; // 首页屏蔽分类
  static const String signIn = 'signIn'; // 签到状态
  static const String signInTime = 'signInTime'; // 签到时间
}

// 哔咔的漫画分类
Map<String, bool> categoryMap = {
  "嗶咔漢化": false,
  "全彩": false,
  "長篇": false,
  "同人": false,
  "短篇": false,
  "圓神領域": false,
  "碧藍幻想": false,
  "CG雜圖": false,
  "英語 ENG": false,
  "生肉": false,
  "純愛": false,
  "百合花園": false,
  "後宮閃光": false,
  "扶他樂園": false,
  "耽美花園": false,
  "偽娘哲學": false,
  "單行本": false,
  "姐姐系": false,
  "妹妹系": false,
  "性轉換": false,
  "SM": false,
  "足の恋": false,
  "人妻": false,
  "NTR": false,
  "強暴": false,
  "非人類": false,
  "艦隊收藏": false,
  "Love Live": false,
  "SAO 刀劍神域": false,
  "Fate": false,
  "東方": false,
  "WEBTOON": false,
  "禁書目錄": false,
  "歐美": false,
  "Cosplay": false,
  "重口地帶": false,
};

// 首页的分类
Map<String, bool> homePageCategoriesMap = {
  "最近更新": false,
  "随机本子": false,
  "援助嗶咔": false,
  "嗶咔小禮物": false,
  "小電影": false,
  "小里番": false,
  "嗶咔畫廊": false,
  "嗶咔商店": false,
  "大家都在看": false,
  "大濕推薦": false,
  "那年今天": false,
  "官方都在看": false,
  "嗶咔運動": false,
  "嗶咔漢化": false,
  "全彩": false,
  "長篇": false,
  "同人": false,
  "短篇": false,
  "圓神領域": false,
  "碧藍幻想": false,
  "CG雜圖": false,
  "英語 ENG": false,
  "生肉": false,
  "純愛": false,
  "百合花園": false,
  "耽美花園": false,
  "偽娘哲學": false,
  "後宮閃光": false,
  "扶他樂園": false,
  "單行本": false,
  "姐姐系": false,
  "妹妹系": false,
  "SM": false,
  "性轉換": false,
  "足の恋": false,
  "人妻": false,
  "NTR": false,
  "強暴": false,
  "非人類": false,
  "艦隊收藏": false,
  "Love Live": false,
  "SAO 刀劍神域": false,
  "Fate": false,
  "東方": false,
  "WEBTOON": false,
  "禁書目錄": false,
  "歐美": false,
  "Cosplay": false,
  "重口地帶": false,
};
