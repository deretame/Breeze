import '../../../config/jm/config.dart';
import 'http_request_build.dart';

Future<Map<String, dynamic>> search(
  String keyword,
  String sort,
  int page,
) async {
  return await request(
    '${JmConfig.baseUrl}/search',
    params: {"search_query": keyword, "page": page, "o": sort},
  );
}
