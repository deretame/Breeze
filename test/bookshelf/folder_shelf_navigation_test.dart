import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/worker_manager.dart';
import 'package:zephyr/page/bookshelf/bloc/folder_shelf_bloc.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';

/// FolderShelfBloc 文件夹导航：逐级回退 + 根保护。
///
/// 这是书架返回链的底座：UI 层的 LocalHistoryEntry 被返回消费后，
/// 调的正是这里的 GoBack；根目录时 UI 层不清 entry、直接放行给导航。
///
/// 说明：bloc 构造即发 LoadRequested，走 worker isolate + 真实 ObjectBox
/// 路径，在测试里只会落到 error 状态。这里不断言列表内容，只断言
/// 导航事件同步发出的 currentPath（先于 load 结果发出，不受影响）。
void main() {
  setUpAll(() async {
    // 让 worker 任务真正跑完（测试里落到 error），否则 LoadRequested
    // handler 挂起会堵住 bloc 的顺序事件队列。
    await workerManager.init(isolatesCount: 1);
  });

  tearDownAll(() async {
    await workerManager.dispose();
  });

  /// 等构造时自带的 LoadRequested 在 worker 里失败返回，队列排空。
  /// 失败后必 emit（isLoading=false + error 非空），轮询等它而不是死等；
  /// 超时则继续（导航事件同步 emit path，不依赖 load 结果）。
  Future<void> pumpEvents(FolderShelfBloc bloc) async {
    for (var i = 0; i < 100; i++) {
      if (!bloc.state.isLoading && bloc.state.error != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  FolderShelfBloc createBloc() => FolderShelfBloc(mode: ShelfPageMode.favorite);

  test('进两级文件夹后 GoBack 逐级回退，到根停住', () async {
    final bloc = createBloc();
    addTearDown(bloc.close);
    await pumpEvents(bloc);

    bloc.add(const FolderShelfEnterFolder('A'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.currentPath, 'A');

    bloc.add(const FolderShelfEnterFolder('A/B'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.currentPath, 'A/B');

    bloc.add(const FolderShelfGoBack());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.currentPath, 'A');

    bloc.add(const FolderShelfGoBack());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);

    // 根上再退：无变化，不抛。
    bloc.add(const FolderShelfGoBack());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);
  });

  test('GoHome 直接回根，根上调用无变化', () async {
    final bloc = createBloc();
    addTearDown(bloc.close);
    await pumpEvents(bloc);

    bloc.add(const FolderShelfEnterFolder('A/B/C'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.currentPath, 'A/B/C');

    bloc.add(const FolderShelfGoHome());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);

    bloc.add(const FolderShelfGoHome());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);
  });

  test('history 模式忽略文件夹导航事件，恒为根', () async {
    final bloc = FolderShelfBloc(mode: ShelfPageMode.history);
    addTearDown(bloc.close);
    await pumpEvents(bloc);

    bloc.add(const FolderShelfEnterFolder('A'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);

    bloc.add(const FolderShelfGoBack());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.isRoot, isTrue);
  });
}
