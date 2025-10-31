import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_status.freezed.dart'; // 运行 build_runner 生成

enum BookShelfStatus { favourite, history, download }

@freezed
abstract class SearchStatusState with _$SearchStatusState {
  const factory SearchStatusState({
    @Default(BookShelfStatus.favourite) BookShelfStatus status,
    @Default(0) int pageCount,
    @Default("") String refresh,
    @Default("") String keyword,
    @Default("dd") String sort,
    @Default(<String>[]) List<String> categories,
  }) = _SearchStatusState;
}

class SearchStatusCubit extends Cubit<SearchStatusState> {
  // 构造函数，传入由 freezed 生成的默认 state
  SearchStatusCubit() : super(const SearchStatusState());

  void setStatus(BookShelfStatus status) {
    emit(state.copyWith(status: status));
  }

  void setPageCount(int pageCount) {
    emit(state.copyWith(pageCount: pageCount));
  }

  void setRefresh(String refresh) {
    emit(state.copyWith(refresh: refresh));
  }

  void setKeyword(String keyword) {
    emit(state.copyWith(keyword: keyword));
  }

  void setSort(String sort) {
    emit(state.copyWith(sort: sort));
  }

  void setCategories(List<String> categories) {
    emit(state.copyWith(categories: categories));
  }

  void resetSearch() {
    emit(const SearchStatusState());
  }
}
