import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/page/comic_read/method/image_header_size.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

Uint8List _png({required int width, required int height}) {
  final b = _bytes(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
    0x00, 0x00, 0x00, 0x0D, // IHDR length
    0x49, 0x48, 0x44, 0x52, // "IHDR"
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // width/height 占位
  ]);
  ByteData.sublistView(b).setUint32(16, width);
  ByteData.sublistView(b).setUint32(20, height);
  return b;
}

Uint8List _jpeg({required int width, required int height, int appPadding = 0}) {
  final b = BytesBuilder();
  b.add(<int>[0xFF, 0xD8]); // SOI
  if (appPadding > 0) {
    b.add(<int>[0xFF, 0xE0, (appPadding + 2) >> 8, (appPadding + 2) & 0xFF]);
    b.add(List<int>.filled(appPadding, 0)); // APPn 填充
  }
  // SOF0：length=17, precision=8, height, width
  b.add(<int>[
    0xFF, 0xC0, 0x00, 0x11, 0x08, //
    height >> 8, height & 0xFF, width >> 8, width & 0xFF, //
    0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
  ]);
  return b.toBytes();
}

Uint8List _gif({required int width, required int height}) {
  final b = _bytes(<int>[
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // "GIF89a"
    0x00, 0x00, 0x00, 0x00,
  ]);
  ByteData.sublistView(b).setUint16(6, width, Endian.little);
  ByteData.sublistView(b).setUint16(8, height, Endian.little);
  return b;
}

Uint8List _bmp({required int width, required int height}) {
  final b = Uint8List(26);
  b[0] = 0x42; // "B"
  b[1] = 0x4D; // "M"
  ByteData.sublistView(b).setInt32(18, width, Endian.little);
  ByteData.sublistView(b).setInt32(22, height, Endian.little);
  return b;
}

Uint8List _webPHeader(String fourcc, List<int> chunkData) {
  final b = BytesBuilder();
  b.add(<int>[0x52, 0x49, 0x46, 0x46]); // "RIFF"
  b.add(<int>[0x00, 0x00, 0x00, 0x00]); // 文件大小占位
  b.add(<int>[0x57, 0x45, 0x42, 0x50]); // "WEBP"
  b.add(fourcc.codeUnits);
  final chunkLength = chunkData.length;
  b.add(<int>[
    chunkLength & 0xFF,
    (chunkLength >> 8) & 0xFF,
    (chunkLength >> 16) & 0xFF,
    (chunkLength >> 24) & 0xFF,
  ]);
  b.add(chunkData);
  return b.toBytes();
}

Uint8List _webpVp8x({required int width, required int height}) {
  final w = width - 1;
  final h = height - 1;
  return _webPHeader('VP8X', <int>[
    0x00, 0x00, 0x00, 0x00, // flags + reserved
    w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF, //
    h & 0xFF, (h >> 8) & 0xFF, (h >> 16) & 0xFF,
  ]);
}

Uint8List _webpVp8l({required int width, required int height}) {
  final bits = (width - 1) | ((height - 1) << 14);
  return _webPHeader('VP8L', <int>[
    0x2F, // signature
    bits & 0xFF, (bits >> 8) & 0xFF, (bits >> 16) & 0xFF, (bits >> 24) & 0xFF,
    // 后续图像数据占位，凑足真实文件的最小长度
    0x00, 0x00, 0x00, 0x00, 0x00,
  ]);
}

Uint8List _webpVp8Lossy({required int width, required int height}) {
  return _webPHeader('VP8 ', <int>[
    0x00, 0x00, 0x00, // frame tag
    0x9D, 0x01, 0x2A, // start code
    width & 0xFF, (width >> 8) & 0xFF, //
    height & 0xFF, (height >> 8) & 0xFF,
  ]);
}

void main() {
  group('parseImageHeaderSize', () {
    test('解析 PNG', () {
      final size = parseImageHeaderSize(_png(width: 1024, height: 768));
      expect(size?.width, 1024);
      expect(size?.height, 768);
    });

    test('解析 JPEG（SOF 紧随 SOI）', () {
      final size = parseImageHeaderSize(_jpeg(width: 800, height: 1200));
      expect(size?.width, 800);
      expect(size?.height, 1200);
    });

    test('解析 JPEG（SOF 在较大的 APPn 段之后）', () {
      final size = parseImageHeaderSize(
        _jpeg(width: 4000, height: 3000, appPadding: 4096),
      );
      expect(size?.width, 4000);
      expect(size?.height, 3000);
    });

    test('解析 GIF', () {
      final size = parseImageHeaderSize(_gif(width: 320, height: 240));
      expect(size?.width, 320);
      expect(size?.height, 240);
    });

    test('解析 BMP', () {
      final size = parseImageHeaderSize(_bmp(width: 640, height: 480));
      expect(size?.width, 640);
      expect(size?.height, 480);
    });

    test('解析 WebP VP8X', () {
      final size = parseImageHeaderSize(_webpVp8x(width: 1920, height: 1080));
      expect(size?.width, 1920);
      expect(size?.height, 1080);
    });

    test('解析 WebP VP8L（无损）', () {
      final size = parseImageHeaderSize(_webpVp8l(width: 500, height: 700));
      expect(size?.width, 500);
      expect(size?.height, 700);
    });

    test('解析 WebP VP8（有损）', () {
      final size = parseImageHeaderSize(
        _webpVp8Lossy(width: 1280, height: 720),
      );
      expect(size?.width, 1280);
      expect(size?.height, 720);
    });

    test('无法识别的数据返回 null', () {
      expect(parseImageHeaderSize(_bytes(List<int>.filled(64, 0x42))), isNull);
    });

    test('截断的数据返回 null', () {
      expect(parseImageHeaderSize(_bytes(<int>[0x89, 0x50, 0x4E])), isNull);
      expect(parseImageHeaderSize(Uint8List(0)), isNull);
    });
  });

  group('readImageHeaderSize', () {
    test('从真实文件读取尺寸', () async {
      final dir = await Directory.systemTemp.createTemp('image_header_size');
      try {
        final file = File('${dir.path}/sample.png');
        await file.writeAsBytes(_png(width: 111, height: 222));
        final size = await readImageHeaderSize(file.path);
        expect(size?.width, 111);
        expect(size?.height, 222);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('文件不存在时返回 null', () async {
      final size = await readImageHeaderSize(
        '${Directory.systemTemp.path}/definitely_not_exist_12345.png',
      );
      expect(size, isNull);
    });
  });
}
