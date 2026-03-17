import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zephyr/page/home/category.dart';

import '../../../../type/enum.dart';

part 'get_category_event.dart';

part 'get_category_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class GetCategoryBloc extends Bloc<GetCategoryStarted, GetCategoryState> {
  GetCategoryBloc() : super(const GetCategoryState()) {
    on<GetCategoryStarted>(
      _fetchCategories,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _fetchCategories(
    GetCategoryStarted event,
    Emitter<GetCategoryState> emit,
  ) async {
    emit(state.copyWith(status: GetCategoryStatus.initial));

    try {
      final response = await callUnifiedComicPlugin(
        from: From.bika,
        fnPath: 'getHomeData',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{'source': 'home'},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      final posts = {
        'data': {
          'categories': asList(envelope.data['categories'])
              .map((item) => asMap(item))
              .toList(),
        },
      };

      final List<HomeCategory> categories = disposeCategories(posts);

      emit(
        state.copyWith(
          status: GetCategoryStatus.success,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GetCategoryStatus.failure, result: e.toString()),
      );
    }
  }

  List<HomeCategory> disposeCategories(Map<String, dynamic> result) {
    final categoriesGlobal = <HomeCategory>[];
    final rawCategories = asList(asMap(result['data'])['categories'])
        .map((item) => asMap(item))
        .toList();

    categoriesGlobal.add(
      HomeCategory(
        title: '最近更新',
        homeThumb: HomeThumb(originalName: '', path: '', fileServer: ''),
        isWeb: false,
        active: true,
        link: 'asset/image/bika_image/cat_latest.jpg',
        id: '',
        description: '',
        action: const {
          'type': 'openSearch',
          'payload': {'mode': 'latest'},
        },
      ),
    );
    categoriesGlobal.add(
      HomeCategory(
        title: '随机本子',
        homeThumb: HomeThumb(originalName: '', path: '', fileServer: ''),
        isWeb: false,
        active: true,
        link: 'asset/image/bika_image/cat_random.jpg',
        id: '',
        description: '',
        action: const {
          'type': 'openSearch',
          'payload': {
            'mode': 'random',
            'url': 'https://picaapi.picacomic.com/comics/random',
          },
        },
      ),
    );

    for (final category in rawCategories) {
      final thumb = asMap(category['thumb']);
      categoriesGlobal.add(
        HomeCategory(
          title: category['title']?.toString() ?? '',
          homeThumb: HomeThumb(
            originalName: thumb['originalName']?.toString() ?? '',
            path: thumb['path']?.toString() ?? '',
            fileServer: thumb['fileServer']?.toString() ?? '',
          ),
          isWeb: category['isWeb'] == true,
          active: category['active'] == true,
          link: category['link']?.toString() ?? '',
          id: category['_id']?.toString() ?? '',
          description: category['description']?.toString() ?? '',
          action: asMap(category['action']),
        ),
      );
    }

    return categoriesGlobal;
  }
}
