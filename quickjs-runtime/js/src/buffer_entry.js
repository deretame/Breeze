// buffer_entry.js —— npm buffer（Node.js Buffer API 官方 JS polyfill）打包入口
//
// esbuild 打成 IIFE 单文件（global-name=__buffer_lib），输出到
// include/qjsbind/polyfill/buffer_lib.js（入库，经 embed_js.py 嵌入 C++）。
// runtime_api.js 挂载 globalThis.Buffer = __buffer_lib.Buffer。
export {
  Buffer,
  SlowBuffer,
  INSPECT_MAX_BYTES,
  kMaxLength,
} from "buffer";
