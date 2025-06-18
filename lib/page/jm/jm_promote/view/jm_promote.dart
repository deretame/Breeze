import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/home/models/event.dart';
import 'package:zephyr/page/jm/jm_promote/jm_promote.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
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
  ScrollController get scrollController => scrollControllers['jmHome']!;
  late StreamSubscription subscription;

  @override
  void initState() {
    subscription = eventBus.on<RefreshCategories>().listen((event) {
      refreshPromote();
    });
    super.initState();
    // scrollController.addListener();
  }

  void refreshPromote() {
    context.read<PromoteBloc>().add(PromoteEvent());
  }

  @override
  void dispose() {
    scrollController.dispose();
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromoteBloc, PromoteState>(
      builder: (context, state) {
        switch (state.status) {
          case PromoteStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case PromoteStatus.failure:
            return _failureWidget(state);
          case PromoteStatus.success:
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
    return ListView.builder(
      itemCount: state.list.length,
      itemBuilder: (context, index) {
        return _commentItem(state.list[index], index);
      },
      controller: scrollController,
    );
  }

  Widget _commentItem(JmPromoteJson element, int index) {
    return PromoteWidget(element: element);
  }
}
