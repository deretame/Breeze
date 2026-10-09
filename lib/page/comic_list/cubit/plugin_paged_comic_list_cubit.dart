import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/plugin/unified_plugin_envelope.dart';
import 'package:zephyr/page/comic_list/cubit/plugin_paged_comic_list_state.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

typedef PluginPageCoreBuilder = Map<String, dynamic> Function(int page);
typedef PluginPageExternBuilder = Map<String, dynamic> Function(int page);

Map<String, dynamic> _sanitizePluginItemMap(dynamic item) {
  return asJsonMap(replaceNestedNullList(asJsonMap(item)));
}

class PluginPagedComicListCubit extends Cubit<PluginPagedComicListState> {
  PluginPagedComicListCubit({
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
  }) : super(const PluginPagedComicListState());

  final String pluginId;
  final String fnPath;
  final PluginPageCoreBuilder coreBuilder;
  final PluginPageExternBuilder externBuilder;

  Future<void> loadInitial() async {
    _safeEmit(
      state.copyWith(
        status: PluginPagedComicListStatus.initial,
        list: const <UnifiedComicListItem>[],
        hasReachedMax: false,
        page: 1,
        result: '',
      ),
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.hasReachedMax ||
        state.status == PluginPagedComicListStatus.loadingMore) {
      return;
    }

    _safeEmit(state.copyWith(status: PluginPagedComicListStatus.loadingMore));
    await _fetchPage(page: state.page + 1, append: true);
  }

  Future<void> retryLoadMore() async {
    await loadMore();
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    final currentList = append ? state.list : const <UnifiedComicListItem>[];
    final resolvedFnPath = fnPath.trim();

    try {
      if (resolvedFnPath.isEmpty) {
        throw StateError('插件列表请求缺少 fnPath: pluginId=$pluginId');
      }
      final pluginResponse = await callUnifiedComicPlugin(
        pluginId: pluginId,
        fnPath: resolvedFnPath,
        core: coreBuilder(page),
        extern: externBuilder(page),
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asJsonMap(envelope.data);
      final source = envelope.source.trim().isNotEmpty
          ? envelope.source.trim()
          : pluginId;
      final items = asJsonList(
        data['items'],
      ).map(_sanitizePluginItemMap).toList();
      final raw = replaceNestedNullList(asJsonMap(data['raw']));
      final listLikeKeys = ['content', 'list'];

      List<UnifiedComicListItem> nextItems = items
          .map((item) => unifiedComicFromPluginListMap(item, source: source))
          .toList();
      if (nextItems.isEmpty) {
        for (final key in listLikeKeys) {
          final rawList = asJsonList(
            raw[key],
          ).map(_sanitizePluginItemMap).toList();
          if (rawList.isNotEmpty) {
            nextItems = rawList
                .map(
                  (item) => unifiedComicFromPluginListMap(item, source: source),
                )
                .toList();
            break;
          }
        }
      }

      final mergedList = [...currentList, ...nextItems];
      final hasReachedMax = data['hasReachedMax'] == true || nextItems.isEmpty;

      _safeEmit(
        state.copyWith(
          status: PluginPagedComicListStatus.success,
          list: mergedList,
          hasReachedMax: hasReachedMax,
          page: page,
          result: page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);

      _safeEmit(
        state.copyWith(
          status: currentList.isNotEmpty
              ? PluginPagedComicListStatus.loadingMoreFailure
              : PluginPagedComicListStatus.failure,
          list: currentList,
          result: normalizeSearchErrorMessage(e),
        ),
      );
    }
  }

  void _safeEmit(PluginPagedComicListState nextState) {
    if (isClosed) {
      return;
    }
    emit(nextState);
  }
}
