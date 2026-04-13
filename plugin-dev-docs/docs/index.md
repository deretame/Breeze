# Breeze 插件开发文档

面向第三方插件开发者的接口与实现文档。

文档聚焦插件接口契约、页面协议、调试与发布流程。

## 文档内容

- 插件最小骨架（可直接开工）
- 必需 API 与可选 API 的输入输出示例
- 设置页/登录页/列表页的 `scheme + data` 协议
- 本地联调、调试模式、打包发布流程
- 交付前检查清单

## 前置假设

- 使用 TypeScript 开发插件
- 构建产物为单文件 bundle（例如 `*.bundle.cjs`）
- 插件入口采用 `export default { ... }`

## 推荐阅读顺序

1. [快速开始](/guide/quick-start)
2. [生命周期与结构](/guide/runtime-and-structure)
3. [插件 API 契约](/guide/plugin-api-contract)
4. [API 响应样例](/guide/api-examples)
5. [Scheme 设计](/guide/scheme-design)
6. [调试与发布](/guide/debug-and-release)
7. [交付检查清单](/guide/checklist)
