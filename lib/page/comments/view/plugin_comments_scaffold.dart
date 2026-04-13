import 'package:flutter/material.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';

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
  final List<_CommentItem> _topItems = <_CommentItem>[];
  final List<_CommentItem> _items = <_CommentItem>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasReachedMax = false;
  bool _canCommentComic = false;
  bool _canCommentReply = false;
  bool _posting = false;
  String _replyMode = 'lazy';
  int _page = 1;
  String? _error;
  final Set<String> _expandedIds = <String>{};
  final Map<String, List<_CommentItem>> _replyItems =
      <String, List<_CommentItem>>{};
  final Map<String, bool> _replyLoading = <String, bool>{};
  final Map<String, bool> _replyHasReachedMax = <String, bool>{};
  final Map<String, int> _replyPage = <String, int>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.comicTitle)),
      body: _buildBody(),
      floatingActionButton: _canCommentComic
          ? FloatingActionButton(
              onPressed: _posting ? null : _postComicComment,
              child: const Icon(Icons.comment),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _wrapBodyContent(const Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _topItems.isEmpty && _items.isEmpty) {
      return _wrapBodyContent(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadInitial, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final merged = <_CommentItem>[..._topItems, ..._items];
    if (merged.isEmpty) {
      return _wrapBodyContent(const Center(child: Text('暂无评论')));
    }

    final count = merged.length + (_loadingMore || !_hasReachedMax ? 1 : 0);
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
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_hasReachedMax) {
              return const SizedBox.shrink();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('上拉加载更多')),
            );
          }

          final item = merged[index];
          return KeyedSubtree(
            key: ValueKey(
              'comment_${item.id}_${index}_${item.avatarUrl}_${item.avatarPath}',
            ),
            child: _buildCommentCell(item, isReply: false, keySeed: '$index'),
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
    _CommentItem item, {
    required bool isReply,
    required String keySeed,
  }) {
    final replies = _replyItems[item.id] ?? const <_CommentItem>[];
    final isExpanded = _expandedIds.contains(item.id);
    final canExpand = item.replyCount > 0 || item.replies.isNotEmpty;
    final loadingReplies = _replyLoading[item.id] == true;
    final hasReachedMaxReplies = _replyHasReachedMax[item.id] == true;

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
                            onTap: () => _toggleReplies(item),
                            child: Text(
                              isExpanded ? '收起回复' : '${item.replyCount} 条回复',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (_canCommentReply && !isReply)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _posting ? null : () => _postReply(item),
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
                    onPressed: () => _loadMoreReplies(item),
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
    _CommentItem item, {
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

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasReachedMax = false;
      _topItems.clear();
      _items.clear();
    });

    try {
      final feed = await _fetchPage(1);
      if (!mounted) {
        return;
      }
      setState(() {
        _topItems
          ..clear()
          ..addAll(feed.topItems);
        _items
          ..clear()
          ..addAll(feed.items);
        _page = 2;
        _hasReachedMax = feed.hasReachedMax;
        _replyMode = feed.replyMode;
        _canCommentComic = feed.canCommentComic;
        _canCommentReply = feed.canCommentReply;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _hasReachedMax || _loading) {
      return;
    }
    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final feed = await _fetchPage(_page);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.addAll(feed.items);
        _page += 1;
        _hasReachedMax = feed.hasReachedMax;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<_CommentFeed> _fetchPage(int page) async {
    final response = await callUnifiedComicPlugin(
      from: widget.from,
      fnPath: 'getCommentFeed',
      core: {'comicId': widget.comicId, 'page': page},
      extern: const <String, dynamic>{},
    );
    final envelope = UnifiedPluginEnvelope.fromMap(response);
    final data = envelope.data;
    final topItems = asJsonList(
      data['topItems'],
    ).map(asJsonMap).map(_CommentItem.fromMap).toList();
    final items = asJsonList(
      data['items'],
    ).map(asJsonMap).map(_CommentItem.fromMap).toList();
    final paging = asJsonMap(data['paging']);
    return _CommentFeed(
      topItems: topItems,
      items: items,
      replyMode: data['replyMode']?.toString() ?? 'lazy',
      canCommentComic: asJsonMap(data['canComment'])['comic'] == true,
      canCommentReply: asJsonMap(data['canComment'])['reply'] == true,
      hasReachedMax: paging['hasReachedMax'] == true,
    );
  }

  Future<void> _postComicComment() async {
    final content = await _openInputDialog(title: '发表评论', hint: '输入评论内容');
    if (content.isEmpty) {
      return;
    }
    await _submitCommentMutation(
      fnPath: 'postComment',
      core: {'comicId': widget.comicId, 'content': content},
      extern: const <String, dynamic>{},
    );
  }

  Future<void> _postReply(_CommentItem item) async {
    final content = await _openInputDialog(title: '回复评论', hint: '输入回复内容');
    if (content.isEmpty) {
      return;
    }
    await _submitCommentMutation(
      fnPath: 'postCommentReply',
      core: {
        'comicId': widget.comicId,
        'commentId': item.id,
        'content': content,
      },
      extern: item.extern,
    );
  }

  Future<void> _submitCommentMutation({
    required String fnPath,
    required Map<String, dynamic> core,
    required Map<String, dynamic> extern,
  }) async {
    setState(() {
      _posting = true;
    });
    try {
      final response = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: fnPath,
        core: core,
        extern: extern,
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = envelope.data;
      if (!mounted) {
        return;
      }

      final needsRefetch =
          asJsonMap(data['insertHint'])['needsRefetch'] == true;
      final applied = !needsRefetch && _applyMutationResult(data);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('发布成功')));
      if (!applied) {
        await _loadInitial();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  bool _applyMutationResult(Map<String, dynamic> data) {
    final createdMap = asJsonMap(data['created']);
    if (createdMap.isEmpty) {
      return false;
    }
    final created = _CommentItem.fromMap(createdMap);
    final hint = asJsonMap(data['insertHint']);
    final strategy = hint['strategy']?.toString() ?? '';

    setState(() {
      if (strategy == 'prependAfterTop') {
        _items.insert(0, created);
        return;
      }

      if (strategy == 'prepend') {
        final targetCommentId =
            hint['targetCommentId']?.toString() ??
            data['parentId']?.toString() ??
            '';
        if (targetCommentId.isNotEmpty) {
          final current = _replyItems[targetCommentId] ?? <_CommentItem>[];
          _replyItems[targetCommentId] = <_CommentItem>[created, ...current];
          _expandedIds.add(targetCommentId);
          _replyHasReachedMax[targetCommentId] = false;
          _bumpReplyCount(targetCommentId);
          return;
        }
      }

      _items.insert(0, created);
    });
    return true;
  }

  void _bumpReplyCount(String commentId) {
    for (var i = 0; i < _topItems.length; i++) {
      if (_topItems[i].id == commentId) {
        _topItems[i] = _topItems[i].copyWith(
          replyCount: _topItems[i].replyCount + 1,
        );
        return;
      }
    }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == commentId) {
        _items[i] = _items[i].copyWith(replyCount: _items[i].replyCount + 1);
        return;
      }
    }
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

  Future<void> _toggleReplies(_CommentItem item) async {
    if (_expandedIds.contains(item.id)) {
      setState(() {
        _expandedIds.remove(item.id);
      });
      return;
    }

    setState(() {
      _expandedIds.add(item.id);
    });

    if (_replyMode == 'embedded') {
      if (_replyItems.containsKey(item.id)) {
        return;
      }
      setState(() {
        _replyItems[item.id] = item.replies;
        _replyHasReachedMax[item.id] = true;
      });
      return;
    }

    if (_replyItems.containsKey(item.id)) {
      return;
    }
    await _loadReplies(item: item, page: 1, reset: true);
  }

  Future<void> _loadMoreReplies(_CommentItem item) async {
    final nextPage = _replyPage[item.id] ?? 1;
    await _loadReplies(item: item, page: nextPage, reset: false);
  }

  Future<void> _loadReplies({
    required _CommentItem item,
    required int page,
    required bool reset,
  }) async {
    if (_replyLoading[item.id] == true) {
      return;
    }
    if (!reset && (_replyHasReachedMax[item.id] == true)) {
      return;
    }

    setState(() {
      _replyLoading[item.id] = true;
    });

    try {
      final response = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'loadCommentReplies',
        core: {'comicId': widget.comicId, 'commentId': item.id, 'page': page},
        extern: item.extern,
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = envelope.data;
      final items = asJsonList(
        data['items'],
      ).map(asJsonMap).map(_CommentItem.fromMap).toList();
      final paging = asJsonMap(data['paging']);
      final hasReachedMax = paging['hasReachedMax'] == true;

      if (!mounted) {
        return;
      }
      setState(() {
        final current = reset
            ? <_CommentItem>[]
            : (_replyItems[item.id] ?? <_CommentItem>[]);
        _replyItems[item.id] = <_CommentItem>[...current, ...items];
        _replyHasReachedMax[item.id] = hasReachedMax;
        _replyPage[item.id] = page + 1;
        _replyLoading[item.id] = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _replyLoading[item.id] = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || _hasReachedMax) {
      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= max * 0.9) {
      _loadMore();
    }
  }
}

class _CommentFeed {
  const _CommentFeed({
    required this.topItems,
    required this.items,
    required this.replyMode,
    required this.canCommentComic,
    required this.canCommentReply,
    required this.hasReachedMax,
  });

  final List<_CommentItem> topItems;
  final List<_CommentItem> items;
  final String replyMode;
  final bool canCommentComic;
  final bool canCommentReply;
  final bool hasReachedMax;
}

class _CommentItem {
  const _CommentItem({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.avatarPath,
    required this.content,
    required this.createdAt,
    required this.replyCount,
    required this.replies,
    required this.extern,
  });

  final String id;
  final String authorName;
  final String avatarUrl;
  final String avatarPath;
  final String content;
  final String createdAt;
  final int replyCount;
  final List<_CommentItem> replies;
  final Map<String, dynamic> extern;

  _CommentItem copyWith({int? replyCount}) {
    return _CommentItem(
      id: id,
      authorName: authorName,
      avatarUrl: avatarUrl,
      avatarPath: avatarPath,
      content: content,
      createdAt: createdAt,
      replyCount: replyCount ?? this.replyCount,
      replies: replies,
      extern: extern,
    );
  }

  factory _CommentItem.fromMap(Map<String, dynamic> map) {
    final author = asJsonMap(map['author']);
    final avatar = asJsonMap(author['avatar']);
    final replies = asJsonList(
      map['replies'],
    ).map(asJsonMap).map(_CommentItem.fromMap).toList();
    return _CommentItem(
      id: map['id']?.toString() ?? '',
      authorName: author['name']?.toString() ?? '匿名用户',
      avatarUrl: avatar['url']?.toString() ?? '',
      avatarPath: avatar['path']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      replyCount: _toInt(map['replyCount']),
      replies: replies,
      extern: asJsonMap(map['extern']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
