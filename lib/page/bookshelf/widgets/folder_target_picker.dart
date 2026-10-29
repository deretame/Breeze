import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/widgets/toast.dart';

/// 文件夹目标选择器（书架移动/复制 + 详情页本地收藏共用）。
///
/// 路径以 `/a/b` 形式表示；根目录用 [kComicFolderRootPath]（空串）表示。
/// 返回选中的路径集合；返回 null 表示用户取消了选择。
/// [allowEmptyConfirm] 为 true 时允许空选确认（详情页用空选表示取消收藏）。
Future<Set<String>?> showFolderTargetPicker(
  BuildContext context, {
  required ComicFolderType type,
  Set<String> initialSelectedPaths = const {},
  bool multiSelect = true,
  bool rootEnabled = true,
  Set<String> disabledSyncIds = const {},
  bool allowCreateFolder = true,
  bool allowEmptyConfirm = false,
  String? title,
  String? currentSyncId,
}) async {
  var folders = ComicFolderService.listAllFolders(type);
  Map<String, ComicFolder> syncIdMap = {
    for (final folder in folders) folder.syncId: folder,
  };
  Map<String, String> pathMap = {
    for (final folder in folders)
      folder.syncId: ComicFolderService.folderPath(
        folder,
        syncIdMap: syncIdMap,
      ),
  };
  final selectedPaths = Set<String>.from(initialSelectedPaths);

  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) {
      final expandedPaths = <String>{};
      return StatefulBuilder(
        builder: (ctx, setState) {
          void reloadFolders() {
            folders = ComicFolderService.listAllFolders(type);
            syncIdMap = {for (final folder in folders) folder.syncId: folder};
            pathMap = {
              for (final folder in folders)
                folder.syncId: ComicFolderService.folderPath(
                  folder,
                  syncIdMap: syncIdMap,
                ),
            };
          }

          void togglePath(String path) {
            setState(() {
              if (!multiSelect) {
                selectedPaths
                  ..clear()
                  ..add(path);
                return;
              }
              if (selectedPaths.contains(path)) {
                selectedPaths.remove(path);
              } else {
                selectedPaths.add(path);
              }
            });
          }

          Future<void> createFolderAtRoot() async {
            final name = await _askFolderName(ctx);
            if (name == null || name.trim().isEmpty) return;
            try {
              final folder = ComicFolderService.createFolder(
                kComicFolderRootPath,
                name.trim(),
                type,
              );
              reloadFolders();
              final newPath = ComicFolderService.folderPath(
                folder,
                syncIdMap: syncIdMap,
              );
              setState(() {
                if (!multiSelect) selectedPaths.clear();
                selectedPaths.add(newPath);
              });
            } catch (e) {
              logger.e(e);
              showErrorToast(e.toString());
            }
          }

          final forest = buildFolderForest(folders, pathMap);
          final confirmEnabled = allowEmptyConfirm || selectedPaths.isNotEmpty;

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text(title ?? t.bookshelf.selectTargetFolder)),
                if (allowCreateFolder)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: t.bookshelf.createFolder,
                    onPressed: createFolderAtRoot,
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
              ],
            ),
            content: SizedBox(
              width: 380,
              height: 400,
              child: multiSelect
                  ? ListView(
                      children: [
                        _RootTargetTile(
                          selected: selectedPaths.contains(
                            kComicFolderRootPath,
                          ),
                          enabled: rootEnabled,
                          onTap: () => togglePath(kComicFolderRootPath),
                        ),
                        const Divider(),
                        ...forest.map(
                          (node) => buildFolderTreeTile(
                            context: ctx,
                            node: node,
                            pathMap: pathMap,
                            expandedPaths: expandedPaths,
                            forbiddenSyncIds: disabledSyncIds,
                            selectedPaths: selectedPaths,
                            currentSyncId: currentSyncId,
                            onToggleExpand: (path) => setState(() {
                              if (expandedPaths.contains(path)) {
                                expandedPaths.remove(path);
                              } else {
                                expandedPaths.add(path);
                              }
                            }),
                            onSelect: togglePath,
                          ),
                        ),
                      ],
                    )
                  : RadioGroup<String>(
                      groupValue: selectedPaths.singleOrNull,
                      onChanged: (value) {
                        if (value != null) togglePath(value);
                      },
                      child: ListView(
                        children: [
                          _RootTargetTile(
                            selected: selectedPaths.contains(
                              kComicFolderRootPath,
                            ),
                            enabled: rootEnabled,
                            onTap: () => togglePath(kComicFolderRootPath),
                            singleValue: kComicFolderRootPath,
                          ),
                          const Divider(),
                          ...forest.map(
                            (node) => buildFolderTreeTile(
                              context: ctx,
                              node: node,
                              pathMap: pathMap,
                              expandedPaths: expandedPaths,
                              forbiddenSyncIds: disabledSyncIds,
                              selectedPaths: selectedPaths,
                              singleSelect: true,
                              currentSyncId: currentSyncId,
                              onToggleExpand: (path) => setState(() {
                                if (expandedPaths.contains(path)) {
                                  expandedPaths.remove(path);
                                } else {
                                  expandedPaths.add(path);
                                }
                              }),
                              onSelect: togglePath,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.common.cancel),
              ),
              FilledButton(
                onPressed: confirmEnabled
                    ? () => Navigator.of(dialogContext).pop(selectedPaths)
                    : null,
                child: Text(t.common.ok),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<String?> _askFolderName(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(t.bookshelf.createFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.bookshelf.folderName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(dialogContext).pop(text);
            },
            child: Text(t.common.ok),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

class _RootTargetTile extends StatelessWidget {
  const _RootTargetTile({
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.singleValue,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String? singleValue;

  @override
  Widget build(BuildContext context) {
    final value = singleValue;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const SizedBox(width: 48),
      title: Text(t.common.root),
      trailing: value == null
          ? Checkbox(
              value: selected,
              onChanged: enabled ? (_) => onTap() : null,
            )
          : Radio<String>(value: value, enabled: enabled),
    );
  }
}

class FolderNode {
  final ComicFolder folder;
  final List<FolderNode> children;

  FolderNode(this.folder) : children = [];
}

List<FolderNode> buildFolderForest(
  List<ComicFolder> folders,
  Map<String, String> pathMap,
) {
  final sorted = folders.toList()
    ..sort(
      (a, b) => (pathMap[a.syncId] ?? '').compareTo(pathMap[b.syncId] ?? ''),
    );
  final map = <String, FolderNode>{};
  final roots = <FolderNode>[];
  for (final folder in sorted) {
    final node = FolderNode(folder);
    map[folder.syncId] = node;
    final parentSyncId = folder.parentSyncId;
    if (parentSyncId == null || parentSyncId.isEmpty) {
      roots.add(node);
    } else {
      map[parentSyncId]?.children.add(node);
    }
  }
  return roots;
}

Map<String, ComicFolder> buildFolderSyncIdMap(ComicFolderType type) {
  final allFolders = ComicFolderService.listAllFolders(type);
  return {for (final folder in allFolders) folder.syncId: folder};
}

void collectForbiddenSyncIds(
  String syncId,
  List<ComicFolder> allFolders,
  Set<String> result,
) {
  if (!result.add(syncId)) return;
  for (final child in allFolders) {
    if (child.parentSyncId == syncId) {
      collectForbiddenSyncIds(child.syncId, allFolders, result);
    }
  }
}

Widget buildFolderTreeTile({
  required BuildContext context,
  required FolderNode node,
  required Map<String, String> pathMap,
  required Set<String> expandedPaths,
  required Set<String> forbiddenSyncIds,
  required Set<String> selectedPaths,
  bool singleSelect = false,
  String? currentSyncId,
  required ValueChanged<String> onToggleExpand,
  required ValueChanged<String> onSelect,
}) {
  final path = pathMap[node.folder.syncId] ?? '/${node.folder.name}';
  final syncId = node.folder.syncId;
  final isExpanded = expandedPaths.contains(path);
  final isCurrentPath = currentSyncId != null && syncId == currentSyncId;
  final isForbidden = isCurrentPath || forbiddenSyncIds.contains(syncId);
  final hasChildren = node.children.isNotEmpty;
  final theme = Theme.of(context);
  final isSelected = selectedPaths.contains(path) && !isForbidden;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: hasChildren
            ? IconButton(
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                ),
                onPressed: () => onToggleExpand(path),
              )
            : const SizedBox(width: 48),
        title: Text(
          node.folder.name,
          style: isForbidden ? TextStyle(color: theme.disabledColor) : null,
        ),
        trailing: singleSelect
            ? Radio<String>(value: path, enabled: !isForbidden)
            : Checkbox(
                value: isSelected,
                onChanged: isForbidden ? null : (_) => onSelect(path),
              ),
        onTap: isForbidden ? null : () => onSelect(path),
      ),
      if (isExpanded)
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map(
                  (child) => buildFolderTreeTile(
                    context: context,
                    node: child,
                    pathMap: pathMap,
                    expandedPaths: expandedPaths,
                    forbiddenSyncIds: forbiddenSyncIds,
                    selectedPaths: selectedPaths,
                    singleSelect: singleSelect,
                    currentSyncId: currentSyncId,
                    onToggleExpand: onToggleExpand,
                    onSelect: onSelect,
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );
}
