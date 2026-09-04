import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/models/favorite_workflow.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/util/json/json_sanitize.dart';
import 'package:zephyr/util/path_util.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/widgets/toast.dart';
import 'package:zephyr/i18n/strings.g.dart';

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
    FavoriteFolderService.removeMemberFromAllFolders(key);
    ComicLinkService.removeComicFromAll(key, ComicFolderType.favorite);
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

  // 新收藏默认添加一条根目录链接
  ComicLinkService.addComic(key, null, ComicFolderType.favorite);

  if (showToast) {
    // showSuccessToast('成功收藏到本地');
  }
  return true;
}

Map<String, dynamic> _comicImageToMap(ComicImage image) {
  return sanitizeDynamic({
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
  favorite.cover = jsonEncode(sanitizeDynamic(coverMap));
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

  final safeId = sanitizePathSegment(id.trim().isEmpty ? 'cover' : id);
  final extension = extractImageExtension(url);
  return '$safeId.$extension';
}

Map<String, dynamic> _creatorToMap(Creator creator) {
  return sanitizeDynamic({
    'id': creator.id,
    'name': creator.name,
    'avatar': _comicImageToMap(creator.avatar),
    'onTap': creator.onTap,
    'extern': creator.extern,
  });
}

Map<String, dynamic> _titleMetaToMap(ComicInfoActionItem item) {
  return sanitizeDynamic({
    'name': item.name,
    'onTap': item.onTap,
    'extern': item.extern,
  });
}

Map<String, dynamic> _metadataToMap(ComicInfoMetadata item) {
  return sanitizeDynamic({
    'name': item.name,
    'type': item.type,
    'value': item.value
        .map(
          (entry) => sanitizeDynamic({
            'name': entry.name,
            'onTap': entry.onTap,
            'extern': entry.extern,
          }),
        )
        .toList(),
  });
}

Future<bool> toggleCloudComicFavorite({
  required BuildContext context,
  required String from,
  String? pluginId,
  required String comicId,
  required bool currentStatus,
  bool legacyAllowCollected = true,
  String? collectionTargetId,
  String? collectionTargetName,
}) async {
  final result = await executeCloudFavoriteWorkflow(
    context: context,
    from: from,
    pluginId: pluginId,
    comicId: comicId,
    action: currentStatus
        ? ((collectionTargetId?.trim().isNotEmpty ?? false) ||
                  (collectionTargetName?.trim().isNotEmpty ?? false)
              ? FavoriteWorkflowAction.removeFromTarget
              : FavoriteWorkflowAction.removeAll)
        : FavoriteWorkflowAction.add,
    currentStatus: currentStatus,
    legacyAllowCollected: legacyAllowCollected,
    collectionTargetId: collectionTargetId,
    collectionTargetName: collectionTargetName,
  );
  if (result.status != FavoriteWorkflowStatus.completed) {
    throw FavoriteWorkflowIncompleteException(result);
  }
  final favorited = result.favorited;
  if (favorited is! bool) {
    throw StateError(t.comicInfo.pluginInvalidFavorited);
  }
  return favorited;
}

Future<FavoriteWorkflowExecutionResult> executeCloudFavoriteWorkflow({
  required BuildContext context,
  required String from,
  String? pluginId,
  required String comicId,
  required FavoriteWorkflowAction action,
  required bool currentStatus,
  bool legacyAllowCollected = true,
  String? collectionTargetId,
  String? collectionTargetName,
}) async {
  final resolvedPluginId = (pluginId?.trim().isNotEmpty ?? false)
      ? pluginId!.trim()
      : from.trim();
  try {
    return await _runFavoriteWorkflow(
      context: context,
      pluginId: resolvedPluginId,
      comicId: comicId,
      action: action,
      currentStatus: currentStatus,
      collectionTargetId: collectionTargetId,
      collectionTargetName: collectionTargetName,
    );
  } catch (error) {
    if (!_isMissingFavoriteWorkflowFunction(error)) {
      rethrow;
    }
    if (!legacyAllowCollected ||
        (action != FavoriteWorkflowAction.add &&
            action != FavoriteWorkflowAction.removeAll)) {
      throw const FavoriteWorkflowUnsupportedException();
    }
    return _runLegacyFavoriteWorkflow(
      context: context,
      pluginId: resolvedPluginId,
      comicId: comicId,
      action: action,
      currentStatus: currentStatus,
    );
  }
}

Future<FavoriteWorkflowExecutionResult> _runFavoriteWorkflow({
  required BuildContext context,
  required String pluginId,
  required String comicId,
  required FavoriteWorkflowAction action,
  required bool currentStatus,
  String? collectionTargetId,
  String? collectionTargetName,
}) async {
  final target = <String, dynamic>{};
  if (collectionTargetId?.trim().isNotEmpty ?? false) {
    target['id'] = collectionTargetId!.trim();
  }
  if (collectionTargetName?.trim().isNotEmpty ?? false) {
    target['name'] = collectionTargetName!.trim();
  }

  var response = await callUnifiedComicPlugin(
    pluginId: pluginId,
    fnPath: 'startFavoriteAction',
    core: {
      'comicId': comicId,
      'action': action.wireName,
      'currentFavorite': currentStatus,
      if (target.isNotEmpty) 'context': {'target': target},
    },
    extern: const <String, dynamic>{},
  );

  for (var step = 0; step < 16; step++) {
    final result = FavoriteWorkflowResult.fromJson(response);
    switch (result.status) {
      case FavoriteWorkflowStatus.completed:
        return _toExecutionResult(result);
      case FavoriteWorkflowStatus.partial:
      case FavoriteWorkflowStatus.failed:
      case FavoriteWorkflowStatus.cancelled:
        final executionResult = _toExecutionResult(result);
        if (result.status == FavoriteWorkflowStatus.failed) {
          throw StateError(result.message ?? t.error.operationFailed);
        }
        throw FavoriteWorkflowIncompleteException(executionResult);
      case FavoriteWorkflowStatus.awaitingInput:
        final token = result.continuationToken?.trim() ?? '';
        final input = result.input;
        if (token.isEmpty || input == null) {
          throw StateError('收藏工作流等待交互时缺少 continuationToken 或 input');
        }
        if (!context.mounted) {
          throw const FavoriteWorkflowIncompleteException(
            FavoriteWorkflowExecutionResult(
              status: FavoriteWorkflowStatus.cancelled,
              message: '页面已关闭，收藏操作已取消',
            ),
          );
        }
        final userInput = await _showFavoriteWorkflowInput(context, input);
        response = await callUnifiedComicPlugin(
          pluginId: pluginId,
          fnPath: 'continueFavoriteAction',
          core: {
            'comicId': comicId,
            'action': action.wireName,
            'continuationToken': token,
            'input': userInput ?? const <String, dynamic>{'cancelled': true},
          },
          extern: const <String, dynamic>{},
        );
    }
  }

  throw StateError('收藏工作流超过最大交互步骤');
}

FavoriteWorkflowExecutionResult _toExecutionResult(
  FavoriteWorkflowResult result,
) {
  return FavoriteWorkflowExecutionResult(
    status: result.status,
    favorited: result.favorited,
    committed: result.committed,
    message: result.message,
  );
}

Future<FavoriteWorkflowExecutionResult> _runLegacyFavoriteWorkflow({
  required BuildContext context,
  required String pluginId,
  required String comicId,
  required FavoriteWorkflowAction action,
  required bool currentStatus,
}) async {
  final data = await callUnifiedComicPlugin(
    pluginId: pluginId,
    fnPath: 'toggleFavorite',
    core: {'comicId': comicId, 'currentFavorite': currentStatus},
    extern: const <String, dynamic>{},
  );
  final favorited = data['favorited'];
  if (favorited is! bool) {
    throw StateError(t.comicInfo.pluginInvalidFavorited);
  }

  final nextStep = data['nextStep']?.toString() ?? 'none';
  if (action != FavoriteWorkflowAction.add ||
      !favorited ||
      nextStep != 'selectFolder' ||
      !context.mounted) {
    return FavoriteWorkflowExecutionResult(
      status: FavoriteWorkflowStatus.completed,
      favorited: favorited,
      committed: true,
    );
  }

  final folders = await _listCloudFavoriteFolders(pluginId);
  if (!context.mounted || folders.isEmpty) {
    return FavoriteWorkflowExecutionResult(
      status: FavoriteWorkflowStatus.completed,
      favorited: favorited,
      committed: true,
    );
  }

  final selectedFolder = await _showFolderSelectionDialog(context, folders);
  if (selectedFolder == null || !context.mounted) {
    return FavoriteWorkflowExecutionResult(
      status: FavoriteWorkflowStatus.completed,
      favorited: favorited,
      committed: true,
    );
  }

  await _moveCloudFavoriteToFolder(
    from: pluginId,
    comicId: comicId,
    folder: selectedFolder,
  );
  showSuccessToast(t.comicInfo.addedToFolder(name: selectedFolder.name));
  return FavoriteWorkflowExecutionResult(
    status: FavoriteWorkflowStatus.completed,
    favorited: favorited,
    committed: true,
  );
}

bool _isMissingFavoriteWorkflowFunction(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('startfavoriteaction') &&
      (message.contains('not a function') ||
          message.contains('function path not found') ||
          message.contains('missing function') ||
          message.contains('undefined'));
}

Future<Map<String, dynamic>?> _showFavoriteWorkflowInput(
  BuildContext context,
  FavoriteWorkflowInput input,
) {
  return switch (input.type) {
    'select' => _showFavoriteWorkflowSelect(context, input),
    'text' => _showFavoriteWorkflowText(context, input),
    'confirm' => _showFavoriteWorkflowConfirm(context, input),
    'form' => _showFavoriteWorkflowForm(context, input),
    _ => throw StateError('不支持的收藏工作流交互类型：${input.type}'),
  };
}

Future<Map<String, dynamic>?> _showFavoriteWorkflowSelect(
  BuildContext context,
  FavoriteWorkflowInput input,
) async {
  final selected = input.options
      .where((option) => option.selected)
      .map((option) => option.id)
      .toSet();
  final createController = TextEditingController();
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final createdName = createController.text.trim();
          final canConfirm =
              !input.required || selected.isNotEmpty || createdName.isNotEmpty;
          return AlertDialog(
            title: Text(input.title ?? t.comicInfo.addToCustomFolder),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (input.description?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(input.description!),
                      ),
                    if (input.options.isNotEmpty)
                      input.isMultiple
                          ? Column(
                              children: input.options.map((option) {
                                return CheckboxListTile(
                                  value: selected.contains(option.id),
                                  title: Text(option.label),
                                  subtitle: option.description == null
                                      ? null
                                      : Text(option.description!),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selected.add(option.id);
                                      } else {
                                        selected.remove(option.id);
                                      }
                                      createController.clear();
                                    });
                                  },
                                );
                              }).toList(),
                            )
                          : RadioGroup<String>(
                              groupValue: selected.isEmpty
                                  ? null
                                  : selected.first,
                              onChanged: (value) {
                                setState(() {
                                  selected
                                    ..clear()
                                    ..add(value!);
                                  createController.clear();
                                });
                              },
                              child: Column(
                                children: input.options.map((option) {
                                  return RadioListTile<String>(
                                    value: option.id,
                                    title: Text(option.label),
                                    subtitle: option.description == null
                                        ? null
                                        : Text(option.description!),
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                            ),
                    if (input.allowCreate) ...[
                      if (input.options.isNotEmpty) const Divider(),
                      TextField(
                        controller: createController,
                        decoration: InputDecoration(
                          labelText: input.createField?.label ?? '新建收藏夹',
                          hintText: input.createField?.placeholder,
                        ),
                        onChanged: (_) {
                          setState(() {
                            selected.clear();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: canConfirm
                    ? () {
                        final value = input.isMultiple
                            ? selected.toList()
                            : selected.isEmpty
                            ? null
                            : selected.first;
                        Navigator.pop(dialogContext, {
                          if (input.key?.isNotEmpty ?? false) 'key': input.key,
                          'value': value,
                          if (createdName.isNotEmpty) 'created': createdName,
                        });
                      }
                    : null,
                child: Text(t.common.confirm),
              ),
            ],
          );
        },
      );
    },
  );
  createController.dispose();
  return result;
}

Future<Map<String, dynamic>?> _showFavoriteWorkflowText(
  BuildContext context,
  FavoriteWorkflowInput input,
) async {
  final controller = TextEditingController();
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final canConfirm =
              !input.required || controller.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(input.title ?? ''),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: input.description),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (canConfirm) {
                  Navigator.pop(dialogContext, {
                    if (input.key?.isNotEmpty ?? false) 'key': input.key,
                    'value': controller.text,
                  });
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: canConfirm
                    ? () => Navigator.pop(dialogContext, {
                        if (input.key?.isNotEmpty ?? false) 'key': input.key,
                        'value': controller.text,
                      })
                    : null,
                child: Text(t.common.confirm),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return result;
}

Future<Map<String, dynamic>?> _showFavoriteWorkflowConfirm(
  BuildContext context,
  FavoriteWorkflowInput input,
) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(input.title ?? t.common.confirm),
        content: input.description == null ? null : Text(input.description!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              if (input.key?.isNotEmpty ?? false) 'key': input.key,
              'value': true,
            }),
            child: Text(t.common.confirm),
          ),
        ],
      );
    },
  );
}

