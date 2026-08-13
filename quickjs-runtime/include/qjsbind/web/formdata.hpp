// qjsbind::web —— FormData（WHATWG FormData，Node/浏览器行为一致）
//
// v1 边界：
//   - 构造仅无参（无 DOM form 元素）
//   - append/set/delete/get/getAll/has/entries/keys/values/forEach/Symbol.iterator
//   - 值：string 或 Blob/File（Blob + filename → File 语义）
//   - multipart 序列化/解析已下沉 fetchcore（include/fetch/formdata.hpp）：
//     本头只剩 JS 绑定（JS ⇄ 条目转换、类注册）与 alias/转发。
#pragma once

#include <fetch/formdata.hpp>

#include <qjsbind/class.hpp>
#include <qjsbind/binary.hpp> // qjs::Context::js_utf8（值语义字符串提取）
#include <qjsbind/context.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/web/blob.hpp>
#include <qjsbind/web/errors.hpp>
#include <qjsbind/web/utf8.hpp>

#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace qjsbind::web {

// ---------- FormData ----------

// FormData 数据模型与 multipart 编解码在 fetchcore（纯 C++，fetch::FormData）；
// 这里用 alias 让绑定层/调用方继续以 FormDataImpl 名义使用，行为不变。
using FormDataImpl = fetch::FormData;
using fetch::encode_multipart;
using fetch::extract_boundary;
using fetch::parse_multipart;

// 判断 JS 值是否为已绑定的 FormDataImpl 实例
inline bool is_form_data_instance(JSContext* ctx, JSValueConst v) {
    if (!JS_IsObject(v))
        return false;
    auto& reg = qjs::registry_of(ctx);
    if (!reg.is_registered<FormDataImpl>())
        return false;
    return reg.id_of<FormDataImpl>(ctx) == JS_GetClassID(v);
}

// JS 值 → FormData 条目（string / Blob / File；filename 参数仅 blob 值生效）
inline FormDataImpl::Entry form_entry_from(JSContext* ctx, JSValueConst value,
                                           const std::optional<std::string>& filename) {
    FormDataImpl::Entry e;
    if (JS_IsString(value)) {
        // Context 成员：js_utf8（UTF-16 → UTF-8，TextEncoder 语义）
        auto s = qjs::Context(ctx).js_utf8(value);
        if (!s)
            throw qjs::js_error(ctx, JS_GetException(ctx));
        e.bytes = std::move(*s);
        return e;
    }
    if (is_file_instance(ctx, value)) {
        const auto* f = qjs::registry_of(ctx).opaque<FileImpl>(ctx, value);
        e.bytes = f->blob.bytes;
        e.type = f->blob.type;
        e.filename = filename ? *filename : f->name;
        e.is_blob = true;
        return e;
    }
    if (is_blob_instance(ctx, value)) {
        const auto* b = qjs::registry_of(ctx).opaque<BlobImpl>(ctx, value);
        e.bytes = b->bytes;
        e.type = b->type;
        e.filename = filename ? *filename : "";
        e.is_blob = true;
        return e;
    }
    throw_type_error(ctx, "FormData: 值必须是字符串或 Blob/File");
    return e;
}

// 条目 → JS 值（get/getAll/迭代：blob 值 → File 对象）
inline qjs::Value form_entry_to_js(JSContext* ctx, const FormDataImpl::Entry& e) {
    if (!e.is_blob)
        return qjs::Value(ctx, JS_NewStringLen(ctx, e.bytes.data(), e.bytes.size()));
    FileImpl f;
    f.blob.bytes = e.bytes;
    f.blob.type = e.type;
    f.name = e.filename;
    f.last_modified = 0;
    return qjs::Value(ctx, qjs::js_convert<FileImpl>::to_js(ctx, f));
}

