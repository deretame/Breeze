export {};

export type NativeChainStep = string | { op: string; extraInputId?: number };

export interface FsApi {
  promises: {
    readFile(
      path: string,
      encoding?: string | null,
    ): Promise<Uint8Array | string>;
    writeFile(
      path: string,
      data: string | ArrayBuffer | ArrayBufferView | Uint8Array,
    ): Promise<void>;
    appendFile(
      path: string,
      data: string | ArrayBuffer | ArrayBufferView | Uint8Array,
    ): Promise<void>;
    mkdir(path: string, options?: { recursive?: boolean }): Promise<void>;
    readdir(
      path: string,
      options?: { withFileTypes?: boolean },
    ): Promise<unknown[]>;
    stat(path: string): Promise<unknown>;
    rm(
      path: string,
      options?: { recursive?: boolean; force?: boolean },
    ): Promise<void>;
  };
}

export interface PathApi {
  join(...parts: string[]): string;
  resolve(...parts: string[]): string;
  dirname(path: string): string;
  basename(path: string, suffix?: string): string;
  extname(path: string): string;
  isAbsolute(path: string): boolean;
}

export interface NativeApi {
  chain(
    steps: NativeChainStep[],
    input: Uint8Array | number,
  ): Promise<Uint8Array>;
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView,
  ): Promise<Uint8Array>;
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView,
  ): Promise<Uint8Array>;
  run(
    op: string,
    input: Uint8Array,
    args?: unknown,
    extraInput?: Uint8Array | number,
  ): Promise<Uint8Array>;
  put(input: Uint8Array): Promise<number>;
  free(id: number): Promise<void>;
}

export interface BridgeApi {
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  call(name: "crypto.md5_hex", input: string): Promise<string>;
  call(name: "crypto.sha1_hex", input: string): Promise<string>;
  call(name: "crypto.sha512_hex", input: string): Promise<string>;
  call(
    name: "crypto.hmac_sha1_hex",
    key: string,
    input: string,
  ): Promise<string>;
  call(
    name: "crypto.hmac_sha512_hex",
    key: string,
    input: string,
  ): Promise<string>;
  call(
    name: "crypto.aes_ecb_pkcs7_decrypt_b64",
    payloadB64: string,
    keyRaw: string,
  ): Promise<string>;
  call(
    name: "crypto.aes_cbc_pkcs7_encrypt_b64",
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  call(
    name: "crypto.aes_cbc_pkcs7_decrypt_b64",
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  call(
    name: "crypto.aes_gcm_encrypt_b64",
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
  call(
    name: "crypto.aes_gcm_decrypt_b64",
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
  call(
    name: "compression.gzip_decompress",
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<number[]>;
  call(
    name: "compression.gzip_compress",
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<number[]>;
  call(name: string, ...args: unknown[]): Promise<unknown>;
  callSync(name: string, ...args: unknown[]): unknown;
}

export interface HostRuntimeApi {
  bridge: BridgeApi;
  [key: string]: unknown;
}

export interface RuntimeFacadeApi extends HostRuntimeApi {
  fs: FsApi;
  FSError: new (message?: string, code?: string, path?: string) => Error;
  native: NativeApi;
  path: PathApi;
  nodeCryptoCompat: CryptoApi;
  uuidv4: () => string;
  mathAdd(a: number, b: number): Promise<number>;
  nativePut(input: Uint8Array): Promise<number>;
  nativeTake(id: number): Promise<Uint8Array>;
  nativeExec(
    op: string,
    inputId: number,
    args?: unknown,
    extraInputId?: Uint8Array | number,
  ): Promise<number>;
  md5Hex(input: string): Promise<string>;
  sha1Hex(input: string): Promise<string>;
  sha512Hex(input: string): Promise<string>;
  hmacSha1Hex(key: string, input: string): Promise<string>;
  hmacSha512Hex(key: string, input: string): Promise<string>;
  aesEcbPkcs7DecryptB64(payloadB64: string, keyRaw: string): Promise<string>;
  aesCbcPkcs7EncryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  aesCbcPkcs7DecryptB64(
    payloadB64: string,
    keyRaw: string,
    ivRaw: string,
  ): Promise<string>;
  aesGcmEncryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
  aesGcmDecryptB64(
    payloadB64: string,
    keyRaw: string,
    nonceRaw: string,
    aadB64?: string | null,
  ): Promise<string>;
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
  bridgeCall(name: string, ...args: unknown[]): Promise<unknown>;
}

export interface CryptoHash {
  update(
    data: string | ArrayBuffer | ArrayBufferView,
    inputEncoding?: "utf8" | "utf-8" | "hex" | "base64" | "latin1" | "binary",
  ): CryptoHash;
  digest(
    encoding?:
      | "hex"
      | "base64"
      | "latin1"
      | "binary"
      | "utf8"
      | "utf-8"
      | "buffer",
  ): string | Buffer;
}

export interface CryptoApi {
  createHash(algorithm: "sha256" | "sha-256"): CryptoHash;
  createHmac(
    algorithm: "sha256" | "sha-256",
    key: string | ArrayBuffer | ArrayBufferView,
  ): CryptoHash;
  randomBytes(size: number): Buffer;
}

declare global {
  var __web: HostRuntimeApi;
  var fs: FsApi | undefined;
  var path: PathApi | undefined;
  var native: NativeApi;
  var bridge: BridgeApi;
  var nodeCryptoCompat: CryptoApi;
  var uuidv4: () => string;
}
