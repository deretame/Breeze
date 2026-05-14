# API 响应样例

本页提供可直接改造的 JSON 样例。

## 1) `searchComic` 样例

```json
{
  "source": "demo-plugin-id",
  "extern": {
    "sortBy": 1,
    "categories": ["同人"]
  },
  "scheme": {
    "version": "1.0.0",
    "type": "searchResult",
    "list": "comicGrid"
  },
  "data": {
    "paging": {
      "page": 1,
      "pages": 20,
      "total": 388,
      "hasReachedMax": false
    },
    "items": [
      {
        "source": "demo-plugin-id",
        "id": "c-001",
        "title": "示例漫画",
        "subtitle": "示例副标题",
        "finished": false,
        "likesCount": 123,
        "viewsCount": 456,
        "updatedAt": "2026-04-09T10:00:00.000Z",
        "cover": {
          "id": "c-001",
          "url": "https://cdn.example.com/cover/c-001.jpg",
          "path": "cover/c-001.jpg",
          "extern": {}
        },
        "metadata": [
          { "type": "author", "name": "作者", "value": ["作者A"] },
          { "type": "category", "name": "分类", "value": ["同人", "短篇"] }
        ],
        "raw": {},
        "extern": {}
      }
    ]
  }
}
```

## 2) `getComicDetail` 样例

```json
{
  "source": "demo-plugin-id",
  "comicId": "c-001",
  "extern": {},
  "scheme": { "version": "1.0.0", "type": "comicDetail" },
  "data": {
    "normal": {
      "comicInfo": {
        "id": "c-001",
        "title": "示例漫画",
        "titleMeta": [{ "name": "浏览：456", "onTap": {}, "extern": {} }],
        "creator": {
          "id": "u-001",
          "name": "作者A",
          "avatar": {
            "id": "u-001",
            "url": "https://cdn.example.com/avatar/u-001.jpg",
            "name": "u-001.jpg",
            "path": "avatar/u-001.jpg",
            "extern": {}
          },
          "onTap": {},
          "extern": {}
        },
        "description": "详情描述",
        "cover": {
          "id": "c-001",
          "url": "https://cdn.example.com/cover/c-001.jpg",
          "name": "c-001.jpg",
          "path": "cover/c-001.jpg",
          "extern": {}
        },
        "metadata": [],
        "extern": {}
      },
      "eps": [
        {
          "id": "ep-1",
          "requestId": "ep-1",
          "logicalKey": "ep-1",
          "storageChapterId": "ep-1",
          "name": "第1话",
          "order": 1,
          "extern": {}
        }
      ],
      "recommend": [],
      "totalViews": 456,
      "totalLikes": 123,
      "totalComments": 10,
      "isFavourite": false,
      "isLiked": false,
      "allowComments": true,
      "allowLike": true,
      "allowCollected": true,
      "allowDownload": true,
      "extern": {}
    },
    "raw": {}
  }
}
```

## 3) `getReadSnapshot` 样例

```json
{
  "source": "demo-plugin-id",
  "extern": {},
  "data": {
    "comic": {
      "id": "c-001",
      "source": "demo-plugin-id",
      "title": "示例漫画",
      "description": "详情描述",
      "cover": {
        "id": "c-001",
        "url": "https://cdn.example.com/cover/c-001.jpg",
        "path": "cover/c-001.jpg",
        "extern": {}
      },
      "creator": {
        "id": "u-001",
        "name": "作者A",
        "avatar": {
          "id": "u-001",
          "url": "https://cdn.example.com/avatar/u-001.jpg",
          "path": "avatar/u-001.jpg",
          "extern": {}
        },
        "extern": {}
      },
      "titleMeta": [],
      "metadata": [],
      "extern": {}
    },
    "chapter": {
      "id": "ep-1",
      "requestId": "ep-1",
      "logicalKey": "ep-1",
      "storageChapterId": "ep-1",
      "name": "第1话",
      "order": 1,
      "pages": [
        {
          "id": "p-1",
          "name": "001.jpg",
          "path": "001.jpg",
          "url": "https://cdn.example.com/pages/ep-1/001.jpg",
          "extern": {}
        },
        {
          "id": "p-2",
          "name": "002.jpg",
          "path": "002.jpg",
          "url": "https://cdn.example.com/pages/ep-1/002.jpg",
          "extern": {}
        }
      ],
      "extern": {}
    },
    "chapters": [
      {
        "id": "ep-1",
        "requestId": "ep-1",
        "logicalKey": "ep-1",
        "storageChapterId": "ep-1",
        "name": "第1话",
        "order": 1,
        "extern": {}
      }
    ]
  }
}
```

## 4) `getChapter` 样例

```json
{
  "source": "demo-plugin-id",
  "extern": {},
  "scheme": { "version": "1.0.0", "type": "chapterContent" },
  "data": {
    "chapter": {
      "id": "ep-1",
      "requestId": "ep-1",
      "logicalKey": "ep-1",
      "storageChapterId": "ep-1",
      "name": "第1话",
      "order": 1,
      "pages": [
        {
          "id": "p-1",
          "name": "001.jpg",
          "path": "001.jpg",
          "url": "https://cdn.example.com/pages/ep-1/001.jpg",
          "extern": {}
        },
        {
          "id": "p-2",
          "name": "002.jpg",
          "path": "002.jpg",
          "url": "https://cdn.example.com/pages/ep-1/002.jpg",
          "extern": {}
        }
      ],
      "extern": {}
    }
  }
}
```

## 5) `getCommentFeed` 样例（`replyMode = lazy`）

```json
{
  "source": "demo-plugin-id",
  "data": {
    "replyMode": "lazy",
    "canComment": { "comic": true, "reply": true },
    "paging": { "page": 1, "hasReachedMax": false },
    "topItems": [],
    "items": [
      {
        "id": "cm-1",
        "author": {
          "name": "用户A",
          "avatar": {
            "url": "https://cdn.example.com/avatar/u-a.jpg",
            "extern": { "path": "avatar/u-a.jpg" }
          }
        },
        "content": "这话太强了",
        "createdAt": "2026-04-09T10:30:00.000Z",
        "replyCount": 3,
        "replies": [],
        "extern": { "commentId": "cm-1" }
      }
    ]
  }
}
```

## 6) `postComment` 样例

```json
{
  "source": "demo-plugin-id",
  "scheme": { "version": "1.0.0", "type": "commentMutation" },
  "data": {
    "ok": true,
    "mode": "postComment",
    "created": {
      "id": "cm-new",
      "author": { "name": "我", "avatar": { "url": "", "extern": {} } },
      "content": "新评论",
      "createdAt": "刚刚",
      "replyCount": 0,
      "replies": [],
      "extern": { "commentId": "cm-new" }
    },
    "insertHint": {
      "strategy": "prependAfterTop",
      "needsRefetch": false
    }
  }
}
```

## 7) `getComicListSceneBundle` 样例

```json
{
  "source": "demo-plugin-id",
  "scheme": { "version": "1.0.0", "type": "comicListSceneBundle" },
  "data": {
    "scene": {
      "title": "排行榜",
      "source": "demo-plugin-id",
      "body": {
        "type": "pluginPagedComicList",
        "request": {
          "fnPath": "getRankingData",
          "core": { "days": "H24", "type": "comic" },
          "extern": { "source": "ranking" }
        }
      },
      "filter": {
        "fnPath": "getRankingFilterBundle",
        "extern": { "source": "ranking" }
      }
    }
  }
}
```
