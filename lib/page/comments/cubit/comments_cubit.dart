import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comments/model/model.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/json/json_value.dart';

part 'comments_cubit.freezed.dart';

@freezed
abstract class CommentsViewState with _$CommentsViewState {
  const factory CommentsViewState({
    @Default(<CommentItem>[]) List<CommentItem> topItems,
    @Default(<CommentItem>[]) List<CommentItem> items,
    @Default(false) bool loading,
    @Default(false) bool loadingMore,
    @Default(false) bool hasReachedMax,
    @Default(false) bool canCommentComic,
    @Default(false) bool canCommentReply,
    @Default(false) bool posting,
    @Default('lazy') String replyMode,
    @Default(1) int page,
    String? error,
    @Default(<String>{}) Set<String> expandedIds,
    @Default(<String, List<CommentItem>>{})
    Map<String, List<CommentItem>> replyItems,
    @Default(<String, bool>{}) Map<String, bool> replyLoading,
    @Default(<String, bool>{}) Map<String, bool> replyHasReachedMax,
    @Default(<String, int>{}) Map<String, int> replyPage,
    @Default('') String noticeMessage,
    @Default(0) int noticeId,
  }) = _CommentsViewState;
}

class CommentsCubit extends Cubit<CommentsViewState> {
  CommentsCubit({required this.from, required this.comicId})
    : super(const CommentsViewState());

  final String from;
  final String comicId;

