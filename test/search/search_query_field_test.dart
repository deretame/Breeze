import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/search/widget/search_input_dialog.dart';

/// SearchQueryField：多行展示 + 回车即搜。
///
/// 断言 `TextInputType.text + maxLines 6` 组合不被回退：
/// multiline 的 keyboardType 会让 Android IME 直接忽略
/// textInputAction.search（a45ae20 的教训），text 则下发
/// actionSearch，同时靠软换行撑高展示。
/// didChangeDependencies 对无 RouterScope 的裸 pump 做了容错，
/// 所以这里不需要搭整页路由，直接 pump 输入框即可。
void main() {
  testWidgets('shows multiple lines and submits on search action', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.useDeviceLocale());

    var submitted = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchQueryField(
            query: '',
            autoExpand: true,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    // multiline 会让 Android IME 忽略 search action，必须是 text。
    expect(textField.keyboardType, TextInputType.text);
    expect(textField.textInputAction, TextInputAction.search);
    // 单行是 a45ae20 的临时方案：只能显示一行。多行展示必须 maxLines > 1。
    expect(textField.maxLines, greaterThan(1));
    // 硬换行必须被拦截，否则粘贴带 \n 的词会真的换行而不是提交。
    expect(textField.inputFormatters, isNotNull);

    await tester.enterText(find.byType(TextField), 'abc\ndef');
    expect(find.text('abc\ndef'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(submitted, 'abcdef');
  });

  testWidgets('taps in text-field group do not dismiss overlay', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.useDeviceLocale());

    // 同一页再放一个普通 TextField，保证点按它会把焦点抢走：
    // 这样能区分"同组点按不收"和"焦点丢失收"两种路径。
    final otherFocus = FocusNode();
    addTearDown(otherFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchQueryField(
                query: '',
                autoExpand: true,
                onSubmitted: (_) {},
              ),
              // 模拟系统选词菜单/粘贴手柄：框架把它们包在 groupId=EditableText
              // 的 TextFieldTapRegion 里（见 SDK text_selection.dart），
              // 同组点按必须视为 inside，不能触发浮层的 onTapOutside。
              const TextFieldTapRegion(
                // SizedBox 本身不参与 hitTest、点按会穿透到底层，
                // 用 ColoredBox 保证 tap 真落在同组区域内。
                child: ColoredBox(
                  key: Key('fake-toolbar'),
                  color: Color(0x00000000),
                  child: SizedBox(width: 100, height: 40),
                ),
              ),
              TextField(key: const Key('other-field'), focusNode: otherFocus),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 浮层展开：overlay 里的输入框 + 页面的普通输入框都在树上。
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('fake-toolbar')));
    await tester.pump();

    // 同组点按：浮层不收，输入框还在。
    expect(find.byType(TextField), findsNWidgets(2));

    // 反例：点真正的外部（另一个普通 TextField），焦点被抢走，
    // _watchFocusLoss 生效，浮层才收起。
    await tester.tap(find.byKey(const Key('other-field')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('dismisses overlay when focus moves to another page', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.useDeviceLocale());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchQueryField(
                query: 'abc',
                autoExpand: true,
                onSubmitted: (_) {},
              ),
              const TextField(key: Key('other-page-field')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // autoExpand 已展开：书架浮层 + 另一个输入框都在树上。
    expect(find.byType(TextField), findsNWidgets(2));

    // 模拟 push 新路由后焦点被抢走：点新页输入框，书架浮层失焦即收起。
    await tester.tap(find.byKey(const Key('other-page-field')));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('hides overlay when tab becomes inactive', (tester) async {
    await LocaleSettings.setLocale(AppLocale.zhCn);
    addTearDown(() => LocaleSettings.useDeviceLocale());

    var tabActive = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => Column(
              children: [
                // 桌面端 IndexedStack 切走：Visibility 翻转但 TickerMode 不变；
                // 移动端切走：Offstage + TickerMode(enabled:false)。
                // 这里用 Visibility 复刻桌面端路径。
                Visibility(
                  visible: tabActive,
                  maintainState: true,
                  child: SearchQueryField(
                    query: 'abc',
                    autoExpand: true,
                    onSubmitted: (_) {},
                  ),
                ),
                TextButton(
                  onPressed: () => refresh(() => tabActive = false),
                  child: const Text('switch tab'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // autoExpand 已展开：overlay 里有一个可聚焦的 TextField。
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('switch tab'));
    await tester.pumpAndSettle();

    // 浮层收起：TextField 随 overlay entry 一起移除。
    expect(find.byType(TextField), findsNothing);
  });
}