Future<Map<String, dynamic>?> _showFavoriteWorkflowForm(
  BuildContext context,
  FavoriteWorkflowInput input,
) async {
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  for (final field in input.fields) {
    if (field.defaultValue != null) {
      values[field.key] = field.defaultValue;
    } else if (field.type == 'switch' || field.type == 'confirm') {
      values[field.key] = false;
    } else if (field.type == 'multiChoice') {
      values[field.key] = <String>[];
    }
  }

  bool isValid() {
    for (final field in input.fields.where((field) => field.required)) {
      final value = values[field.key];
      if (value == null ||
          value is String && value.trim().isEmpty ||
          value is List && value.isEmpty ||
          (field.type == 'switch' || field.type == 'confirm') &&
              value != true) {
        return false;
      }
    }
    return true;
  }

  Widget buildField(
    FavoriteWorkflowField field,
    void Function(void Function()) setState,
  ) {
    switch (field.type) {
      case 'switch':
      case 'confirm':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label),
          subtitle: field.description == null ? null : Text(field.description!),
          value: values[field.key] == true,
          onChanged: (value) => setState(() => values[field.key] = value),
        );
      case 'choice':
        return RadioGroup<String>(
          groupValue: values[field.key]?.toString(),
          onChanged: (value) => setState(() => values[field.key] = value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.label),
              if (field.description != null) Text(field.description!),
              ...field.options.map(
                (option) => RadioListTile<String>(
                  value: option.id,
                  title: Text(option.label),
                  subtitle: option.description == null
                      ? null
                      : Text(option.description!),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        );
      case 'multiChoice':
        final selected =
            (values[field.key] as List?)?.cast<String>() ?? <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label),
            if (field.description != null) Text(field.description!),
            ...field.options.map(
              (option) => CheckboxListTile(
                value: selected.contains(option.id),
                title: Text(option.label),
                subtitle: option.description == null
                    ? null
                    : Text(option.description!),
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selected.add(option.id);
                  } else {
                    selected.remove(option.id);
                  }
                  values[field.key] = selected;
                }),
              ),
            ),
          ],
        );
      case 'text':
      case 'password':
      case 'number':
      default:
        final controller = controllers.putIfAbsent(
          field.key,
          () =>
              TextEditingController(text: field.defaultValue?.toString() ?? ''),
        );
        return TextField(
          controller: controller,
          obscureText: field.type == 'password',
          keyboardType: field.type == 'number'
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.placeholder,
          ),
          onChanged: (value) => values[field.key] = value,
        );
    }
  }

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(input.title ?? t.common.confirm),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.65,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (input.description != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(input.description!),
                        ),
                      ),
                    ...input.fields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildField(field, setState),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: isValid()
                    ? () => Navigator.pop(dialogContext, {
                        'values': Map<String, dynamic>.from(values),
                      })
                    : null,
                child: Text(t.common.confirm),
              ),
            ],
          );
        },
      );
    },
  );
  for (final controller in controllers.values) {
    controller.dispose();
  }
  return result;
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
    throw StateError(t.comicInfo.pluginInvalidLiked);
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
            title: Text(t.comicInfo.addToCustomFolder),
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
                child: Text(t.comicInfo.skipAdd),
              ),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(dialogContext, selected),
                child: Text(t.comicInfo.confirmAdd),
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
