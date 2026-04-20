import 'package:zephyr/page/search_result/models/comic_number.dart';

class BlocState {
  bool hasReachedMax = false;
  int pagesCount = 0;
  List<ComicNumber> comics = [];
  List<ComicNumber> visibleComics = [];
  Map<String, dynamic> pluginExtern = const <String, dynamic>{};
  String maskedKeywordsFingerprint = '';

  BlocState({
    this.hasReachedMax = false,
    this.pagesCount = 0,
    this.comics = const [],
    this.visibleComics = const [],
    this.pluginExtern = const <String, dynamic>{},
    this.maskedKeywordsFingerprint = '',
  });
}