inline void install_form_data(qjs::Context& ctx) {
    auto cls = qjs::class_<FormDataImpl>(ctx, "FormData")
                   .constructor<>()
                   .method("append",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self, const std::string& name,
                              qjs::Value value, qjs::Opt<std::string> filename) {
                               auto e = form_entry_from(ctx.ctx, value.raw(),
                                                        filename ? std::optional<std::string>(*filename)
                                                                 : std::nullopt);
                               e.name = name;
                               self->list.push_back(std::move(e));
                           })
                   .method("set",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self, const std::string& name,
                              qjs::Value value, qjs::Opt<std::string> filename) {
                               const auto e = form_entry_from(
                                   ctx.ctx, value.raw(),
                                   filename ? std::optional<std::string>(*filename)
                                            : std::nullopt);
                               // 替换首个同名，删除其余；无同名 → append
                               bool replaced = false;
                               for (size_t i = 0; i < self->list.size();) {
                                   if (self->list[i].name == name) {
                                       if (!replaced) {
                                           self->list[i] = e;
                                           self->list[i].name = name; // e 不含 name
                                           replaced = true;
                                           ++i;
                                       } else {
                                           self->list.erase(self->list.begin() +
                                                            static_cast<std::ptrdiff_t>(i));
                                       }
                                   } else {
                                       ++i;
                                   }
                               }
                               if (!replaced) {
                                   self->list.push_back(e);
                                   self->list.back().name = name;
                               }
                           })
                   .method("delete",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self, const std::string& name) {
                               self->erase_entry(name);
                           })
                   .method("has", [](qjs::This<FormDataImpl> self, const std::string& name) {
                       return self->has_entry(name);
                   })
                   .method("get",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self,
                              const std::string& name) -> qjs::Value {
                               for (const auto& e : self->list)
                                   if (e.name == name)
                                       return form_entry_to_js(ctx.ctx, e);
                               return qjs::Value(ctx.ctx, JS_NULL);
                           })
                   .method("getAll",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self,
                              const std::string& name) -> qjs::Value {
                               qjs::Array arr(ctx.ctx, JS_NewArray(ctx.ctx));
                               std::size_t i = 0;
                               for (const auto& e : self->list)
                                   if (e.name == name)
                                       arr.set(i++, form_entry_to_js(ctx.ctx, e));
                               return qjs::Value(std::move(arr));
                           })
                   .method("entries",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self) -> qjs::Value {
                               qjs::Array arr(ctx.ctx, JS_NewArray(ctx.ctx));
                               std::size_t i = 0;
                               for (const auto& e : self->list) {
                                   qjs::Array pair(ctx.ctx, JS_NewArray(ctx.ctx));
                                   pair.set(0, qjs::Value(ctx.ctx, JS_NewString(ctx.ctx, e.name.c_str())));
                                   pair.set(1, form_entry_to_js(ctx.ctx, e));
                                   arr.set(i++, qjs::Value(std::move(pair)));
                               }
                               return qjs::Value(std::move(arr));
                           })
                   .method("keys",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self) -> qjs::Value {
                               qjs::Array arr(ctx.ctx, JS_NewArray(ctx.ctx));
                               std::size_t i = 0;
                               for (const auto& e : self->list)
                                   arr.set(i++, qjs::Value(ctx.ctx, JS_NewString(ctx.ctx, e.name.c_str())));
                               return qjs::Value(std::move(arr));
                           })
                   .method("values",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self) -> qjs::Value {
                               qjs::Array arr(ctx.ctx, JS_NewArray(ctx.ctx));
                               std::size_t i = 0;
                               for (const auto& e : self->list)
                                   arr.set(i++, form_entry_to_js(ctx.ctx, e));
                               return qjs::Value(std::move(arr));
                           })
                   .method("forEach",
                           [](qjs::Ctx ctx, qjs::This<FormDataImpl> self, qjs::Function cb,
                              qjs::Opt<qjs::Value> this_arg) {
                               for (const auto& e : self->list) {
                                   // args 以 RAII Value 持有（借用 raw()），调用后自动释放
                                   qjs::Context cx(ctx.ctx);
                                   qjs::Value val = form_entry_to_js(ctx.ctx, e);
                                   qjs::Value a1 = cx.to_js(e.name);
                                   qjs::Value a2(ctx.ctx, JS_DupValue(
                                       ctx.ctx, this_arg ? this_arg->raw() : JS_UNDEFINED));
                                   JSValue args[3] = {val.raw(), a1.raw(), a2.raw()};
                                   qjs::Value r = cb.call_raw(3, args);
                                   if (r.is_exception())
                                       throw qjs::js_error(ctx.ctx, JS_GetException(ctx.ctx));
                               }
                           });
    ctx.globals().set("FormData", cls.constructor_function());
    ctx.eval(
        "FormData.prototype[Symbol.iterator] = function* () { yield* this.entries(); };"
        "FormData.prototype[Symbol.toStringTag] = 'FormData';");
}

} // namespace qjsbind::web
