import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/model/unified_creator_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/models/comic_info_action.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/widgets/creator_link_card.dart';
import 'package:zephyr/widgets/error_view.dart';

typedef PluginCreatorPageCoreBuilder = Map<String, dynamic> Function(int page);
typedef PluginCreatorPageExternBuilder =
    Map<String, dynamic> Function(int page);

Map<String, dynamic> _sanitizeCreatorItemMap(dynamic item) {
  return asMap(item);
}

enum PluginPagedCreatorListStatus {
  initial,
  success,
  failure,
  loadingMore,
  loadingMoreFailure,
}

class PluginPagedCreatorListState extends Equatable {
  const PluginPagedCreatorListState({
    this.status = PluginPagedCreatorListStatus.initial,
    this.list = const <UnifiedCreatorListItem>[],
    this.hasReachedMax = false,
    this.page = 1,
    this.result = '',
  });

  final PluginPagedCreatorListStatus status;
  final List<UnifiedCreatorListItem> list;
  final bool hasReachedMax;
  final int page;
  final String result;

  PluginPagedCreatorListState copyWith({
    PluginPagedCreatorListStatus? status,
    List<UnifiedCreatorListItem>? list,
    bool? hasReachedMax,
    int? page,
    String? result,
  }) {
    return PluginPagedCreatorListState(
      status: status ?? this.status,
      list: list ?? this.list,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, list, hasReachedMax, page, result];
}

class PluginPagedCreatorListCubit extends Cubit<PluginPagedCreatorListState> {
  PluginPagedCreatorListCubit({
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
  }) : super(const PluginPagedCreatorListState());

  final String pluginId;
  final String fnPath;
  final PluginCreatorPageCoreBuilder coreBuilder;
  final PluginCreatorPageExternBuilder externBuilder;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        status: PluginPagedCreatorListStatus.initial,
        list: const <UnifiedCreatorListItem>[],
        hasReachedMax: false,
        page: 1,
        result: '',
      ),
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (state.hasReachedMax ||
        state.status == PluginPagedCreatorListStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: PluginPagedCreatorListStatus.loadingMore));
    await _fetchPage(page: state.page + 1, append: true);
  }

  Future<void> retryLoadMore() async {
    await loadMore();
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    final currentList = append ? state.list : const <UnifiedCreatorListItem>[];
    final resolvedFnPath = fnPath.trim();

    try {
      if (resolvedFnPath.isEmpty) {
        throw StateError('插件作者列表请求缺少 fnPath: pluginId=$pluginId');
      }
      final pluginResponse = await callUnifiedComicPlugin(
        pluginId: pluginId,
        fnPath: resolvedFnPath,
        core: coreBuilder(page),
        extern: externBuilder(page),
      );
      final envelope = UnifiedPluginEnvelope.fromMap(pluginResponse);
      final data = asMap(envelope.data);
      final items = asList(data['items']).map(_sanitizeCreatorItemMap).toList();
      final nextItems = items.map(UnifiedCreatorListItem.fromJson).toList();
      final hasReachedMax = data['hasReachedMax'] == true || nextItems.isEmpty;

      emit(
        state.copyWith(
          status: PluginPagedCreatorListStatus.success,
          list: [...currentList, ...nextItems],
          hasReachedMax: hasReachedMax,
          page: page,
          result: page.toString(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: currentList.isNotEmpty
              ? PluginPagedCreatorListStatus.loadingMoreFailure
              : PluginPagedCreatorListStatus.failure,
          list: currentList,
          result: e.toString(),
        ),
      );
    }
  }
}

class PluginPagedCreatorListView extends StatelessWidget {
  const PluginPagedCreatorListView({
    super.key,
    required this.pluginId,
    required this.fnPath,
    required this.coreBuilder,
    required this.externBuilder,
  });

  final String pluginId;
  final String fnPath;
  final PluginCreatorPageCoreBuilder coreBuilder;
  final PluginCreatorPageExternBuilder externBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginPagedCreatorListCubit(
        pluginId: pluginId,
        fnPath: fnPath,
        coreBuilder: coreBuilder,
        externBuilder: externBuilder,
      )..loadInitial(),
      child: const _PluginPagedCreatorListBody(),
    );
  }
}

class _PluginPagedCreatorListBody extends StatefulWidget {
  const _PluginPagedCreatorListBody();

  @override
  State<_PluginPagedCreatorListBody> createState() =>
      _PluginPagedCreatorListBodyState();
}

class _PluginPagedCreatorListBodyState
    extends State<_PluginPagedCreatorListBody>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<
      PluginPagedCreatorListCubit,
      PluginPagedCreatorListState
    >(
      builder: (context, state) {
        switch (state.status) {
          case PluginPagedCreatorListStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case PluginPagedCreatorListStatus.failure:
            return ErrorView(
              errorMessage: '${state.result}\n加载失败，请重试。',
              onRetry: () =>
                  context.read<PluginPagedCreatorListCubit>().loadInitial(),
            );
          case PluginPagedCreatorListStatus.loadingMore:
          case PluginPagedCreatorListStatus.loadingMoreFailure:
          case PluginPagedCreatorListStatus.success:
            return _buildContent(context, state);
        }
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PluginPagedCreatorListState state,
  ) {
    if (state.list.isEmpty &&
        state.status == PluginPagedCreatorListStatus.success) {
      return const Center(
        child: Text('啥都没有', style: TextStyle(fontSize: 20.0)),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: state.list.length + 1,
      itemBuilder: (context, index) {
        if (index == state.list.length) {
          if (state.hasReachedMax) {
            return const Padding(
              padding: EdgeInsets.all(30.0),
              child: Center(child: Text('没有更多了')),
            );
          }
          if (state.status == PluginPagedCreatorListStatus.loadingMore) {
            return const Center(child: BottomLoader());
          }
          if (state.status == PluginPagedCreatorListStatus.loadingMoreFailure) {
            return Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.read<PluginPagedCreatorListCubit>().retryLoadMore(),
                child: const Text('点击重试'),
              ),
            );
          }
          if (state.status == PluginPagedCreatorListStatus.success &&
              !state.hasReachedMax) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14, top: 6),
                child: TextButton.icon(
                  onPressed: () =>
                      context.read<PluginPagedCreatorListCubit>().loadMore(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  label: const Text('点击加载更多'),
                ),
              ),
            );
          }
          return const SizedBox(height: 10);
        }

        final item = state.list[index];
        return Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
          child: CreatorLinkCard(
            creatorName: item.name,
            avatarUrl: item.avatar.url,
            avatarPath: item.avatar.path,
            from: item.from,
            imageKey: item.id,
            errorAssetPath: 'asset/image/error_image/404.png',
            infoChildren: [
              if (item.subtitle.trim().isNotEmpty) Text(item.subtitle),
              if (item.stats.isNotEmpty)
                Wrap(
                  spacing: 20,
                  children: item.stats.map((text) => Text(text)).toList(),
                ),
            ],
            onTap: item.onTap.isNotEmpty
                ? () => handleComicInfoAction(
                    context,
                    item.onTap,
                    fallbackPluginId: item.from,
                  )
                : null,
          ),
        );
      },
    );
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final currentScroll = scrollController.offset;
    if (currentScroll >= maxScroll * 0.9) {
      context.read<PluginPagedCreatorListCubit>().loadMore();
    }
  }
}
