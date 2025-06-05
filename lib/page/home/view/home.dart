import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/widgets/top_tab_bar.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';
import '../../search_result/models/search_enter.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  final _key = GlobalKey<ExpandableFabState>();
  String title = "哔咔漫画";
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 动画持续时间
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // 初始位置
      end: const Offset(0, 2),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut, // 动画曲线
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    children: [
                      // 第一个 Chip
                      SimpleDialogOption(
                        onPressed: () {
                          context.pop();
                          context.pushRoute(
                            SearchResultRoute(
                              searchEnter: SearchEnter.initial(),
                            ),
                          );
                        },
                        child: const Chip(
                          label: Text("哔咔漫画"),
                          backgroundColor: Colors.pink,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                      // 第二个 Chip
                      SimpleDialogOption(
                        onPressed: () {
                          context.pop();
                          context.pushRoute(
                            JmSearchResultRoute(event: JmSearchResultEvent()),
                          );
                        },
                        child: const Chip(
                          label: Text("禁漫天堂"),
                          backgroundColor: Colors.orange,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_currentIndex == 1) {
            eventBus.fire(RefreshCategories());
          } else {
            // TODO：添加刷新禁漫界面的功能
          }
        },
        child:
            _currentIndex == 1
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: scrollControllers['category']!,
                  children: const [KeywordPage(), CategoryWidget()],
                )
                : const JmPromotePage(),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: _key,
        // childrenAnimation: ExpandableFabAnimation.rotate,
        distance: 70,
        overlayStyle: ExpandableFabOverlayStyle(
          color: globalSetting.backgroundColor.withValues(alpha: 0.9),
        ),
        children: [
          Row(
            children: [
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: Uuid(),
                onPressed: () {
                  _currentIndex == 1 ? _currentIndex = 2 : _currentIndex = 1;
                  title = _currentIndex == 1 ? "哔咔漫画" : "禁漫首页";
                  setState(() {});
                  final state = _key.currentState;
                  if (state != null) {
                    state.toggle();
                  }
                },
                child: Icon(Icons.compare_arrows),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                onPressed: () {
                  if (_currentIndex == 1) {
                    scrollControllers['category']!.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    scrollControllers['jmHome']!.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  final state = _key.currentState;
                  if (state != null) {
                    state.toggle();
                  }
                },
                child: Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
