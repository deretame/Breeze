import 'package:flutter/cupertino.dart';

// 此文件用于定义全局变量，也做部分初始化工作

// 用于存储屏幕宽度和高度
// 用于在不同页面之间传递数据
double screenWidth = 0;
double screenHeight = 0;

// 用于判断是否已经初始化完成
bool inited = false;

// 分流设置
int shunt = 3;

// realm数据库版本号
int shieldedCategoriesVersion = 0;

class Global {
  final BuildContext context;

  Global(this.context) {
    // 在构造函数中初始化屏幕宽度和高度
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }
}

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

Map<String, bool> shieldCategoryMapRealm = {
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
