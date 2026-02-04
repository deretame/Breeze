import 'package:zephyr/page/search_result/models/comic_number.dart';

class BlocState {
  bool hasReachedMax = false;
  int pagesCount = 0;
  List<ComicNumber> comics = [];

  BlocState({
    this.hasReachedMax = false,
    this.pagesCount = 0,
    this.comics = const [],
  });
}
