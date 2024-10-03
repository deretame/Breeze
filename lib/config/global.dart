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

class Global {
  final BuildContext context;

  Global(this.context) {
    // 在构造函数中初始化屏幕宽度和高度
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }
}
