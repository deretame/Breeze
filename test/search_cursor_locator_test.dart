import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_locator.dart';
import 'package:zephyr/page/search_result/search_cursor/search_cursor_record.dart';

/// 构造一个“从新到旧”的合成搜索世界：
/// items 为全局降序的完整结果，[pageSize] 模拟服务端每页条数。
class _FakeSearchWorld {
  _FakeSearchWorld({required this.pageSize, required this.items});

  final int pageSize;
  final List<SearchCursorPageSnapshotItem> items;

  int fetchCount = 0;

  SearchCursorPageSnapshot fetch(int page) {
    fetchCount++;
    final start = (page - 1) * pageSize;
    if (start >= items.length) {
      return SearchCursorPageSnapshot(
        page: page,
        items: const [],
        endReached: true,
      );
    }
    final end = (start + pageSize).clamp(0, items.length);
    return SearchCursorPageSnapshot(
      page: page,
      items: items.sublist(start, end),
      endReached: end >= items.length,
    );
  }
}

void main() {
  const pageSize = 80;

  test('锚点仍在记录页：一次探测命中', () async {
    final anchorId = 'comic-1-100';
    final items = <SearchCursorPageSnapshotItem>[];
    for (var i = 0; i < 200; i++) {
      items.add(
        SearchCursorPageSnapshotItem(id: 'comic-1-$i', updateAt: 100000 - i),
      );
    }
    final world = _FakeSearchWorld(pageSize: pageSize, items: items);
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: anchorId,
      anchorUpdateAt: 100000 - 100,
      anchorPage: 2,
      budget: 8,
    );

    expect(result.found, isTrue);
    expect(result.page, 2);
    expect(result.probesUsed, 1);
  });

  test('新内容把锚点推深：二分定位到新页', () async {
    // 服务端 300 条，锚点在第 120 条（page 2）；此后头部插入 150 条新内容，
    // 锚点移到 index 270 → page 4。
    final anchorId = 'comic-1-120';
    final anchorUpdateAt = 100000 - 120;
    final newItems = List.generate(
      150,
      (index) => SearchCursorPageSnapshotItem(
        id: 'new-$index',
        updateAt: 200000 - index,
      ),
    );
    final oldItems = List.generate(
      300,
      (index) => SearchCursorPageSnapshotItem(
        id: index == 120 ? anchorId : 'comic-1-$index',
        updateAt: 100000 - index,
      ),
    );
    final world = _FakeSearchWorld(
      pageSize: pageSize,
      items: [...newItems, ...oldItems],
    );
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: anchorId,
      anchorUpdateAt: anchorUpdateAt,
      anchorPage: 2,
      budget: 8,
    );

    expect(result.found, isTrue);
    expect(result.page, 4); // index 270 → 第 4 页
    expect(world.fetchCount, lessThanOrEqualTo(8));
  });

  test('锚点被删除：返回近似页', () async {
    final newItems = List.generate(
      150,
      (index) => SearchCursorPageSnapshotItem(
        id: 'new-$index',
        updateAt: 200000 - index,
      ),
    );
    final oldItems = List.generate(
      300,
      (index) => SearchCursorPageSnapshotItem(
        id: index == 120 ? 'deleted' : 'comic-1-$index',
        updateAt: 100000 - index,
      ),
    );
    final world = _FakeSearchWorld(
      pageSize: pageSize,
      items: [...newItems, ...oldItems],
    );
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: 'comic-1-120',
      anchorUpdateAt: 100000 - 120,
      anchorPage: 2,
      budget: 8,
    );

    expect(result.found, isFalse);
    // 锚点若还在，应位于 index 270 → 第 4 页附近。
    expect(result.page, inInclusiveRange(3, 5));
  });

  test('update_at 倒挂：邻域扫描仍能命中', () async {
    // 100 条中，index 10 的条目 update_at 被抬高（章节更新），
    // 使页内前 80 条顺序与其 update_at 排序不完全一致。
    final items = List.generate(100, (index) {
      return SearchCursorPageSnapshotItem(
        id: 'comic-1-$index',
        updateAt: index == 10 ? 100000 + 500 : 100000 - index,
      );
    });
    final world = _FakeSearchWorld(pageSize: pageSize, items: items);
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: 'comic-1-90',
      anchorUpdateAt: 100000 - 90,
      anchorPage: 1,
      budget: 8,
    );

    expect(result.found, isTrue);
    expect(result.page, 2);
  });

  test('预算耗尽：返回当前最优近似页', () async {
    final newItems = List.generate(
      400,
      (index) => SearchCursorPageSnapshotItem(
        id: 'new-$index',
        updateAt: 200000 - index,
      ),
    );
    final oldItems = List.generate(
      300,
      (index) => SearchCursorPageSnapshotItem(
        id: index == 120 ? 'deleted' : 'comic-1-$index',
        updateAt: 100000 - index,
      ),
    );
    final world = _FakeSearchWorld(
      pageSize: pageSize,
      items: [...newItems, ...oldItems],
    );
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: 'comic-1-120',
      anchorUpdateAt: 100000 - 120,
      anchorPage: 2,
      budget: 3,
    );

    expect(result.probesUsed, lessThanOrEqualTo(3));
    expect(result.found, isFalse);
  });

  test('锚点比当前全部结果都新：近似第 1 页', () async {
    final items = List.generate(
      160,
      (index) => SearchCursorPageSnapshotItem(
        id: 'comic-1-$index',
        updateAt: 100000 - index,
      ),
    );
    final world = _FakeSearchWorld(pageSize: pageSize, items: items);
    final result = await locateSearchCursor(
      fetchPage: (page) async => world.fetch(page),
      anchorId: 'gone',
      anchorUpdateAt: 500000,
      anchorPage: 2,
      budget: 8,
    );

    expect(result.found, isFalse);
    expect(result.page, 1);
  });

  group('插件支持表', () {
    test('JM/Bika 均已登记且最新排序值为 1', () {
      expect(searchCursorPlugins.containsKey(jmComicPluginUuid), isTrue);
      expect(searchCursorPlugins.containsKey(bikaComicPluginUuid), isTrue);
      expect(searchCursorPlugins[jmComicPluginUuid]!.newestSortBy, 1);
      expect(searchCursorPlugins[bikaComicPluginUuid]!.newestSortBy, 1);
    });

    test('JM 排序键：Unix 秒直取', () {
      final support = searchCursorPlugins[jmComicPluginUuid]!;
      expect(support.sortKeyOf({'update_at': 1761000000}), 1761000000);
      expect(support.sortKeyOf({'update_at': '1761000000'}), 1761000000);
      expect(support.sortKeyOf(const {}), 0);
    });

    test('Bika 排序键：ISO 8601 解析为 Unix 秒', () {
      final support = searchCursorPlugins[bikaComicPluginUuid]!;
      final seconds = support.sortKeyOf({
        'updated_at': '2026-10-20T08:00:00.000Z',
      });
      expect(
        seconds,
        DateTime.utc(2026, 10, 20, 8).millisecondsSinceEpoch ~/ 1000,
      );
      expect(support.sortKeyOf({'updated_at': 'not-a-date'}), 0);
      expect(support.sortKeyOf(const {}), 0);
    });

    test('记录带完整 extern 序列化往返', () {
      final record = SearchCursorRecord(
        pluginId: bikaComicPluginUuid,
        keyword: '测试',
        sortBy: 1,
        anchorComicId: 'abc',
        anchorTitle: '标题',
        anchorUpdateAt: 1761000000,
        anchorPage: 3,
        createdAt: 1761000000000,
        extern: const {
          'sortBy': 1,
          'categories': ['全彩', '純愛'],
        },
      );
      final restored = SearchCursorRecord.fromJson(record.toJson());
      expect(restored, isNotNull);
      expect(restored!.pluginId, bikaComicPluginUuid);
      expect(restored.extern['sortBy'], 1);
      expect((restored.extern['categories'] as List).length, 2);
      expect(restored.anchorTitle, '标题');
    });

    test('纯关键词 extern 判定', () {
      expect(isPlainKeywordExtern(const {'sortBy': 1}), isTrue);
      expect(
        isPlainKeywordExtern(const {
          'sortBy': 1,
          'categories': ['全彩'],
        }),
        isTrue,
      );
      expect(
        isPlainKeywordExtern(const {'url': 'https://example.com/comics?x'}),
        isFalse,
      );
      expect(isPlainKeywordExtern(const {'mode': 'creator'}), isFalse);
      expect(isPlainKeywordExtern(const {'creatorId': 'u1'}), isFalse);
    });
  });
}
