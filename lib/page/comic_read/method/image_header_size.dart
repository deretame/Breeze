import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Size;

/// 探测时读取的最大字节数。
///
/// 只读取文件头来解析尺寸，避免为获取宽高而完整解码图片。
/// JPEG 的 SOF 段偶尔排在较大的 APPn（EXIF 等）段之后，256KB 足够覆盖常见情况。
const int _kProbeBytes = 256 * 1024;

/// 从图片文件头解析原始像素尺寸（不做完整解码）。
///
/// 支持 PNG / JPEG / GIF / BMP / WebP；无法识别或解析失败时返回 null。
Future<Size?> readImageHeaderSize(String filePath) async {
  RandomAccessFile? raf;
  try {
    raf = await File(filePath).open();
    final bytes = await raf.read(_kProbeBytes);
    return parseImageHeaderSize(bytes);
  } catch (_) {
    return null;
  } finally {
    await raf?.close();
  }
}

/// 从图片头字节序列解析原始像素尺寸，无法识别时返回 null。
Size? parseImageHeaderSize(Uint8List bytes) {
  if (bytes.length < 10) return null;
  return _parsePng(bytes) ??
      _parseJpeg(bytes) ??
      _parseGif(bytes) ??
      _parseBmp(bytes) ??
      _parseWebP(bytes);
}

Size? _parsePng(Uint8List b) {
  const sig = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (b.length < 24) return null;
  for (var i = 0; i < sig.length; i++) {
    if (b[i] != sig[i]) return null;
  }
  final data = ByteData.sublistView(b);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  if (width <= 0 || height <= 0) return null;
  return Size(width.toDouble(), height.toDouble());
}

Size? _parseJpeg(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;

  // 逐段扫描，直到找到 SOF0-SOF15（不含 DHT/DAC/JPG 扩展）段。
  var offset = 2;
  while (offset + 1 < b.length) {
    if (b[offset] != 0xFF) {
      offset++;
      continue;
    }
    var markerIndex = offset + 1;
    while (markerIndex < b.length && b[markerIndex] == 0xFF) {
      markerIndex++;
    }
    if (markerIndex >= b.length) return null;
    final marker = b[markerIndex];
    offset = markerIndex + 1;

    // 独立标记（无长度字段）。
    if (marker == 0x00 ||
        marker == 0x01 ||
        marker == 0xD8 ||
        marker == 0xD9 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      continue;
    }
    if (offset + 2 > b.length) return null;
    final segmentLength = (b[offset] << 8) | b[offset + 1];
    if (segmentLength < 2) return null;

    final isStartOfFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isStartOfFrame) {
      if (offset + 7 > b.length) return null;
      final height = (b[offset + 3] << 8) | b[offset + 4];
      final width = (b[offset + 5] << 8) | b[offset + 6];
      if (width <= 0 || height <= 0) return null;
      return Size(width.toDouble(), height.toDouble());
    }
    offset += segmentLength;
  }
  return null;
}

Size? _parseGif(Uint8List b) {
  if (b.length < 10) return null;
  // "GIF"
  if (b[0] != 0x47 || b[1] != 0x49 || b[2] != 0x46) return null;
  final data = ByteData.sublistView(b);
  final width = data.getUint16(6, Endian.little);
  final height = data.getUint16(8, Endian.little);
  if (width <= 0 || height <= 0) return null;
  return Size(width.toDouble(), height.toDouble());
}

Size? _parseBmp(Uint8List b) {
  if (b.length < 26) return null;
  // "BM"
  if (b[0] != 0x42 || b[1] != 0x4D) return null;
  final data = ByteData.sublistView(b);
  final width = data.getInt32(18, Endian.little);
  final height = data.getInt32(22, Endian.little).abs();
  if (width <= 0 || height <= 0) return null;
  return Size(width.toDouble(), height.toDouble());
}

Size? _parseWebP(Uint8List b) {
  if (b.length < 30) return null;
  // "RIFF" .... "WEBP"
  if (b[0] != 0x52 || b[1] != 0x49 || b[2] != 0x46 || b[3] != 0x46) return null;
  if (b[8] != 0x57 || b[9] != 0x45 || b[10] != 0x42 || b[11] != 0x50) {
    return null;
  }

  final data = ByteData.sublistView(b);
  final fourcc = String.fromCharCodes(b.sublist(12, 16));
  switch (fourcc) {
    case 'VP8X':
      // 画布宽高为 24 位小端（值 = 实际 - 1）。
      final width = 1 + (b[24] | (b[25] << 8) | (b[26] << 16));
      final height = 1 + (b[27] | (b[28] << 8) | (b[29] << 16));
      return Size(width.toDouble(), height.toDouble());
    case 'VP8L':
      if (b[20] != 0x2F) return null;
      final bits = data.getUint32(21, Endian.little);
      final width = 1 + (bits & 0x3FFF);
      final height = 1 + ((bits >> 14) & 0x3FFF);
      return Size(width.toDouble(), height.toDouble());
    case 'VP8 ':
      // 帧头 3 字节 + 起始码 0x9D 0x01 0x2A，随后是 14 位宽高。
      if (b[23] != 0x9D || b[24] != 0x01 || b[25] != 0x2A) return null;
      final width = data.getUint16(26, Endian.little) & 0x3FFF;
      final height = data.getUint16(28, Endian.little) & 0x3FFF;
      if (width <= 0 || height <= 0) return null;
      return Size(width.toDouble(), height.toDouble());
  }
  return null;
}
