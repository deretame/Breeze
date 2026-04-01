import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/widgets/toast.dart';

Future<bool> isLocalComicCollected({
  required String from,
  required String comicId,
}) async {
  final pluginId = sanitizePluginId(from);
  final key = '$pluginId:$comicId';
  final unified = objectbox.unifiedFavoriteBox
      .query(UnifiedComicFavorite_.uniqueKey.equals(key))
      .build()
      .findFirst();
  return unified != null && unified.deleted == false;
}

Future<bool> toggleLocalComicFavorite({
  required String from,
  required NormalComicAllInfo normalInfo,
  bool showToast = true,
}) async {
  final comicInfo = normalInfo.comicInfo;
  final pluginId = sanitizePluginId(from);
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
      showSuccessToast('已取消本地收藏');
    }
    return false;
  }

  final createdAt = unified?.createdAt ?? now;
  objectbox.unifiedFavoriteBox.put(
    UnifiedComicFavorite(
      id: unified?.id ?? 0,
      uniqueKey: key,
      source: pluginId,
      comicId: comicInfo.id,
      title: comicInfo.title,
      description: comicInfo.description,
      cover: comicInfo.cover.toJson(),
      creator: comicInfo.creator.toJson(),
      titleMeta: comicInfo.titleMeta.map((item) => item.toJson()).toList(),
      metadata: comicInfo.metadata.map((item) => item.toJson()).toList(),
      createdAt: createdAt,
      updatedAt: now,
      deleted: false,
      schemaVersion: 2,
    ),
  );

  if (showToast) {
    showSuccessToast('成功收藏到本地');
  }
  return true;
}

Future<Map<String, dynamic>> collectJmComicToLocal(dynamic comicInfo) async {
  if (comicInfo is! NormalComicAllInfo) {
    throw StateError(
      'collectJmComicToLocal expects NormalComicAllInfo, got ${comicInfo.runtimeType}',
    );
  }
  await toggleLocalComicFavorite(from: kJmPluginUuid, normalInfo: comicInfo);
  return {"error": null, "message": "收藏成功"};
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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (itemCtx, index) {
                    final folder = folders[index];
                    return RadioListTile<String>(
                      title: Text(folder.name),
                      subtitle: Text('ID: ${folder.id}'),
                      value: folder.id,
                      // ignore: deprecated_member_use
                      groupValue: selected?.id,
                      // ignore: deprecated_member_use
                      onChanged: (_) {
                        setState(() {
                          selected = folder;
                        });
                      },
                    );
                  },
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
