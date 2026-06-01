import type {
  BridgeApi,
  CryptoApi,
  FsApi,
  NativeApi,
  PathApi,
} from "../types/runtime-globals";

export interface RuntimeApiSet {
  fs: FsApi;
  FSError: new (message?: string, code?: string, path?: string) => Error;
  native: NativeApi;
  bridge: BridgeApi;
  path: PathApi;
  nodeCryptoCompat: CryptoApi;
  uuidv4: () => string;
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

  const compat = getApi("nodeCryptoCompat");
  if (isCryptoApi(compat)) return compat;

  return undefined;
}

export function requireCryptoLike(): CryptoApi {
  const value = getCryptoLike();
  if (!value) {
    throw new TypeError("runtime API 不可用: crypto/nodeCryptoCompat");
  }
  return value;
}

export const runtime = {
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
  md5Hex(input: string) {
    return requireApi("bridge").call("crypto.md5_hex", input) as Promise<string>;
  },
  sha1Hex(input: string) {
    return requireApi("bridge").call("crypto.sha1_hex", input) as Promise<string>;
  },
  sha512Hex(input: string) {
    return requireApi("bridge").call("crypto.sha512_hex", input) as Promise<string>;
  },
  hmacSha1Hex(key: string, input: string) {
    return requireApi("bridge").call("crypto.hmac_sha1_hex", key, input) as Promise<string>;
  },
  hmacSha512Hex(key: string, input: string) {
    return requireApi("bridge").call("crypto.hmac_sha512_hex", key, input) as Promise<string>;
  },
  aesEcbPkcs7DecryptB64(payloadB64: string, keyRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_ecb_pkcs7_decrypt_b64",
      payloadB64,
      keyRaw,
    ) as Promise<string>;
  },
  aesCbcPkcs7EncryptB64(payloadB64: string, keyRaw: string, ivRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_cbc_pkcs7_encrypt_b64",
      payloadB64,
      keyRaw,
      ivRaw,
    ) as Promise<string>;
  },
  aesCbcPkcs7DecryptB64(payloadB64: string, keyRaw: string, ivRaw: string) {
    return requireApi("bridge").call(
      "crypto.aes_cbc_pkcs7_decrypt_b64",
      payloadB64,
      keyRaw,
      ivRaw,
    ) as Promise<string>;
  },
  aesGcmEncryptB64(payloadB64: string, keyRaw: string, nonceRaw: string, aadB64?: string) {
    return requireApi("bridge").call(
      "crypto.aes_gcm_encrypt_b64",
      payloadB64,
      keyRaw,
      nonceRaw,
      aadB64 ?? null,
    ) as Promise<string>;
  },
  aesGcmDecryptB64(payloadB64: string, keyRaw: string, nonceRaw: string, aadB64?: string) {
    return requireApi("bridge").call(
      "crypto.aes_gcm_decrypt_b64",
      payloadB64,
      keyRaw,
      nonceRaw,
      aadB64 ?? null,
    ) as Promise<string>;
  },
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ) {
    return requireApi("bridge").gzipCompress(input);
  },
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ) {
    return requireApi("bridge").gzipDecompress(input);
  },
  bridgeCall(name: string, ...args: unknown[]) {
    return requireApi("bridge").call(name, ...args);
  },
};
