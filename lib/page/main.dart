import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/page/user_profile/view/view.dart';

import '../main.dart';
import '../network/http/http_request.dart';
import 'home/view/home.dart';
import 'search/search_page.dart';
import 'setting/setting_page.dart';

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final bikaSetting = BikaSetting();
  late List<Widget> _pageList;
  late int index;
  late PageController _pageController;
  bool canPopNow = false;
  bool hasNewVersion = false;
  double? bottomNavigatorHeight;
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();

    _pageList = [
      HomePage(),
      RankingListPage(),
      SearchPage(),
      UserInfoPage(),
      SettingsPage(),
    ];
    index = globalSetting.welcomePageNum;
    _pageController = PageController(initialPage: index);
    _signIn();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bottomNavigatorHeight ??= MediaQuery.of(context).padding.bottom + 80;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > constraints.maxHeight;
        return PopScope(
          canPop: canPopNow,
          onPopInvokedWithResult: (didPop, dynamic) async {
            final now = DateTime.now();
            if (globalSetting.doubleReturn &&
                (currentBackPressTime == null ||
                    now.difference(currentBackPressTime!) >
                        const Duration(seconds: 2))) {
              currentBackPressTime = now;
              // 显示对话框提醒用户
              EasyLoading.showInfo("再按一次返回退出应用");
              setState(() {
                canPopNow = false;
              });
              return;
            } else {
              setState(() {
                canPopNow = true;
              });
              // 如果两次点击的时间间隔小于等于2秒，则退出应用
              await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              return; // 退出应用
            }
          },
          child: Scaffold(
            body: Row(children: [
              if (wide) ..._buildRail(context),
              Expanded(child: _buildPageView(context))
            ]),
            extendBody: true,
            bottomNavigationBar: wide
                ? null
                : Observer(
                    builder: (context) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        transform: Matrix4.translationValues(
                            0,
                            fullScreenStore.fullscreen
                                ? bottomNavigatorHeight!
                                : 0,
                            0),
                        child: _buildNavigationBar(context),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPageView(BuildContext context) {
    return Stack(
      children: [
        _buildPageContent(context),
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          right: 16,
          child: Observer(builder: (context) {
            return AnimatedToggleFullscreenFAB(
                isFullscreen: fullScreenStore.fullscreen,
                toggleFullscreen: toggleFullscreen);
          }),
        )
      ],
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return PageView.builder(
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _pageList[index];
      },
      onPageChanged: (index) {
        setState(() {
          this.index = index;
        });
      },
      controller: _pageController,
      itemCount: _pageList.length,
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: NavigationBar(
          height: 68,
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.9),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: "首页"),
            NavigationDestination(icon: Icon(Icons.leaderboard), label: "排行"),
            NavigationDestination(icon: Icon(Icons.search), label: "搜索"),
            NavigationDestination(icon: Icon(Icons.person), label: "个人"),
            NavigationDestination(icon: Icon(Icons.settings), label: "设置")
          ],
          selectedIndex: index,
          onDestinationSelected: (index) {
            setState(() {
              this.index = index;
            });
            if (_pageController.hasClients) _pageController.jumpToPage(index);
          },
        ),
      ),
    );
  }

  List<Widget> _buildRail(BuildContext context) {
    return [
      Stack(
        children: [
          NavigationRail(
            selectedIndex: index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (int index) {
              _pageController.jumpToPage(index);
              setState(() {
                index = index;
              });
            },
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                  icon: Icon(Icons.home), label: Text("首页")),
              NavigationRailDestination(
                  icon: Icon(Icons.leaderboard), label: Text("排行")),
              NavigationRailDestination(
                  icon: Icon(Icons.search), label: Text("搜索")),
              NavigationRailDestination(
                  icon: Icon(Icons.person), label: Text("个人")),
              NavigationRailDestination(
                  icon: Icon(Icons.settings), label: Text("设置")),
            ],
          ),
        ],
      ),
      const VerticalDivider(thickness: 1, width: 1),
    ];
  }

  void toggleFullscreen() {
    fullScreenStore.toggle();
  }
}

// 用来实现退出全屏功能的FAB
class AnimatedToggleFullscreenFAB extends StatefulWidget {
  final bool isFullscreen;
  final Function toggleFullscreen;

  const AnimatedToggleFullscreenFAB({
    super.key,
    required this.isFullscreen,
    required this.toggleFullscreen,
  });

  @override
  State<AnimatedToggleFullscreenFAB> createState() =>
      _AnimatedToggleFullscreenFABState();
}

class _AnimatedToggleFullscreenFABState
    extends State<AnimatedToggleFullscreenFAB>
    with SingleTickerProviderStateMixin {
  // 用动画实现滑动出现效果
  late final Animation<Offset> _offsetAnimation = Tween<Offset>(
    begin: const Offset(0.0, 4.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.linear,
  ));
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  @override
  void didUpdateWidget(covariant AnimatedToggleFullscreenFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFullscreen != widget.isFullscreen) {
      if (widget.isFullscreen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.isFullscreen,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SizedBox(
          child: FloatingActionButton(
            onPressed: () {
              widget.toggleFullscreen();
            },
            child: Icon(
              Icons.close_fullscreen,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _signIn() async {
  // 获取当前时间
  DateTime now = DateTime.now();

  // 获取今天的日期
  DateTime today = DateTime(now.year, now.month, now.day, 16); // 今天4点的时间

  try {
    if (!bikaSetting.getSignInTime().isBefore(today)) {
      debugPrint("自动签到成功！");
      return;
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  while (true) {
    try {
      var result = await signIn();
      if (result.toString().contains("success")) {
        bikaSetting.setSignInTime(DateTime.now());
        bikaSetting.setSignIn(true);
        EasyLoading.showSuccess("自动签到成功！");
        debugPrint("自动签到成功！");
        break;
      }
    } catch (e) {
      debugPrint(e.toString());
      continue;
    }
  }
}
