/**
 * 运行时注入的完整 API 集合与全局声明。
 *
 * 对应 `js/00_bootstrap.js` 组装的 `__web` 对象，
 * 以及 `js/99_exports.js` 向 `globalThis` 导出的全局变量。
 */

/// <reference path="./breeze-html.d.ts" />

import type { BridgeApi } from "./bridge";
import type { CryptoApi } from "./crypto";
import type { FsApi, PathApi } from "./fs";
import type { NativeApi } from "./native";

export interface FSErrorConstructor {
  new (message?: string, code?: string, path?: string): Error;
}

/**
 * 运行时向插件暴露的完整 API 集合。
 *
 * 对应运行时内部的 `__web` 对象。
 */
export interface RuntimeApiSet {
  fs: FsApi;
  FSError: FSErrorConstructor;
  native: NativeApi;
  bridge: BridgeApi;
  path: PathApi;
  crypto: CryptoApi;
  /** @deprecated use {@link crypto} */
  nodeCryptoCompat?: CryptoApi;
  uuidv4: () => string;
}

/**
 * `__web` 的类型别名，与 `RuntimeApiSet` 完全一致。
 */
export type HostRuntimeApi = RuntimeApiSet;

declare global {
  /** 运行时内部总线，包含全部注入能力。 */
  var __web: HostRuntimeApi;

  /** 文件系统 API（可能不存在于纯 Node 测试环境）。 */
  var fs: FsApi | undefined;

  /** 路径工具 API（可能不存在于纯 Node 测试环境）。 */
  var path: PathApi | undefined;

  /** Rust 原生二进制处理 API。 */
  var native: NativeApi;

  /** JS ↔ Rust bridge 调用通道。 */
  var bridge: BridgeApi;

  /** 运行时注入的 crypto 模块。 */
  var crypto: CryptoApi;

  /** @deprecated use {@link crypto} */
  var nodeCryptoCompat: CryptoApi | undefined;

  /** UUID v4 生成器。 */
  var uuidv4: () => string;
}

export {};
