import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/json/json_dispose.dart';

part 'promote_bloc.freezed.dart';
part 'promote_event.dart';
part 'promote_state.dart';

const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class PromoteBloc extends Bloc<PromoteEvent, PromoteState> {
  PromoteBloc() : super(PromoteState()) {
    on<PromoteEvent>(
      _fetchPromote,
      transformer: _throttleDroppable(_throttleDuration),
    );
  }

  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> suggestionItems = [];
  bool hasReachedMax = false;

  Future<void> _fetchPromote(
    PromoteEvent event,
    Emitter<PromoteState> emit,
  ) async {
    if (event.status == PromoteStatus.initial) {
      emit(
        state.copyWith(
          status: PromoteStatus.initial,
          sections: [],
          suggestionItems: [],
          hasReachedMax: false,
        ),
      );
      sections = [];
      suggestionItems = [];
      hasReachedMax = false;
    }

    int page = 0;
    if (event.page != -1) {
      page = event.page;
    }
    if (event.status == PromoteStatus.initial) {
      page = -1;
    }

    try {
      if (page == -1) {
        final response = await callUnifiedComicPlugin(
          from: From.jm,
          fnPath: 'getHomeData',
          core: {'page': -1, 'path': '${JmConfig.baseUrl}/promote?page=0'},
          extern: const {
            'source': 'home',
            'promotePath': 'https://www.cdnsha.org/promote?page=0',
          },
        );
        final envelope = UnifiedPluginEnvelope.fromMap(response);

        final promoteRaw = replaceNestedNullList(asList(envelope.data['sections']));
        final promoteData = promoteRaw
            .map((item) => item as Map<String, dynamic>)
            .toList();
        promoteData.removeWhere((e) => e['title'] == '禁漫书库');
        promoteData.removeWhere((e) => e['title'] == '禁漫去码&全彩化');
        promoteData.removeWhere((e) => e['title'] == '禁漫小说');
        sections = promoteData
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        if (hasReachedMax) {
          return;
        }
        emit(
          state.copyWith(
            status: PromoteStatus.loadingMore,
            sections: sections,
            suggestionItems: suggestionItems,
            hasReachedMax: hasReachedMax,
          ),
        );
        final response = await callUnifiedComicPlugin(
          from: From.jm,
          fnPath: 'getHomeData',
          core: {'page': page, 'path': '${JmConfig.baseUrl}/latest'},
          extern: const {
            'source': 'home',
            'suggestionPath': 'https://www.cdnsha.org/latest',
          },
        );
        final envelope = UnifiedPluginEnvelope.fromMap(response);
        final suggestionRaw = replaceNestedNullList(
          asList(envelope.data['suggestionItems']),
        );
        final temp = suggestionRaw
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        hasReachedMax = asMap(envelope.data)['hasReachedMax'] == true;
        suggestionItems = [...suggestionItems, ...temp];
      }

      emit(
        state.copyWith(
          status: PromoteStatus.success,
          sections: sections,
          suggestionItems: suggestionItems,
          hasReachedMax: hasReachedMax,
          result: page.toString(),
        ),
      );
    } catch (e, stackTrace) {
      logger.e(e, stackTrace: stackTrace);

      if (sections.isNotEmpty) {
        emit(
          state.copyWith(
            status: PromoteStatus.loadingMoreFailure,
            sections: sections,
            suggestionItems: suggestionItems,
            hasReachedMax: hasReachedMax,
            result: e.toString(),
          ),
        );
        return;
      }

      emit(state.copyWith(status: PromoteStatus.failure, result: e.toString()));
    }
  }
}
