import 'package:dio/dio.dart';
import 'package:zephyr/network/http/bika/pica_client.dart';

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  dynamic body,
  bool cache = false,
  String? imageQuality,
  String? authorization,
}) async {
  try {
    final response = await PicaClient().dio.request(
      url,
      data: body,
      options: Options(
        method: method,
        extra: {
          'imageQuality': imageQuality,
          'authorization': authorization,
          'useCache': cache,
        },
      ),
    );

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw Exception(e.error);
  }
}
