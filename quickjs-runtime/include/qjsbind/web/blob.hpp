// qjsbind::web —— Blob / File（WHATWG File API 子集，Node/浏览器行为一致）
//
// v1 边界：
//   - Blob：构造（string/ArrayBuffer/TypedArray/DataView/Blob parts）、size/type、
//     slice()、text()/arrayBuffer()（返回 Promise）
//   - File：Blob 语义 + name/lastModified（独立类，非原型继承）
//   - 无 stream()（v1 无 ReadableStream）
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/promise.hpp>
#include <qjsbind/web/errors.hpp>
#include <qjsbind/web/utf8.hpp>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <optional>
#include <string>

#include <stdexec/execution.hpp>

namespace qjsbind::web {

struct FileImpl; // 前向（append_part 里 is_file_instance 用；定义见后）
inline bool is_blob_instance(JSContext* ctx, JSValueConst v);
inline bool is_file_instance(JSContext* ctx, JSValueConst v);
inline bool try_blob_bytes(JSContext* ctx, JSValueConst v, std::string& out);

// ---------- Blob ----------

struct BlobImpl {
    std::string bytes; // 合并后的原始字节
    std::string type;  // 小写 MIME（保留参数，如 multipart 的 boundary）

    std::size_t size() const { return bytes.size(); }

    // 规范化 type：参照 Node(undici) —— ASCII 小写 + 去首尾空白，保留 MIME
    // 参数（boundary 等）。规范（File API）上 Blob.type 是解析后的 MIME type
    // 序列化，参数必须保留——`new Blob(body, {type: 'multipart/form-data;
    // boundary=x'})` 再经 Response 回传 formData() 依赖它（wpt formdata.any.js
    // case-insensitive）。
    static std::string normalize_type(const std::string& t) {
        std::string out = t;
        std::transform(out.begin(), out.end(), out.begin(),
                       [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        size_t b = 0;
        while (b < out.size() && (out[b] == ' ' || out[b] == '\t'))
            ++b;
        size_t e = out.size();
        while (e > b && (out[e - 1] == ' ' || out[e - 1] == '\t'))
            --e;
        return out.substr(b, e - b);
    }

    // 追加一个 part（string / ArrayBuffer / TypedArray / DataView / Blob / File）
    void append_part(JSContext* ctx, JSValueConst v) {
        if (JS_IsString(v)) {
            // Context 成员：js_utf8（UTF-16 → UTF-8，TextEncoder 语义）
            auto s = qjs::Context(ctx).js_utf8(v);
            if (!s)
                throw qjs::js_error(ctx, JS_GetException(ctx));
            bytes += *s;
            return;
        }
        if (qjs::is_binary(v)) {
            // Context 成员：js_bytes（值拷贝 + detached/resize 守卫）
            auto b = qjs::Context(ctx).js_bytes(v);
            bytes.append(reinterpret_cast<const char*>(b.data()), b.size());
            return;
        }
        if (is_blob_instance(ctx, v)) {
            const auto* b = qjs::registry_of(ctx).opaque<BlobImpl>(ctx, v);
            bytes += b->bytes;
            return;
        }
        if (is_file_instance(ctx, v)) {
            // FileImpl 未完整（类内定义）：经 try_blob_bytes（定义在 FileImpl 之后）延迟
            std::string b;
            if (try_blob_bytes(ctx, v, b))
                bytes += b;
            return;
        }
        throw_type_error(ctx, "Blob: 不支持的 part 类型");
    }

    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> parts, qjs::Opt<qjs::Value> options);
};

struct FileImpl; // 前向（append_part 里 is_file_instance 用；定义见后）
inline bool is_blob_instance(JSContext* ctx, JSValueConst v);
inline bool is_file_instance(JSContext* ctx, JSValueConst v);
inline bool try_blob_bytes(JSContext* ctx, JSValueConst v, std::string& out);

inline bool is_blob_instance(JSContext* ctx, JSValueConst v) {
    if (!JS_IsObject(v))
        return false;
    auto& reg = qjs::registry_of(ctx);
    if (!reg.is_registered<BlobImpl>())
        return false;
    return reg.id_of<BlobImpl>(ctx) == JS_GetClassID(v);
}

// ---------- File（Blob 语义 + name/lastModified）----------

struct FileImpl {
    BlobImpl blob;
    std::string name;
    int64_t last_modified = 0;

