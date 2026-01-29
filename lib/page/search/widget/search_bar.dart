import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart';
import 'package:zephyr/util/router/router.gr.dart';

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

    return Padding(
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
                      onSubmitted: _onSearch,
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
            onPressed: () {
              /* 弹出高级搜索Dialog */
            },
          ),
          TextButton(
            onPressed: () => _onSearch(_controller.text),
            child: const Text("搜索"),
          ),
        ],
      ),
    );
  }

  void _onSearch(String keyword) {
    context.pushRoute(
      SearchResultRoute(
        searchEnter: SearchEnter.initial().copyWith(
          from: "bika",
          keyword: keyword,
        ),
      ),
    );
  }
}
