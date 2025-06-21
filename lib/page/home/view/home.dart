import 'package:auto_route/auto_route.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
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
  final _key = GlobalKey<ExpandableFabState>();
  String title = "哔咔漫画";
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 动画持续时间
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

    // 根据初始状态添加正确的监听器
    if (globalSetting.comicChoice == 1) {
      scrollControllers['category']?.addListener(_handleScroll);
      title = "哔咔漫画";
    } else {
      // 假设只有 1 和 2 两种情况
      scrollControllers['jmHome']?.addListener(_handleScroll);
      title = "禁漫首页";
    }
  }

  void _handleScroll() {
    // 根据当前的 comicChoice 获取正确的控制器
    final controller =
        globalSetting.comicChoice == 1
            ? scrollControllers['category']!
            : scrollControllers['jmHome']!;

    // 判断滚动方向
    if (controller.position.userScrollDirection == ScrollDirection.reverse) {
      // 向下滚动，播放动画隐藏FAB
      if (_animationController.status == AnimationStatus.completed) return;
      _animationController.forward();
    } else if (controller.position.userScrollDirection ==
        ScrollDirection.forward) {
      // 向上滚动，反向播放动画显示FAB
      if (_animationController.status == AnimationStatus.dismissed) return;
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    scrollControllers['category']!.removeListener(_handleScroll);
    scrollControllers['jmHome']!.removeListener(_handleScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: search),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => eventBus.fire(RefreshCategories()),
            child:
                globalSetting.comicChoice == 1
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: scrollControllers['category']!,
                      children: const [KeywordPage(), CategoryWidget()],
                    )
                    : const JmPromotePage(),
          ),
          floatingActionButtonLocation: ExpandableFab.location,
          floatingActionButton: SlideTransition(
            position: _slideAnimation, // 将动画应用到 position 属性
            child: ExpandableFab(
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
                      onPressed: comicChange,
                      child: Icon(Icons.compare_arrows),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(width: 20),
                    FloatingActionButton.small(
                      heroTag: null,
                      onPressed: goTop,
                      child: Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void search() {
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
                  SearchResultRoute(searchEnter: SearchEnter.initial()),
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
  }

  void comicChange() {
    // 1. 获取当前活动的 controller 的 key
    final currentKey = globalSetting.comicChoice == 1 ? 'category' : 'jmHome';
    // 2. 在切换视图前，从【当前活动】的 controller 移除监听器
    // 使用 ?. 安全调用，防止 controller 为 null 的情况
    scrollControllers[currentKey]?.removeListener(_handleScroll);

    // 3. 切换漫画源的状态
    if (globalSetting.comicChoice == 1) {
      globalSetting.setComicChoice(2);
    } else {
      globalSetting.setComicChoice(1);
    }

    // 4. 【关键】等待UI更新完成后，再为【新的】controller 添加监听器
    // addPostFrameCallback 保证在下一帧绘制完成时执行，此时新的 Widget 和它的 controller 已准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newKey = globalSetting.comicChoice == 1 ? 'category' : 'jmHome';
      scrollControllers[newKey]?.addListener(_handleScroll);

      // 检查 Widget 是否还在树中，然后更新标题并刷新UI
      if (mounted) {
        setState(() {
          title = globalSetting.comicChoice == 1 ? "哔咔漫画" : "禁漫首页";
        });
      }
    });

    // 5. 关闭 ExpandableFab
    final state = _key.currentState;
    if (state != null) {
      state.toggle();
    }
  }

  void goTop() {
    if (globalSetting.comicChoice == 1) {
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
  }
}