  Future<void> loadInitial() async {
    _safeEmit(
      state.copyWith(
        loading: true,
        error: null,
        page: 1,
        hasReachedMax: false,
        topItems: const <CommentItem>[],
        items: const <CommentItem>[],
        expandedIds: const <String>{},
        replyItems: const <String, List<CommentItem>>{},
        replyLoading: const <String, bool>{},
        replyHasReachedMax: const <String, bool>{},
        replyPage: const <String, int>{},
      ),
    );

    try {
      final feed = await _fetchPage(1);
      _safeEmit(
        state.copyWith(
          topItems: feed.topItems,
          items: feed.items,
          page: 2,
          hasReachedMax: feed.hasReachedMax,
          replyMode: feed.replyMode,
          canCommentComic: feed.canCommentComic,
          canCommentReply: feed.canCommentReply,
          loading: false,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(loading: false, error: normalizeSearchErrorMessage(e)),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.hasReachedMax || state.loading) {
      return;
    }
    _safeEmit(state.copyWith(loadingMore: true, error: null));

    try {
      final feed = await _fetchPage(state.page);
      _safeEmit(
        state.copyWith(
          items: <CommentItem>[...state.items, ...feed.items],
          page: state.page + 1,
          hasReachedMax: feed.hasReachedMax,
          loadingMore: false,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          loadingMore: false,
          error: normalizeSearchErrorMessage(e),
        ),
      );
    }
  }

  Future<void> postComicComment(String content) async {
    await _submitCommentMutation(
      fnPath: 'postComment',
      core: {'comicId': comicId, 'content': content},
      extern: const <String, dynamic>{},
    );
  }

  Future<void> postReply(CommentItem item, String content) async {
    await _submitCommentMutation(
      fnPath: 'postCommentReply',
      core: {'comicId': comicId, 'commentId': item.id, 'content': content},
      extern: item.extern,
    );
  }

  Future<void> toggleReplies(CommentItem item) async {
    if (state.expandedIds.contains(item.id)) {
      final expandedIds = Set<String>.from(state.expandedIds)..remove(item.id);
      _safeEmit(state.copyWith(expandedIds: expandedIds));
      return;
    }

    final expandedIds = Set<String>.from(state.expandedIds)..add(item.id);
    _safeEmit(state.copyWith(expandedIds: expandedIds));

    if (state.replyMode == 'embedded') {
      if (state.replyItems.containsKey(item.id)) {
        return;
      }
      final replyItems = Map<String, List<CommentItem>>.from(state.replyItems)
        ..[item.id] = item.replies;
      final replyHasReachedMax = Map<String, bool>.from(
        state.replyHasReachedMax,
      )..[item.id] = true;
      _safeEmit(
        state.copyWith(
          replyItems: replyItems,
          replyHasReachedMax: replyHasReachedMax,
        ),
      );
      return;
    }

    if (state.replyItems.containsKey(item.id)) {
      return;
    }
    await _loadReplies(item: item, page: 1, reset: true);
  }

  Future<void> loadMoreReplies(CommentItem item) async {
    final nextPage = state.replyPage[item.id] ?? 1;
    await _loadReplies(item: item, page: nextPage, reset: false);
  }

  Future<void> _submitCommentMutation({
    required String fnPath,
    required Map<String, dynamic> core,
    required Map<String, dynamic> extern,
  }) async {
    if (state.posting) {
      return;
    }
    _safeEmit(state.copyWith(posting: true));
    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: fnPath,
        core: core,
        extern: extern,
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = envelope.data;

      final needsRefetch =
          asJsonMap(data['insertHint'])['needsRefetch'] == true;
      var applied = false;
      if (!needsRefetch) {
        final nextState = _buildMutationAppliedState(data);
        if (nextState != null) {
          _safeEmit(nextState);
          applied = true;
        }
      }

      _emitNotice('发布成功');
      if (!applied) {
        await loadInitial();
      }
    } catch (e) {
      _emitNotice('发布失败: $e');
    } finally {
      _safeEmit(state.copyWith(posting: false));
    }
  }

  CommentsViewState? _buildMutationAppliedState(Map<String, dynamic> data) {
    final createdMap = asJsonMap(data['created']);
    if (createdMap.isEmpty) {
      return null;
    }

    final created = CommentItem.fromMap(createdMap);
    final hint = asJsonMap(data['insertHint']);
    final strategy = hint['strategy']?.toString() ?? '';

    if (strategy == 'prependAfterTop') {
      return state.copyWith(items: <CommentItem>[created, ...state.items]);
    }

    if (strategy == 'prepend') {
      final targetCommentId =
          hint['targetCommentId']?.toString() ??
          data['parentId']?.toString() ??
          '';
      if (targetCommentId.isNotEmpty) {
        final currentReplies =
            state.replyItems[targetCommentId] ?? const <CommentItem>[];
        final replyItems = Map<String, List<CommentItem>>.from(state.replyItems)
          ..[targetCommentId] = <CommentItem>[created, ...currentReplies];
        final expandedIds = Set<String>.from(state.expandedIds)
          ..add(targetCommentId);
        final replyHasReachedMax = Map<String, bool>.from(
          state.replyHasReachedMax,
        )..[targetCommentId] = false;

        return state.copyWith(
          topItems: _bumpReplyCount(state.topItems, targetCommentId),
          items: _bumpReplyCount(state.items, targetCommentId),
          replyItems: replyItems,
          expandedIds: expandedIds,
          replyHasReachedMax: replyHasReachedMax,
        );
      }
    }

    return state.copyWith(items: <CommentItem>[created, ...state.items]);
  }

  List<CommentItem> _bumpReplyCount(
    List<CommentItem> source,
    String commentId,
  ) {
    final next = List<CommentItem>.from(source);
    for (var i = 0; i < next.length; i++) {
      if (next[i].id == commentId) {
        next[i] = next[i].copyWith(replyCount: next[i].replyCount + 1);
        break;
      }
    }
    return next;
  }

  Future<void> _loadReplies({
    required CommentItem item,
    required int page,
    required bool reset,
  }) async {
    if (state.replyLoading[item.id] == true) {
      return;
    }
    if (!reset && (state.replyHasReachedMax[item.id] == true)) {
      return;
    }

    final replyLoading = Map<String, bool>.from(state.replyLoading)
      ..[item.id] = true;
    _safeEmit(state.copyWith(replyLoading: replyLoading));

    try {
      final response = await callUnifiedComicPlugin(
        from: from,
        fnPath: 'loadCommentReplies',
        core: {'comicId': comicId, 'commentId': item.id, 'page': page},
        extern: item.extern,
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final data = envelope.data;
      final items = asJsonList(
        data['items'],
      ).map(asJsonMap).map(CommentItem.fromMap).toList();
      final paging = asJsonMap(data['paging']);
      final hasReachedMax = paging['hasReachedMax'] == true;

      final current = reset
          ? const <CommentItem>[]
          : (state.replyItems[item.id] ?? const <CommentItem>[]);

      final replyItems = Map<String, List<CommentItem>>.from(state.replyItems)
        ..[item.id] = <CommentItem>[...current, ...items];
      final nextReplyLoading = Map<String, bool>.from(state.replyLoading)
        ..[item.id] = false;
      final replyHasReachedMax = Map<String, bool>.from(
        state.replyHasReachedMax,
      )..[item.id] = hasReachedMax;
      final replyPage = Map<String, int>.from(state.replyPage)
        ..[item.id] = page + 1;

      _safeEmit(
        state.copyWith(
          replyItems: replyItems,
          replyLoading: nextReplyLoading,
          replyHasReachedMax: replyHasReachedMax,
          replyPage: replyPage,
        ),
      );
    } catch (_) {
      final nextReplyLoading = Map<String, bool>.from(state.replyLoading)
        ..[item.id] = false;
      _safeEmit(state.copyWith(replyLoading: nextReplyLoading));
    }
  }

  Future<_CommentFeed> _fetchPage(int page) async {
    final response = await callUnifiedComicPlugin(
      from: from,
      fnPath: 'getCommentFeed',
      core: {'comicId': comicId, 'page': page},
      extern: const <String, dynamic>{},
    );
    final envelope = UnifiedPluginEnvelope.fromMap(response);
    final data = envelope.data;
    final topItems = asJsonList(
      data['topItems'],
    ).map(asJsonMap).map(CommentItem.fromMap).toList();
    final items = asJsonList(
      data['items'],
    ).map(asJsonMap).map(CommentItem.fromMap).toList();
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

  void _emitNotice(String message) {
    _safeEmit(
      state.copyWith(noticeMessage: message, noticeId: state.noticeId + 1),
    );
  }

  void _safeEmit(CommentsViewState nextState) {
    if (isClosed) {
      return;
    }
    emit(nextState);
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

  final List<CommentItem> topItems;
  final List<CommentItem> items;
  final String replyMode;
  final bool canCommentComic;
  final bool canCommentReply;
  final bool hasReachedMax;
}
