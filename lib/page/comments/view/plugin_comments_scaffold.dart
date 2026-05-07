import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comments/cubit/cubit.dart';
import 'package:zephyr/page/comments/model/model.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';

@RoutePage(name: 'PluginCommentsScaffoldRoute')
class PluginCommentsScaffold extends StatefulWidget {
  const PluginCommentsScaffold({
    super.key,
    required this.from,
    required this.comicId,
    required this.comicTitle,
  });

  final String from;
  final String comicId;
  final String comicTitle;

  @override
  State<PluginCommentsScaffold> createState() => _PluginCommentsScaffoldState();
}

class _PluginCommentsScaffoldState extends State<PluginCommentsScaffold> {
  final ScrollController _scrollController = ScrollController();
  CommentsCubit? _commentsCubit;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CommentsCubit(from: widget.from, comicId: widget.comicId)
            ..loadInitial(),
      child: BlocListener<CommentsCubit, CommentsViewState>(
        listenWhen: (previous, current) =>
            previous.noticeId != current.noticeId &&
            current.noticeMessage.trim().isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.noticeMessage)));
        },
        child: BlocBuilder<CommentsCubit, CommentsViewState>(
          builder: (context, state) {
            final cubit = context.read<CommentsCubit>();
            _commentsCubit = cubit;
            return Scaffold(
              appBar: AppBar(title: Text(widget.comicTitle)),
              body: _buildBody(state, cubit),
              floatingActionButton: state.canCommentComic
                  ? FloatingActionButton(
                      onPressed: state.posting
                          ? null
                          : () => _postComicComment(cubit),
                      child: const Icon(Icons.comment),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(CommentsViewState state, CommentsCubit cubit) {
    if (state.loading) {
      return _wrapBodyContent(const Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && state.topItems.isEmpty && state.items.isEmpty) {
      return _wrapBodyContent(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: cubit.loadInitial,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final merged = <CommentItem>[...state.topItems, ...state.items];
    if (merged.isEmpty) {
      return _wrapBodyContent(const Center(child: Text('暂无评论')));
    }

    final count =
        merged.length + (state.loadingMore || !state.hasReachedMax ? 1 : 0);
    return _wrapBodyContent(
      ListView.separated(
        controller: _scrollController,
        itemCount: count,
        separatorBuilder: (_, _) => const Padding(
          padding: EdgeInsets.only(left: 68, right: 16),
          child: Divider(height: 1, thickness: 0.3),
        ),
        itemBuilder: (context, index) {
          if (index >= merged.length) {
            if (state.loadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.hasReachedMax) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: cubit.loadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('加载更多'),
                ),
              ),
            );
          }

          final item = merged[index];
          return KeyedSubtree(
            key: ValueKey(
              'comment_${item.id}_${index}_${item.avatarUrl}_${item.avatarPath}',
            ),
            child: _buildCommentCell(
              item,
              cubit: cubit,
              state: state,
              isReply: false,
              keySeed: '$index',
            ),
          );
        },
      ),
    );
  }

  Widget _wrapBodyContent(Widget child) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 1200
        ? 24.0
        : width >= 900
        ? 16.0
        : 8.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCommentCell(
    CommentItem item, {
    required CommentsCubit cubit,
    required CommentsViewState state,
    required bool isReply,
    required String keySeed,
  }) {
    final replies = state.replyItems[item.id] ?? const <CommentItem>[];
    final isExpanded = state.expandedIds.contains(item.id);
    final canExpand = item.replyCount > 0 || item.replies.isNotEmpty;
    final loadingReplies = state.replyLoading[item.id] == true;
    final hasReachedMaxReplies = state.replyHasReachedMax[item.id] == true;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 56 : 16,
        right: 16,
        top: 16,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(item, keySeed: keySeed, isReply: isReply),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.authorName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.content,
                      style: textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.createdAt.isNotEmpty)
                          Text(
                            item.createdAt,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        if (!isReply && canExpand)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => cubit.toggleReplies(item),
                            child: Text(
                              isExpanded ? '收起回复' : '${item.replyCount} 条回复',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (state.canCommentReply && !isReply)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: state.posting
                                ? null
                                : () => _postReply(cubit, item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.reply_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isReply && isExpanded) ...[
            if (loadingReplies)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            for (var i = 0; i < replies.length; i++)
              KeyedSubtree(
                key: ValueKey(
                  'reply_${item.id}_${replies[i].id}_${i}_${replies[i].avatarUrl}_${replies[i].avatarPath}',
                ),
                child: _buildCommentCell(
                  replies[i],
                  cubit: cubit,
                  state: state,
                  isReply: true,
                  keySeed: '$keySeed-$i',
                ),
              ),
            if (replies.isEmpty && !loadingReplies)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '暂无子评论',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (!hasReachedMaxReplies && !loadingReplies)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => cubit.loadMoreReplies(item),
                    child: const Text('加载更多回复'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(
    CommentItem item, {
    required String keySeed,
    bool isReply = false,
  }) {
    final size = isReply ? 28.0 : 40.0;
    if (item.avatarUrl.trim().isEmpty && item.avatarPath.trim().isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Icon(Icons.person, size: size * 0.6),
      );
    }
    return ClipOval(
      child: CoverWidget(
        key: ValueKey(
          'avatar_${item.id}_${keySeed}_${item.avatarUrl}_${item.avatarPath}',
        ),
        fileServer: item.avatarUrl,
        path: item.avatarPath,
        id: item.id,
        from: widget.from,
        pictureType: PictureType.user,
        width: size,
        height: size,
      ),
    );
  }

  Future<void> _postComicComment(CommentsCubit cubit) async {
    final content = await _openInputDialog(title: '发表评论', hint: '输入评论内容');
    if (content.isEmpty) {
      return;
    }
    await cubit.postComicComment(content);
  }

  Future<void> _postReply(CommentsCubit cubit, CommentItem item) async {
    final content = await _openInputDialog(title: '回复评论', hint: '输入回复内容');
    if (content.isEmpty) {
      return;
    }
    await cubit.postReply(item, content);
  }

  Future<String> _openInputDialog({
    required String title,
    required String hint,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    return (result ?? '').trim();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= max * 0.9) {
      _commentsCubit?.loadMore();
    }
  }
}
