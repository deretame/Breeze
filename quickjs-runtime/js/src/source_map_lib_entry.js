// source_map_lib_entry.js —— @jridgewell/trace-mapping 的打包入口
//
// esbuild 打成 IIFE 单文件（global-name=__sourcemap_lib），输出到
// include/qjsbind/polyfill/source_map_lib.js（入库，经 embed_js.py 嵌入 C++）。
// 暴露：TraceMap（映射结构）/ originalPositionFor（原始位置查询）/
//       eachMapping / encodedMappings / decodedMappings（测试夹具生成用）。
export {
  TraceMap,
  originalPositionFor,
  eachMapping,
  encodedMappings,
  decodedMappings,
} from "@jridgewell/trace-mapping";
