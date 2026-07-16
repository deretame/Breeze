import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/discover/view/discover_scheme_renderer.dart';
import 'package:zephyr/page/plugin_function/cubit/plugin_function_cubit.dart';
import 'package:zephyr/i18n/strings.g.dart';

@RoutePage()
class PluginFunctionPage extends StatelessWidget {
  const PluginFunctionPage({
    super.key,
    required this.from,
    required this.functionId,
    required this.title,
    required this.onAction,
  });

  final String from;
  final String functionId;
  final String title;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PluginFunctionCubit()..load(from: from, functionId: functionId),
      child: _PluginFunctionView(
        from: from,
        title: title,
        functionId: functionId,
        onAction: onAction,
      ),
    );
  }
}

class _PluginFunctionView extends StatelessWidget {
  const _PluginFunctionView({
    required this.from,
    required this.title,
    required this.functionId,
    required this.onAction,
  });

  final String from;
  final String title;
  final String functionId;
  final Future<void> Function(Map<String, dynamic> action) onAction;

  @override
  Widget build(BuildContext context) {
    final renderer = const DiscoverSchemeRenderer();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<PluginFunctionCubit, PluginFunctionState>(
        builder: (context, state) => state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<PluginFunctionCubit>().load(
                        from: from,
                        functionId: functionId,
                      ),
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              )
            : renderer.buildPage(
                context,
                from: from,
                scheme: state.scheme,
                data: state.data,
                onReachBottom: () async {},
                onAction: onAction,
                isLoadingMore: false,
                showLoadMoreRetry: false,
                onRetryLoadMore: () {},
              ),
      ),
    );
  }
}
