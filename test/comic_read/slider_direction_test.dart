import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/comic_read_preference_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/controls/slider.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

/// 直接 emit 预设 state，不走 updateReadSetting（后者会写 ObjectBox，
/// Windows 下 `flutter test` 缺 objectbox.dll 跑不起来）。
Widget _harness({
  required GlobalSettingCubit globalCubit,
  required ComicReadPreferenceCubit preferenceCubit,
  required ReaderCubit readerCubit,
  required PageController pageController,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: globalCubit),
      BlocProvider.value(value: preferenceCubit),
      BlocProvider.value(value: readerCubit),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            SliderWidget(
              observerController: ListObserverController(),
              pageController: pageController,
            ),
          ],
        ),
      ),
    ),
  );
}

/// 最靠近 Slider 的 Directionality：LTR 时是 MaterialApp 自带的，
/// RTL 时是我们包的那层。
TextDirection _sliderDirection(WidgetTester tester) {
  Directionality? nearest;
  tester.element(find.byType(Slider)).visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is Directionality) {
      nearest = widget;
      return false;
    }
    return true;
  });
  return nearest!.textDirection;
}

Future<void> _pumpWithReadMode(WidgetTester tester, int readMode) async {
  final globalCubit = GlobalSettingCubit();
  globalCubit.emit(
    globalCubit.state.copyWith(
      readSetting: globalCubit.state.readSetting.copyWith(readMode: readMode),
    ),
  );
  final readerCubit = ReaderCubit()
    ..updateTotalSlots(10)
    ..updateCurrentSlot(2);
  final pageController = PageController();
  addTearDown(pageController.dispose);

  await tester.pumpWidget(
    _harness(
      globalCubit: globalCubit,
      preferenceCubit: ComicReadPreferenceCubit(),
      readerCubit: readerCubit,
      pageController: pageController,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('单页从左到右：滑杆方向为 ltr', (tester) async {
    await _pumpWithReadMode(tester, kReadModeRowLtr);
    expect(_sliderDirection(tester), TextDirection.ltr);
  });

  testWidgets('单页从右到左：滑杆方向为 rtl', (tester) async {
    await _pumpWithReadMode(tester, kReadModeRowRtl);
    expect(_sliderDirection(tester), TextDirection.rtl);
  });
}
