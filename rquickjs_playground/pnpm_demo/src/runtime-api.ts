import type {
  BridgeApi,
  CryptoApi,
  FsApi,
  NativeApi,
  PathApi,
  WasiApi,
} from "../types/runtime-globals";

export interface RuntimeApiSet {
  Headers: typeof Headers;
  AbortController: typeof AbortController;
  AbortSignal: typeof AbortSignal;
  Request: typeof Request;
  Response: typeof Response;
  fetch: typeof fetch;
  fs: FsApi;
  FSError: new (message?: string, code?: string, path?: string) => Error;
  native: NativeApi;
  wasi: WasiApi;
  bridge: BridgeApi;
  path: PathApi;
  URL: typeof URL;
  URLSearchParams: typeof URLSearchParams;
  Blob: typeof Blob;
  File: typeof File;
  FormData: typeof FormData;
  crypto: CryptoApi;
  nodeCryptoCompat: CryptoApi;
  uuidv4: () => string;
  TextEncoder: typeof TextEncoder;
  TextDecoder: typeof TextDecoder;
  Buffer: typeof Buffer;
  console: Console;
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

export function getCryptoLike(): CryptoApi | undefined {
  const direct = getApi("crypto");
  if (isCryptoApi(direct)) return direct;

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

export function getRuntimeApis(): Partial<RuntimeApiSet> {
  return {
    Headers: getApi("Headers"),
    AbortController: getApi("AbortController"),
    AbortSignal: getApi("AbortSignal"),
    Request: getApi("Request"),
    Response: getApi("Response"),
    fetch: getApi("fetch"),
    fs: getApi("fs"),
    FSError: getApi("FSError"),
    native: getApi("native"),
    wasi: getApi("wasi"),
    bridge: getApi("bridge"),
    path: getApi("path"),
    URL: getApi("URL"),
    URLSearchParams: getApi("URLSearchParams"),
    Blob: getApi("Blob"),
    File: getApi("File"),
    FormData: getApi("FormData"),
    crypto: getApi("crypto"),
    nodeCryptoCompat: getApi("nodeCryptoCompat"),
    uuidv4: getApi("uuidv4"),
    TextEncoder: getApi("TextEncoder"),
    TextDecoder: getApi("TextDecoder"),
    Buffer: getApi("Buffer"),
    console: getApi("console"),
  };
}

export const runtime = {
  get Headers() {
    return requireApi("Headers");
  },
  get AbortController() {
    return requireApi("AbortController");
  },
  get AbortSignal() {
    return requireApi("AbortSignal");
  },
  get Request() {
    return requireApi("Request");
  },
  get Response() {
    return requireApi("Response");
  },
  get fetch() {
    return requireApi("fetch");
  },
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
  get URL() {
    return requireApi("URL");
  },
  get URLSearchParams() {
    return requireApi("URLSearchParams");
  },
  get Blob() {
    return requireApi("Blob");
  },
  get File() {
    return requireApi("File");
  },
  get FormData() {
    return requireApi("FormData");
  },
  get crypto() {
    return requireCryptoLike();
  },
  get uuidv4() {
    return requireApi("uuidv4");
  },
  get TextEncoder() {
    return requireApi("TextEncoder");
  },
  get TextDecoder() {
    return requireApi("TextDecoder");
  },
  get Buffer() {
    return requireApi("Buffer");
  },
  get console() {
    return requireApi("console");
  },
};
