// lexbor_handle.hpp —— BreezeHtml 只读选择集的核心句柄（内部头文件）
//
// 设计：HTML 解析、DOM 树、选择器匹配全部在 lexbor C 树侧完成，QuickJS
// 只持有不可变选择集（Selection class）。选择集创建后节点列表不再变化，
// 因此 length 在创建时写为普通属性，不需要 exotic 方法。
//
// 生命周期：DomRef 引用计数，最后一个选择集 / load 函数释放时销毁文档。
#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <lexbor/dom/dom.h>
#include <lexbor/html/html.h>

namespace qjsbind::cheerio {

// ---------------------------------------------------------------------------
// DomRef：文档生命周期（引用计数）
// ---------------------------------------------------------------------------
struct DomRef {
    lxb_html_document_t* doc = nullptr;
    uint32_t refs = 0;

    void retain() { ++refs; }
    void release()
    {
        if (--refs == 0) {
            if (doc)
                lxb_html_document_destroy(doc);
            delete this;
        }
    }
};

// 选择集 opaque：不可变节点列表
struct Selection {
    DomRef* ref = nullptr;
    std::vector<lxb_dom_node_t*> nodes;

    Selection(DomRef* r, std::vector<lxb_dom_node_t*> n)
        : ref(r), nodes(std::move(n))
    {
        ref->retain();
    }
    ~Selection() { ref->release(); }
};

// ---------------------------------------------------------------------------
// class 注册（per-runtime；JS_SetClassProto 的 proto 由 engine 持有）
// ---------------------------------------------------------------------------
struct SelClass {
    JSClassID id = 0;
    JSValue proto = JS_UNDEFINED; // 方法注册处（borrow，随 runtime 销毁）
};

inline SelClass& sel_class(JSRuntime* rt)
{
    static std::unordered_map<JSRuntime*, SelClass> m;
    return m[rt];
}

inline void register_sel_class(JSRuntime* rt, JSContext* ctx)
{
    // 注意：sel_class 以裸 rt 指针为键，旧 Runtime 销毁后地址可能被新
    // Runtime 复用，因此不做"已注册跳过"判断——每次 install 全新注册
    // （重复 install 罕见；旧对象 finalizer 因 class_id 不匹配跳过释放，
    // 仅泄漏，不崩溃）。
    SelClass& sc = sel_class(rt);
    sc = SelClass{};

    JS_NewClassID(rt, &sc.id);
    JSClassDef def{};
    def.class_name = "BreezeSelection";
    def.finalizer = [](JSRuntime* rt, JSValue val) {
        delete (Selection*)JS_GetOpaque(val, sel_class(rt).id);
    };
    JS_NewClass(rt, sc.id, &def);

    // 原型（方法由 lexbor_api.hpp 注册）。JS_SetClassProto 转移引用，
    // 调用后不得 FreeValue。
    sc.proto = JS_NewObject(ctx);
    JS_SetClassProto(ctx, sc.id, sc.proto);
}

// ---------------------------------------------------------------------------
// 选择集创建 / 解包
// ---------------------------------------------------------------------------
inline JSValue make_sel(JSContext* ctx, DomRef* ref,
                        std::vector<lxb_dom_node_t*> nodes)
{
    JSValue obj = JS_NewObjectClass(ctx, sel_class(JS_GetRuntime(ctx)).id);
    if (JS_IsException(obj))
        return obj;
    auto* s = new Selection(ref, std::move(nodes));
    JS_SetOpaque(obj, s);
    JS_SetPropertyStr(ctx, obj, "length",
                      JS_NewUint32(ctx, (uint32_t)s->nodes.size()));
    return obj;
}

inline Selection* unwrap_sel(JSContext* ctx, JSValueConst v)
{
    if (!JS_IsObject(v))
        return nullptr;
    JSClassID id = sel_class(JS_GetRuntime(ctx)).id;
    if (!id)
        return nullptr;
    return (Selection*)JS_GetOpaque(v, id);
}

// ---------------------------------------------------------------------------
// 文档解析：失败时设置 JS 异常并返回 nullptr（不抛 C++ 异常——调用方是
// 裸 C 函数回调，C++ 异常穿 C 边界是 UB）
// ---------------------------------------------------------------------------
inline DomRef* parse_document(JSContext* ctx, const std::string& html)
{
    lxb_html_document_t* doc = lxb_html_document_create();
    if (!doc) {
        JS_ThrowTypeError(ctx, "lexbor: document create failed");
        return nullptr;
    }
    lxb_status_t st =
        lxb_html_document_parse(doc, (const lxb_char_t*)html.data(), html.size());
    if (st != LXB_STATUS_OK) {
        lxb_html_document_destroy(doc);
        JS_ThrowTypeError(ctx, "lexbor: html parse failed");
        return nullptr;
    }
    return new DomRef{doc, 0};
}

} // namespace qjsbind::cheerio
