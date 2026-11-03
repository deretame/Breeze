import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

void main() {
  group('mapSlotForDoublePageToggle', () {
    test('单页切双页向下取整', () {
      expect(mapSlotForDoublePageToggle(currentSlot: 0, toDoublePage: true), 0);
      expect(mapSlotForDoublePageToggle(currentSlot: 1, toDoublePage: true), 0);
      expect(mapSlotForDoublePageToggle(currentSlot: 2, toDoublePage: true), 1);
      expect(mapSlotForDoublePageToggle(currentSlot: 3, toDoublePage: true), 1);
      expect(mapSlotForDoublePageToggle(currentSlot: 5, toDoublePage: true), 2);
    });

    test('双页切单页乘 2', () {
      expect(mapSlotForDoublePageToggle(currentSlot: 0, toDoublePage: false), 0);
      expect(mapSlotForDoublePageToggle(currentSlot: 1, toDoublePage: false), 2);
      expect(mapSlotForDoublePageToggle(currentSlot: 3, toDoublePage: false), 6);
    });

    test('负槽位按 0 处理', () {
      expect(mapSlotForDoublePageToggle(currentSlot: -1, toDoublePage: true), 0);
      expect(mapSlotForDoublePageToggle(currentSlot: -1, toDoublePage: false), 0);
    });
  });

  group('autoDoublePageInLandscape 持久化', () {
    test('JSON 往返保留开关值', () {
      const state = ReadSettingState(
        autoDoublePageInLandscape: true,
        doublePageMode: true,
      );
      final restored = ReadSettingState.fromJson(state.toJson());

      expect(restored.autoDoublePageInLandscape, isTrue);
      expect(restored.doublePageMode, isTrue);
    });

    test('旧 JSON 缺少字段时默认关闭', () {
      final json = const ReadSettingState().toJson()
        ..remove('autoDoublePageInLandscape');
      final restored = ReadSettingState.fromJson(json);

      expect(restored.autoDoublePageInLandscape, isFalse);
    });
  });
}
