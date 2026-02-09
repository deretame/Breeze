import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search/method/on_search.dart';
import 'package:zephyr/page/search/widget/advanced_search_dialog.dart';
import 'package:zephyr/util/search_setting_utils.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialKeyword = context.read<SearchCubit>().state.searchKeyword;
    if (initialKeyword.isNotEmpty) {
      _controller.text = initialKeyword;
    }
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route is PageRoute && route.animation != null) {
        if (route.animation!.isCompleted) {
          _focusNode.requestFocus();
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _focusNode.requestFocus();
            }
          });
        }
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<SearchCubit, SearchStates>(
      listenWhen: (previous, current) =>
          previous.searchKeyword != current.searchKeyword,
      listener: (context, state) {
        if (_controller.text != state.searchKeyword) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _controller.text = state.searchKeyword;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.maybePop(),
            ),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (keyword) => onSearch(context, keyword),
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '搜索...',
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel, size: 20),
                        onPressed: () => _controller.clear(),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () async {
                final searchCubit = context.read<SearchCubit>();
                final newStates = await showDialog<SearchStates>(
                  context: context,
                  builder: (context) =>
                      AdvancedSearchDialog(initialState: searchCubit.state),
                );
                if (newStates != null && mounted) {
                  searchCubit.update(newStates);
                  if (!context.mounted) return;
                  updateAdvancedSearchSettings(context, newStates);
                }
              },
            ),
            TextButton(
              onPressed: () => onSearch(context, _controller.text),
              child: const Text("搜索"),
            ),
          ],
        ),
      ),
    );
  }
}
