import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/sundry.dart';

import '../../../../main.dart';
import '../../../../object_box/model.dart';
import '../../../../object_box/objectbox.g.dart';

part 'user_history_event.dart';
part 'user_history_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class UserHistoryBloc extends Bloc<UserHistoryEvent, UserHistoryState> {
  UserHistoryBloc() : super(UserHistoryState()) {
    on<UserHistoryEvent>(
      _fetchComicList,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  bool initial = true;
  int totalComicCount = 0;

  Future<void> _fetchComicList(
    UserHistoryEvent event,
    Emitter<UserHistoryState> emit,
  ) async {
    if (state.searchEnterConst == event.searchEnterConst && initial == false) {
      return; // 如果状态相同，直接返回，避免再次请求
    }

    if (initial) {
      emit(
        state.copyWith(
          status: UserHistoryStatus.initial,
          comics: [],
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }

    try {
      emit(
        state.copyWith(
          status: UserHistoryStatus.success,
          comics: _getComicList(event),
          searchEnterConst: event.searchEnterConst,
          result: totalComicCount.toString(),
        ),
      );
      initial = false;
    } catch (e) {
      emit(
        state.copyWith(
          status: UserHistoryStatus.failure,
          result: e.toString(),
          searchEnterConst: event.searchEnterConst,
        ),
      );
    }
  }

  List<UnifiedComicHistory> _fetchOfSort(
    List<UnifiedComicHistory> comicList,
    String sort,
  ) {
    if (sort == "dd") {
      comicList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    if (sort == "da") {
      comicList.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    }
    if (sort == "ld") {
      comicList.sort((a, b) => _likes(a).compareTo(_likes(b)));
    }
    if (sort == "vd") {
      comicList.sort((a, b) => _views(b).compareTo(_views(a)));
    }
    return comicList;
  }

  List<UnifiedComicHistory> _filterShieldedComics(
    List<UnifiedComicHistory> comics,
  ) {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    // 获取所有被屏蔽的分类
    List<String> shieldedCategoriesList = settings.shieldCategoryMap.entries
        .where((entry) => entry.value) // 只选择值为 true 的条目
        .map((entry) => entry.key) // 提取键（分类名）
        .toList();

    // 过滤掉包含屏蔽分类的漫画
    return comics.where((comic) {
      final metadata = _historyMetadata(comic.metadata);
      // 检查该漫画的分类是否与屏蔽分类列表中的任何分类匹配
      return !metadata.any((entry) {
        final type = entry['type']?.toString();
        if (type != 'categories') return false;
        final values = asJsonList(
          entry['value'],
        ).map((e) => asJsonMap(e)['name']?.toString() ?? '').toList();
        return values.any(shieldedCategoriesList.contains);
      });
    }).toList();
  }

  List<dynamic> _getComicList(UserHistoryEvent event) {
    logger.d("event: $event");
    List<dynamic> comics = [];
    final sourceFilter = event.searchEnterConst.sources
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    for (final source in sourceFilter) {
      var comicList = objectbox.unifiedHistoryBox
          .query(UnifiedComicHistory_.source.equals(source))
          .build()
          .find();

      totalComicCount = comicList.length;
      comicList = _filterShieldedComics(comicList);

      if (event.searchEnterConst.categories.isNotEmpty) {
        for (var category in event.searchEnterConst.categories) {
          comicList = comicList.where((comic) {
            final metadata = _historyMetadata(comic.metadata);
            return metadata.any((entry) {
              if (entry['type']?.toString() != 'categories') return false;
              final values = asJsonList(
                entry['value'],
              ).map((e) => asJsonMap(e)['name']?.toString() ?? '').toList();
              return values.contains(category);
            });
          }).toList();
        }
      }

      if (event.searchEnterConst.keyword.isNotEmpty) {
        final keyword = event.searchEnterConst.keyword.toLowerCase().let(t2s);

        comicList = comicList.where((comic) {
          var allString =
              comic.comicId +
              comic.title +
              comic.description +
              _historyCreatorName(comic.creator) +
              comic.metadata.toString();
          return allString.toLowerCase().let(t2s).contains(keyword);
        }).toList();
      }

      comicList.removeWhere((comic) => comic.deleted == true);
      comics.addAll(comicList);
    }

    comics = _fetchOfSort(
      comics.cast<UnifiedComicHistory>().toList(),
      event.searchEnterConst.sort,
    );
    return comics;
  }

  int _likes(UnifiedComicHistory item) {
    return 0;
  }

  int _views(UnifiedComicHistory item) {
    for (final entry in _historyTitleMeta(item.titleMeta)) {
      final name = entry['name']?.toString() ?? '';
      if (name.startsWith('浏览：')) {
        return int.tryParse(name.substring(3)) ?? 0;
      }
    }
    return 0;
  }
}

String _historyCreatorName(String creatorJson) {
  if (creatorJson.trim().isEmpty) {
    return '';
  }
  try {
    final decoded = jsonDecode(creatorJson);
    if (decoded is Map) {
      return decoded['name']?.toString() ?? '';
    }
  } catch (_) {}
  return '';
}

List<Map<String, dynamic>> _historyTitleMeta(String titleMetaJson) {
  if (titleMetaJson.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(titleMetaJson);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

List<Map<String, dynamic>> _historyMetadata(String metadataJson) {
  if (metadataJson.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(metadataJson);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}
