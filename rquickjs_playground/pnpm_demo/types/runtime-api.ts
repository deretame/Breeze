import type { CryptoApi, RuntimeApiSet } from "../types";

export interface RuntimeFacade extends RuntimeApiSet {
  mathAdd(a: number, b: number): Promise<number>;
  nativePut(input: Uint8Array): Promise<number>;
  nativeTake(id: number): Promise<Uint8Array>;
  nativeExec(
    op: string,
    inputId: number,
    args?: unknown,
    extraInputId?: Uint8Array | number,
  ): Promise<number>;
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  bridgeCall(name: string, ...args: unknown[]): Promise<unknown>;

  /** @deprecated use {@link CryptoApi.md5 crypto.md5} */
  md5Hex(input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.sha1 crypto.sha1} */
  sha1Hex(input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.sha256 crypto.sha256} */
  sha256Hex(input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.sha512 crypto.sha512} */
  sha512Hex(input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.hmacSha1 crypto.hmacSha1} */
  hmacSha1Hex(key: string, input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.hmacSha256 crypto.hmacSha256} */
  hmacSha256Hex(key: string, input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.hmacSha512 crypto.hmacSha512} */
  hmacSha512Hex(key: string, input: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.aesEcbPkcs7Decrypt crypto.aesEcbPkcs7Decrypt} */
  aesEcbPkcs7DecryptB64(payloadB64: string, keyRaw: string): Promise<string>;
  /** @deprecated use {@link CryptoApi.aesCbcPkcs7Encrypt crypto.aesCbcPkcs7Encrypt} */
  aesCbcPkcs7EncryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  /** @deprecated use {@link CryptoApi.aesCbcPkcs7Decrypt crypto.aesCbcPkcs7Decrypt} */
  aesCbcPkcs7DecryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  /** @deprecated use {@link CryptoApi.aesGcmEncrypt crypto.aesGcmEncrypt} */
  aesGcmEncryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
  /** @deprecated use {@link CryptoApi.aesGcmDecrypt crypto.aesGcmDecrypt} */
  aesGcmDecryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
}

export type RuntimeApiName = keyof RuntimeApiSet;

type RuntimeGlobal = typeof globalThis & Partial<RuntimeApiSet>;

function isCryptoApi(value: unknown): value is CryptoApi {
  if (!value || typeof value !== "object") return false;
  const candidate = value as {
    createHash?: unknown;
    createHmac?: unknown;
    randomBytes?: unknown;
  };
  return (
    typeof candidate.createHash === "function" &&
    typeof candidate.createHmac === "function" &&
    typeof candidate.randomBytes === "function"
  );
}

function readGlobal<K extends RuntimeApiName>(
  name: K,
): RuntimeApiSet[K] | undefined {
  const g = globalThis as RuntimeGlobal;
  return g[name] as RuntimeApiSet[K] | undefined;
}

export function getApi<K extends RuntimeApiName>(
  name: K,
): RuntimeApiSet[K] | undefined {
  return readGlobal(name);
}

export function requireApi<K extends RuntimeApiName>(
  name: K,
): RuntimeApiSet[K] {
  const value = readGlobal(name);
  if (value === undefined || value === null) {
    throw new TypeError(`runtime API 不可用: ${String(name)}`);
  }
  return value;
}

function getCryptoLike(): CryptoApi | undefined {
  if (isCryptoApi(globalThis.crypto)) return globalThis.crypto;

  const runtimeCrypto = getApi("crypto");
  if (isCryptoApi(runtimeCrypto)) return runtimeCrypto;

  // 兼容旧命名：部分宿主/测试环境仍通过 nodeCryptoCompat 暴露。
  const legacyCompat = getApi("nodeCryptoCompat");
  if (isCryptoApi(legacyCompat)) return legacyCompat;

  return undefined;
}

export function requireCryptoLike(): CryptoApi {
  const value = getCryptoLike();
  if (!value) {
    throw new TypeError("runtime API 不可用: crypto");
  }
  return value;
}

