import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/bookshelf/widgets/jm/cloud_favorite_page.dart';

class JmTabBar extends StatefulWidget {
  const JmTabBar({super.key});

  @override
  State<JmTabBar> createState() => _JmTabBarState();
}

class _JmTabBarState extends State<JmTabBar>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        int index = _tabController.index;
        final jmCubit = context.read<JmSettingCubit>();
        jmCubit.updateFavoriteSet(index);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelPadding: EdgeInsets.symmetric(horizontal: 10),
          tabs: [
            Tab(text: '本地'),
            Tab(text: '云端'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [const JmFavoritePage(), const JmCloudFavoritePage()],
          ),
        ),
      ],
    );
  }
}
