import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';

import 'search_scheme_renderer.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  final SearchStates searchState;
  final bool aggregateMode;

  const SearchPage({
    super.key,
    required this.searchState,
    this.aggregateMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => SearchCubit(searchState))],
      child: _SearchPageContent(
        searchState: searchState,
        aggregateMode: aggregateMode,
      ),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  final SearchStates searchState;
  final bool aggregateMode;

  const _SearchPageContent({
    required this.searchState,
    required this.aggregateMode,
  });

  @override
  State<_SearchPageContent> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPageContent> {
  late final SearchSchemeRenderer _renderer;

  @override
  void initState() {
    super.initState();
    _renderer = SearchSchemeRenderer(aggregateMode: widget.aggregateMode);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(child: _renderer.build()),
    );
  }
}
