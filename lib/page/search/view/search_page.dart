import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/search.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  final SearchStates searchState;

  const SearchPage({super.key, required this.searchState});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => SearchCubit(searchState))],
      child: _SearchPageContent(searchState: searchState),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  final SearchStates searchState;

  const _SearchPageContent({required this.searchState});

  @override
  State<_SearchPageContent> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPageContent> {
  @override
  void initState() {
    super.initState();
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
      body: SafeArea(
        child: Column(
          children: [
            const SearchBar(),
            const Divider(height: 1),
            const Expanded(child: HistoryWidget()),
          ],
        ),
      ),
    );
  }
}
