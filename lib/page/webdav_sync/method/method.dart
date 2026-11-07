import 'dart:convert';

import 'package:minio/minio.dart';
import 'package:zephyr/config/global/global.dart';

import 'package:zephyr/main.dart';

Future<void> testWebDavServer(
  String host,
  String username,
  String password,
) async {
  final client = WindHttp(
    baseUrl: host,
    headers: {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  try {
    logger.d('请求 URL: ${client.baseUrl}\n请求头: ${client.defaultHeaders}');

    final response = await client.fetch('/', method: 'OPTIONS');

    final FetchResponse propfindResponse;
    try {
      propfindResponse = await client.fetch(
        '/${appName}_$syncVersion/',
        method: 'PROPFIND',
        headers: {'Depth': '0'},
      );
    } on FetchException catch (e) {
      // 404 表示服务可用，只是同步目录尚未创建。
      if (e.status == 404) {
        logger.d(
          'WebDAV 服务可用\n支持的 HTTP 方法: ${response.header('allow') ?? response.headers['allow']}',
        );
        return;
      }
      rethrow;
    }

    if (propfindResponse.status == 207) {
      logger.d(
        'WebDAV 服务可用\n支持的 HTTP 方法: ${response.header('allow') ?? response.headers['allow']}',
      );
      return;
    }

    throw Exception('WebDAV PROPFIND 检查失败，状态码: ${propfindResponse.status}');
  } catch (e) {
    throw Exception('连接失败: $e');
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
  required bool pathStyle,
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
    pathStyle: pathStyle,
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
