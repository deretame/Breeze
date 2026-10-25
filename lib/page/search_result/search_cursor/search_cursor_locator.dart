/// 搜索游标定位算法。
///
/// 本文件保持纯 Dart、零 Flutter 依赖，便于单元测试。
///
/// 背景：JM 搜索是页码偏移式分页（每页 80 条），“从新到旧”排序的键是
/// 服务端的上架时间，而响应里只有 `update_at`（最近更新时间）。两者
/// 大多数情况一致，更新过章节的老漫画会产生小幅倒挂，因此 `update_at`
/// 只能作为**近似单调**的定位键。算法采用“update_at 二分逼近 + 邻域
/// 扫描找锚点 id + 预算内兜底”：
///
/// 1. 先探测记录时的页码，锚点还在就直接命中；
/// 2. 判断锚点被新内容推深了还是浮浅了，按谓词
///    “该页最新一条 update_at >= 锚点 update_at”做二分逼近；
/// 3. 在边界页附近（±2 页）扫描锚点 id，预算内找不到则返回近似页。
library;

/// 一次分页探测返回的单条结果。
class SearchCursorPageSnapshotItem {
  const SearchCursorPageSnapshotItem({
    required this.id,
    required this.updateAt,
  });

  final String id;

  /// 秒级时间戳；缺失时填 0（排序时视为最旧）。
  final int updateAt;
}

/// 一次分页探测的快照。
class SearchCursorPageSnapshot {
  const SearchCursorPageSnapshot({
    required this.page,
    required this.items,
    this.endReached = false,
  });

  final int page;
  final List<SearchCursorPageSnapshotItem> items;

  /// 服务端已到尾页（空页 / 短页 / 插件 hasReachedMax）。
  final bool endReached;
}

typedef SearchCursorPageFetcher =
    Future<SearchCursorPageSnapshot> Function(int page);

/// 定位结果。
class SearchCursorLocateResult {
  const SearchCursorLocateResult({
    required this.found,
    required this.page,
    required this.probesUsed,
  });

  /// true：锚点 id 精确命中；false：锚点缺失（被删/倒挂过大/预算耗尽），
  /// [page] 为就近页。
  final bool found;

  /// 锚点所在页，或近似定位页。
  final int page;

  /// 实际发起的网络探测次数（缓存命中不计）。
  final int probesUsed;
}

Future<SearchCursorLocateResult> locateSearchCursor({
  required SearchCursorPageFetcher fetchPage,
  required String anchorId,
  required int anchorUpdateAt,
  required int anchorPage,
  int budget = 8,
  int maxPage = 100000,
  Duration probeInterval = Duration.zero,
}) async {
  assert(anchorPage >= 1);
  assert(budget >= 1);

  final cache = <int, SearchCursorPageSnapshot>{};
  var used = 0;

  Future<SearchCursorPageSnapshot?> probe(int page) async {
    final key = page.clamp(1, maxPage);
    final hit = cache[key];
    if (hit != null) return hit;
    if (used >= budget) return null;
    // 第二次起的网络探测前等待，避免连续请求打满服务端。
    if (used > 0 && probeInterval > Duration.zero) {
      await Future.delayed(probeInterval);
    }
    used++;
    final snapshot = await fetchPage(key);
    cache[key] = snapshot;
    return snapshot;
  }

  bool contains(SearchCursorPageSnapshot? snapshot) =>
      snapshot != null && snapshot.items.any((item) => item.id == anchorId);

  // 该页最新一条仍新于（或等于）锚点 → 锚点在本页或更深的页。
  bool predicate(SearchCursorPageSnapshot? snapshot) {
    if (snapshot == null || snapshot.items.isEmpty) return false;
    return snapshot.items.first.updateAt >= anchorUpdateAt;
  }

  var anchorSnapshot = await probe(anchorPage);
  if (contains(anchorSnapshot)) {
    return SearchCursorLocateResult(
      found: true,
      page: anchorPage,
      probesUsed: used,
    );
  }

  var lo = 1;
  var hi = anchorPage;

  if (anchorSnapshot != null && predicate(anchorSnapshot)) {
    // 锚点被新内容推深了（或仍在附近）：从 anchorPage 成倍扩展上界，
    // 直到谓词为假或到尾页。
    var lastTruePage = anchorPage;
    while (used < budget) {
      final next = hi * 2;
      final snapshot = await probe(next);
      if (snapshot == null) break;
      if (contains(snapshot)) {
        return SearchCursorLocateResult(
          found: true,
          page: next,
          probesUsed: used,
        );
      }
      if (!predicate(snapshot) || snapshot.endReached) {
        hi = next;
        break;
      }
      hi = next;
      lastTruePage = next;
    }
    lo = lastTruePage;
  } else {
    // 锚点变浅了（部分结果被删等）：在 [1, anchorPage] 内找。
    final first = await probe(1);
    if (first == null) {
      return SearchCursorLocateResult(
        found: false,
        page: anchorPage,
        probesUsed: used,
      );
    }
    if (contains(first)) {
      return SearchCursorLocateResult(found: true, page: 1, probesUsed: used);
    }
    if (!predicate(first)) {
      // 锚点比当前全部结果都新：内容结构变化过大，就近定位第 1 页。
      return SearchCursorLocateResult(found: false, page: 1, probesUsed: used);
    }
  }

  // 二分找谓词边界：最大的满足 predicate 的页。
  while (lo < hi && used < budget) {
    final mid = lo + (hi - lo + 1) ~/ 2;
    final snapshot = await probe(mid);
    if (contains(snapshot)) {
      return SearchCursorLocateResult(found: true, page: mid, probesUsed: used);
    }
    if (snapshot == null) break;
    if (!predicate(snapshot) || snapshot.endReached) {
      hi = mid - 1;
    } else {
      lo = mid;
    }
  }

  // 邻域扫描：二分落点受倒挂影响最多偏差一两页。
  for (final page in [lo, lo + 1, lo - 1, lo + 2, lo - 2]) {
    if (page < 1) continue;
    final snapshot = await probe(page);
    if (contains(snapshot)) {
      return SearchCursorLocateResult(
        found: true,
        page: page,
        probesUsed: used,
      );
    }
  }

  return SearchCursorLocateResult(
    found: false,
    page: lo.clamp(1, maxPage),
    probesUsed: used,
  );
}
