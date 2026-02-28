import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';

class JmResponseCodec {
  static dynamic decode(dynamic data, {String? ts}) {
    if (data == null) {
      return null;
    }

    final debugEnabled = _isDebugEnabled();
    _debugLog(
      debugEnabled,
      '开始解析: rawType=${_describeType(data)}, hasTs=${ts != null && ts.isNotEmpty}',
    );

    try {
      final normalizedData = _normalizeRawData(data);
      final result = _decodeValue(
        normalizedData,
        ts: ts,
        debugEnabled: debugEnabled,
      );
      _debugLog(debugEnabled, '解析完成: resultType=${_describeType(result)}');
      return result;
    } catch (e, stackTrace) {
      logger.w('JM 响应解析失败，返回原始数据', error: e, stackTrace: stackTrace);
      _debugLog(debugEnabled, '解析异常回退: resultType=${_describeType(data)}');
      return data;
    }
  }

  static dynamic _normalizeRawData(dynamic data) {
    if (data is! List<int>) {
      return data;
    }

    final bytes = _decodeGzip(data);
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return bytes;
    }
  }

  static dynamic _decodeValue(
    dynamic value, {
    String? ts,
    required bool debugEnabled,
  }) {
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) {
        return '';
      }

      final decodedJson = _tryJsonDecode(raw);
      if (decodedJson != null) {
        _debugLog(
          debugEnabled,
          '字符串解析为 JSON: jsonType=${_describeType(decodedJson)}',
        );
        return _decodeValue(decodedJson, ts: ts, debugEnabled: debugEnabled);
      }

      return value;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );

      final dataField = map['data'];
      if (dataField is String) {
        final payload = dataField.trim();
        if (payload.isNotEmpty) {
          final decrypted = _tryDecrypt(payload, ts);
          if (decrypted != null) {
            _debugLog(
              debugEnabled,
              '命中加密 data 字段并解密成功: decryptedType=${_describeType(decrypted)}',
            );
            return decrypted;
          }

          final parsedPayload = _tryJsonDecode(payload);
          if (parsedPayload != null) {
            _debugLog(
              debugEnabled,
              'data 字段为明文 JSON 字符串: parsedType=${_describeType(parsedPayload)}',
            );
            return parsedPayload;
          }

          _debugLog(debugEnabled, 'data 字段为普通字符串，保持原样返回 Map');
        }
      }

      return map;
    }

    if (value is List) {
      return value;
    }

    return value;
  }

  static dynamic _tryJsonDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static dynamic _tryDecrypt(String payload, String? ts) {
    if (ts == null || ts.isEmpty) {
      return null;
    }

    try {
      return _decodeRespData(payload, ts);
    } catch (_) {
      return null;
    }
  }

  static List<int> _decodeGzip(List<int> bytes) {
    final isGzipMagic =
        bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (!isGzipMagic) {
      return bytes;
    }

    try {
      return GZipCodec().decode(bytes);
    } catch (_) {
      return bytes;
    }
  }

  static dynamic _decodeRespData(String data, String ts) {
    final dataB64 = base64.decode(data);
    final key = md5.convert(utf8.encode('$ts${JmConfig.kJmSecret}')).toString();
    final encrypter = Encrypter(AES(Key(utf8.encode(key)), mode: AESMode.ecb));
    final dataAes = encrypter.decryptBytes(Encrypted(dataB64));

    return json.decode(utf8.decode(dataAes));
  }

  static bool _isDebugEnabled() {
    try {
      return objectbox.userSettingBox.get(1)?.globalSetting.enableMemoryDebug ??
          false;
    } catch (_) {
      return false;
    }
  }

  static void _debugLog(bool enabled, String message) {
    if (!enabled) {
      return;
    }
    logger.d('[JM响应调试] $message');
  }

  static String _describeType(dynamic value) {
    if (value is List<int>) {
      return 'List<int>(len=${value.length})';
    }
    if (value is List) {
      return 'List(len=${value.length})';
    }
    if (value is Map) {
      return 'Map(len=${value.length})';
    }
    if (value is String) {
      return 'String(len=${value.length})';
    }
    return value.runtimeType.toString();
  }
}
