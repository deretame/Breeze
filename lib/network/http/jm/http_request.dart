import '../../../config/jm/config.dart';
import 'http_request_build.dart';

Future<Map<String, dynamic>> search(String keyword, String sort) async {
  return await request(
    JmConfig.baseUrl,
    params: {"search_query": keyword, "sort_by": sort},
  );
}
