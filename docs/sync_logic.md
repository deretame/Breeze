# Breeze 漫画数据同步逻辑

> 对应代码：`lib/network/sync/comic_sync_core.dart`

## 1. 同步范围

同步只包含以下四类数据：

| 数据类型 | 实体 | 同步方式 |
|---------|------|---------|
| 收藏 | `UnifiedComicFavorite` | LWW（Last-Write-Wins） |
| 历史 | `UnifiedComicHistory` | LWW |
| 文件夹 | `ComicFolder`（favorite / history） | 版本向量 + LWW |
| 链接 | `ComicLink`（favorite / history） | 版本向量 + LWW |

**下载（download）类型不参与同步**，本地删除时直接物理删除。

## 2. Payload 结构

`buildCompressedPayload()` 生成：

```json
{
  "version": "v1",
  "favorites": [...],
  "histories": [...],
  "folders": [...],
  "links": [...]
}
```

- 序列化时会去掉本地 `id`。
- 然后经过压缩 + AES-CTR 加密。

## 3. 一次完整同步流程

`runComicSync()`：

1. 生成本地 payload 并计算 md5。
2. 拉取远端 md5 和文件列表。
3. 如果本地 md5 == 远端 md5 → 直接跳过。
4. 否则下载最新的远端 comic 数据，解密解压。
5. 在 ObjectBox 写事务中调用 `mergeUnifiedData()`。
6. 合并后再生成本地 payload：
   - 若 md5 与远端相同 → 不上传。
   - 否则 → 上传新的数据文件和 md5。
7. 清理旧远端文件。

## 4. 合并规则

### 4.1 Favorites / Histories

以 `uniqueKey` 为合并键，纯 LWW：

- 同一本漫画的收藏/历史记录，谁的 `updatedAt` 更晚就用谁。

### 4.2 Folders / Links

以 **版本向量** 为主，`updatedAt` 为辅：

- `ComicFolder` 合并键：`syncId`
- `ComicLink` 合并键：`${comicUniqueKey}|${folderSyncId}|${typeData}`

每个设备安装时生成一个 `syncDeviceId`（UUIDv4）。`versionVectorJson` 是一个计数器映射：

```json
{"deviceA": 3, "deviceB": 2}
```

比较两个向量：

| 关系 | 处理 |
|-----|------|
| 相等 | 优先比较 `updatedAt`，更大者胜出；`updatedAt` 相同则按内容 JSON / `syncId` 字典序选出唯一 winner，并提升版本向量 |
| 一方全 ≥ 另一方 | 较大的一方胜出 |
| 冲突（互有高低） | 比较 `updatedAt`，相同时使用确定性 tie-breaker；胜方向量合并后在本设备计数 +1 |

## 5. 冲突处理

### 5.1 文件夹 uniqueKey 冲突

合并后如果多个 folder 拥有相同 `uniqueKey` 但不同 `syncId`：

- 用版本向量 / LWW 选出 winner。
- **winner active**：把 loser 的直接子文件夹挂到 winner 下，loser 下的链接也迁到 winner。
- **winner tombstone**：把 loser 整个子树全部 tombstone，并清理指向它们的 active link。

### 5.2 孤儿链接修复

`_repairOrphanLinks()` 处理“active link 指向不存在/已删除文件夹”。

它先于孤儿文件夹修复执行，因为：

- 指向 tombstone 文件夹的 link 可能向量更大，此时应复活文件夹而不是 tombstone 子树。
- 旧版 `path|type` 链接会补全缺失的祖先文件夹，避免子文件夹被误判为孤儿。

处理规则：

- link 有 `folderSyncId`：
  - 对应文件夹是 tombstone → 按版本向量决定是复活文件夹还是把 link tombstone。
  - 对应文件夹 active → 只校准 `uniqueKey`。
- link 没有 `folderSyncId`（旧版数据）：
  - 从旧 `uniqueKey` 解析目标路径，逐级补全祖先文件夹。
  - 最终把 link 指向最深的有效文件夹。

### 5.3 孤儿文件夹修复

`_repairOrphanFolders()` 处理“active folder 的 `parentSyncId` 指向已删除或不存在的文件夹”。

典型场景：某个文件夹在 uniqueKey 冲突中作为 loser 被移除，但其 active 子文件夹仍保留在列表中。

处理规则：

- 递归扫描所有 active folder，若其 `parentSyncId` 对应的文件夹不存在或已被 tombstone，则将该 folder tombstone 并提升版本向量。
- 同时把指向这些 folder 的 active link 也 tombstone，避免产生新的孤儿链接。

该步骤在 `_repairOrphanLinks()` 之后执行，以便链接先有机会复活父文件夹或补全路径链。

## 6. 软删除

- favorite / history / folder / link 使用 tombstone（`deletedAt`）。
- 同步时 tombstone 也会参与合并，避免误删的跨设备复活。
- download 不走同步，删除即物理删除。

## 7. 旧数据兼容

由于早期版本用 `path|type` 作为 folder 的 `uniqueKey`，用 `comic|folderPath|type` 作为 link 的 `uniqueKey`，合并时会做一次性兼容：

- 从旧 folder `uniqueKey` 中反推 `parentSyncId`。
- 从旧 link `uniqueKey` 中反推 `folderSyncId`。
- 合并完成后统一把 folder `uniqueKey` 规范化为 `parentSyncId|name|type`。

## 8. 常见场景

### 云端没有 folder/link 数据

`_parseJsonList(data['folders'])` 返回空列表；版本向量合并时本地直接胜出，本地文件夹/链接原样保留，最后上传会把本地数据带上去。

### 多端同时创建同名文件夹

两边 `syncId` 不同，但规范化的 `uniqueKey` 相同，会进入冲突处理：版本向量 + LWW 选一个 winner，另一边被合并或 tombstone。
