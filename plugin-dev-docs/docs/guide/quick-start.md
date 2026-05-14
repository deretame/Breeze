# 快速开始

## 1) 环境准备

- Node.js 22+
- pnpm 10+（推荐 11+）
- Git

## 2) 直接使用示例仓库

推荐直接基于示例仓库开始开发：

- 仓库地址：`https://github.com/deretame/Breeze-plugin-example`

```bash
git clone https://github.com/deretame/Breeze-plugin-example.git your-plugin-name
cd your-plugin-name
pnpm install
```

初始化后，先修改这些内容：

1. `package.json`、`src/common.ts`、`src/get-info.ts` 里的插件信息
2. `src/common.ts` 或 `src/get-info.ts` 里的插件 ID 和展示信息
3. `src/index.ts` 里的 API 实现
4. 需要时执行 `pnpm run build` 生成 `manifest.json`

## 3) 推荐起步方式

建议按下面顺序改造示例仓库：

1. 先接 `searchComic`，保证能搜到漫画
2. 再接 `getComicDetail`，保证能打开详情页
3. 再接 `getReadSnapshot`，保证能拿到当前章节和页面信息
4. 再接 `fetchImageBytes`，保证阅读时能真正取到图片
5. 最后接 `getChapter` 和其他可选能力，补齐下载链路

`getInfo` 主要是插件信息入口，不是阅读主链路的优先瓶颈。

## 4) 工程结构

```text
Breeze-plugin-example/
  src/
    index.ts
    common.ts
    get-info.ts
  types/
    runtime-api.ts
    runtime-api.typecheck.ts
    runtime-globals.d.ts
  build/
  package.json
  tsconfig.json
  rspack.config.ts
  manifest.json
```

说明：

- `src/index.ts` 是插件入口
- `src/common.ts` 放公共构造函数和常量
- `src/get-info.ts` 放插件信息拼装
- `manifest.json` 由 `pnpm run build` 自动生成，不手动维护
- `export default` 导出的对象即 API 表
- 键名必须与 Breeze 调用的 `fnPath` 一致

## 5) 当前章节模型

示例仓库里的章节字段采用当前模型：

- `requestId`: 插件交互字段
- `logicalKey`: 宿主逻辑章节字段
- `storageChapterId`: 本地存储字段
- `extern`: 仅承载插件自己的透传数据

简单理解：

- `id`: 章节自身标识，章节列表和章节对象都会带上它
- `requestId`: 宿主后续调用 `getReadSnapshot`、`getChapter` 时用于请求这个章节
- `logicalKey`: 宿主内部用于识别“这是哪一个章节”
- `storageChapterId`: 下载到本地后，这个章节对应的目录名
- `name`: 章节名
- `order`: 章节顺序
- `pages`: 当前章节的图片列表
- `extern`: 插件自己需要继续透传的补充数据

## 6) 调试连通流程

1. 执行 `pnpm run dev`
2. 等待 dev server 输出 bundle 地址
3. 在 Breeze 里进入“发现”
4. 打开“插件商店”
5. 通过本地或网络方式安装插件
6. 安装完成后回到“发现”页
7. 进入该插件的设置页
8. 打开调试模式
9. 把输出的 bundle 地址填到 `调试地址（debugUrl）`
10. 保存后开始调试，在客户端触发搜索、详情、阅读做冒烟

## 7) 下一步阅读

继续看 [插件 API 契约](/guide/plugin-api-contract)、[API 响应样例](/guide/api-examples) 和 [Scheme 设计](/guide/scheme-design)。
