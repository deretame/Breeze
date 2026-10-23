import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/bloc/folder_shelf_bloc.dart';
import 'package:zephyr/page/bookshelf/cubit/bookshelf_search_cubit.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/widgets/folder_shelf_page.dart';

import '../test_helper.dart';

/// 书架文件夹返回：进子文件夹后按系统返回逐级回退，到根放行。
///
/// 回归背景：书架 tab 嵌在 PersistentTabView 内部 Navigator 里，文件夹下钻
/// 是 bloc 状态而非路由 push；该库在非首页 tab 按返回时内部 `canPop == false`
/// 就直接切回首页，tab 内部的 PopScope 永远收不到事件（三导航时代书架是
/// tab 0，库走 maybePop 转发，所以没暴露）。
/// 修复用 LocalHistoryEntry 把「待处理返回」注册到 tab 内部路由上：
/// 有 entry → 库正常 pop → entry 消费 → bloc 回退一级；
/// 到根（entry 已清）→ 放行，库按既有逻辑切 tab/退应用。
///
/// 注意：testWidgets 测试体跑在 FakeAsync zone，真异步（ObjectBox IO、
/// worker isolate 握手/回包）必须包在 tester.runAsync 里走真实时间，
/// 否则零 CPU 卡死；pump 只负责刷 microtask + 重建帧。
void main() {
  // setUpAll 跑在真实 zone，可以直接做真异步初始化。
  setUpAll(() async {
    await TestObjectBoxHelper.setUpTestObjectBox();
    // worker isolate 的 ObjectBox 指向同一测试库（attach 共享），
    // 否则 load 读不到测试建的数据。
    debugShelfDbRootPath = TestObjectBoxHelper.tempPath;
    await workerManager.init(isolatesCount: 1);
  });
  tearDownAll(() async {
    await workerManager.dispose();
    debugShelfDbRootPath = null;
    await TestObjectBoxHelper.tearDownTestObjectBox();
  });
  tearDown(TestObjectBoxHelper.cleanComicFolderBoxes);

  /// 等指定文案出现：真实等待让 worker 回包，pump 刷重建。
  /// loading 态有 shimmer 无限动画，不能用 pumpAndSettle。
  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 150; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.text(text).evaluate().isNotEmpty) return;
    }
    throw StateError('等待 "$text" 出现超时');
  }

  /// 等指定文案消失（load 完成后文件夹行不再出现）。
  Future<void> waitForTextGone(WidgetTester tester, String text) async {
    for (var i = 0; i < 150; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.text(text).evaluate().isEmpty) return;
    }
    throw StateError('等待 "$text" 消失超时');
  }

  Future<void> pumpShelf(WidgetTester tester) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.useDeviceLocale());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GlobalSettingCubit>(create: (_) => GlobalSettingCubit()),
          BlocProvider<BookshelfSearchCubit>(
            create: (_) => BookshelfSearchCubit(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FolderShelfPage(mode: ShelfPageMode.favorite, isActive: true),
          ),
        ),
      ),
    );
  }

  testWidgets('进两级文件夹后返回逐级回退，到根放行', (tester) async {
    await tester.runAsync(() async {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );
    });

    await pumpShelf(tester);
    await waitForText(tester, 'parent');

    // 进 parent，再进 child。
    await tester.tap(find.text('parent'));
    await waitForText(tester, 'child');
    expect(find.text('parent'), findsNothing);

    await tester.tap(find.text('child'));
    // child 为空文件夹：load 完成后文件夹行消失（显示空态）。
    await waitForTextGone(tester, 'child');

    // 第一次返回：child -> parent（entry 消费，路由仍在）。
    var consumed = await tester.binding.handlePopRoute();
    expect(consumed, isTrue);
    await waitForText(tester, 'child');

    // 第二次返回：parent -> 根。
    consumed = await tester.binding.handlePopRoute();
    expect(consumed, isTrue);
    await waitForText(tester, 'parent');

    // 到根：entry 已清，不再拦截，放行给导航（路由本身不被 pop）。
    consumed = await tester.binding.handlePopRoute();
    expect(consumed, isFalse);
    await tester.pump();
    expect(find.text('parent'), findsOneWidget);
    // 放行测试体结束时的 FakeAsync 检查：把一次性 Timer 跑完。
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('根目录直接返回不拦截', (tester) async {
    await tester.runAsync(() async {
      ComicFolderService.createFolder('', 'solo', ComicFolderType.favorite);
    });

    await pumpShelf(tester);
    await waitForText(tester, 'solo');

    final consumed = await tester.binding.handlePopRoute();
    expect(consumed, isFalse);
    await tester.pump();
    expect(find.text('solo'), findsOneWidget);
    // 放行测试体结束时的 FakeAsync 检查：把一次性 Timer 跑完。
    await tester.pump(const Duration(seconds: 5));
  });
}
