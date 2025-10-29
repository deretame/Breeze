// 存储哔咔的设置和账号信息
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'bika_setting.freezed.dart';
part 'bika_setting.g.dart';

@freezed
abstract class BikaSettingState with _$BikaSettingState {
  const factory BikaSettingState({
    @Default('') String account,
    @Default('') String password,
    @Default('') String authorization,
    @Default(0) int level,
    @Default(false) bool checkIn,
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

// -----------------------------------------------------------------
// 步骤 4: Cubit 逻辑类
// -----------------------------------------------------------------
class BikaSettingCubit extends Cubit<BikaSettingState> {
  late final Box<dynamic> _box;

  BikaSettingCubit() : super(const BikaSettingState());

  static const _constDefaults = BikaSettingState();
  static final Map<String, bool> _defaultShieldCategoryMap = Map.of(
    categoryMap,
  );
  static final Map<String, bool> _defaultShieldHomePageCategoriesMap = Map.of(
    homePageCategoriesMap,
  );

  static const String _defaultImageQuality = 'original';
  static const int _defaultProxy = 3;

  Future<void> initBox() async {
    _box = await Hive.openBox(BikaSettingBoxKeys.bikaSettingBox);

    final dynamic shieldMapRaw = _box.get(
      BikaSettingBoxKeys.shieldCategoryMap,
      defaultValue: _defaultShieldCategoryMap,
    );
    final dynamic homeShieldMapRaw = _box.get(
      BikaSettingBoxKeys.shieldHomePageCategories,
      defaultValue: _defaultShieldHomePageCategoriesMap,
    );

    emit(
      state.copyWith(
        account: _box.get(
          BikaSettingBoxKeys.account,
          defaultValue: _constDefaults.account,
        ),
        password: _box.get(
          BikaSettingBoxKeys.password,
          defaultValue: _constDefaults.password,
        ),
        authorization: _box.get(
          BikaSettingBoxKeys.authorization,
          defaultValue: _constDefaults.authorization,
        ),
        level: _box.get(
          BikaSettingBoxKeys.level,
          defaultValue: _constDefaults.level,
        ),
        checkIn: _box.get(
          BikaSettingBoxKeys.checkIn,
          defaultValue: _constDefaults.checkIn,
        ),
        proxy: _box.get(BikaSettingBoxKeys.proxy, defaultValue: _defaultProxy),
        imageQuality: _box.get(
          BikaSettingBoxKeys.imageQuality,
          defaultValue: _defaultImageQuality,
        ),
        shieldCategoryMap: Map<String, bool>.from(shieldMapRaw),
        shieldHomePageCategoriesMap: Map<String, bool>.from(homeShieldMapRaw),
        signIn: _box.get(
          BikaSettingBoxKeys.signIn,
          defaultValue: _constDefaults.signIn,
        ),
        brevity: _box.get(
          BikaSettingBoxKeys.brevity,
          defaultValue: _constDefaults.brevity,
        ),
        slowDownload: _box.get(
          BikaSettingBoxKeys.slowDownload,
          defaultValue: _constDefaults.slowDownload,
        ),
      ),
    );
  }

  // --- update / reset 方法 ---

  void updateAccount(String value) {
    _box.put(BikaSettingBoxKeys.account, value);
    emit(state.copyWith(account: value));
  }

  void resetAccount() {
    _box.delete(BikaSettingBoxKeys.account);
    emit(state.copyWith(account: _constDefaults.account));
  }

  void updatePassword(String value) {
    _box.put(BikaSettingBoxKeys.password, value);
    emit(state.copyWith(password: value));
  }

  void resetPassword() {
    _box.delete(BikaSettingBoxKeys.password);
    emit(state.copyWith(password: _constDefaults.password));
  }

  void updateAuthorization(String value) {
    _box.put(BikaSettingBoxKeys.authorization, value);
    emit(state.copyWith(authorization: value));
  }

  void resetAuthorization() {
    _box.delete(BikaSettingBoxKeys.authorization);
    emit(state.copyWith(authorization: _constDefaults.authorization));
  }

  void updateLevel(int value) {
    _box.put(BikaSettingBoxKeys.level, value);
    emit(state.copyWith(level: value));
  }

  void resetLevel() {
    _box.delete(BikaSettingBoxKeys.level);
    emit(state.copyWith(level: _constDefaults.level));
  }

  void updateCheckIn(bool value) {
    _box.put(BikaSettingBoxKeys.checkIn, value);
    emit(state.copyWith(checkIn: value));
  }

  void resetCheckIn() {
    _box.delete(BikaSettingBoxKeys.checkIn);
    emit(state.copyWith(checkIn: _constDefaults.checkIn));
  }

  void updateProxy(int value) {
    _box.put(BikaSettingBoxKeys.proxy, value);
    emit(state.copyWith(proxy: value));
  }

  void resetProxy() {
    _box.delete(BikaSettingBoxKeys.proxy);
    emit(state.copyWith(proxy: _defaultProxy));
  }

  void updateImageQuality(String value) {
    _box.put(BikaSettingBoxKeys.imageQuality, value);
    emit(state.copyWith(imageQuality: value));
  }

  void resetImageQuality() {
    _box.delete(BikaSettingBoxKeys.imageQuality);
    emit(state.copyWith(imageQuality: _defaultImageQuality));
  }

  void updateShieldCategoryMap(Map<String, bool> value) {
    _box.put(BikaSettingBoxKeys.shieldCategoryMap, value);
    emit(state.copyWith(shieldCategoryMap: value));
  }

  void resetShieldCategoryMap() {
    _box.delete(BikaSettingBoxKeys.shieldCategoryMap);
    emit(state.copyWith(shieldCategoryMap: _defaultShieldCategoryMap));
  }

  void updateShieldHomePageCategoriesMap(Map<String, bool> value) {
    // 你的 MobX store 有一个拼写错误 (setShieldHomeCategories)
    // 我在这里纠正了: shieldHomePageCategoriesMap
    _box.put(BikaSettingBoxKeys.shieldHomePageCategories, value);
    emit(state.copyWith(shieldHomePageCategoriesMap: value));
  }

  void resetShieldHomePageCategoriesMap() {
    _box.delete(BikaSettingBoxKeys.shieldHomePageCategories);
    emit(
      state.copyWith(
        shieldHomePageCategoriesMap: _defaultShieldHomePageCategoriesMap,
      ),
    );
  }

  void updateSignIn(bool value) {
    _box.put(BikaSettingBoxKeys.signIn, value);
    emit(state.copyWith(signIn: value));
  }

  void resetSignIn() {
    _box.delete(BikaSettingBoxKeys.signIn);
    emit(state.copyWith(signIn: _constDefaults.signIn));
  }

  void updateBrevity(bool value) {
    _box.put(BikaSettingBoxKeys.brevity, value);
    emit(state.copyWith(brevity: value));
  }

  void resetBrevity() {
    _box.delete(BikaSettingBoxKeys.brevity);
    emit(state.copyWith(brevity: _constDefaults.brevity));
  }

  void updateSlowDownload(bool value) {
    _box.put(BikaSettingBoxKeys.slowDownload, value);
    emit(state.copyWith(slowDownload: value));
  }

  void resetSlowDownload() {
    _box.delete(BikaSettingBoxKeys.slowDownload);
    emit(state.copyWith(slowDownload: _constDefaults.slowDownload));
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
  static const String brevity = 'brevity'; // 精简漫画展示
  static const String slowDownload = 'slowDownload'; // 慢速下载
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