export const hostRuntime: RuntimeFacade = {
  get fs() {
    return requireApi("fs");
  },
  get FSError() {
    return requireApi("FSError");
  },
  get native() {
    return requireApi("native");
  },
  get bridge() {
    return requireApi("bridge");
  },
  get path() {
    return requireApi("path");
  },
  get crypto() {
    return requireCryptoLike();
  },
  get uuidv4() {
    return requireApi("uuidv4");
  },
  mathAdd(a: number, b: number) {
    return requireApi("bridge").call("math.add", a, b) as Promise<number>;
  },
  nativePut(input: Uint8Array) {
    return requireApi("bridge").call("native.put", input) as Promise<number>;
  },
  nativeTake(id: number) {
    return requireApi("bridge").call("native.take", id) as Promise<Uint8Array>;
  },
  nativeExec(
    op: string,
    inputId: number,
    args?: unknown,
    extraInputId?: Uint8Array | number,
  ) {
    return requireApi("bridge").call(
      "native.exec",
      op,
      inputId,
      args,
      extraInputId ?? null,
    ) as Promise<number>;
  },
  gzipCompress(input: Uint8Array | ArrayBuffer | ArrayBufferView | number[]) {
    return requireApi("bridge").gzipCompress(input);
  },
  gzipDecompress(input: Uint8Array | ArrayBuffer | ArrayBufferView | number[]) {
    return requireApi("bridge").gzipDecompress(input);
  },
  bridgeCall(name: string, ...args: unknown[]) {
    return requireApi("bridge").call(name, ...args);
  },
  /** @deprecated use {@link CryptoApi.md5 crypto.md5} */
  md5Hex(input: string) {
    return requireApi("bridge").call(
      "crypto.md5_hex",
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.sha1 crypto.sha1} */
  sha1Hex(input: string) {
    return requireApi("bridge").call(
      "crypto.sha1_hex",
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.sha256 crypto.sha256} */
  sha256Hex(input: string) {
    return requireApi("bridge").call(
      "crypto.sha256_hex",
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.sha512 crypto.sha512} */
  sha512Hex(input: string) {
    return requireApi("bridge").call(
      "crypto.sha512_hex",
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.hmacSha1 crypto.hmacSha1} */
  hmacSha1Hex(key: string, input: string) {
    return requireApi("bridge").call(
      "crypto.hmac_sha1_hex",
      key,
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.hmacSha256 crypto.hmacSha256} */
  hmacSha256Hex(key: string, input: string) {
    return requireApi("bridge").call(
      "crypto.hmac_sha256_hex",
      key,
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.hmacSha512 crypto.hmacSha512} */
  hmacSha512Hex(key: string, input: string) {
    return requireApi("bridge").call(
      "crypto.hmac_sha512_hex",
      key,
      input,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.aesEcbPkcs7Decrypt crypto.aesEcbPkcs7Decrypt} */
  aesEcbPkcs7DecryptB64(payloadB64: string, keyRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_ecb_pkcs7_decrypt_b64",
      payloadB64,
      keyRaw,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.aesCbcPkcs7Encrypt crypto.aesCbcPkcs7Encrypt} */
  aesCbcPkcs7EncryptB64(payloadB64: string, keyRaw: string, ivRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_cbc_pkcs7_encrypt_b64",
      payloadB64,
      keyRaw,
      ivRaw,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.aesCbcPkcs7Decrypt crypto.aesCbcPkcs7Decrypt} */
  aesCbcPkcs7DecryptB64(payloadB64: string, keyRaw: string, ivRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_cbc_pkcs7_decrypt_b64",
      payloadB64,
      keyRaw,
      ivRaw,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.aesGcmEncrypt crypto.aesGcmEncrypt} */
  aesGcmEncryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ) {
    return requireApi("bridge").call(
      "crypto.aes_gcm_encrypt_b64",
      payloadB64,
      keyRaw,
      nonceRaw,
      aadB64 ?? null,
    ) as Promise<string>;
  },
  /** @deprecated use {@link CryptoApi.aesGcmDecrypt crypto.aesGcmDecrypt} */
  aesGcmDecryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ) {
    return requireApi("bridge").call(
      "crypto.aes_gcm_decrypt_b64",
      payloadB64,
      keyRaw,
      nonceRaw,
      aadB64 ?? null,
    ) as Promise<string>;
  },
};

/**
 * @deprecated use {@link hostRuntime}
 */
export const runtime = hostRuntime;

/** @deprecated use {@link requireCryptoLike} */
export const requireNodeCrypto = requireCryptoLike;
