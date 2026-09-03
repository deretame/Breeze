import 'dart:typed_data';

class QjsFetchImageHttpResult {
  const QjsFetchImageHttpResult({
    required this.bytes,
    this.statusCode,
    this.responseBodyLength,
    this.error,
  });

  static const int cborVersion = 1;

  final Uint8List bytes;
  final int? statusCode;
  final int? responseBodyLength;
  final String? error;

  factory QjsFetchImageHttpResult.fromCbor(Object? decoded) {
    if (decoded is! Map) {
      throw const FormatException('图片请求结果 CBOR 不是对象');
    }

    final version = _readInt(decoded['version'], field: 'version');
    if (version != cborVersion) {
      throw FormatException('不支持的图片请求结果 CBOR 版本: $version');
    }

    return QjsFetchImageHttpResult(
      bytes: _readBytes(decoded['bytes']),
      statusCode: _readNullableInt(decoded['statusCode'], field: 'statusCode'),
      responseBodyLength: _readNullableInt(
        decoded['responseBodyLength'],
        field: 'responseBodyLength',
      ),
      error: _readNullableString(decoded['error'], field: 'error'),
    );
  }

  static Uint8List _readBytes(Object? value) {
    if (value is Uint8List) {
      return value;
    }
    if (value is List) {
      final bytes = <int>[];
      for (final item in value) {
        final byte = _readInt(item, field: 'bytes');
        if (byte < 0 || byte > 255) {
          throw const FormatException('图片请求结果 bytes 包含无效字节');
        }
        bytes.add(byte);
      }
      return Uint8List.fromList(bytes);
    }
    throw const FormatException('图片请求结果缺少 bytes 字段');
  }

  static int _readInt(Object? value, {required String field}) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value.toInt();
    }
    throw FormatException('图片请求结果字段 $field 不是整数');
  }

  static int? _readNullableInt(Object? value, {required String field}) {
    if (value == null) {
      return null;
    }
    return _readInt(value, field: field);
  }

  static String? _readNullableString(Object? value, {required String field}) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('图片请求结果字段 $field 不是字符串');
  }
}
