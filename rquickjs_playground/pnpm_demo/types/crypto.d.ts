/**
 * 运行时注入的 crypto 能力类型声明。
 *
 * 对应 JS 运行时 `js/00_bootstrap.js` 中组装的 `cryptoModule`，
 * 并通过 `js/99_exports.js` 挂载到 `globalThis.crypto`。
 *
 * 注意：本文件声明的所有 hash / 加密 / HMAC / AES / PBKDF2 等 API 只接受原始二进制数据。
 * 如果需要传入 base64 或字符串，请先在 JS 层转换为 Uint8Array：
 *   - base64: 使用全局的 bytesFromBase64(base64String)
 *   - 字符串: 使用 new TextEncoder().encode(string) 或 encodeUtf8(string)
 */

/** 可被作为二进制输入的数据类型。 */
export type BinaryInput = Uint8Array | ArrayBuffer | ArrayBufferView | number[];

/** 支持的哈希/HMAC 算法名。 */
export type HashAlgorithm =
  | "sha1"
  | "sha-1"
  | "sha256"
  | "sha-256"
  | "sha512"
  | "sha-512";

/** `digest()` 支持的输出编码；传 `buffer` 或不传返回 `Buffer`。 */
export type CryptoOutputEncoding =
  | "hex"
  | "base64"
  | "latin1"
  | "binary"
  | "utf8"
  | "utf-8"
  | "buffer";

/** 流式哈希，兼容 Node.js crypto.createHash 的子集。 */
export interface CryptoHash {
  update(data: BinaryInput): CryptoHash;
  digest(): Buffer;
  digest(encoding: "buffer"): Buffer;
  digest(encoding: Exclude<CryptoOutputEncoding, "buffer">): string;
}

/** 流式 HMAC，兼容 Node.js crypto.createHmac 的子集。 */
export interface CryptoHmac {
  update(data: BinaryInput): CryptoHmac;
  digest(): Buffer;
  digest(encoding: "buffer"): Buffer;
  digest(encoding: Exclude<CryptoOutputEncoding, "buffer">): string;
}

/**
 * Breeze 运行时注入的 crypto 对象。
 *
 * 注意：并非完整 Web Crypto API，也不包含 Node.js crypto 全部方法。
 */
export interface CryptoApi {
  /** 创建流式哈希对象。 */
  createHash(algorithm: HashAlgorithm): CryptoHash;

  /** 创建流式 HMAC 对象。 */
  createHmac(algorithm: HashAlgorithm, key: BinaryInput): CryptoHmac;

  /** MD5 摘要，返回 hex 字符串。 */
  md5(input: BinaryInput): Promise<string>;

  /** SHA-1 摘要，返回 hex 字符串。 */
  sha1(input: BinaryInput): Promise<string>;

  /** SHA-256 摘要，返回 hex 字符串。 */
  sha256(input: BinaryInput): Promise<string>;

  /** SHA-512 摘要，返回 hex 字符串。 */
  sha512(input: BinaryInput): Promise<string>;

  /** HMAC-SHA1，返回 hex 字符串。 */
  hmacSha1(key: BinaryInput, input: BinaryInput): Promise<string>;

  /** HMAC-SHA256，返回 hex 字符串。 */
  hmacSha256(key: BinaryInput, input: BinaryInput): Promise<string>;

  /** HMAC-SHA512，返回 hex 字符串。 */
  hmacSha512(key: BinaryInput, input: BinaryInput): Promise<string>;

  /** AES-ECB-PKCS7 加密，返回二进制。 */
  aesEcbPkcs7Encrypt(input: BinaryInput, keyRaw: BinaryInput): Promise<Uint8Array>;

  /** AES-ECB-PKCS7 解密，返回二进制。 */
  aesEcbPkcs7Decrypt(input: BinaryInput, keyRaw: BinaryInput): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 加密，返回二进制。 */
  aesCbcPkcs7Encrypt(
    input: BinaryInput,
    keyRaw: BinaryInput,
    ivRaw: BinaryInput,
  ): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 解密，返回二进制。 */
  aesCbcPkcs7Decrypt(
    input: BinaryInput,
    keyRaw: BinaryInput,
    ivRaw: BinaryInput,
  ): Promise<Uint8Array>;

  /** AES-GCM 加密，返回二进制。 */
  aesGcmEncrypt(
    input: BinaryInput,
    keyRaw: BinaryInput,
    nonceRaw: BinaryInput,
    aad?: BinaryInput | null,
  ): Promise<Uint8Array>;

  /** AES-GCM 解密，返回二进制。 */
  aesGcmDecrypt(
    input: BinaryInput,
    keyRaw: BinaryInput,
    nonceRaw: BinaryInput,
    aad?: BinaryInput | null,
  ): Promise<Uint8Array>;

  /** @deprecated 已废弃，请使用 {@link aesCbcPkcs7Encrypt}。 */
  aesCbcPkcs7EncryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): string;

  /** @deprecated 已废弃，请使用 {@link aesCbcPkcs7Decrypt}。 */
  aesCbcPkcs7DecryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): string;

  /** @deprecated 已废弃，请使用 {@link aesGcmEncrypt}。 */
  aesGcmEncryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): string;

  /** @deprecated 已废弃，请使用 {@link aesGcmDecrypt}。 */
  aesGcmDecryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): string;

  /** 生成密码学安全随机字节。 */
  randomBytes(size: number): Buffer;

  /** 生成 UUID v4。 */
  randomUUID(): string;

  /** 时序安全比较，防御 timing attack。 */
  timingSafeEqual(a: BinaryInput, b: BinaryInput): boolean;

  /** PBKDF2-HMAC-SHA256 同步派生。 */
  pbkdf2Sync(
    password: BinaryInput,
    salt: BinaryInput,
    iterations: number,
    keyLen: number,
    digest?: HashAlgorithm,
  ): Buffer;

  /** PBKDF2-HMAC-SHA256 异步派生。 */
  pbkdf2(
    password: BinaryInput,
    salt: BinaryInput,
    iterations: number,
    keyLen: number,
    digest?: HashAlgorithm | ((err: Error | null, derivedKey?: Buffer) => void),
    callback?: (err: Error | null, derivedKey?: Buffer) => void,
  ): void;
}
