// cheerio.hpp —— BreezeHtml 安装入口（qjsbind::cheerio）
//
// install_cheerio(ctx) 注入全局 `BreezeHtml`：lexbor 原生 HTML 解析 +
// cheerio 兼容的只读选择集 API。
//
//   const $ = BreezeHtml.load(html);   // $ 可调用
//   $('selector') / $(selection)       // -> BreezeSelection
//   选择集方法（只读）：
//     find/first/last/eq/closest/parent/children/siblings/next/prev/
//     filter/has/slice/index/is、attr/text/html/val、toArray/each/map
//
// 本层不意图完整替代 cheerio：无 DOM 修改能力（append/remove/attr 写等）。
// 需要完整功能时插件仍可自行引入 cheerio。
#pragma once

#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>

#include <qjsbind/cheerio/lexbor_api.hpp>

namespace qjsbind::cheerio {

// 安装全局 `BreezeHtml`。返回值恒为 true（保留 bool 以兼容既有调用点）。
inline bool install_cheerio(qjs::Context& ctx)
{
    JSContext* jctx = ctx.raw();
    register_sel_class(JS_GetRuntime(jctx), jctx);
    register_sel_methods(jctx);

    qjs::Value api(jctx, JS_NewObject(jctx));
    // JS_SetPropertyStr 接管 value 引用，无需 FreeValue
    JS_SetPropertyStr(jctx, api.raw(), "load",
                      JS_NewCFunction(jctx, fn_load, "load", 1));
    ctx.globals().set("BreezeHtml", std::move(api));
    return true;
}

} // namespace qjsbind::cheerio
