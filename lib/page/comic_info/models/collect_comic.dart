import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/widgets/toast.dart';

Future<bool> isLocalComicCollected({
  required String from,
  required String comicId,
}) async {
  final pluginId = (from).trim();
  final key = '$pluginId:$comicId';
  final unified = objectbox.unifiedFavoriteBox
      .query(UnifiedComicFavorite_.uniqueKey.equals(key))
      .build()
      .findFirst();
  final collected = unified != null && unified.deleted == false;
  if (collected) {
    _repairFavoriteCoverPathIfNeeded(unified);
  }
  return collected;
}

Future<bool> toggleLocalComicFavorite({
  required String from,
  required NormalComicAllInfo normalInfo,
  bool showToast = true,
}) async {
  final comicInfo = normalInfo.comicInfo;
  final pluginId = (from).trim();
  final key = '$pluginId:${comicInfo.id}';
  final now = DateTime.now().toUtc();
  final unified = objectbox.unifiedFavoriteBox
      .query(UnifiedComicFavorite_.uniqueKey.equals(key))
      .build()
      .findFirst();

  if (unified != null && unified.deleted == false) {
    unified.deleted = true;
    unified.updatedAt = now;
    objectbox.unifiedFavoriteBox.put(unified);
    if (showToast) {
      // showSuccessToast('已取消本地收藏');
    }
    return false;
  }

  final createdAt = unified?.createdAt ?? now;
  final coverMap = _comicImageToMap(comicInfo.cover);

  objectbox.unifiedFavoriteBox.put(
    UnifiedComicFavorite(
      id: unified?.id ?? 0,
      uniqueKey: key,
      source: pluginId,
      comicId: comicInfo.id,
      title: comicInfo.title,
      description: comicInfo.description,
      cover: jsonEncode(coverMap),
      creator: jsonEncode(_creatorToMap(comicInfo.creator)),
      titleMeta: jsonEncode(comicInfo.titleMeta.map(_titleMetaToMap).toList()),
      metadata: jsonEncode(comicInfo.metadata.map(_metadataToMap).toList()),
      createdAt: createdAt,
      updatedAt: now,
      deleted: false,
      schemaVersion: 2,
    ),
  );

  if (showToast) {
    // showSuccessToast('成功收藏到本地');
  }
  return true;
}

Map<String, dynamic> _comicImageToMap(ComicImage image) {
  return _sanitizeMap({
    'id': image.id,
    'url': image.url,
    'name': image.name,
    'path': _resolveImagePath(
      id: image.id,
      url: image.url,
      rawPath: image.path,
    ),
    'extern': image.extern,
  });
}

void _repairFavoriteCoverPathIfNeeded(UnifiedComicFavorite favorite) {
  final coverRaw = favorite.cover.trim();
  if (coverRaw.isEmpty) {
    return;
  }

  Map<String, dynamic> coverMap;
  try {
    final decoded = jsonDecode(coverRaw);
    if (decoded is! Map) {
      return;
    }
    coverMap = Map<String, dynamic>.from(decoded);
  } catch (_) {
    return;
  }

  final currentPath = coverMap['path']?.toString().trim() ?? '';
  if (currentPath.isNotEmpty) {
    return;
  }

  final repairedPath = _resolveImagePath(
    id: coverMap['id']?.toString() ?? favorite.comicId,
    url: coverMap['url']?.toString() ?? '',
    rawPath: currentPath,
  );
  if (repairedPath.isEmpty) {
    return;
  }

  coverMap['path'] = repairedPath;
  favorite.cover = jsonEncode(_sanitizeMap(coverMap));
  favorite.updatedAt = DateTime.now().toUtc();
  objectbox.unifiedFavoriteBox.put(favorite);
}

String _resolveImagePath({
  required String id,
  required String url,
  required String rawPath,
}) {
  final path = rawPath.trim();
  if (path.isNotEmpty) {
    return path;
  }

  final safeId = _sanitizePathSegment(id.trim().isEmpty ? 'cover' : id);
  final extension = _extractImageExtension(url);
  return '$safeId.$extension';
}

String _sanitizePathSegment(String input) {
  final sanitized = input
      .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return sanitized.isEmpty ? 'cover' : sanitized;
}

String _extractImageExtension(String url) {
  try {
    final uri = Uri.parse(url);
    final lastDot = uri.path.lastIndexOf('.');
    if (lastDot >= 0 && lastDot < uri.path.length - 1) {
      final ext = uri.path.substring(lastDot + 1).toLowerCase();
      if (RegExp(r'^[a-z0-9]{1,8}$').hasMatch(ext)) {
        return ext;
      }
    }
  } catch (_) {}
  return 'jpg';
}

Map<String, dynamic> _creatorToMap(Creator creator) {
  return _sanitizeMap({
    'id': creator.id,
    'name': creator.name,
    'avatar': _comicImageToMap(creator.avatar),
    'onTap': creator.onTap,
    'extern': creator.extern,
  });
}

