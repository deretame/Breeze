import 'package:flutter_bloc/flutter_bloc.dart';

/// 章节多选态版本号：只在进入/切换/全选/清空/退出选择时 +1。
///
/// 章节行用它做行级监听，下载进度 tick 只走下载状态 cubit，
/// 不会触发选中 UI 的全列表重建。
class EpisodeSelectionCubit extends Cubit<int> {
  EpisodeSelectionCubit() : super(0);

  void bump() => emit(state + 1);
}
