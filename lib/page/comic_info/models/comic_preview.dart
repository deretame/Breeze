import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/util/json/json_value.dart';

class ComicPreviewCapability {
  const ComicPreviewCapability({
    required this.enabled,
    this.extern = const <String, dynamic>{},
  });

  const ComicPreviewCapability.disabled()
    : enabled = false,
      extern = const <String, dynamic>{};

  final bool enabled;
  final Map<String, dynamic> extern;

  factory ComicPreviewCapability.fromInfo(NormalComicAllInfo info) {
    final candidates = <Map<String, dynamic>>[
      info.preview,
      asJsonMap(info.extern['preview']),
      asJsonMap(info.comicInfo.extern['preview']),
    ];
    final preview = candidates.firstWhere(
      (item) => item.isNotEmpty,
      orElse: () => const <String, dynamic>{},
    );
    if (preview['enabled'] != true) {
      return const ComicPreviewCapability.disabled();
    }

    return ComicPreviewCapability(
      enabled: true,
      extern: asJsonMap(preview['extern']),
    );
  }
}
