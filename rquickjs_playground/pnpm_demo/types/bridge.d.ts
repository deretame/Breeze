/**
 * Bridge API 类型声明。
 *
 * `bridge` 是 JS 与宿主 Rust 之间的调用通道，支持异步 `call` 与同步 `callSync`。
 */

import type { BinaryInput } from "./crypto";

export interface BridgeApi {
  /** gzip 压缩（bridge 层快捷方法）。 */
  gzipCompress(input: BinaryInput): Promise<Uint8Array>;

  /** gzip 解压（bridge 层快捷方法）。 */
  gzipDecompress(input: BinaryInput): Promise<Uint8Array>;

  /** 数学加法（测试用）。 */
  call(name: "math.add", a: number, b: number): Promise<number>;

  /** native 内存池放入数据。 */
  call(name: "native.put", input: BinaryInput): Promise<number>;

  /** native 内存池取出数据。 */
  call(name: "native.take", id: number): Promise<Uint8Array | number[]>;

  /** 执行单个 native 操作。 */
  call(
    name: "native.exec",
    op: string,
    inputId: number,
    args?: unknown,
    extraInputId?: number | null,
  ): Promise<number>;

  /** MD5 摘要，返回 hex 字符串。 */
  call(name: "crypto.md5", input: BinaryInput): Promise<string>;

  /** SHA-1 摘要，返回 hex 字符串。 */
  call(name: "crypto.sha1", input: BinaryInput): Promise<string>;

  /** SHA-256 摘要，返回 hex 字符串。 */
  call(name: "crypto.sha256", input: BinaryInput): Promise<string>;

  /** SHA-512 摘要，返回 hex 字符串。 */
  call(name: "crypto.sha512", input: BinaryInput): Promise<string>;

  /** HMAC-SHA1，返回 hex 字符串。 */
  call(
    name: "crypto.hmac_sha1",
    key: string,
    input: BinaryInput,
  ): Promise<string>;

  /** HMAC-SHA256，返回 hex 字符串。 */
  call(
    name: "crypto.hmac_sha256",
    key: string,
    input: BinaryInput,
  ): Promise<string>;

  /** HMAC-SHA512，返回 hex 字符串。 */
  call(
    name: "crypto.hmac_sha512",
    key: string,
    input: BinaryInput,
  ): Promise<string>;

  /** AES-ECB-PKCS7 加密。 */
  call(
    name: "crypto.aes_ecb_pkcs7_encrypt",
    input: BinaryInput,
    keyRaw: string,
  ): Promise<Uint8Array>;

  /** AES-ECB-PKCS7 解密。 */
  call(
    name: "crypto.aes_ecb_pkcs7_decrypt",
    input: BinaryInput,
    keyRaw: string,
  ): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 加密。 */
  call(
    name: "crypto.aes_cbc_pkcs7_encrypt",
    input: BinaryInput,
    keyRaw: string,
    ivRaw: string,
  ): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 解密。 */
  call(
    name: "crypto.aes_cbc_pkcs7_decrypt",
    input: BinaryInput,
    keyRaw: string,
    ivRaw: string,
  ): Promise<Uint8Array>;

  /** AES-GCM 加密。 */
  call(
    name: "crypto.aes_gcm_encrypt",
    input: BinaryInput,
    keyRaw: string,
    nonceRaw: string,
    aad?: BinaryInput | null,
  ): Promise<Uint8Array>;

  /** AES-GCM 解密。 */
  call(
    name: "crypto.aes_gcm_decrypt",
    input: BinaryInput,
    keyRaw: string,
    nonceRaw: string,
    aad?: BinaryInput | null,
  ): Promise<Uint8Array>;

  /** gzip 压缩（route 形式）。 */
  call(
    name: "compression.gzip_compress",
    input: BinaryInput,
  ): Promise<number[]>;

  /** gzip 解压（route 形式）。 */
  call(
    name: "compression.gzip_decompress",
    input: BinaryInput,
  ): Promise<number[]>;

  /** 兜底：任意 bridge 调用。 */
  call(name: string, ...args: unknown[]): Promise<unknown>;

  /** 同步 bridge 调用（慎用，可能阻塞 JS 线程）。 */
  callSync(name: string, ...args: unknown[]): unknown;
}
