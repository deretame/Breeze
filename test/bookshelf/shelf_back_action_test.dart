import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/bookshelf/models/shelf_back_action.dart';

/// 书架返回决策：选择模式 > 文件夹回退 > 放行给导航。
///
/// 背景：PersistentTabView 在非首页 tab 按返回时，内部 Navigator
/// `canPop == false` 就直接切回首页，事件到不了 tab 内部；
/// 书架下钻是 bloc 状态而非路由 push，所以用 LocalHistoryEntry
/// 把「待处理返回」注册到 tab 内部路由上。这里锁定决策优先级。
void main() {
  group('shelfBackActionFor', () {
    test('选择模式优先退选，即使不在根目录', () {
      expect(
        shelfBackActionFor(selectionMode: true, isRoot: false),
        ShelfBackAction.exitSelection,
      );
    });

    test('根目录选择模式仍先退选', () {
      expect(
        shelfBackActionFor(selectionMode: true, isRoot: true),
        ShelfBackAction.exitSelection,
      );
    });

    test('子文件夹回退一级', () {
      expect(
        shelfBackActionFor(selectionMode: false, isRoot: false),
        ShelfBackAction.goBack,
      );
    });

    test('根目录无选择时放行给导航', () {
      expect(
        shelfBackActionFor(selectionMode: false, isRoot: true),
        ShelfBackAction.none,
      );
    });
  });

  group('wantShelfBackEntry', () {
    test('后台 tab 不持有 entry，避免抢前台返回', () {
      expect(
        wantShelfBackEntry(
          isActive: false,
          selectionMode: false,
          isRoot: false,
        ),
        isFalse,
      );
    });

    test('前台子文件夹持有 entry', () {
      expect(
        wantShelfBackEntry(isActive: true, selectionMode: false, isRoot: false),
        isTrue,
      );
    });

    test('前台选择模式持有 entry', () {
      expect(
        wantShelfBackEntry(isActive: true, selectionMode: true, isRoot: true),
        isTrue,
      );
    });

    test('前台根目录无选择不持有，放行给导航', () {
      expect(
        wantShelfBackEntry(isActive: true, selectionMode: false, isRoot: true),
        isFalse,
      );
    });
  });
}
