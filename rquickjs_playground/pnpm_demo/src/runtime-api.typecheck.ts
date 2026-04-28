import {
  getApi,
  getCryptoLike,
  requireApi,
  requireCryptoLike,
  runtime,
} from "./runtime-api";

function expectType<T>(_value: T): void {}

const maybeNative = getApi("native");
expectType<Promise<number> | undefined>(maybeNative?.put(new Uint8Array([1])));

const native = requireApi("native");
expectType<Promise<Uint8Array>>(native.chain(["invert"], new Uint8Array([1, 2, 3])));

const wasi = requireApi("wasi");
expectType<Promise<number>>(wasi.run(new Uint8Array([0])).then((v) => v.exitCode));

const bridge = requireApi("bridge");
expectType<Promise<unknown>>(bridge.call("math.add", 1, 2));

const maybeCrypto = getCryptoLike();
expectType<string | undefined>(
  maybeCrypto?.createHmac("sha256", "key").update("hello").digest("hex") as string | undefined,
);

const crypto = requireCryptoLike();
expectType<string>(crypto.createHash("sha256").update("hello").digest("hex") as string);

const uuid = runtime.uuidv4();
expectType<string>(uuid);

expectType<typeof fetch>(runtime.fetch);
expectType<typeof Buffer>(runtime.Buffer);
expectType<typeof FormData>(runtime.FormData);
