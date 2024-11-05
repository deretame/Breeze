import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';

import '../../../../config/global.dart';
import '../../../../type/search_enter.dart';
import '../widget/comic_list_widget.dart';

class ComicSearchPage extends StatefulWidget {
  final SearchEnter enter;

  const ComicSearchPage({super.key, required this.enter});

  @override
  State<ComicSearchPage> createState() => _ComicSearchPageState();
}

class _ComicSearchPageState extends State<ComicSearchPage> {
  SearchEnter get enter => widget.enter;
  final TextEditingController _controller = TextEditingController(text: '');
  late SearchEnter _localEnter;
  late String _keyword;
  late String _sort;
  late final List<String> _sortList = ["dd", "da", "ld", "vd"];
  late final Map<String, String> _sortMap = {
    "dd": "从新到旧",
    "da": "从旧到新",
    "ld": "最多点赞",
    "vd": "最多观看",
  };
  late int _pageCount;
  late List<String> _categories;
  late Map<String, bool> _categoriesMap;
  late Map<String, bool> _shieldCategoriesMap;

  // 这个是用来通知刷新的，所以值其实不重要，用int只是为了方便改变值而已
  late int refresh = 0;

  final ValueNotifier<int> _pageCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalCountNotifier = ValueNotifier<int>(0);
  int totalCount = 0;

  late TextEditingController inputController;
  late FocusNode focusNode;
  late FocusScopeNode focusScopeNode;

  // 仅作为跳页使用
  int pageSkip = 0;

  @override
  void initState() {
    super.initState();
    _localEnter = enter;
    _keyword = enter.keyword;
    _sort = enter.sort;
    _pageCount = enter.pageCount;
    _controller.text = _keyword;
    // 如果列表中有值，则将其设置为true
    for (var categories in enter.categories) {
      if (_categoriesMap.containsKey(categories)) {
        _categoriesMap[categories] = true;
      }
    }
    _categories = [];
    // 遍历Map，检查每个值，如果为true，则将键添加到列表中
    _categoriesMap.forEach((key, value) {
      if (value == true) {
        _categories.add(key); // 如果值为true，则将键添加到列表中
      }
    });

    _pageCountNotifier.value = _pageCount;

    _shieldCategoriesMap = {};
    _shieldCategoriesMap = bikaSetting.getShieldCategoryMap();

    inputController = TextEditingController();
    focusNode = FocusNode();
    focusScopeNode = FocusScopeNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    inputController.dispose();
    focusNode.dispose();
    focusScopeNode.dispose();
    super.dispose();
  }

