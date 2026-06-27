# Breeze 收藏 / 下载文件夹操作逻辑

> 对应代码：
> - `lib/page/bookshelf/service/comic_folder_service.dart`
> - `lib/page/bookshelf/service/comic_link_service.dart`
> - `lib/page/bookshelf/widgets/folder_shelf_page.dart`
> - `lib/page/bookshelf/bloc/folder_shelf_bloc.dart`

## 1. 核心概念

### 1.1 文件夹类型

```dart
enum ComicFolderType { favorite, history, download }
```

- `favorite` / `history`：参与同步，软删除。
- `download`：不参与同步，删除漫画时直接物理删除下载文件。

### 1.2 身份字段

| 字段 | 含义 |
|-----|------|
| `syncId` | 文件夹全局稳定 ID，创建后不变 |
| `parentSyncId` | 父文件夹的 `syncId`，`null` 表示根目录 |
| `folderSyncId` | 链接指向的文件夹 `syncId`，`null` 表示根目录 |

### 1.3 路径计算

`path` / `folderPath` 字段已被移除，路径实时通过 `parentSyncId` 链计算：

```dart
static String folderPath(ComicFolder folder, {Map<String, ComicFolder>? syncIdMap})
```

UI 层在需要显示路径时调用此方法。

### 1.4 唯一键

- **Folder**：`uniqueKey = "${parentSyncId ?? ''}|${name}|${typeData}"`
- **Link**：`uniqueKey = "${comicUniqueKey}|${folderSyncId ?? ''}|${typeData}"`

同一父目录下同名文件夹会冲突；同一文件夹下同一本漫画只会有一条链接。

## 2. ComicFolderService 文件夹操作

### 2.1 查询

| 方法 | 说明 |
|-----|------|
| `folderSyncIdByPath(path, type)` | 根据显示路径反查文件夹 `syncId` |
| `listChildFolders(parentPath, type)` | 列出某路径下的直接子文件夹 |
| `listAllFolders(type)` | 列出某类型全部未删除文件夹 |
| `folderName(path, type)` | 根据路径获取文件夹名称 |
| `folderPath(folder)` | 根据 `parentSyncId` 链计算显示路径 |

### 2.2 创建

`createFolder(parentPath, name, type)`：

1. 检查名称非空、不含 `/`。
2. 计算新路径 `newPath` 和 `uniqueKey`。
3. 如果 `uniqueKey` 已存在且是 tombstone → 复活该文件夹。
4. 否则创建新文件夹，分配 `syncId`、`parentSyncId`、版本向量。

### 2.3 重命名

`renameFolder(path, newName, type)`：

1. 根据路径找到文件夹。
2. 检查新名称是否冲突（先物理删除同位置的 tombstone）。
3. 更新 `name` 和 `uniqueKey`。

> 子文件夹和链接的 `folderSyncId` 不需要更新，因为它们只关心父文件夹的 `syncId`。

### 2.4 删除

`deleteFolder(path, type)`：

- 根目录不可删除。
- 对目标文件夹及其所有后代文件夹做**软删除**（`deletedAt` + 版本向量 +1）。

### 2.5 批量操作

| 方法 | 说明 |
|-----|------|
| `batchMoveFolders(paths, targetPath, type)` | 批量移动文件夹 |
| `batchCopyFolders(paths, targetPath, type)` | 批量复制文件夹（重名自动加序号） |
| `batchDeleteFolders(paths, type)` | 批量删除文件夹 |

移动 / 复制会检查：

- 不能移动到自身。
- 不能移动到自身子路径下。

复制时递归创建新的 `syncId`，链接也复制到新文件夹下。

## 3. ComicLinkService 漫画链接操作

### 3.1 查询

| 方法 | 说明 |
|-----|------|
| `listLinks(folderPath, type)` | 列出某路径下的漫画链接 |
| `linksOfComic(comicUniqueKey, type)` | 列出某漫画在某类型下的全部链接 |

### 3.2 添加

`addComic(comicUniqueKey, folderPath, type)`：

1. 根据路径找到 `folderSyncId`。
2. 如果该链接已存在且是 tombstone → 复活。
3. 否则新建 `ComicLink`。

### 3.3 移除

`removeComic(comicUniqueKey, folderPath, type)`：

- `favorite` / `history`：软删除链接。
- `download`：物理删除链接。

对于 `favorite`：如果这是该漫画的最后一条链接，会把对应的 `UnifiedComicFavorite` 也标记为删除。

对于 `download`：如果这是该漫画的最后一条链接，会删除下载记录及本地文件。

### 3.4 移动

`moveComic(comicUniqueKey, fromPath, toPath, type)`：

> 先添加目标链接，再移除原链接，避免中间态被判定为“最后一个链接”而误删收藏/下载记录。

### 3.5 批量操作

| 方法 | 说明 |
|-----|------|
| `batchMoveComics(keys, fromPath, targetPath, type)` | 批量移动漫画 |
| `batchCopyComics(keys, targetPath, type)` | 批量复制漫画 |
| `batchRemoveComics(keys, folderPath, type)` | 批量移除漫画 |

### 3.6 删除整棵文件夹树下的链接

`removeLinksInFolderTree(folderPath, type)`：

1. 根据路径找到根文件夹 `syncId`。
2. 递归收集该文件夹下所有后代文件夹的 `syncId`。
3. 遍历该类型全部 active link，属于子树的逐一移除。

## 4. UI 层状态

`FolderShelfPage` 使用 `FolderShelfBloc` 管理：

- `currentPath`：当前路径字符串，根目录为 `''`。
- `folders` / `comics`：当前路径下的子文件夹和漫画。
- `selectionMode` / `selectedFolderPaths` / `selectedComicKeys`：多选管理状态。
- `_FolderShelfPageContentState` 混入了 `AutomaticKeepAliveClientMixin`，切换 Tab 时状态不丢失。

空状态会显示“啥都没有”和刷新按钮，且支持下拉刷新。

## 5. 收藏 vs 下载的关键区别

| 行为 | favorite / history | download |
|-----|-------------------|----------|
| 是否同步 | 是 | 否 |
| 删除链接 | 软删除 | 物理删除 |
| 移除最后一条链接 | 标记收藏为删除 | 删除下载记录及文件 |
| 删除文件夹 | 软删除 | 软删除 |
