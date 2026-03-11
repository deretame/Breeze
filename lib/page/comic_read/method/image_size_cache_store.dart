import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/util/get_path.dart';

class ImageSizeCacheStore {
  static const List<int> _magic = <int>[0x50, 0x53, 0x48, 0x31]; // PSH1

  final String sourceTag;
  final List<String> pageKeys;

  ImageSizeCacheStore({required this.sourceTag, required this.pageKeys});

  Future<Map<int, Size>> readIndexedSizes({
    required List<String> pageKeys,
    required int count,
  }) async {
    final persisted = await _readFromDisk();
    if (persisted.isEmpty) return <int, Size>{};

    final out = <int, Size>{};
    final max = count < pageKeys.length ? count : pageKeys.length;
    for (var i = 0; i < max; i++) {
      final size = persisted[_hashKey64(pageKeys[i])];
      if (size != null) {
        out[i] = size;
      }
    }
    return out;
  }

  Future<void> write({
    required List<String> pageKeys,
    required Map<int, Size> sizeCache,
    required Set<int> resolvedIndices,
    required int count,
  }) async {
    final filePath = await cacheFilePath();
    final file = File(filePath);
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (resolvedIndices.isEmpty) return;

    final records = <({int keyHash, int width, int height})>[];
    final max = count < pageKeys.length ? count : pageKeys.length;
    for (var i = 0; i < max; i++) {
      if (!resolvedIndices.contains(i)) continue;
      final size = sizeCache[i];
      if (size == null || size.width <= 0 || size.height <= 0) continue;

      final width = size.width.round().clamp(1, 65535);
      final height = size.height.round().clamp(1, 65535);
      records.add((
        keyHash: _hashKey64(pageKeys[i]),
        width: width,
        height: height,
      ));
    }

    if (records.isEmpty) return;

    final builder = BytesBuilder(copy: false);
    builder.add(_magic);
    final header = ByteData(4)..setUint32(0, records.length, Endian.little);
    builder.add(header.buffer.asUint8List());

    for (final rec in records) {
      final record = ByteData(12);
      record.setUint64(0, rec.keyHash, Endian.little);
      record.setUint16(8, rec.width, Endian.little);
      record.setUint16(10, rec.height, Endian.little);
      builder.add(record.buffer.asUint8List());
    }

    final tmpFile = File('$filePath.tmp');
    await tmpFile.writeAsBytes(builder.toBytes(), flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmpFile.rename(filePath);
  }

  Future<({int recordCount, int fileBytes, String filePath})> getStats() async {
    final filePath = await cacheFilePath();
    final file = File(filePath);
    if (!await file.exists()) {
      return (recordCount: 0, fileBytes: 0, filePath: filePath);
    }

    final fileBytes = await file.length();
    final bytes = await file.readAsBytes();
    if (bytes.length < 8 || !_isMagicMatched(bytes)) {
      return (recordCount: 0, fileBytes: fileBytes, filePath: filePath);
    }
    final data = ByteData.sublistView(bytes);
    final recordCount = data.getUint32(_magic.length, Endian.little);
    return (recordCount: recordCount, fileBytes: fileBytes, filePath: filePath);
  }

  Future<String> cacheFilePath() async {
    final fileRoot = await getFilePath();
    final dir = p.join(fileRoot, 'pictureCache');
    final fileName =
        '${_safeFileSegment(sourceTag)}_${_hashAllPageKeysHex(pageKeys)}.bin';
    return p.join(dir, fileName);
  }

  Future<Map<int, Size>> _readFromDisk() async {
    final file = File(await cacheFilePath());
    if (!await file.exists()) return <int, Size>{};

    final bytes = await file.readAsBytes();
    if (bytes.length < 8) return <int, Size>{};

    var offset = 0;
    if (!_isMagicMatched(bytes)) return <int, Size>{};
    offset += _magic.length;

    final data = ByteData.sublistView(bytes);
    final count = data.getUint32(offset, Endian.little);
    offset += 4;

    final out = <int, Size>{};
    for (var i = 0; i < count; i++) {
      if (offset + 12 > bytes.length) break;
      final keyHash = data.getUint64(offset, Endian.little);
      offset += 8;
      final width = data.getUint16(offset, Endian.little);
      offset += 2;
      final height = data.getUint16(offset, Endian.little);
      offset += 2;

      if (width == 0 || height == 0) continue;
      out[keyHash] = Size(width.toDouble(), height.toDouble());
    }

    return out;
  }

  bool _isMagicMatched(Uint8List bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  String _safeFileSegment(String value) {
    if (value.isEmpty) return 'unknown';
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  int _hashKey64(String value) {
    const int offsetBasis = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    const int mask = 0xFFFFFFFFFFFFFFFF;

    var hash = offsetBasis;
    final bytes = utf8.encode(value);
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    return hash;
  }

  String _hashAllPageKeysHex(List<String> keys) {
    const int offsetBasis = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    const int mask = 0xFFFFFFFFFFFFFFFF;

    var hash = offsetBasis;
    for (final key in keys) {
      final bytes = utf8.encode(key);
      for (final byte in bytes) {
        hash ^= byte;
        hash = (hash * prime) & mask;
      }
      hash ^= 0x1f;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
