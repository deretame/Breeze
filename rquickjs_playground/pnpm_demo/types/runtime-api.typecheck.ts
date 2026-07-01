import { getApi, requireApi, requireCryptoLike } from "./runtime-api";

function expectType<T>(_value: T): void {}

const base64 = requireApi("base64");
expectType<string>(base64.encode(new Uint8Array([1, 2, 3])));
expectType<Uint8Array>(base64.decode("AQID"));
expectType<string>(bytesToBase64(new Uint8Array([1, 2, 3])));
expectType<Uint8Array>(bytesFromBase64("AQID"));

const maybeNative = getApi("native");
expectType<Promise<number> | undefined>(maybeNative?.put(new Uint8Array([1])));

const native = requireApi("native");
expectType<Promise<Uint8Array>>(
  native.chain(["invert"], new Uint8Array([1, 2, 3])),
);

const bridge = requireApi("bridge");
expectType<Promise<unknown>>(bridge.call("math.add", 1, 2));

const crypto = requireCryptoLike();
expectType<string>(crypto.createHash("sha1").digest("hex"));
expectType<string>(crypto.createHash("sha-256").digest("hex"));
expectType<string>(crypto.createHash("sha512").digest("hex"));
expectType<string>(crypto.createHmac("sha256", "key").digest("hex"));
expectType<Buffer>(crypto.randomBytes(16));
expectType<string>(crypto.randomUUID());
expectType<boolean>(crypto.timingSafeEqual("a", "b"));
expectType<Promise<string>>(crypto.md5("hello"));
expectType<Promise<string>>(crypto.sha256("hello"));
expectType<Promise<string>>(crypto.hmacSha256("key", "hello"));
expectType<Promise<Uint8Array>>(crypto.aesEcbPkcs7Encrypt("hello", "key"));
expectType<Promise<Uint8Array>>(
  crypto.aesCbcPkcs7Encrypt("hello", "key", "iv"),
);
