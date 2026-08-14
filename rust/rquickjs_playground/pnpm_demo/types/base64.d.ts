/**
 * Base64 编解码工具类型声明。
 *
 * 对应 JS 运行时 `js/00_bootstrap.js` 中暴露的 `bytesToBase64` /
 * `bytesFromBase64` 全局函数，以及 `__web.base64` 模块。
 */

import type { BinaryInput } from "./crypto";

/** Base64 编解码 API。 */
export interface Base64Api {
  /** 将二进制数据编码为标准 base64 字符串。 */
  encode(input: BinaryInput): string;

  /** 将标准 base64 字符串解码为二进制数据。 */
  decode(text: string): Uint8Array;
}

/** 将二进制数据编码为标准 base64 字符串。 */
export declare function bytesToBase64(input: BinaryInput): string;

/** 将标准 base64 字符串解码为二进制数据。 */
export declare function bytesFromBase64(text: string): Uint8Array;

declare global {
  /** 将二进制数据编码为标准 base64 字符串。 */
  var bytesToBase64: (input: BinaryInput) => string;

  /** 将标准 base64 字符串解码为二进制数据。 */
  var bytesFromBase64: (text: string) => Uint8Array;
}

export {};
