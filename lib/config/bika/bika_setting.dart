// 存储哔咔的设置和账号信息
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/main.dart';

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
    emit(objectbox.userSettingBox.get(1)!.bikaSetting);
  }

  // --- update / reset 方法 ---

  void updateAccount(String value) {
    final temp = state.copyWith(account: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetAccount() {
    final temp = state.copyWith(account: _constDefaults.account);
    updateDataBase(temp);
    emit(temp);
  }

  void updatePassword(String value) {
    final temp = state.copyWith(password: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetPassword() {
    final temp = state.copyWith(password: _constDefaults.password);
    updateDataBase(temp);
    emit(temp);
  }

  void updateAuthorization(String value) {
    final temp = state.copyWith(authorization: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetAuthorization() {
    final temp = state.copyWith(authorization: _constDefaults.authorization);
    updateDataBase(temp);
    emit(temp);
  }

  void updateLevel(int value) {
    final temp = state.copyWith(level: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetLevel() {
    final temp = state.copyWith(level: _constDefaults.level);
    updateDataBase(temp);
    emit(temp);
  }

  void updateCheckIn(bool value) {
    final temp = state.copyWith(checkIn: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetCheckIn() {
    final temp = state.copyWith(checkIn: _constDefaults.checkIn);
    updateDataBase(temp);
    emit(temp);
  }

  void updateProxy(int value) {
    final temp = state.copyWith(proxy: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetProxy() {
    final temp = state.copyWith(proxy: _defaultProxy);
    updateDataBase(temp);
    emit(temp);
  }

  void updateImageQuality(String value) {
    final temp = state.copyWith(imageQuality: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetImageQuality() {
    final temp = state.copyWith(imageQuality: _defaultImageQuality);
    updateDataBase(temp);
    emit(temp);
  }

  void updateShieldCategoryMap(Map<String, bool> value) {
    final temp = state.copyWith(shieldCategoryMap: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetShieldCategoryMap() {
    final temp = state.copyWith(shieldCategoryMap: _defaultShieldCategoryMap);
    updateDataBase(temp);
    emit(temp);
  }

  void updateShieldHomePageCategoriesMap(Map<String, bool> value) {
    final temp = state.copyWith(shieldHomePageCategoriesMap: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetShieldHomePageCategoriesMap() {
    final temp = state.copyWith(
      shieldHomePageCategoriesMap: _defaultShieldHomePageCategoriesMap,
    );
    updateDataBase(temp);
    emit(temp);
  }

  void updateSignIn(bool value) {
    final temp = state.copyWith(signIn: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSignIn() {
    final temp = state.copyWith(signIn: _constDefaults.signIn);
    updateDataBase(temp);
    emit(temp);
  }

  void updateBrevity(bool value) {
    final temp = state.copyWith(brevity: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetBrevity() {
    final temp = state.copyWith(brevity: _constDefaults.brevity);
    updateDataBase(temp);
    emit(temp);
  }

  void updateSlowDownload(bool value) {
    final temp = state.copyWith(slowDownload: value);
    updateDataBase(temp);
    emit(temp);
  }

  void resetSlowDownload() {
    final temp = state.copyWith(slowDownload: _constDefaults.slowDownload);
    updateDataBase(temp);
    emit(temp);
  }

  void updateDataBase(BikaSettingState state) {
    final userBox = objectbox.userSettingBox;
    var dbSettings = userBox.get(1)!;
    dbSettings.bikaSetting = state;
    userBox.put(dbSettings);
  }
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
