import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

class ImageSizeCacheStore {
  static const List<int> _magic = <int>[0x50, 0x53, 0x48, 0x31]; // PSH1
  static const List<int> _zstdCompressedMagic = <int>[
    0x50,
    0x53,
    0x5a,
    0x32,
  ]; // PSZ2 (zstd)

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

    final payload = builder.toBytes();
    final compressed = await zstdCompressBytes(raw: payload, level: 10);
    final output = BytesBuilder(copy: false)
      ..add(_zstdCompressedMagic)
      ..add(compressed);

    final tmpFile = File('$filePath.tmp');
    await tmpFile.writeAsBytes(output.toBytes(), flush: true);
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

    final payload = await _readPayloadOrDelete(file);
    if (payload == null || !_isPayloadStructValid(payload)) {
      return (recordCount: 0, fileBytes: 0, filePath: filePath);
    }

    final fileBytes = await file.length();
    final data = ByteData.sublistView(payload);
    final recordCount = data.getUint32(_magic.length, Endian.little);
    return (recordCount: recordCount, fileBytes: fileBytes, filePath: filePath);
  }

  Future<String> cacheFilePath() async {
    final fileRoot = await getFilePath();
    final dir = p.join(fileRoot, 'pictureCache');
    final fileName = '${_hashIdentityHex(sourceTag, pageKeys)}.bin';
    return p.join(dir, fileName);
  }

  Future<Map<int, Size>> _readFromDisk() async {
    final file = File(await cacheFilePath());
    if (!await file.exists()) return <int, Size>{};

    final payload = await _readPayloadOrDelete(file);
    if (payload == null || !_isPayloadStructValid(payload)) {
      await _safeDelete(file);
      return <int, Size>{};
    }

    return _parsePayload(payload);
  }

  Future<Uint8List?> _readPayloadOrDelete(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final payload = await _decodePayload(bytes);
      if (payload != null) return payload;
    } catch (_) {
      // ignore
    }
    await _safeDelete(file);
    return null;
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // ignore
    }
  }

  bool _isPayloadStructValid(Uint8List bytes) {
    if (bytes.length < 8 || !_isMagicMatched(bytes)) return false;
    final data = ByteData.sublistView(bytes);
    final count = data.getUint32(_magic.length, Endian.little);
    final expectedBytes = 8 + (count * 12);
    return expectedBytes <= bytes.length;
  }

  Map<int, Size> _parsePayload(Uint8List bytes) {
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

  Future<Uint8List?> _decodePayload(Uint8List bytes) async {
    if (bytes.length < 4) return null;
    if (!_isZstdCompressedMagicMatched(bytes)) return null;

    try {
      final decoded = await zstdDecompressBytes(encoded: bytes.sublist(4));
      return Uint8List.fromList(decoded);
    } catch (_) {
      return null;
    }
  }

  bool _isMagicMatched(Uint8List bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  bool _isZstdCompressedMagicMatched(Uint8List bytes) {
    if (bytes.length < _zstdCompressedMagic.length) return false;
    for (var i = 0; i < _zstdCompressedMagic.length; i++) {
      if (bytes[i] != _zstdCompressedMagic[i]) return false;
    }
    return true;
  }

  String _hashIdentityHex(String source, List<String> keys) {
    final builder = BytesBuilder(copy: false)
      ..add(utf8.encode(source))
      ..addByte(0x00);
    for (final key in keys) {
      builder
        ..add(utf8.encode(key))
        ..addByte(0x1f);
    }
    return sha256.convert(builder.toBytes()).toString();
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
}
