import 'package:flutter/cupertino.dart';

// 此文件用于定义全局变量，也做部分初始化工作

// 用于存储屏幕宽度和高度
// 用于在不同页面之间传递数据
double screenWidth = 0;
double screenHeight = 0;
double statusBarHeight = 0;

class Global {
  final BuildContext context;

  Global(this.context) {
    // 在构造函数中初始化屏幕宽度和高度
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }
}

// 用来判断哔咔的用户信息是否加载完毕
bool loadBikaProfile = false;

late GlobalBIkaProfile globalBikaProfile;

class GlobalBIkaProfile {
  final int code;
  final String message;
  final GlobalBIkaData data;

  GlobalBIkaProfile({
    required this.code,
    required this.message,
    required this.data,
  });
}

class GlobalBIkaData {
  final GlobalBIkaUser user;

  GlobalBIkaData({required this.user});
}

class GlobalBIkaUser {
  final String id;
  final DateTime birthday;
  final String email;
  final String gender;
  final String name;
  final String slogan;
  final String title;
  final bool verified;
  final int exp;
  final String role;
  final int level;
  final List<String> characters;
  final DateTime createdAt;
  final GlobalBIkaAvatar avatar;
  final bool isPunched;
  final String character;

  GlobalBIkaUser({
    required this.id,
    required this.birthday,
    required this.email,
    required this.gender,
    required this.name,
    required this.slogan,
    required this.title,
    required this.verified,
    required this.exp,
    required this.role,
    required this.level,
    required this.characters,
    required this.createdAt,
    required this.avatar,
    required this.isPunched,
    required this.character,
  });
}

class GlobalBIkaAvatar {
  final String originalName;
  final String path;
  final String fileServer;

  GlobalBIkaAvatar({
    required this.originalName,
    required this.path,
    required this.fileServer,
  });
}
