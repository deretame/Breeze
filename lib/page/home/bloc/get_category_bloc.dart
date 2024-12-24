import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../main.dart';
import '../../../network/http/http_request.dart';
import '../json/categories/categories.dart';
import '../models/category.dart';

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
    emit(
      state.copyWith(
        status: GetCategoryStatus.initial,
      ),
    );

    try {
      var posts = await getCategories();

      final List<HomeCategory> categories = disposeCategories(posts);

      emit(
        state.copyWith(
          status: GetCategoryStatus.success,
          categories: categories,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GetCategoryStatus.failure,
          result: e.toString(),
        ),
      );
    }
  }

  List<HomeCategory> disposeCategories(
    Map<String, dynamic> result,
  ) {
    late List<HomeCategory> categoriesGlobal = [];
    // 值里面缺胳膊少腿的比较多，需要处理一下
    var temp = result['data']['categories'];
    for (var category in temp) {
      category['isWeb'] = category['isWeb'] ?? false;
      category['active'] = category['active'] ?? false;
      category['link'] = category['link'] ?? '';
      category['description'] = category['description'] ?? '';
      category['_id'] = category['_id'] ?? '';
    }
    result['data']['categories'] = temp;

    List<String> shieldList = bikaSetting.shieldCategoryMap.keys
        .where((key) => bikaSetting.shieldCategoryMap[key] == true)
        .toList();
    try {
      var temp = Categories.fromJson(result);
      debugPrint(temp.toString());
      // 下面两个不会出现在请求结果中，所以直接添加进去
      categoriesGlobal.add(
        HomeCategory(
          title: '最近更新',
          homeThumb: HomeThumb(originalName: '', path: '', fileServer: ''),
          isWeb: false,
          active: true,
          link: 'asset/image/bika_image/cat_latest.jpg',
          id: '',
          description: '',
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
        ),
      );
      for (var category in temp.data.categories) {
        var temp = HomeCategory(
          title: category.title,
          homeThumb: HomeThumb(
            originalName: category.thumb.originalName,
            path: category.thumb.path,
            fileServer: category.thumb.fileServer,
          ),
          isWeb: category.isWeb!,
          active: category.active!,
          link: category.link!,
          id: category.id!,
          description: category.description!,
        );
        if (!shieldList.any((string) => string.contains(temp.title))) {
          categoriesGlobal.add(temp);
        }
      }
    } catch (e) {
      rethrow;
    }

    return categoriesGlobal;
  }
}
