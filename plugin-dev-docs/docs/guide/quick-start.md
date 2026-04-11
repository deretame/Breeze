# 快速开始

## 1) 你需要准备什么

- Node.js 18+
- pnpm 8+
- TypeScript 基础
- 一个可访问的静态文件地址（用于调试模式加载 bundle）

## 2) 初始化插件项目

```bash
mkdir breeze-plugin-demo
cd breeze-plugin-demo
pnpm init
pnpm add axios
pnpm add -D typescript tsx @types/node @rspack/core @rspack/cli cross-env
```

建议脚本：

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "pnpm typecheck && cross-env NODE_OPTIONS=\"--import tsx\" rspack build"
  }
}
```

## 3) 推荐目录结构

```text
breeze-plugin-demo/
  src/
    index.ts
  type/
    runtime-api.ts
    runtime-globals.d.ts
  package.json
  tsconfig.json
  rspack.config.ts
```

说明：

- `src/index.ts` 是插件入口
- `export default` 导出的对象即 API 表
- 键名必须与 Breeze 调用的 `fnPath` 一致

## 4) 最小可运行插件

下面是一份可直接改造的最小骨架：

```ts
const PLUGIN_ID = "replace-with-your-plugin-id";

type SearchPayload = {
  keyword?: string;
  page?: number;
  extern?: Record<string, unknown>;
};

type DetailPayload = {
  comicId?: string;
  extern?: Record<string, unknown>;
};

type ChapterPayload = {
  comicId?: string;
  chapterId?: string;
  extern?: Record<string, unknown>;
};

async function getInfo() {
  return {
    name: "示例插件",
    uuid: PLUGIN_ID,
    describe: "第三方插件示例",
    version: "0.1.0",
    function: []
  };
}

async function searchComic(payload: SearchPayload = {}) {
  return {
    source: PLUGIN_ID,
    extern: payload.extern ?? {},
    data: {
      paging: {
        page: Number(payload.page ?? 1),
        pages: 1,
        total: 0,
        hasReachedMax: true
      },
      items: []
    }
  };
}

async function getComicDetail(payload: DetailPayload = {}) {
  const comicId = String(payload.comicId ?? "").trim();

  return {
    source: PLUGIN_ID,
    comicId,
    extern: payload.extern ?? {},
    data: {
      normal: {
        comicInfo: {
          source: PLUGIN_ID,
          id: comicId,
          title: "",
          subtitle: "",
          description: "",
          likesCount: 0,
          viewsCount: 0,
          cover: { id: comicId, url: "", path: "", extern: {} },
          creator: {
            id: "",
            name: "",
            subtitle: "",
            avatar: { url: "", path: "" },
            extern: {}
          },
          titleMeta: [],
          metadata: [],
          extern: {}
        },
        eps: []
      },
      raw: {}
    }
  };
}

async function getChapter(payload: ChapterPayload = {}) {
  return {
    source: PLUGIN_ID,
    comicId: String(payload.comicId ?? ""),
    chapterId: String(payload.chapterId ?? ""),
    extern: payload.extern ?? {},
    data: {
      chapter: {
        epId: String(payload.chapterId ?? ""),
        epName: "",
        length: 0,
        epPages: "0",
        docs: []
      }
    }
  };
}

async function fetchImageBytes(_: { url?: string; timeoutMs?: number } = {}) {
  throw new Error("请实现 fetchImageBytes");
}

export default {
  getInfo,
  searchComic,
  getComicDetail,
  getChapter,
  fetchImageBytes
};
```

## 5) 调试连通流程

1. 本地构建出 bundle
2. 在 Breeze 插件管理中打开调试模式
3. 设置 `debugUrl` 指向你的最新 bundle 地址
4. 在客户端触发搜索、详情、阅读做冒烟

如果页面出现 `target is not function`，基本就是 `export default` 漏函数。

## 6) 下一步阅读

继续看 [插件 API 契约](/guide/plugin-api-contract)、[API 响应样例](/guide/api-examples) 和 [Scheme 设计](/guide/scheme-design)。
