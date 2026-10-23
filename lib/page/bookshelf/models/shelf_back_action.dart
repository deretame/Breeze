/// 书架返回键决策：纯函数，可单测。
///
/// 背景：书架 tab 嵌在 PersistentTabView 的内部 Navigator 里，文件夹下钻是
/// bloc 状态（currentPath）而非路由 push；该库在非首页 tab 上按返回时，
/// 只要内部 Navigator `canPop == false` 就直接切回首页，事件根本到不了
/// tab 内部的 PopScope（以前书架恰好是第 0 个 tab，库走 maybePop 转发，
/// 所以没暴露）。因此用 [LocalHistoryEntry] 把“待处理的返回”注册到 tab
/// 内部路由上，让库的 `canPop`/`pop` 走到我们的状态机：
/// 有 entry → 库正常 pop → entry 被消费 → onRemove 回退一级；
/// 到根（entry 已清掉）→ 放行，库按既有逻辑切首页/退应用。
enum ShelfBackAction {
  /// 先退出选择模式。
  exitSelection,

  /// 文件夹回退一级。
  goBack,

  /// 根目录且无选择：不拦截，放行给导航。
  none,
}

/// 按优先级派发一次返回：选择模式 > 文件夹回退 > 不拦截。
ShelfBackAction shelfBackActionFor({
  required bool selectionMode,
  required bool isRoot,
}) {
  if (selectionMode) {
    return ShelfBackAction.exitSelection;
  }
  if (!isRoot) {
    return ShelfBackAction.goBack;
  }
  return ShelfBackAction.none;
}

/// 是否需要在 tab 内部路由上持有 LocalHistoryEntry。
/// 只有当前可见的书架 tab 才持有，避免后台 tab 抢返回。
bool wantShelfBackEntry({
  required bool isActive,
  required bool selectionMode,
  required bool isRoot,
}) {
  if (!isActive) {
    return false;
  }
  return shelfBackActionFor(selectionMode: selectionMode, isRoot: isRoot) !=
      ShelfBackAction.none;
}
