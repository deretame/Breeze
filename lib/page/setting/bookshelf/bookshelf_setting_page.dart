import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class BookshelfSettingPage extends StatefulWidget {
  const BookshelfSettingPage({super.key});

  @override
  State<BookshelfSettingPage> createState() => _BookshelfSettingPageState();
}

class _BookshelfSettingPageState extends State<BookshelfSettingPage> {
  late final List<String> _homePageLabels = [
    t.bookshelf.favorite,
    t.bookshelf.history,
    t.bookshelf.download,
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state.bookshelfSetting;

    return SettingPageShell(
      title: t.settings.bookshelf,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.bookshelf,
            icon: Icons.collections_bookmark_outlined,
          ),
          _homePageTile(state, cubit),
          const Divider(height: 1, thickness: 0.3),
          _rememberSortTile(
            icon: Icons.favorite_outline,
            title: t.settings.bookshelfRememberFavoriteSort,
            subtitle: t.settings.bookshelfRememberFavoriteSortSubtitle,
            value: state.rememberFavoriteSort,
            onChanged: (value) => cubit.updateBookshelfSetting(
              (current) => current.copyWith(rememberFavoriteSort: value),
            ),
          ),
          const Divider(height: 1, thickness: 0.3),
          _rememberSortTile(
            icon: Icons.history_outlined,
            title: t.settings.bookshelfRememberHistorySort,
            subtitle: t.settings.bookshelfRememberHistorySortSubtitle,
            value: state.rememberHistorySort,
            onChanged: (value) => cubit.updateBookshelfSetting(
              (current) => current.copyWith(rememberHistorySort: value),
            ),
          ),
          const Divider(height: 1, thickness: 0.3),
          _rememberSortTile(
            icon: Icons.download_outlined,
            title: t.settings.bookshelfRememberDownloadSort,
            subtitle: t.settings.bookshelfRememberDownloadSortSubtitle,
            value: state.rememberDownloadSort,
            onChanged: (value) => cubit.updateBookshelfSetting(
              (current) => current.copyWith(rememberDownloadSort: value),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _homePageTile(BookshelfSettingState state, GlobalSettingCubit cubit) {
    final index = state.homePageIndex.clamp(0, _homePageLabels.length - 1);
    final items = {
      for (var i = 0; i < _homePageLabels.length; i++) i: _homePageLabels[i],
    };

    return ListTile(
      leading: const Icon(Icons.home_outlined),
      title: Text(t.settings.bookshelfHomePage),
      subtitle: Text(t.settings.bookshelfHomePageSubtitle),
      trailing: FluentDropdown<int>(
        value: index,
        displayValue: _homePageLabels[index],
        items: items,
        onChanged: (int value) {
          if (value == index) return;
          cubit.updateBookshelfSetting(
            (current) => current.copyWith(homePageIndex: value),
          );
          showSuccessToast(t.common.settingSaved);
        },
      ),
    );
  }

  Widget _rememberSortTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: value,
      onChanged: (bool newValue) {
        onChanged(newValue);
        showSuccessToast(t.common.settingSaved);
      },
    );
  }
}
