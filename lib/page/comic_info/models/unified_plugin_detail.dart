import 'package:zephyr/util/json/json_value.dart';

class UnifiedPluginDetailResponse {
  const UnifiedPluginDetailResponse({
    required this.source,
    required this.comicId,
    required this.extern,
    required this.scheme,
    required this.normal,
    required this.raw,
  });

  final String source;
  final String comicId;
  final Map<String, dynamic> extern;
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> normal;
  final Map<String, dynamic> raw;

  factory UnifiedPluginDetailResponse.fromMap(Map<String, dynamic> map) {
    final data = asJsonMap(map['data']);
    final normal = data.isNotEmpty
        ? asJsonMap(data['normal'])
        : asJsonMap(map['normal']);
    final raw = data.isNotEmpty
        ? asJsonMap(data['raw'])
        : asJsonMap(map['raw']);

    return UnifiedPluginDetailResponse(
      source: map['source']?.toString() ?? '',
      comicId: map['comicId']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
      scheme: asJsonMap(map['scheme']),
      normal: normal,
      raw: raw,
    );
  }
}
