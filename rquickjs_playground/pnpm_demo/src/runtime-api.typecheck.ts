import {
  getApi,
  requireApi,
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
