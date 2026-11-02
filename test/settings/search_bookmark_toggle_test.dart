import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/more/widgets/settings.dart';
import 'package:zephyr/page/setting/global/appearance_setting_page.dart';
import 'package:zephyr/page/setting/global/content_network_setting_page.dart';

class _TestGlobalSettingCubit extends GlobalSettingCubit {
  @override
  void updateState(GlobalSettingState Function(GlobalSettingState) updates) {
    emit(updates(state));
  }

  void setShowSearchBookmark(bool value) {
    emit(state.copyWith(showSearchBookmark: value));
  }
}

class _TestComicFollowCubit extends ComicFollowCubit {
  @override
  Future<void> loadFromDatabase() async {}
}

void main() {
  Future<void> pumpMore(WidgetTester tester, GlobalSettingCubit cubit) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GlobalSettingCubit>.value(value: cubit),
          BlocProvider<ComicFollowCubit>(
            create: (_) => _TestComicFollowCubit(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsWidget())),
      ),
    );
    await tester.pump();
  }

  testWidgets('更多页搜索书签入口跟随开关显示/隐藏', (tester) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    final cubit = _TestGlobalSettingCubit();

    await pumpMore(tester, cubit);
    expect(find.text(t.searchBookmark.title), findsOneWidget);

    cubit.setShowSearchBookmark(false);
    // BlocListener 收到流事件后 setState，第二帧才反映到树。
    await tester.pump();
    await tester.pump();
    expect(find.text(t.searchBookmark.title), findsNothing);

    cubit.setShowSearchBookmark(true);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.searchBookmark.title), findsOneWidget);
  });

  testWidgets('外观设置页开关可切换 showSearchBookmark', (tester) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    final cubit = _TestGlobalSettingCubit();
    await tester.pumpWidget(
      BlocProvider<GlobalSettingCubit>.value(
        value: cubit,
        child: const MaterialApp(home: AppearanceSettingPage()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text(t.settings.showSearchBookmark),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(t.settings.showSearchBookmark), findsOneWidget);
    await tester.tap(find.text(t.settings.showSearchBookmark));
    await tester.pump();
    expect(cubit.state.showSearchBookmark, isFalse);
  });

  testWidgets('内容与网络页的找回页数随开关隐藏', (tester) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    final cubit = _TestGlobalSettingCubit();
    await tester.pumpWidget(
      BlocProvider<GlobalSettingCubit>.value(
        value: cubit,
        child: const MaterialApp(home: ContentNetworkSettingPage()),
      ),
    );

    expect(find.text(t.searchBookmark.probePages), findsOneWidget);
    cubit.setShowSearchBookmark(false);
    await tester.pump();
    await tester.pump();
    expect(find.text(t.searchBookmark.probePages), findsNothing);
  });
}