    void qjs_init(JSContext* ctx, qjs::Value parts, std::string name,
                  qjs::Opt<qjs::Value> options) {
        qjs::Opt<qjs::Value> parts_opt;
        parts_opt.value.emplace(ctx, JS_DupValue(ctx, parts.raw()));
        blob.qjs_init(ctx, parts_opt, options);
        this->name = name;
        last_modified = -1; // 规范：缺省 = 当前时间（构造时取一次）
        if (options && options->is_object()) {
            qjs::Object obj(*options);
            qjs::Value lm = obj.get("lastModified");
            if (!lm.is_undefined() && !lm.is_null())
                last_modified = static_cast<int64_t>(lm.as<double>());
        }
        if (last_modified < 0)
            // 规范：缺省 = 构造时时间（近似 Date.now()，epoch 毫秒）
            last_modified = static_cast<int64_t>(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch())
                    .count());
    }
};

inline bool is_file_instance(JSContext* ctx, JSValueConst v) {
    if (!JS_IsObject(v))
        return false;
    auto& reg = qjs::registry_of(ctx);
    if (!reg.is_registered<FileImpl>())
        return false;
    return reg.id_of<FileImpl>(ctx) == JS_GetClassID(v);
}

// 从 JS 值提取 Blob 字节（body 提取用；非 Blob/File → 返回 false）
inline bool try_blob_bytes(JSContext* ctx, JSValueConst v, std::string& out) {
    if (is_blob_instance(ctx, v)) {
        out = qjs::registry_of(ctx).opaque<BlobImpl>(ctx, v)->bytes;
        return true;
    }
    if (is_file_instance(ctx, v)) {
        out = qjs::registry_of(ctx).opaque<FileImpl>(ctx, v)->blob.bytes;
        return true;
    }
    return false;
}

// qjs_init 类外定义（is_file_instance 已就绪）
inline void BlobImpl::qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> parts,
                               qjs::Opt<qjs::Value> options) {
    if (parts && !parts->is_undefined() && !parts->is_null()) {
        qjs::Array arr(ctx, JS_DupValue(ctx, parts->raw()));
        for (std::size_t i = 0; i < arr.length(); ++i)
            append_part(ctx, arr.get(i).raw());
    }
    if (options && options->is_object()) {
        qjs::Object obj(*options);
        qjs::Value t = obj.get("type");
        if (!t.is_undefined() && !t.is_null())
            type = normalize_type(t.as<std::string>());
    }
}

// ---------- 安装 ----------

