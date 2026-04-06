import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:minio/minio.dart';
import 'package:zephyr/config/global/global.dart';

import '../../../main.dart';

Future<void> testWebDavServer(
  String host,
  String username,
  String password,
) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: host,
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  try {
    logger.d('请求 URL: ${dio.options.baseUrl}\n请求头: ${dio.options.headers}');

    final response = await dio.request(
      '/',
      options: Options(method: 'OPTIONS'),
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('WebDAV 服务返回异常状态码: ${response.statusCode}');
    }

    final propfindResponse = await dio.request(
      '/${appName}_$syncVersion/',
      options: Options(
        method: 'PROPFIND',
        headers: {'Depth': '0'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final propfindCode = propfindResponse.statusCode ?? 0;
    if (propfindCode == 207 || propfindCode == 404) {
      logger.d('WebDAV 服务可用\n支持的 HTTP 方法: ${response.headers['allow']}');
      return;
    }

    throw Exception('WebDAV PROPFIND 检查失败，状态码: $propfindCode');
  } on DioException catch (e) {
    if (e.response != null) {
      logger.e(
        '响应状态码: ${e.response?.statusCode}\n响应头: ${e.response?.headers}\n响应体: ${e.response?.data}\n',
      );
      throw Exception('WebDAV 服务返回错误: ${e.response?.statusCode}');
    } else {
      throw Exception('连接失败: ${e.message}');
    }
  } catch (e) {
    throw Exception('未知错误: $e');
  }
}

Future<void> testS3Server({
  required String endpoint,
  required String accessKey,
  required String secretKey,
  required String bucket,
  required bool useSSL,
  required int port,
  required String region,
}) async {
  if (endpoint.isEmpty ||
      accessKey.isEmpty ||
      secretKey.isEmpty ||
      bucket.isEmpty) {
    throw Exception('S3 配置不完整');
  }

  final resolved = _resolveEndpoint(endpoint, port);

  final minio = Minio(
    endPoint: resolved.host,
    port: resolved.port,
    accessKey: accessKey,
    secretKey: secretKey,
    useSSL: useSSL,
    region: region.isEmpty ? null : region,
  );

  try {
    final exists = await minio.bucketExists(bucket);
    if (!exists) {
      throw Exception('S3 Bucket 不存在或没有访问权限');
    }
  } catch (e) {
    throw Exception('S3 连接失败: $e');
  }
}

class _ResolvedEndpoint {
  const _ResolvedEndpoint({required this.host, required this.port});

  final String host;
  final int? port;
}

_ResolvedEndpoint _resolveEndpoint(String endpoint, int configuredPort) {
  final trimmed = endpoint.trim();
  final raw = trimmed.startsWith('http://') || trimmed.startsWith('https://')
      ? trimmed
      : 'https://$trimmed';
  final uri = Uri.tryParse(raw);

  if (uri == null || uri.host.isEmpty) {
    throw Exception('S3 Endpoint 格式错误');
  }

  final resolvedPort = configuredPort > 0
      ? configuredPort
      : (uri.hasPort ? uri.port : null);

  return _ResolvedEndpoint(host: uri.host, port: resolvedPort);
}
