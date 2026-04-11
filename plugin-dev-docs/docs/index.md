# Breeze 插件开发文档

这是一份给第三方插件作者的实战手册。

你不需要了解 Breeze 客户端内部实现，只需要按本文档的函数契约返回正确结构，即可被客户端调用。

## 你将得到什么

- 插件最小骨架（可直接开工）
- 必需 API 与可选 API 的输入输出示例
- 设置页/登录页/列表页的 `scheme + data` 协议
- 本地联调、调试模式、打包发布流程
- 交付前检查清单

## 文档假设

- 你使用 TypeScript 开发插件
- 你输出一个单文件 bundle（如 `*.bundle.cjs`）
- 你的入口是 `export default { ... }`

## 推荐阅读顺序

1. [快速开始](/guide/quick-start)
2. [生命周期与结构](/guide/runtime-and-structure)
3. [插件 API 契约](/guide/plugin-api-contract)
4. [API 响应样例](/guide/api-examples)
5. [Scheme 设计](/guide/scheme-design)
6. [调试与发布](/guide/debug-and-release)
7. [交付检查清单](/guide/checklist)