inline void install_blob(qjs::Context& ctx) {
    auto cls = qjs::class_<BlobImpl>(ctx, "Blob")
                   .constructor<qjs::Opt<qjs::Value>, qjs::Opt<qjs::Value>>()
                   .getter("size", [](qjs::This<BlobImpl> self) { return self->size(); })
                   .getter("type", [](qjs::This<BlobImpl> self) { return self->type; })
                   .method("slice",
                           [](qjs::Ctx ctx, qjs::This<BlobImpl> self, qjs::Opt<int> start,
                              qjs::Opt<int> end, qjs::Opt<std::string> content_type)
                               -> qjs::Value {
                               // 规范：start/end 为绝对索引（负值按 size+v 归一化），越界截断
                               const int64_t size = static_cast<int64_t>(self->size());
                               const int64_t s = start ? (*start < 0 ? size + *start : *start) : 0;
                               const int64_t e =
                                   end ? (*end < 0 ? size + *end : *end) : size;
                               const int64_t s_clamped = std::clamp<int64_t>(s, 0, size);
                               const int64_t e_clamped = std::clamp<int64_t>(e, 0, size);
                               BlobImpl out;
                               if (s_clamped < e_clamped)
                                   out.bytes = self->bytes.substr(
                                       static_cast<std::size_t>(s_clamped),
                                       static_cast<std::size_t>(e_clamped - s_clamped));
                               out.type = content_type ? BlobImpl::normalize_type(*content_type)
                                                       : self->type;
                               return qjs::Value(ctx.ctx, qjs::js_convert<BlobImpl>::to_js(ctx.ctx, out));
                           })
                   .method("text",
                           [](qjs::Ctx ctx, qjs::This<BlobImpl> self) -> qjs::Value {
                               // UTF-8 decode（去 BOM，TextDecoder 默认语义）
                               std::string s = self->bytes;
                               if (s.size() >= 3 && static_cast<uint8_t>(s[0]) == 0xEF &&
                                   static_cast<uint8_t>(s[1]) == 0xBB &&
                                   static_cast<uint8_t>(s[2]) == 0xBF)
                                   s.erase(0, 3);
                               return qjs::Value(ctx.ctx, qjs::promise_from_sender(
                                   ctx.ctx, stdexec::just(qjs::Value(ctx.ctx, JS_NewStringLen(
                                                                             ctx.ctx, s.data(),
                                                                             s.size())))));
                           })
                   .method("arrayBuffer",
                           [](qjs::Ctx ctx, qjs::This<BlobImpl> self) -> qjs::Value {
                               return qjs::Value(ctx.ctx, qjs::promise_from_sender(
                                   ctx.ctx,
                                   stdexec::just(qjs::Value(
                                       ctx.ctx,
                                       JS_NewArrayBufferCopy(
                                           ctx.ctx,
                                           reinterpret_cast<const uint8_t*>(self->bytes.data()),
                                           self->bytes.size())))));
                           });
    ctx.globals().set("Blob", cls.constructor_function());

    auto fcls = qjs::class_<FileImpl>(ctx, "File")
                    .constructor<qjs::Value, std::string, qjs::Opt<qjs::Value>>()
                    .getter("size", [](qjs::This<FileImpl> self) { return self->blob.size(); })
                    .getter("type", [](qjs::This<FileImpl> self) { return self->blob.type; })
                    .getter("name", [](qjs::This<FileImpl> self) { return self->name; })
                    .getter("lastModified",
                            [](qjs::This<FileImpl> self) { return self->last_modified; })
                    .method("slice",
                            [](qjs::Ctx ctx, qjs::This<FileImpl> self, qjs::Opt<int> start,
                               qjs::Opt<int> end, qjs::Opt<std::string> content_type)
                                -> qjs::Value {
                                // 复用 BlobImpl 的 slice 逻辑（含 type/字节）
                                const int64_t size = static_cast<int64_t>(self->blob.size());
                                const int64_t s = start ? (*start < 0 ? size + *start : *start) : 0;
                                const int64_t e =
                                    end ? (*end < 0 ? size + *end : *end) : size;
                                const int64_t s_clamped = std::clamp<int64_t>(s, 0, size);
                                const int64_t e_clamped = std::clamp<int64_t>(e, 0, size);
                                BlobImpl out;
                                if (s_clamped < e_clamped)
                                    out.bytes = self->blob.bytes.substr(
                                        static_cast<std::size_t>(s_clamped),
                                        static_cast<std::size_t>(e_clamped - s_clamped));
                                out.type = content_type
                                               ? BlobImpl::normalize_type(*content_type)
                                               : self->blob.type;
                                return qjs::Value(ctx.ctx,
                                                  qjs::js_convert<BlobImpl>::to_js(ctx.ctx, out));
                            })
                    .method("text",
                            [](qjs::Ctx ctx, qjs::This<FileImpl> self) -> qjs::Value {
                                std::string s = self->blob.bytes;
                                if (s.size() >= 3 && static_cast<uint8_t>(s[0]) == 0xEF &&
                                    static_cast<uint8_t>(s[1]) == 0xBB &&
                                    static_cast<uint8_t>(s[2]) == 0xBF)
                                    s.erase(0, 3);
                                return qjs::Value(ctx.ctx, qjs::promise_from_sender(
                                    ctx.ctx, stdexec::just(qjs::Value(ctx.ctx, JS_NewStringLen(
                                                                              ctx.ctx, s.data(),
                                                                              s.size())))));
                            })
                    .method("arrayBuffer",
                            [](qjs::Ctx ctx, qjs::This<FileImpl> self) -> qjs::Value {
                                return qjs::Value(ctx.ctx, qjs::promise_from_sender(
                                    ctx.ctx,
                                    stdexec::just(qjs::Value(
                                        ctx.ctx,
                                        JS_NewArrayBufferCopy(
                                            ctx.ctx,
                                            reinterpret_cast<const uint8_t*>(
                                                self->blob.bytes.data()),
                                            self->blob.bytes.size())))));
                            });
    ctx.globals().set("File", fcls.constructor_function());
}

} // namespace qjsbind::web
