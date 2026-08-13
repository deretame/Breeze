// dyn_blob.js —— dyn::call / callSync 的二进制参数 polyfill
//
// 问题：动态调用参数走 JSON 序列化，二进制（ArrayBuffer/TypedArray/DataView/
// Blob）无法表达。本 polyfill 包装全局 call/callSync：二进制参数先
// native_put 进 blob_store，原位替换为占位对象
//   { "$blob": "<uuid>", "$host": "<host_id>" }
// C++ handler 按占位 id 从 BlobStore 取字节（dyn::BlobStore::get / find_any）。
//
// 前置：install_dynamic_call（提供 call/callSync）+
//       install_blob_store（提供 native_put / native_host_id）。
// 生成嵌入头文件：scripts/embed_js.py（见 CMakeLists.txt configure 期生成）。
(function () {
  "use strict";

  const rawCall = globalThis.call;
  const rawCallSync = globalThis.callSync;

  function isBinary(v) {
    // ArrayBuffer.isView 覆盖全部 TypedArray 与 DataView
    return v instanceof ArrayBuffer || ArrayBuffer.isView(v);
  }
  function isBlob(v) {
    return typeof Blob !== "undefined" && v instanceof Blob;
  }
  function placeholder(id) {
    return { $blob: id, $host: native_host_id() };
  }
  // 同步可打包：ArrayBuffer / TypedArray / DataView（Blob 只能异步读取）
  function packSync(v) {
    return isBinary(v) ? placeholder(native_put(v)) : v;
  }

  globalThis.callSync = function (name, ...args) {
    for (const v of args) {
      if (isBlob(v))
        throw new TypeError("callSync: Blob 参数请改用异步 call（Blob 只能异步读取）");
    }
    return rawCallSync(name, ...args.map(packSync));
  };

  globalThis.call = function (name, ...args) {
    return (async () => {
      const packed = [];
      for (const v of args) {
        if (isBlob(v))
          packed.push(placeholder(native_put(await v.arrayBuffer())));
        else
          packed.push(packSync(v));
      }
      return rawCall(name, ...packed);
    })();
  };
})();
