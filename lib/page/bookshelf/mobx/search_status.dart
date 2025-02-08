import 'package:mobx/mobx.dart';

part 'search_status.g.dart';

enum BookShelfStatus { favourite, history, download }

// ignore: library_private_types_in_public_api
class SearchStatusStore = _SearchStatusStore with _$SearchStatusStore;

abstract class _SearchStatusStore with Store {
  @observable
  BookShelfStatus status = BookShelfStatus.favourite;
  @observable
  int pageCount = 0;
  @observable
  String refresh = "";
  @observable
  String keyword = "";
  @observable
  String sort = "";
  @observable
  List<String> categories = ObservableList<String>();

  @action
  void setStatus(BookShelfStatus status) {
    this.status = status;
  }

  @action
  void setPageCount(int pageCount) {
    this.pageCount = pageCount;
  }

  @action
  void setRefresh(String refresh) {
    this.refresh = refresh;
  }

  @action
  void setKeyword(String keyword) {
    this.keyword = keyword;
  }

  @action
  void setSort(String sort) {
    this.sort = sort;
  }

  @action
  void setCategories(List<String> categories) {
    this.categories = ObservableList<String>();
    this.categories = ObservableList<String>.of(categories);
  }
}
