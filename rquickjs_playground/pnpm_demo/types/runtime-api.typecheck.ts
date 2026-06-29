import { getApi, requireApi, requireCryptoLike } from "./runtime-api";

function expectType<T>(_value: T): void {}

const encoder = new TextEncoder();
const key = encoder.encode("key");
const iv = encoder.encode("iv");
const input = encoder.encode("hello");

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
expectType<string>(crypto.createHmac("sha256", key).digest("hex"));
expectType<Buffer>(crypto.randomBytes(16));
expectType<string>(crypto.randomUUID());
expectType<boolean>(crypto.timingSafeEqual(input, input));
expectType<Promise<string>>(crypto.md5(input));
expectType<Promise<string>>(crypto.sha256(input));
expectType<Promise<string>>(crypto.hmacSha256(key, input));
expectType<Promise<Uint8Array>>(crypto.aesEcbPkcs7Encrypt(input, key));
expectType<Promise<Uint8Array>>(
  crypto.aesCbcPkcs7Encrypt(input, key, iv),
);
