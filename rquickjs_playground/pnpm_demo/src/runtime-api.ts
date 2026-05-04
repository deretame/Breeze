import type {
  BridgeApi,
  CryptoApi,
  FsApi,
  NativeApi,
  PathApi,
  WasiApi,
} from "../types/runtime-globals";

export interface RuntimeApiSet {
  fs: FsApi;
  FSError: new (message?: string, code?: string, path?: string) => Error;
  native: NativeApi;
  wasi: WasiApi;
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
  get wasi() {
    return requireApi("wasi");
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
};
