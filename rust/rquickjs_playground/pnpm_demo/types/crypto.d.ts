/**
 * 运行时注入的 crypto 能力类型声明。
 *
 * 对应 JS 运行时 `js/00_bootstrap.js` 中组装的 `cryptoModule`，
 * 并通过 `js/99_exports.js` 挂载到 `globalThis.crypto`。
 */

/** 可被作为二进制输入的数据类型。 */
export type BinaryInput = Uint8Array | ArrayBuffer | ArrayBufferView | number[];

/** 可被作为文本/二进制混合输入的数据类型。 */
export type TextInput = BinaryInput | string;

/** 支持的哈希/HMAC 算法名。 */
export type HashAlgorithm =
  | "sha1"
  | "sha-1"
  | "sha256"
  | "sha-256"
  | "sha512"
  | "sha-512";

/** `update()` 接受的输入编码。 */
export type CryptoInputEncoding =
  | "utf8"
  | "utf-8"
  | "hex"
  | "base64"
  | "latin1"
  | "binary";

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
  update(data: TextInput): CryptoHash;
  update(data: string, inputEncoding: CryptoInputEncoding): CryptoHash;
  digest(): Buffer;
  digest(encoding: "buffer"): Buffer;
  digest(encoding: Exclude<CryptoOutputEncoding, "buffer">): string;
}

/** 流式 HMAC，兼容 Node.js crypto.createHmac 的子集。 */
export interface CryptoHmac {
  update(data: TextInput): CryptoHmac;
  update(data: string, inputEncoding: CryptoInputEncoding): CryptoHmac;
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
  createHmac(algorithm: HashAlgorithm, key: TextInput): CryptoHmac;

  /** MD5 摘要，返回 hex 字符串。 */
  md5(input: TextInput): Promise<string>;

  /** SHA-1 摘要，返回 hex 字符串。 */
  sha1(input: TextInput): Promise<string>;

  /** SHA-256 摘要，返回 hex 字符串。 */
  sha256(input: TextInput): Promise<string>;

  /** SHA-512 摘要，返回 hex 字符串。 */
  sha512(input: TextInput): Promise<string>;

  /** HMAC-SHA1，返回 hex 字符串。 */
  hmacSha1(key: string, input: TextInput): Promise<string>;

  /** HMAC-SHA256，返回 hex 字符串。 */
  hmacSha256(key: string, input: TextInput): Promise<string>;

  /** HMAC-SHA512，返回 hex 字符串。 */
  hmacSha512(key: string, input: TextInput): Promise<string>;

  /** AES-ECB-PKCS7 加密，返回二进制。 */
  aesEcbPkcs7Encrypt(input: TextInput, keyRaw: string): Promise<Uint8Array>;

  /** AES-ECB-PKCS7 解密，返回二进制。 */
  aesEcbPkcs7Decrypt(input: TextInput, keyRaw: string): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 加密，返回二进制。 */
  aesCbcPkcs7Encrypt(
    input: TextInput,
    keyRaw: string,
    ivRaw: string,
  ): Promise<Uint8Array>;

  /** AES-CBC-PKCS7 解密，返回二进制。 */
  aesCbcPkcs7Decrypt(
    input: TextInput,
    keyRaw: string,
    ivRaw: string,
  ): Promise<Uint8Array>;

  /** @deprecated use {@link aesCbcPkcs7Encrypt} */
  aesCbcPkcs7EncryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;

  /** @deprecated use {@link aesCbcPkcs7Decrypt} */
  aesCbcPkcs7DecryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;

  /** AES-GCM 加密，返回二进制。 */
  aesGcmEncrypt(
    input: TextInput,
    keyRaw: string,
    nonceRaw: string,
    aad?: BinaryInput | string | null,
  ): Promise<Uint8Array>;

  /** AES-GCM 解密，返回二进制。 */
  aesGcmDecrypt(
    input: TextInput,
    keyRaw: string,
    nonceRaw: string,
    aad?: BinaryInput | string | null,
  ): Promise<Uint8Array>;

  /** @deprecated use {@link aesGcmEncrypt} */
  aesGcmEncryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;

  /** @deprecated use {@link aesGcmDecrypt} */
  aesGcmDecryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;

  /** 生成密码学安全随机字节。 */
  randomBytes(size: number): Buffer;

  /** 生成 UUID v4。 */
  randomUUID(): string;

  /** 时序安全比较，防御 timing attack。 */
  timingSafeEqual(a: TextInput, b: TextInput): boolean;

  /** PBKDF2-HMAC-SHA256 同步派生。 */
  pbkdf2Sync(
    password: TextInput,
    salt: TextInput,
    iterations: number,
    keyLen: number,
    digest?: HashAlgorithm,
  ): Buffer;

  /** PBKDF2-HMAC-SHA256 异步派生。 */
  pbkdf2(
    password: TextInput,
    salt: TextInput,
    iterations: number,
    keyLen: number,
    digest?: HashAlgorithm | ((err: Error | null, derivedKey?: Buffer) => void),
    callback?: (err: Error | null, derivedKey?: Buffer) => void,
  ): void;
}
