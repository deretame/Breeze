import 'dart:typed_data';

import 'package:cbor/simple.dart' as cbor;
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/network/http/plugin/qjs_fetch_image_result.dart';

void main() {
  test('decodes a CBOR image result with binary data and HTTP metadata', () {
    final encoded = cbor.cbor.encode({
      'version': 1,
      'bytes': Uint8List.fromList([0, 1, 255]),
      'statusCode': 404,
      'responseBodyLength': 3,
      'error': 'HTTP 404',
    });

    final result = QjsFetchImageHttpResult.fromCbor(cbor.cbor.decode(encoded));

    expect(result.bytes, [0, 1, 255]);
    expect(result.statusCode, 404);
    expect(result.responseBodyLength, 3);
    expect(result.error, 'HTTP 404');
  });

  test('rejects an unsupported CBOR result version', () {
    final encoded = cbor.cbor.encode({
      'version': 2,
      'bytes': Uint8List(0),
      'statusCode': null,
      'responseBodyLength': null,
      'error': null,
    });

    expect(
      () => QjsFetchImageHttpResult.fromCbor(cbor.cbor.decode(encoded)),
      throwsA(isA<FormatException>()),
    );
  });
}
