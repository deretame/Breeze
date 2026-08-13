// dyn_blob.hpp —— dyn blob polyfill 安装入口
//
// 把 polyfill/dyn_blob.js（经 scripts/embed_js.py 嵌入为字符串）eval 进 context：
// 包装全局 call/callSync，二进制参数（ArrayBuffer/TypedArray/DataView/Blob）
// 先 native_put 进 blob_store，原位替换为占位对象
//   { "$blob": "<uuid>", "$host": "<host_id>" }
// C++ handler 按占位 id 从 dyn::BlobStore 取字节（get(host,id) 或 find_any(id)）。
//
// 前置：install_dynamic_call + install_blob_store。
// 幂等：重复安装只是再包一层包装，无害但不必要。
#pragma once

#include <quickjs.h>

#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>

#include <qjsbind/polyfill/dyn_blob_embedded.hpp> // 生成物（configure 期生成，不入库）

namespace qjs {
namespace dyn {

inline void install_dyn_blob_polyfill(qjs::Context& ctx)
{
    Value v = ctx.eval(polyfill::dyn_blob_js, "<dyn_blob_polyfill>");
    if (v.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));
}

} // namespace dyn
} // namespace qjs
