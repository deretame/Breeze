import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/home/models/event.dart';
import 'package:zephyr/page/jm/jm_promote/jm_promote.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/page/jm/jm_promote/json/suggestion/jm_suggestion_json.dart'
    show JmSuggestionJson;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/error_view.dart';

@RoutePage()
class JmPromotePage extends StatelessWidget {
  const JmPromotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PromoteBloc()..add(PromoteEvent()),
      child: const _JmPromotePage(),
    );
  }
}

class _JmPromotePage extends StatefulWidget {
  const _JmPromotePage();

  @override
  _JmPromotePageState createState() => _JmPromotePageState();
}

class _JmPromotePageState extends State<_JmPromotePage> {
  late ScrollController scrollController;
  late StreamSubscription subscription;
  int page = 0;

  @override
  void initState() {
    super.initState();
    subscription = eventBus.on<RefreshCategories>().listen((event) {
      refreshPromote();
    });
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  void refreshPromote() {
    context.read<PromoteBloc>().add(PromoteEvent());
  }

  @override
  void dispose() {
    subscription.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromoteBloc, PromoteState>(
      builder: (context, state) {
        switch (state.status) {
          case PromoteStatus.initial:
            page = -1;
            return const Center(child: CircularProgressIndicator());
          case PromoteStatus.failure:
            return _failureWidget(state);
          case PromoteStatus.loadingMore:
          case PromoteStatus.loadingMoreFailure:
          case PromoteStatus.success:
            if (state.status == PromoteStatus.success) {
              page = state.result.let(toInt);
            }
            return _successWidget(state);
        }
      },
    );
  }

  Widget _failureWidget(PromoteState state) {
    return ErrorView(
      errorMessage: '${state.result.toString()}\n加载失败，请重试。',
      onRetry: () {
        context.read<PromoteBloc>().add(PromoteEvent());
      },
    );
  }

  Widget _successWidget(PromoteState state) {
    final elementsRows = _convertToEntryInfoList(state.suggestionList);

    final length =
        elementsRows.length +
        state.list.length +
        (elementsRows.isNotEmpty ? 1 : 0) +
        (state.status == PromoteStatus.loadingMore ? 1 : 0) +
        (state.status == PromoteStatus.loadingMoreFailure ? 1 : 0);

    return ListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        if (index == length - 1) {
          if (state.status == PromoteStatus.loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (state.status == PromoteStatus.loadingMoreFailure) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<PromoteBloc>().add(PromoteEvent(page: page + 1));
                },
              ),
            );
          }
        }

        if (index < state.list.length) {
          return _commentItem(state.list[index]);
        }

        if (index == state.list.length) {
          return Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                color: materialColorScheme.secondaryFixed.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              width: double.infinity,
              child: Row(
                children: [
                  Text(
                    '最新上传',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: materialColorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          );
        }

        return _suggestionItem(elementsRows[index - state.list.length - 1]);
      },
      controller: scrollController,
    );
  }

  Widget _commentItem(JmPromoteJson element) {
    return PromoteWidget(element: element);
  }

  Widget _suggestionItem(List<ComicSimplifyEntryInfo> element) {
    return ComicSimplifyEntryRow(
      key: ValueKey(element.map((e) => e.id).join(',')),
      entries: element,
      type: ComicEntryType.normal,
      refresh: () {},
    );
  }

  // 转换数据格式
  List<List<ComicSimplifyEntryInfo>> _convertToEntryInfoList(
    List<JmSuggestionJson> comics,
  ) {
    return generateResponsiveRows(
      context,
      comics
          .map(
            (element) => ComicSimplifyEntryInfo(
              title: element.name,
              id: element.id.toString(),
              fileServer: getJmCoverUrl(element.id.toString()),
              path: "${element.id}.jpg",
              pictureType: 'cover',
              from: 'jm',
            ),
          )
          .toList(),
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PromoteBloc>().add(
        PromoteEvent(status: PromoteStatus.loadingMore, page: page + 1),
      );
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
