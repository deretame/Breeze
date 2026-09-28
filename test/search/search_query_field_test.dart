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
}
