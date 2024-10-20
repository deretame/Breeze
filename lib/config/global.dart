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

  // 搜索界面信息
  CategoriesGlobal categories = CategoriesGlobal();

  Global(this.context) {
    // 在构造函数中初始化屏幕宽度和高度
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // 因为部分分类不在返回值中，所以需要在这里添加
    CategoryGlobal temp = CategoryGlobal(
      title: '哔咔排行榜',
      thumb: ThumbGlobal(originalName: '', path: '', fileServer: ''),
      isWeb: false,
      active: true,
      link: 'asset/image/bika_image/cat_leaderboard.jpg',
    );

    categories.categoriesGlobal.add(temp);

    temp = CategoryGlobal(
      title: '最近更新',
      thumb: ThumbGlobal(originalName: '', path: '', fileServer: ''),
      isWeb: false,
      active: true,
      link: 'asset/image/bika_image/cat_latest.jpg',
    );

    categories.categoriesGlobal.add(temp);

    temp = CategoryGlobal(
      title: '随机本子',
      thumb: ThumbGlobal(originalName: '', path: '', fileServer: ''),
      isWeb: false,
      active: true,
      link: 'asset/image/bika_image/cat_random.jpg',
    );

    categories.categoriesGlobal.add(temp);
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

// 存储屏蔽分类
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

// 分类信息
class CategoriesGlobal {
  late List<CategoryGlobal> categoriesGlobal;

  CategoriesGlobal() {
    categoriesGlobal = [];
  }

  // 排序方法，将isWeb为true的CategoryGlobal对象放在前面
  void sortCategoriesByIsWeb() {
    categoriesGlobal.sort((a, b) {
      if (b.isWeb && !a.isWeb) return 1; // 如果b是Web而a不是，b排在前面
      if (!b.isWeb && a.isWeb) return -1; // 如果a是Web而b不是，a排在前面
      return 0; // 如果两者都是Web或者都不是，保持原来的顺序
    });
  }
}

class CategoryGlobal {
  late String title;
  late ThumbGlobal thumb;
  late bool isWeb;
  late bool active;
  late String link;

  CategoryGlobal({
    required this.title,
    required this.thumb,
    required this.isWeb,
    required this.active,
    required this.link,
  });
}

class ThumbGlobal {
  late String originalName;
  late String path;
  late String fileServer;

  ThumbGlobal({
    required this.originalName,
    required this.path,
    required this.fileServer,
  });
}