Map<String, dynamic> _titleMetaToMap(ComicInfoActionItem item) {
  return _sanitizeMap({
    'name': item.name,
    'onTap': item.onTap,
    'extern': item.extern,
  });
}

Map<String, dynamic> _metadataToMap(ComicInfoMetadata item) {
  return _sanitizeMap({
    'name': item.name,
    'type': item.type,
    'value': item.value
        .map(
          (entry) => _sanitizeMap({
            'name': entry.name,
            'onTap': entry.onTap,
            'extern': entry.extern,
          }),
        )
        .toList(),
  });
}

Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
  return input.map((key, value) => MapEntry(key, _sanitizeValue(value)));
}

dynamic _sanitizeValue(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Map) {
    return Map<String, dynamic>.from(
      value,
    ).map((key, item) => MapEntry(key, _sanitizeValue(item)));
  }
  if (value is List) {
    return value.map(_sanitizeValue).toList();
  }
  try {
    final json = (value as dynamic).toJson();
    return _sanitizeValue(json);
  } catch (_) {
    return value.toString();
  }
}

Future<bool> toggleCloudComicFavorite({
  required BuildContext context,
  required String from,
  required String comicId,
  required bool currentStatus,
}) async {
  final data = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'toggleFavorite',
    core: {'comicId': comicId, 'currentFavorite': currentStatus},
    extern: const <String, dynamic>{},
  );
  final favorited = data['favorited'];
  if (favorited is! bool) {
    throw StateError('插件未返回有效 favorited 状态');
  }

  final nextStep = data['nextStep']?.toString() ?? 'none';
  if (!favorited || nextStep != 'selectFolder' || !context.mounted) {
    return favorited;
  }

  final folders = await _listCloudFavoriteFolders(from);
  if (!context.mounted || folders.isEmpty) {
    return favorited;
  }

  final selectedFolder = await _showFolderSelectionDialog(context, folders);
  if (selectedFolder == null || !context.mounted) {
    return favorited;
  }

  await _moveCloudFavoriteToFolder(
    from: from,
    comicId: comicId,
    folder: selectedFolder,
  );
  showSuccessToast('已添加到收藏夹: ${selectedFolder.name}');
  return favorited;
}

Future<bool> toggleCloudComicLike({
  required String from,
  required String comicId,
  required bool currentStatus,
}) async {
  final data = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'toggleLike',
    core: {'comicId': comicId, 'currentLiked': currentStatus},
    extern: const <String, dynamic>{},
  );
  if (data['liked'] is! bool) {
    throw StateError('插件未返回有效 liked 状态');
  }
  return data['liked'] as bool;
}

Future<List<_FavoriteFolder>> _listCloudFavoriteFolders(String from) async {
  final data = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'listFavoriteFolders',
    core: const <String, dynamic>{},
    extern: const <String, dynamic>{},
  );
  final items = data['items'];
  if (items is! List) {
    return const <_FavoriteFolder>[];
  }
  return items
      .whereType<Map>()
      .map((item) => _FavoriteFolder.fromJson(Map<String, dynamic>.from(item)))
      .where((item) => item.id.isNotEmpty)
      .toList();
}

Future<void> _moveCloudFavoriteToFolder({
  required String from,
  required String comicId,
  required _FavoriteFolder folder,
}) async {
  await callUnifiedComicPlugin(
    from: from,
    fnPath: 'moveFavoriteToFolder',
    core: {
      'comicId': comicId,
      'folderId': folder.id,
      'folderName': folder.name,
    },
    extern: const <String, dynamic>{},
  );
}

Future<_FavoriteFolder?> _showFolderSelectionDialog(
  BuildContext context,
  List<_FavoriteFolder> folders,
) {
  _FavoriteFolder? selected;
  return showDialog<_FavoriteFolder>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加到自定义收藏夹'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.5,
              ),
              child: SizedBox(
                width: double.maxFinite,
                child: RadioGroup<String>(
                  groupValue: selected?.id,
                  onChanged: (value) {
                    setState(() {
                      final selectedIndex = folders.indexWhere(
                        (item) => item.id == value,
                      );
                      selected = selectedIndex >= 0
                          ? folders[selectedIndex]
                          : null;
                    });
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (itemCtx, index) {
                      final folder = folders[index];
                      return RadioListTile<String>(
                        title: Text(folder.name),
                        subtitle: Text('ID: ${folder.id}'),
                        value: folder.id,
                      );
                    },
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('跳过/不添加'),
              ),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(dialogContext, selected),
                child: const Text('确定添加'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _FavoriteFolder {
  const _FavoriteFolder({required this.id, required this.name});

  final String id;
  final String name;

  factory _FavoriteFolder.fromJson(Map<String, dynamic> json) {
    return _FavoriteFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
