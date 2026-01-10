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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final jmCubit = context.watch<JmSettingCubit>();
    return jmCubit.state.favoriteSet == 1
        ? const JmFavoritePage()
        : const JmCloudFavoritePage();
  }
}
