import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/home/models/event.dart';
import 'package:zephyr/page/jm/jm_promote/jm_promote.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/page/jm/jm_promote/json/suggestion/jm_suggestion_json.dart'
    show JmSuggestionJson;
import 'package:zephyr/page/jm/jm_promote/view/jm_promote_scheme_renderer.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

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
  final JmPromoteSchemeRenderer _renderer = JmPromoteSchemeRenderer();
  late ScrollController scrollController;
  late StreamSubscription subscription;
  int page = 0;

  @override
  void initState() {
    super.initState();
    subscription = eventBus.on<RefreshCategories>().listen((event) {
      if (mounted) {
        refreshPromote();
      }
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
        if (state.status == PromoteStatus.initial) {
          page = -1;
        } else if (state.status == PromoteStatus.success) {
          page = state.result.let(toInt);
        }

        return _renderer.build(
          context,
          state: state,
          scrollController: scrollController,
          promoteItemBuilder: _commentItem,
          suggestionEntries: _toSimplifyEntries(state.suggestionList),
          onRetryInitial: refreshPromote,
          onRetryLoadMore: () {
            context.read<PromoteBloc>().add(PromoteEvent(page: page + 1));
          },
        );
      },
    );
  }

  Widget _commentItem(JmPromoteJson element) {
    return RepaintBoundary(
      child: PromoteWidget(
        key: ValueKey('${element.id}-${element.title}'),
        element: element,
      ),
    );
  }

  List<ComicSimplifyEntryInfo> _toSimplifyEntries(
    List<JmSuggestionJson> comics,
  ) {
    return mapToJmComicSimplifyEntryInfoList(
      comics,
      title: (element) => element.name,
      id: (element) => element.id.toString(),
    );
  }

  void _onScroll() {
    final state = context.read<PromoteBloc>().state;
    if (state.status == PromoteStatus.loadingMore) {
      return;
    }

    if (_isBottom) {
      context.read<PromoteBloc>().add(
        PromoteEvent(status: PromoteStatus.loadingMore, page: page + 1),
      );
    }
  }

  bool get _isBottom {
    if (!scrollController.hasClients) return false;

    final positions = scrollController.positions;
    if (positions.isEmpty) return false;

    final position = positions.first;

    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll <= 0) return false;

    return currentScroll >= (maxScroll * 0.9);
  }
}