  Future<void> _showCategoryDialog(BuildContext context) {
    // 在弹出对话框之前保存原始的_categoriesMap副本
    final Map<String, bool> originalCategoriesMap = Map.from(_categoriesMap);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择分类'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Widget> checkboxes = [];
              _categoriesMap.forEach((key, value) {
                checkboxes.add(
                  CheckboxListTile(
                    title: Text(key),
                    value: _categoriesMap[key],
                    onChanged: (bool? newValue) {
                      setState(() {
                        _categoriesMap[key] = newValue!;
                      });
                    },
                  ),
                );
              });
              return SizedBox(
                width: screenWidth * 0.8, // 设置对话框宽度
                height: screenHeight * 0.6, // 设置对话框高度
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: checkboxes,
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                // 点击取消时，恢复原始的_categoriesMap
                _categoriesMap = originalCategoriesMap;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('提交'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        debugPrint('Checkbox values: $value');
      }
    });
  }

  Future<void> _showShieldCategoryDialog(BuildContext context) {
    _shieldCategoriesMap = {};
    _shieldCategoriesMap = bikaSetting.getShieldCategoryMap();

    // 在弹出对话框之前保存原始的_categoriesMap副本
    final Map<String, bool> originalCategoriesMap =
        Map.from(_shieldCategoriesMap);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择屏蔽分类'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              List<Widget> checkboxes = [];
              _shieldCategoriesMap.forEach((key, value) {
                checkboxes.add(
                  CheckboxListTile(
                    title: Text(key),
                    value: _shieldCategoriesMap[key],
                    onChanged: (bool? newValue) {
                      setState(() {
                        _shieldCategoriesMap[key] = newValue!;
                      });
                    },
                  ),
                );
              });
              return SizedBox(
                width: screenWidth * 0.8, // 设置对话框宽度
                height: screenHeight * 0.6, // 设置对话框高度
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: checkboxes,
                  ),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                // 点击取消时，恢复原始的_categoriesMap
                _shieldCategoriesMap = originalCategoriesMap;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('提交'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        debugPrint('Checkbox values: $value');
      }
    });
  }

  void _handleNotification(List<int> data) {
    // 处理通知和接收到的int数据
    totalCount = data[0];
    _totalCountNotifier.value = totalCount; // 更新 notifier
    debugPrint("刷新页面，新的totalCount为：$totalCount");
    _pageCount = data[1];
    _pageCountNotifier.value = _pageCount; // 更新 notifier
    debugPrint("刷新页面，新的pageCount为：$_pageCount");
  }

  Future<void> _showNumberInputDialog() async {
    bool isDialogOpen = true;
    // 在显示对话框之前清空输入控制器的内容
    inputController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext innerContext) {
        // 在AlertDialog构建时立即请求焦点
        FocusScope.of(innerContext).requestFocus(focusNode);

        return AlertDialog(
          title: Text('输入页数'),
          content: TextField(
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: InputDecoration(hintText: '请输入页数（仅支持数字）'),
            controller: inputController,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                String number = inputController.text;
                pageSkip = int.parse(number);
                debugPrint('输入的数字是: $number');
              }
              isDialogOpen = false;
              Navigator.of(innerContext).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                isDialogOpen = false;
                pageSkip = 0;
                Navigator.of(innerContext).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () {
                String number = inputController.text;
                if (number.isNotEmpty) {
                  pageSkip = int.parse(number);
                  debugPrint('输入的数字是: $number');
                }
                isDialogOpen = false;
                Navigator.of(innerContext).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (isDialogOpen) {
        focusNode.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String label = "搜索本子";

    if (_categories.isNotEmpty) {
      String temp = _categories.join('、');
      label = ("分类：$temp");
    }

    if (_keyword.isNotEmpty) {
      label = ("搜索：$_keyword");
    }

    return Scaffold(
      appBar: AppBar(
        //清除title左右的padding，默认会有一定的距离
        titleSpacing: 0,
        elevation: 0,
        title: AnimatedSearchBar(
          label: label,
          controller: _controller,
          labelStyle: TextStyle(
            color: globalSetting.textColor,
            fontWeight: FontWeight.normal,
          ),
          searchStyle: TextStyle(color: globalSetting.textColor),
          cursorColor: globalSetting.textColor,
          searchDecoration: InputDecoration(
            labelText: '搜索本子',
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          textInputAction: TextInputAction.done,
          // 动画效果，似乎没有用
          // animationDuration: const Duration(seconds: 5),
          onFieldSubmitted: ((value) {
            debugPrint("value on Change : $value");
            // 检查新旧文本是否相同
            setState(
              () {
                _keyword = value;
                _localEnter = SearchEnter(
                  keyword: _keyword,
                  pageCount: 1,
                  sort: _sort,
                  categories: _categories,
                );
              },
            );
          }),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                SizedBox(height: 35), // 为顶部阴影容器预留空间
                Expanded(
                  child: ComicListWidget(
                    enter: _localEnter,
                    updatePageCount: _handleNotification,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                color: globalSetting.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: globalSetting.themeType
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 5,
                  ),
                  DropdownButton<String>(
                    value: _sort,
                    icon: const Icon(Icons.expand_more),
                    elevation: 16,
                    // style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      // color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        _sort = value!;
                        setState(
                          () {
                            _localEnter = SearchEnter(
                              keyword: _keyword,
                              sort: _sort,
                              pageCount: 1,
                              categories: _categories,
                            );
                          },
                        );
                      });
                    },
                    items:
                        _sortList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_sortMap[value]!),
                      );
                    }).toList(),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () {
                      var oldCategoriesMap = Map.of(_categoriesMap);
                      _showCategoryDialog(context).then((_) {
                        // 这个回调会在对话框关闭后执行
                        if (!const MapEquality()
                            .equals(_categoriesMap, oldCategoriesMap)) {
                          setState(() {
                            _categories = [];
                            _categoriesMap.forEach((key, value) {
                              if (value == true) {
                                _categories.add(key);
                              }
                            });
                            _localEnter = SearchEnter(
                              keyword: _keyword,
                              sort: _sort,
                              pageCount: 1,
                              categories: _categories,
                            );
                          });
                        }
                      });
                    },
                    child: Row(
                      children: <Widget>[
                        Text(
                          "分类",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Icon(Icons.expand_more)
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () {
                      var oldCategoriesMap = Map.of(_shieldCategoriesMap);
                      _showShieldCategoryDialog(context).then(
                        (_) {
                          // 这个回调会在对话框关闭后执行
                          if (!const MapEquality()
                              .equals(_shieldCategoriesMap, oldCategoriesMap)) {
                            bikaSetting
                                .setShieldCategoryMap(_shieldCategoriesMap);

                            setState(
                              () {
                                debugPrint("点击屏蔽分类");
                                _categories = [];
                                _categoriesMap.forEach((key, value) {
                                  if (value == true) {
                                    _categories.add(key);
                                  }
                                });
                                refresh = refresh + 1;
                                _localEnter = SearchEnter(
                                  keyword: _keyword,
                                  sort: _sort,
                                  pageCount: 1,
                                  categories: _categories,
                                  refresh: refresh,
                                );
                              },
                            );
                          }
                        },
                      );
                    },
                    child: Row(
                      children: <Widget>[
                        Text(
                          "屏蔽分类",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        Icon(Icons.expand_more)
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  Row(
                    children: <Widget>[
                      ValueListenableBuilder<int>(
                        valueListenable: _pageCountNotifier,
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _totalCountNotifier,
                        builder: (context, value, child) {
                          return Text(
                            '/$value',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showNumberInputDialog().then((_) {
            if (_pageCount != pageSkip && pageSkip != 0) {
              setState(
                () {
                  _localEnter = SearchEnter(
                    keyword: _keyword,
                    sort: _sort,
                    pageCount: pageSkip,
                    categories: _categories,
                  );
                },
              );
            }
          });
        },
        label: Text('跳页'),
        // icon: Icon(Icons.arrow_upward),
        // backgroundColor: Colors.blue, // 自定义背景颜色
      ),
    );
  }
}
