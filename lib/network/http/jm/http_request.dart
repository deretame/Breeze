import '../../../config/jm/config.dart';
import 'http_request_build.dart';

Future<Map<String, dynamic>> search(
  String keyword,
  String sort,
  int page,
) async => await request(
  '${JmConfig.baseUrl}/search',
  params: {"search_query": keyword, "page": page, "o": sort},
);

Future<Map<String, dynamic>> getComicInfo(String comicId) async =>
    await request(
      '${JmConfig.baseUrl}/album',
      params: {'id': comicId},
      cache: true,
    );
