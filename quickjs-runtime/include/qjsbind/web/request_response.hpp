// qjsbind::web —— Request / Response（fetch 规范 v1 边界）
//
// body 支持：string / ArrayBuffer / TypedArray / URLSearchParams / undefined；
// 消费：text() / json() / arrayBuffer() / formData()；不做 blob() / ReadableStream。
// Request 相对 URL 以 globalThis.location.href 为 base（无 location 时仅绝对 URL）。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/std_exec.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/rt_value.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/web/abort.hpp>

#include <fmt/format.h> // fmt::format（错误消息拼接）
#include <qjsbind/web/errors.hpp>
#include <qjsbind/web/headers.hpp>
#include <qjsbind/web/stream.hpp>
#include <qjsbind/web/url.hpp>
#include <fetch/url_check.hpp>

#include <stdexec/execution.hpp>

#include <optional>
#include <cstdlib>
#include <string>
#include <utility>
#include <vector>

namespace qjsbind::web {

// ---------- body 提取 / 消费 ----------

struct ExtractedBody {
    std::shared_ptr<ReadableStreamImpl> stream; // null = 无 body（统一内部 body 模型）
    std::string content_type;                   // 可能为空
    bool has = false;
};

// io_context 取用（构造路径经 JSContext；绑定层保证 ctx 存活）
inline boost::asio::io_context& io_of(JSContext* ctx) { return qjs::runtime_of(ctx).io(); }

// 字节 → MemorySource 流（字节 body 统一流化的唯一出口）
inline std::shared_ptr<ReadableStreamImpl> bytes_to_stream(JSContext* ctx, std::string bytes)
{
    auto src = std::make_shared<MemorySource>(std::move(bytes));
    auto st = make_stream(io_of(ctx), std::move(src));
    return st;
}

inline bool is_url_params_instance(JSContext* ctx, JSValueConst v) {
    if (!JS_IsObject(v))
        return false;
    auto& reg = qjs::registry_of(ctx);
    if (!reg.is_registered<UrlSearchParamsImpl>())
        return false;
    return reg.id_of<UrlSearchParamsImpl>(ctx) == JS_GetClassID(v);
}

// JS body 参数 → 字节（undefined/null → has=false；其他类型 → TypeError）
inline ExtractedBody extract_body(JSContext* ctx, JSValueConst body) {
    ExtractedBody out;
    if (JS_IsUndefined(body) || JS_IsNull(body))
        return out;
    out.has = true;
    if (JS_IsString(body)) {
        // Context 成员：js_utf8（UTF-16 → UTF-8，TextEncoder 语义）
        auto s = qjs::Context(ctx).js_utf8(body);
        if (!s)
            throw qjs::js_error(ctx, JS_GetException(ctx));
        out.stream = bytes_to_stream(ctx, std::move(*s));
        // 规范：string body 默认 Content-Type
        out.content_type = "text/plain;charset=UTF-8";
        return out;
    }
    if (is_url_params_instance(ctx, body)) {
        const auto* p = qjs::registry_of(ctx).opaque<UrlSearchParamsImpl>(ctx, body);
        out.stream = bytes_to_stream(ctx, p->to_query());
        out.content_type = "application/x-www-form-urlencoded;charset=UTF-8";
        return out;
    }
    if (qjs::is_binary(body)) {
        out.stream = bytes_to_stream(ctx, js_bytes_from(ctx, body));
        return out;
    }
    {
        std::string blob_bytes;
        if (try_blob_bytes(ctx, body, blob_bytes)) {
            out.stream = bytes_to_stream(ctx, std::move(blob_bytes));
            // Blob/File：Content-Type 取自 type（规范：body 是 Blob 时自动设置）
            if (is_blob_instance(ctx, body))
                out.content_type = qjs::registry_of(ctx).opaque<BlobImpl>(ctx, body)->type;
            else if (is_file_instance(ctx, body))
                out.content_type = qjs::registry_of(ctx).opaque<FileImpl>(ctx, body)->blob.type;
            return out;
        }
    }
    if (is_form_data_instance(ctx, body)) {
        // FormData → multipart/form-data（随机 boundary；规范语义）
        const auto* fd = qjs::registry_of(ctx).opaque<FormDataImpl>(ctx, body);
        static const char* hexd = "0123456789abcdef";
        std::string boundary = "----qjsformdata";
        for (int i = 0; i < 16; ++i)
            boundary.push_back(hexd[(rand() >> 4) & 15]);
        out.stream = bytes_to_stream(ctx, encode_multipart(*fd, boundary));
        out.content_type = "multipart/form-data; boundary=" + boundary;
        return out;
    }
    // 其他值（对象/数字/布尔等）：ToString 后按字符串处理（fetch 规范 body 提取；wpt request-init-002）
    {
        // Context 成员：js_utf8（ToString 语义，含非字符串参数；失败 → TypeError）
        auto s = qjs::Context(ctx).js_utf8(body);
        if (!s)
            throw qjs::js_error(ctx, JS_GetException(ctx)); // Symbol 等 → TypeError
        out.stream = bytes_to_stream(ctx, std::move(*s));
        out.content_type = "text/plain;charset=UTF-8";
        return out;
    }
}

// 消费字节：text / json / arrayBuffer
inline qjs::Value consume_text(JSContext* ctx, const std::string& bytes) {
    // 规范：text() 走 UTF-8 decode（剥离 BOM，与 TextDecoder 默认一致；wpt 测试权威）
    std::string s = bytes;
    if (s.size() >= 3 && static_cast<uint8_t>(s[0]) == 0xEF &&
        static_cast<uint8_t>(s[1]) == 0xBB && static_cast<uint8_t>(s[2]) == 0xBF)
        s.erase(0, 3);
    return qjs::Value(ctx, JS_NewStringLen(ctx, s.data(), s.size()));
}
inline qjs::Value consume_json(JSContext* ctx, const std::string& bytes) {
    // 规范：JSON 解析前先做 UTF-8 decode（去 BOM）——wpt json.any.js
    std::string s = bytes;
    if (s.size() >= 3 && static_cast<uint8_t>(s[0]) == 0xEF &&
        static_cast<uint8_t>(s[1]) == 0xBB && static_cast<uint8_t>(s[2]) == 0xBF)
        s.erase(0, 3);
    JSValue v = JS_ParseJSON(ctx, s.data(), s.size(), "<json>");
    if (JS_IsException(v))
        throw qjs::js_error(ctx, JS_GetException(ctx));
    return qjs::Value(ctx, v);
}
inline qjs::Value consume_array_buffer(JSContext* ctx, const std::string& bytes) {
    // Context 成员：new_array_buffer（JS_NewArrayBufferCopy 包装，拷贝）
    return qjs::Context(ctx).new_array_buffer(
        reinterpret_cast<const std::byte*>(bytes.data()), bytes.size());
}
// 规范：bytes() 返回 Uint8Array（Body mixin；wpt request/response-consume 的
// "Consume ... body as bytes"：instanceof Uint8Array + buffer 内容一致）
inline qjs::Value consume_bytes(JSContext* ctx, const std::string& bytes) {
    // Context 成员：new_uint8_array（JS_NewUint8ArrayCopy 包装，拷贝）
    return qjs::Context(ctx).new_uint8_array(
        reinterpret_cast<const std::byte*>(bytes.data()), bytes.size());
}
// 规范：blob() 返回的 Blob.type = 响应 Content-Type（小写；保留参数——
// 浏览器实测含 boundary，`new Response(blob).formData()` 依赖它）
inline qjs::Value consume_blob(JSContext* ctx, const std::string& bytes, const std::string& type) {
    // 与 Blob 构造同一规范化（小写 + trim，保留 MIME 参数如 boundary）
    BlobImpl b;
    b.bytes = bytes;
    b.type = BlobImpl::normalize_type(type);
    return qjs::Value(ctx, qjs::js_convert<BlobImpl>::to_js(ctx, b));
}

// 消费入口（置 bodyUsed；重复消费 → TypeError）
// v2 流式：内部 body 为"字节（构造/复制）或流（fetch 响应）"——有流则拉模型
// 读干（pull 循环），读干期间可被 abort（read() 以 stopped 完成 → 整个消费 task
// 以 stopped 结束 → reject AbortError）；读 body 中途失败 → reject TypeError
// （fetch 已 resolve，见 docs/fetch_streaming_design.md §3.3）。
template <class Self, class Fn>
std_exec::task<qjs::Value> consume_impl(JSContext* ctx, Self& self, const char* what, Fn&& fn) {
    // 前置检查（设计文档 §4.3）：locked → TypeError；disturbed → TypeError
    if (self.body_stream && self.body_stream->locked())
        throw_type_error(ctx, fmt::format("{}: body 已被 reader 锁定", what));
    if (self.body_stream && self.body_stream->disturbed)
        throw_type_error(ctx, fmt::format("{}: body 已被消费", what));
    // 规范：body 为 null（无 body）时消费直接返回空结果，不置 bodyUsed
    //（wpt request/response-consume-empty：text/json/blob/arrayBuffer 后
    // assert_false(bodyUsed)；有 body 的消费才置位）
    if (!self.body_stream)
        co_return fn(ctx, "");
    // 挂起期间持有 stream 副本：JS 对象（Response/Request）可在消费挂起时被 GC
    //（规范允许），流状态机的生命周期由消费协程保证。
    std::shared_ptr<ReadableStreamImpl> stream = self.body_stream;
    std::string all;
    try {
        for (;;) {
            auto block = co_await stream->read();
            if (!block)
                break;
            all += *block;
        }
    } catch (const qjs::js_error&) {
        throw; // JS 异常原样透传
    } catch (const std::exception& e) {
        throw_type_error(ctx, fmt::format("fetch failed: {}", e.what()));
    }
    co_return fn(ctx, all);
}

// 读取当前 content-type：优先从 headers JS 对象（用户 set/delete 后同步）；
// 未访问过 headers 时退回内部 list（headers getter 是独立拷贝，见 install 注释）
template <class T>
std::string content_type_of(JSContext* ctx, const T& self) {
    if (!self.headers_js.empty()) {
        auto* h = qjs::registry_of(ctx).opaque<HeadersImpl>(ctx, self.headers_js.raw());
        if (h) {
            auto v = h->get(ctx, "content-type");
            if (v)
                return *v;
            return "";
        }
    }
    return self.headers.get(ctx, "content-type").value_or("");
}

// Content-Type → MIME essence（';' 前部分 trim + ASCII 小写；
// formData() 的 multipart/urlencoded 分支判断用）
inline std::string mime_essence(const std::string& ct) {
    const size_t semi = ct.find(';');
    std::string s = ct.substr(0, semi);
    size_t b = 0;
    while (b < s.size() && (s[b] == ' ' || s[b] == '\t'))
        ++b;
    size_t e = s.size();
    while (e > b && (s[e - 1] == ' ' || s[e - 1] == '\t'))
        --e;
    s = s.substr(b, e - b);
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return s;
}

// 解析 URL 的端口并做 blocked 检查（定义见 RequestImpl 之后；类内方法先声明）
inline void check_url_ports(JSContext* ctx, const std::string& url);

// 前向声明（RequestImpl::qjs_init 的 init.body 需检查 Response 实例）
struct ResponseImpl;

// init.body 是 Request/Response 实例时复制其内部 body（bodyUsed → TypeError）。
// 定义见 ResponseImpl 之后（需完整类型）；RequestImpl::qjs_init 里调用。
inline bool try_extract_init_body(JSContext* ctx, JSValueConst v, ExtractedBody& out,
                                  void** consumed_out = nullptr);

// ---------- Request ----------

struct RequestImpl {
    std::string method = "GET";
    std::string url;             // 绝对 URL
    HeadersImpl headers;         // guard=request
    std::shared_ptr<ReadableStreamImpl> body_stream; // 统一内部 body（null = 无 body）
    qjs::RtValue body_js;                            // body getter SameObject 缓存
    std::string redirect = "follow";
    std::string integrity;            // SRI 元数据（空 = 不校验）
    AbortSignalImpl* signal = nullptr; // 借用（signal JS 对象持有）
    qjs::RtValue signal_js;            // 持有 signal JS 引用（fetch 取消用）
    qjs::RtValue headers_js;           // 缓存的 Headers JS 对象（同一对象语义）

    RequestImpl() = default;
    // 拷贝：signal 不复制（fetch 规范：Request clone 不继承 signal）
    RequestImpl(const RequestImpl& o)
        : method(o.method), url(o.url), headers(o.headers), body_stream(o.body_stream),
          redirect(o.redirect),
          integrity(o.integrity), signal(nullptr) {}
    RequestImpl& operator=(const RequestImpl& o) {
        method = o.method;
        url = o.url;
        headers = o.headers;
        body_stream = o.body_stream;
        redirect = o.redirect;
        integrity = o.integrity;
        signal = nullptr;
        signal_js = qjs::RtValue(); // 释放旧引用（若有）
        headers_js = qjs::RtValue();
        return *this;
    }

    // 从缓存的 Headers JS 对象同步回数据（用户可能通过 r.headers 修改过）
    void sync_headers(JSContext* ctx) {
        if (!headers_js.empty()) {
            const auto* h = qjs::registry_of(ctx).opaque<HeadersImpl>(ctx, headers_js.dup(ctx));
            if (h)
                headers = *h;
        }
    }
    // Headers getter 缓存实现（同一对象语义，wpt 要求）
    qjs::Value headers_value(qjs::Ctx ctx, qjs::This<RequestImpl> self) {
        if (self->headers_js.empty())
            self->headers_js = qjs::RtValue(JS_GetRuntime(ctx.ctx),
                                            qjs::js_convert<HeadersImpl>::to_js(ctx.ctx, self->headers));
        return qjs::Value(ctx.ctx, self->headers_js.dup(ctx.ctx));
    }

    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> input, qjs::Opt<qjs::Value> init) {
        // 1. input：Request 实例 → 拷贝；string/URL → 解析绝对 URL
        void* body_consumed = nullptr; // 构造成功末尾置 disturbed 的源（Request/Response）
        if (input && !input->is_undefined() && !input->is_null()) {
            if (JS_IsObject(input->raw())) {
                auto& reg = qjs::registry_of(ctx);
                if (reg.is_registered<RequestImpl>() &&
                    reg.id_of<RequestImpl>(ctx) == JS_GetClassID(input->raw())) {
                    auto* src = reg.opaque<RequestImpl>(ctx, input->raw());
                    *this = *src;
                    // input 的 body：init.body 存在时由 init 覆盖（不 tee，但 input
                    // 仍在构造成功时标记消费——wpt "became disturbed even if body is
                    // not used"）；否则 tee 共享 + 检查 disturbed/locked
                    const bool init_has_body =
                        init && init->is_object() &&
                        !qjs::Context(ctx).get_property(init->raw(), "body").is_undefined();
                    if (init_has_body) {
                        if (src->body_stream)
                            body_consumed = src->body_stream.get();
                    } else {
                        ExtractedBody b;
                        if (try_extract_init_body(ctx, input->raw(), b, &body_consumed))
                            body_stream = std::move(b.stream);
                    }
                } else {
                    // URL 实例或字符串
                    url = url_string_of(ctx, input->raw());
                }
            } else if (input->is_string()) {
                // 走 url_string_of：UTF-16 单元转 UTF-8（孤立代理 → U+FFFD）
                url = url_string_of(ctx, input->raw());
            } else {
                throw_type_error(ctx, "Request: input 类型不支持");
            }
        } else {
            throw_type_error(ctx, "Request: 缺少 input");
        }
        check_url_ports(ctx, url); // fetch 规范 #port-blocking（核心清单下沉 fetch/url_check.hpp）
        headers.set_guard(HeadersImpl::Guard::Request);
        if (signal)
            signal = nullptr; // 拷贝 input 时不继承 signal（规范：signal 不复制）

        // 2. init
        if (init && init->is_object()) {
            qjs::Object obj(*init);
            // init 本身是 Request/Response 实例（new Request(url, req)）：复制其内部 body
            ExtractedBody init_body;
            bool init_body_extracted = false;
            if (try_extract_init_body(ctx, init->raw(), init_body, &body_consumed)) {
                body_stream = std::move(init_body.stream);
                init_body_extracted = true;
                if (!init_body.content_type.empty())
                    headers.append(ctx, "Content-Type", init_body.content_type);
            }
            qjs::Value method = obj.get("method");
            if (!method.is_undefined())
                this->method = normalize_method(ctx, method.as<std::string>());
            // fetch 规范（2024）：duplex 选项——仅 'half' 合法（半双工传输）；
            // 用户级 ReadableStream body 必须显式 duplex:'half'（v2 不支持用户流，
            // 但 duplex 校验本身照做）
            {
                qjs::Value duplex = obj.get("duplex");
                if (!duplex.is_undefined() && !duplex.is_null()) {
                    const std::string d = duplex.as<std::string>();
                    if (d != "half")
                        throw_type_error(ctx, "Request: duplex 必须为 'half'");
                }
            }
            qjs::Value hdrs = obj.get("headers");
            if (!hdrs.is_undefined() && !hdrs.is_null()) {
                headers = headers_from(ctx, hdrs.raw());
                headers.set_guard(HeadersImpl::Guard::Request);
            }
            qjs::Value body = obj.get("body");
            if (!body.is_undefined() && !body.is_null() && !init_body_extracted) {
                ExtractedBody b;
                // init 是 Request/Response 实例时复制其内部 body（disturbed → TypeError）
                if (!try_extract_init_body(ctx, body.raw(), b, &body_consumed))
                    b = extract_body(ctx, body.raw());
                body_stream = std::move(b.stream);
                if (!b.content_type.empty() && !headers.has(ctx, "Content-Type"))
                    headers.append(ctx, "Content-Type", b.content_type);
            }
            qjs::Value redirect = obj.get("redirect");
            if (!redirect.is_undefined())
                this->redirect = normalize_redirect(ctx, redirect.as<std::string>());
            qjs::Value integrity = obj.get("integrity");
            if (!integrity.is_undefined() && !integrity.is_null()) {
                // SRI 元数据解析（fetch 规范 §4.7）：空格分隔项，每项 algo-base64；
                // 算法必须 sha256/sha384/sha512，digest 为 base64（标准或 url-safe，可去 padding）
                const std::string meta = integrity.as<std::string>();
                auto check_item = [](const std::string& item) -> bool {
                    const size_t dash = item.find('-');
                    if (dash == std::string::npos || dash + 1 >= item.size())
                        return false;
                    const std::string algo = item.substr(0, dash);
                    if (algo != "sha256" && algo != "sha384" && algo != "sha512")
                        return false;
                    for (size_t i = dash + 1; i < item.size(); ++i) {
                        const char c = item[i];
                        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '+' || c == '/' ||
                              c == '-' || c == '_' || c == '='))
                            return false;
                    }
                    return true;
                };
                bool ok = true;
                std::string cur;
                for (const char c : meta + " ") {
                    if (c == ' ') {
                        if (!cur.empty() && !check_item(cur)) {
                            ok = false;
                            break;
                        }
                        cur.clear();
                    } else {
                        cur.push_back(c);
                    }
                }
                if (!ok)
                    throw_type_error(ctx, "Request: integrity 元数据非法");
                this->integrity = meta;
            }
            qjs::Value signal_v = obj.get("signal");
            if (!signal_v.is_undefined() && !signal_v.is_null()) {
                auto& reg = qjs::registry_of(ctx);
                if (reg.is_registered<AbortSignalImpl>() &&
                    reg.id_of<AbortSignalImpl>(ctx) == JS_GetClassID(signal_v.raw())) {
                    signal = reg.opaque<AbortSignalImpl>(ctx, signal_v.raw());
                    signal_js = qjs::RtValue(JS_GetRuntime(ctx), JS_DupValue(ctx, signal_v.raw()));
                } else {
                    throw_type_error(ctx, "Request: signal 类型不支持");
                }
            }
        }
        // GET/HEAD 带 body → TypeError（fetch 规范）
        if (body_stream && (method == "GET" || method == "HEAD"))
            throw_type_error(ctx, "Request: GET/HEAD 不能带 body");
        // 构造成功末尾：提取过的源 body 标记 disturbed（spec：new Request(input)
        // 后 input.bodyUsed === true；构造失败（如上检查）不置位——wpt request-disturbed）
        if (body_consumed)
            static_cast<ReadableStreamImpl*>(body_consumed)->disturbed = true;
    }

    static std::string normalize_method(JSContext* ctx, std::string m) {
        for (auto& c : m)
            c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
        if (m.empty())
            throw_type_error(ctx, "Request: method 为空");
        // fetch 规范：forbidden method（CONNECT/TRACE/TRACK）→ TypeError
        if (m == "CONNECT" || m == "TRACE" || m == "TRACK")
            throw_type_error(ctx, "Request: method 非法（forbidden method）");
        return m;
    }
    static std::string normalize_redirect(JSContext* ctx, const std::string& r) {
        if (r != "follow" && r != "error" && r != "manual")
            throw_type_error(ctx, "Request: redirect 非法");
        return r;
    }
    // GC 标记：signal 对象引用
    void qjs_mark(JSRuntime* rt, JS_MarkFunc* mark_func) {
        signal_js.mark(rt, mark_func);
        headers_js.mark(rt, mark_func);
        body_js.mark(rt, mark_func);
    }

    static std::string url_string_of(JSContext* ctx, JSValueConst v);
    static std::string resolve_url(JSContext* ctx, const std::string& str);
};

// fetch 规范 #port-blocking：Request URL 的端口在列表内 → 构造时 TypeError。
// 清单与检查逻辑已下沉到核心层（fetch/url_check.hpp），此处仅做异常适配。
inline void check_url_ports(JSContext* ctx, const std::string& url) {
    try {
        fetch::check_url_ports(url);
    } catch (const fetch::Error& e) {
        throw_type_error(ctx, fmt::format("Request: {}", e.what()));
    }
}

// URL 实例 → 序列化；相对字符串 → location.href 为 base 解析
inline std::string RequestImpl::url_string_of(JSContext* ctx, JSValueConst v) {
    auto& reg = qjs::registry_of(ctx);
    if (reg.is_registered<UrlImpl>() && reg.id_of<UrlImpl>(ctx) == JS_GetClassID(v))
        return reg.opaque<UrlImpl>(ctx, v)->href();
    if (JS_IsString(v)) {
        // Context 成员：js_utf8（UTF-16 → UTF-8，孤立代理 → U+FFFD，与 WHATWG URL 编码一致）
        auto s = qjs::Context(ctx).js_utf8(v);
        return resolve_url(ctx, s ? std::move(*s) : std::string{});
    }
    // 其他对象（含 wpt 的 URL 全局——URL 构造器函数）：USVString 转换后按 URL 解析
    //（fetch spec：非 string/Request/URL 对象 → ToString；wpt request-disturbed 依赖）
    {
        auto opt = qjs::Context(ctx).js_utf8(v); // ToString 语义；失败 → TypeError
        if (!opt)
            throw qjs::js_error(ctx, JS_GetException(ctx)); // Symbol 等 → TypeError
        std::string s = std::move(*opt);
        // WHATWG 宽松解析：URL 构造器函数 ToString（"function URL() {...}"）含
        // 空格/花括号/方括号等 path 特殊字符——boost::urls 严格拒绝，先做路径编码
        //（仅保留 RFC 3986 unreserved，其余 %XX；与 WHATWG 的 path 编码一致）
        static const char* kValid =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
        static const char* kHex = "0123456789ABCDEF";
        std::string enc;
        enc.reserve(s.size());
        for (const unsigned char c : s) {
            if (strchr(kValid, c) != nullptr) {
                enc.push_back(static_cast<char>(c));
            } else {
                enc.push_back('%');
                enc.push_back(kHex[c >> 4]);
                enc.push_back(kHex[c & 0xF]);
            }
        }
        return resolve_url(ctx, std::move(enc));
    }
}

inline std::string RequestImpl::resolve_url(JSContext* ctx, const std::string& str) {
    // WHATWG basic URL parser：先删除 ASCII tab/newline（wpt 用 URL 构造器函数
    // 作 input 时 ToString 含换行——Chrome 按规范删除后解析）
    std::string s;
    s.reserve(str.size());
    for (const char c : str)
        if (c != '\t' && c != '\n' && c != '\r')
            s.push_back(c);
    // base = globalThis.location.href（wpt 运行器等环境注入）
    // g/loc/href 均为 RAII Value，析构自动释放
    std::string base;
    qjs::Context cx(ctx);
    qjs::Value g = cx.global_object();
    qjs::Value loc = cx.get_property(g.raw(), "location");
    if (loc.is_object()) {
        qjs::Value href = cx.get_property(loc.raw(), "href");
        if (href.is_string()) {
            // Context 成员：js_string（值语义提取，嵌入 '\0' 保留）
            if (auto s = cx.js_string(href.raw()))
                base = std::move(*s);
        }
    }
    return UrlImpl::parse(ctx, s, base).href();
}

inline void install_request(qjs::Context& ctx) {
    auto cls = qjs::class_<RequestImpl>(ctx, "Request")
                   .constructor<qjs::Opt<qjs::Value>, qjs::Opt<qjs::Value>>()
                   .getter("method", [](qjs::This<RequestImpl> self) { return self->method; })
                   .getter("url", [](qjs::This<RequestImpl> self) { return self->url; })
                   .getter("headers", &RequestImpl::headers_value)
                   .getter("bodyUsed", [](qjs::This<RequestImpl> self) {
                       return self->body_stream && self->body_stream->disturbed;
                   })
                   .getter("body", [](qjs::Ctx ctx, qjs::This<RequestImpl> self) -> qjs::Value {
                       if (!self->body_stream)
                           return qjs::Value(ctx.ctx, JS_NULL);
                       if (self->body_js.empty()) {
                           qjs::Value v = new_binding_object<ReadableStreamBinding>(
                               ctx.ctx, self->body_stream);
                           self->body_js = qjs::RtValue(JS_GetRuntime(ctx.ctx), v.take());
                       }
                       return qjs::Value(ctx.ctx, self->body_js.dup(ctx.ctx));
                   })
                   .getter("redirect", [](qjs::This<RequestImpl> self) { return self->redirect; })
                   .getter("integrity", [](qjs::This<RequestImpl> self) { return self->integrity; })
                   .getter("signal", [](qjs::Ctx ctx, qjs::This<RequestImpl> self) -> qjs::Value {
                       if (self->signal_js.empty())
                           return qjs::Value(ctx.ctx, JS_UNDEFINED);
                       return qjs::Value(ctx.ctx, self->signal_js.dup(ctx.ctx));
                   })
                   .method("clone", [](qjs::Ctx ctx, qjs::This<RequestImpl> self) -> qjs::Value {
                       if (self->body_stream) {
                           if (self->body_stream->locked())
                               throw_type_error(ctx.ctx, "Request: body 已被 reader 锁定");
                           if (self->body_stream->disturbed)
                               throw_type_error(ctx.ctx, "Request: body 已被消费");
                       }
                       RequestImpl c = *self; // 拷贝（headers/url/...）；body_stream 待 tee
                       if (self->body_stream) {
                           // tee：原对象持分支 A，克隆持分支 B（设计文档 §4.3）
                           auto [a, b] = TeeSource::tee(self->body_stream->source);
                           const std::stop_token st = self->body_stream->st_;
                           self->body_stream = make_stream(io_of(ctx.ctx), a, st);
                           c.body_stream = make_stream(io_of(ctx.ctx), b, st);
                           c.body_js = qjs::RtValue(); // 独立 JS 流对象
                       }
                       return qjs::Value(ctx.ctx, qjs::js_convert<RequestImpl>::to_js(ctx.ctx, c));
                   })
                   .method("text", [](qjs::Ctx ctx, qjs::This<RequestImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Request", consume_text);
                   })
                   .method("json", [](qjs::Ctx ctx, qjs::This<RequestImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Request", consume_json);
                   })
                   .method("arrayBuffer", [](qjs::Ctx ctx, qjs::This<RequestImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Request", consume_array_buffer);
                   })
                   .method("bytes", [](qjs::Ctx ctx, qjs::This<RequestImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Request", consume_bytes);
                   })
                   .method("formData",
                           [](qjs::Ctx ctx, qjs::This<RequestImpl> self) -> std_exec::task<qjs::Value> {
                               const std::string ct = content_type_of(ctx.ctx, *self);
                               const std::string essence = mime_essence(ct);
                               // 规范：essence 不是 multipart/urlencoded → TypeError
                               if (essence != "multipart/form-data" &&
                                   essence != "application/x-www-form-urlencoded")
                                   throw_type_error(
                                       ctx.ctx,
                                       "Request: formData() 需要 multipart/form-data 或 "
                                       "application/x-www-form-urlencoded Content-Type");
                               const bool has_body = self->body_stream != nullptr;
                               co_return co_await consume_impl(
                                   ctx.ctx, *self, "Request",
                                   [ct, essence, has_body](JSContext* ctx,
                                                           const std::string& bytes)
                                       -> qjs::Value {
                                       if (essence == "application/x-www-form-urlencoded") {
                                           // urlencoded → FormData（字符串值；无 body 空串 → 空 FormData）
                                           FormDataImpl fd;
                                           for (auto& kv : UrlSearchParamsImpl::from_query(bytes).list)
                                               fd.append_entry(std::move(kv.first),
                                                               std::move(kv.second), "", "", false);
                                           return qjs::Value(
                                               ctx, qjs::js_convert<FormDataImpl>::to_js(ctx, fd));
                                       }
                                       // multipart：body 为 null（无 body）→ TypeError
                                       //（fetch 规范 formData() 步骤：bodyBytes null → reject）
                                       if (!has_body)
                                           throw_type_error(ctx,
                                                            "Request: multipart/form-data 需要 body");
                                       auto fd = parse_multipart(bytes, extract_boundary(ct));
                                       if (!fd) // 解析失败 → TypeError（wpt invalidCases）
                                           throw_type_error(ctx,
                                                            "Request: multipart/form-data 解析失败");
                                       return qjs::Value(
                                           ctx, qjs::js_convert<FormDataImpl>::to_js(ctx, *fd));
                                   });
                           })
                   .method("blob", [](qjs::Ctx ctx, qjs::This<RequestImpl> self)
                               -> std_exec::task<qjs::Value> {
                       const std::string ct =
                           content_type_of(ctx.ctx, *self);
                       co_return co_await consume_impl(
                           ctx.ctx, *self, "Request",
                           [ct](JSContext* c, const std::string& bytes) {
                               return consume_blob(c, bytes, ct);
                           });
                   });
    ctx.globals().set("Request", cls.constructor_function());
}

// ---------- Response ----------

struct ResponseImpl {
    int status = 200;
    std::string status_text;
    HeadersImpl headers; // guard=response
    std::shared_ptr<ReadableStreamImpl> body_stream; // 统一内部 body（null = 无 body）
    std::string type = "default";
    std::string url;
    bool redirected = false;
    qjs::RtValue headers_js; // 缓存的 Headers JS 对象（同一对象语义）
    qjs::RtValue body_js;    // body getter SameObject 缓存

    ResponseImpl() = default;
    // 拷贝：headers_js/body_js 缓存不复制（to_js/clone 场景）；body_stream 复制
    //（to_js 时 JS 对象需持有流；clone() 对流 body 另有 tee 检查）
    ResponseImpl(const ResponseImpl& o)
        : status(o.status), status_text(o.status_text), headers(o.headers),
          body_stream(o.body_stream), type(o.type), url(o.url), redirected(o.redirected)
    {
    }
    ResponseImpl& operator=(const ResponseImpl& o)
    {
        status = o.status;
        status_text = o.status_text;
        headers = o.headers;
        body_stream = o.body_stream;
        type = o.type;
        url = o.url;
        redirected = o.redirected;
        headers_js = qjs::RtValue();
        body_js = qjs::RtValue();
        return *this;
    }

    void qjs_mark(JSRuntime* rt, JS_MarkFunc* mark_func)
    {
        headers_js.mark(rt, mark_func);
        body_js.mark(rt, mark_func);
    }

    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> body, qjs::Opt<qjs::Value> init) {
        headers.set_guard(HeadersImpl::Guard::Response);
        if (init && init->is_object()) {
            qjs::Object obj(*init);
            qjs::Value status_v = obj.get("status");
            if (!status_v.is_undefined()) {
                const int s = status_v.as<int>();
                // 规范：状态码范围违规 → RangeError（wpt 要求 instanceof RangeError）
                if (s < 200 || s > 599)
                    throw_range_error(ctx, "Response: status 必须在 200-599");
                status = s;
            }
            qjs::Value st = obj.get("statusText");
            if (!st.is_undefined())
                status_text = st.as<std::string>();
            // 规范：statusText 必须 HTTP reason-phrase（ByteString：代码点 ≤ U+00FF；
            // CR/LF 禁；0x80-0xFF obs-text 允许）
            for (const char c : status_text)
                if (c == '\r' || c == '\n')
                    throw_type_error(ctx, "Response: statusText 含 CR/LF");
            {
                const std::string& s = status_text;
                for (auto it = s.begin(); it != s.end();) {
                    uint32_t cp = 0;
                    try {
                        cp = utf8::next(it, s.end());
                    } catch (...) {
                        throw_type_error(ctx, "Response: statusText 非 UTF-8");
                    }
                    if (cp > 0xFF)
                        throw_type_error(ctx, "Response: statusText 代码点超出 ByteString 范围");
                }
            }
            qjs::Value hdrs = obj.get("headers");
            if (!hdrs.is_undefined() && !hdrs.is_null()) {
                headers = headers_from(ctx, hdrs.raw());
                headers.set_guard(HeadersImpl::Guard::Response);
            }
        }
        if (body && !body->is_undefined() && !body->is_null()) {
            // 规范：204/205/304 带 body → TypeError
            if (status == 204 || status == 205 || status == 304)
                throw_type_error(ctx, "Response: 204/205/304 不能带 body");
            ExtractedBody b = extract_body(ctx, body->raw());
            body_stream = std::move(b.stream);
            if (!b.content_type.empty() && !headers.has(ctx, "Content-Type"))
                headers.append(ctx, "Content-Type", b.content_type); // 规范：Blob/URLSearchParams 自动设置
        }
        // 规范：204/205/304 无 body
        if (status == 204 || status == 205 || status == 304)
            body_stream = nullptr;
    }

    bool ok() const { return status >= 200 && status <= 299; }
};

// init.body 是 Request/Response 实例时复制其内部 body：源为字节（MemorySource 流）
// 未 disturbed → tee 共享；已 disturbed → TypeError（v1 语义衔接，设计文档 §4.3）。
// consumed_out：tee 后原对象的分支 A 流指针（ReadableStreamImpl*）——由调用方在
// 构造成功末尾置 disturbed（wpt request-disturbed："构造失败不置 bodyUsed"）。
inline bool try_extract_init_body(JSContext* ctx, JSValueConst v, ExtractedBody& out,
                                  void** consumed_out) {
    auto& reg = qjs::registry_of(ctx);
    if (reg.is_registered<RequestImpl>() && reg.id_of<RequestImpl>(ctx) == JS_GetClassID(v)) {
        auto* r = reg.opaque<RequestImpl>(ctx, v);
        if (!r->body_stream)
            return true; // 无 body
        if (r->body_stream->locked())
            throw_type_error(ctx, "Request: body 已被 reader 锁定");
        if (r->body_stream->disturbed)
            throw_type_error(ctx, "Request: body 已被消费");
        auto [a, b] = TeeSource::tee(r->body_stream->source);
        const std::stop_token st = r->body_stream->st_;
        auto ia = make_stream(io_of(ctx), a, st); // 原对象持分支 A
        auto ib = make_stream(io_of(ctx), b, st); // 新对象持分支 B
        r->body_stream = std::move(ia);
        out.stream = std::move(ib);
        out.has = true;
        if (consumed_out)
            *consumed_out = r->body_stream.get();
        return true;
    }
    if (reg.is_registered<ResponseImpl>() && reg.id_of<ResponseImpl>(ctx) == JS_GetClassID(v)) {
        auto* r = reg.opaque<ResponseImpl>(ctx, v);
        if (!r->body_stream)
            return true; // 无 body
        if (r->body_stream->locked())
            throw_type_error(ctx, "Response: body 已被 reader 锁定");
        if (r->body_stream->disturbed)
            throw_type_error(ctx, "Response: body 已被消费");
        auto [a, b] = TeeSource::tee(r->body_stream->source);
        const std::stop_token st = r->body_stream->st_;
        auto ia = make_stream(io_of(ctx), a, st); // 原对象持分支 A
        auto ib = make_stream(io_of(ctx), b, st); // 新对象持分支 B
        r->body_stream = std::move(ia);
        out.stream = std::move(ib);
        out.has = true;
        if (consumed_out)
            *consumed_out = r->body_stream.get();
        return true;
    }
    {
        std::string blob_bytes;
        if (try_blob_bytes(ctx, v, blob_bytes)) { // Blob/File 作 init
            out.stream = bytes_to_stream(ctx, std::move(blob_bytes));
        out.has = true;
        if (is_blob_instance(ctx, v))
            out.content_type = reg.opaque<BlobImpl>(ctx, v)->type;
        else if (is_file_instance(ctx, v))
            out.content_type = reg.opaque<FileImpl>(ctx, v)->blob.type;
        return true;
        }
    }
    return false;
}

inline void install_response(qjs::Context& ctx) {
    auto cls = qjs::class_<ResponseImpl>(ctx, "Response")
                   .constructor<qjs::Opt<qjs::Value>, qjs::Opt<qjs::Value>>()
                   .getter("status", [](qjs::This<ResponseImpl> self) { return self->status; })
                   .getter("statusText", [](qjs::This<ResponseImpl> self) { return self->status_text; })
                   .getter("ok", [](qjs::This<ResponseImpl> self) { return self->ok(); })
                   .getter("type", [](qjs::This<ResponseImpl> self) { return self->type; })
                   .getter("url", [](qjs::This<ResponseImpl> self) { return self->url; })
                   .getter("redirected", [](qjs::This<ResponseImpl> self) { return self->redirected; })
                   .getter("headers", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self) -> qjs::Value {
                       if (self->headers_js.empty())
                           self->headers_js = qjs::RtValue(
                               JS_GetRuntime(ctx.ctx),
                               qjs::js_convert<HeadersImpl>::to_js(ctx.ctx, self->headers));
                       return qjs::Value(ctx.ctx, self->headers_js.dup(ctx.ctx));
                   })
                   .getter("bodyUsed", [](qjs::This<ResponseImpl> self) {
                       return self->body_stream && self->body_stream->disturbed;
                   })
                   .getter("body", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self) -> qjs::Value {
                       if (!self->body_stream)
                           return qjs::Value(ctx.ctx, JS_NULL);
                       if (self->body_js.empty()) {
                           qjs::Value v = new_binding_object<ReadableStreamBinding>(
                               ctx.ctx, self->body_stream);
                           self->body_js = qjs::RtValue(JS_GetRuntime(ctx.ctx), v.take());
                       }
                       return qjs::Value(ctx.ctx, self->body_js.dup(ctx.ctx));
                   })
                   .method("clone", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self) -> qjs::Value {
                       if (self->body_stream) {
                           if (self->body_stream->locked())
                               throw_type_error(ctx.ctx, "Response: body 已被 reader 锁定");
                           if (self->body_stream->disturbed)
                               throw_type_error(ctx.ctx, "Response: body 已被消费");
                       }
                       ResponseImpl c = *self; // 拷贝（headers/状态）；body_stream 待 tee
                       if (self->body_stream) {
                           // tee：原对象持分支 A，克隆持分支 B（设计文档 §4.3）
                           auto [a, b] = TeeSource::tee(self->body_stream->source);
                           const std::stop_token st = self->body_stream->st_;
                           self->body_stream = make_stream(io_of(ctx.ctx), a, st);
                           c.body_stream = make_stream(io_of(ctx.ctx), b, st);
                           c.body_js = qjs::RtValue(); // 独立 JS 流对象
                       }
                       return qjs::Value(ctx.ctx, qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, c));
                   })
                   .method("text", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Response", consume_text);
                   })
                   .method("json", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Response", consume_json);
                   })
                   .method("arrayBuffer", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Response", consume_array_buffer);
                   })
                   .method("bytes", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self)
                               -> std_exec::task<qjs::Value> {
                       co_return co_await consume_impl(ctx.ctx, *self, "Response", consume_bytes);
                   })
                   .method("formData",
                           [](qjs::Ctx ctx, qjs::This<ResponseImpl> self) -> std_exec::task<qjs::Value> {
                               const std::string ct = content_type_of(ctx.ctx, *self);
                               const std::string essence = mime_essence(ct);
                               if (essence != "multipart/form-data" &&
                                   essence != "application/x-www-form-urlencoded")
                                   throw_type_error(
                                       ctx.ctx,
                                       "Response: formData() 需要 multipart/form-data 或 "
                                       "application/x-www-form-urlencoded Content-Type");
                               const bool has_body = self->body_stream != nullptr;
                               co_return co_await consume_impl(
                                   ctx.ctx, *self, "Response",
                                   [ct, essence, has_body](JSContext* ctx,
                                                           const std::string& bytes)
                                       -> qjs::Value {
                                       if (essence == "application/x-www-form-urlencoded") {
                                           FormDataImpl fd;
                                           for (auto& kv : UrlSearchParamsImpl::from_query(bytes).list)
                                               fd.append_entry(std::move(kv.first),
                                                               std::move(kv.second), "", "", false);
                                           return qjs::Value(
                                               ctx, qjs::js_convert<FormDataImpl>::to_js(ctx, fd));
                                       }
                                       if (!has_body)
                                           throw_type_error(
                                               ctx, "Response: multipart/form-data 需要 body");
                                       auto fd = parse_multipart(bytes, extract_boundary(ct));
                                       if (!fd) // 解析失败 → TypeError（wpt invalidCases）
                                           throw_type_error(
                                               ctx, "Response: multipart/form-data 解析失败");
                                       return qjs::Value(
                                           ctx, qjs::js_convert<FormDataImpl>::to_js(ctx, *fd));
                                   });
                           })
                   .method("blob", [](qjs::Ctx ctx, qjs::This<ResponseImpl> self)
                               -> std_exec::task<qjs::Value> {
                       const std::string ct =
                           content_type_of(ctx.ctx, *self);
                       co_return co_await consume_impl(
                           ctx.ctx, *self, "Response",
                           [ct](JSContext* c, const std::string& bytes) {
                               return consume_blob(c, bytes, ct);
                           });
                   })
                   .static_method("error", [](qjs::Ctx ctx) -> qjs::Value {
                       ResponseImpl r;
                       r.status = 0;
                       r.type = "error";
                       r.headers.set_guard(HeadersImpl::Guard::Immutable); // 规范：error 响应 headers 不可变
                       return qjs::Value(ctx.ctx, qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, r));
                   })
                   .static_method("redirect", [](qjs::Ctx ctx, const std::string& url,
                                                 qjs::Opt<int> status) -> qjs::Value {
                       const int s = status ? *status : 302;
                       if (s != 301 && s != 302 && s != 303 && s != 307 && s != 308)
                           throw_range_error(ctx.ctx, "Response: redirect 状态非法");
                       ResponseImpl r;
                       r.status = s;
                       r.type = "default";
                       r.headers.append_raw("location", RequestImpl::resolve_url(ctx.ctx, url));
                       return qjs::Value(ctx.ctx, qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, r));
                   })
                   .static_method("json", [](qjs::Ctx ctx, qjs::Value data,
                                             qjs::Opt<qjs::Value> init) -> qjs::Value {
                       // 规范：bytes = JSON serialize(data)（BigInt/循环引用 → TypeError）
                       qjs::Value s(ctx.ctx,
                                    JS_JSONStringify(ctx.ctx, data.raw(), JS_UNDEFINED,
                                                     JS_UNDEFINED)); // RAII
                       if (s.is_exception())
                           throw qjs::js_error(ctx.ctx, JS_GetException(ctx.ctx));
                       std::string json;
                       {
                           // Context 成员：js_string（值语义提取，嵌入 '\0' 保留）
                           auto str = qjs::Context(ctx.ctx).js_string(s.raw());
                           json = str ? std::move(*str) : std::string{};
                       }
                       // 规范：仅当 init.headers 未显式给 content-type 时补 application/json
                       //（string body 的默认 text/plain 需被替换）
                       bool user_ct = false;
                       if (init && init->is_object()) {
                           qjs::Object obj(*init);
                           qjs::Value hdrs = obj.get("headers");
                           if (!hdrs.is_undefined() && !hdrs.is_null()) {
                               HeadersImpl h = headers_from(ctx.ctx, hdrs.raw());
                               user_ct = h.has(ctx.ctx, "content-type");
                           }
                       }
                       qjs::Opt<qjs::Value> body;
                       body.value.emplace(ctx.ctx,
                                          JS_NewStringLen(ctx.ctx, json.data(), json.size()));
                       ResponseImpl r;
                       r.qjs_init(ctx.ctx, body, init);
                       if (!user_ct)
                           r.headers.set(ctx.ctx, "content-type", "application/json");
                       return qjs::Value(ctx.ctx,
                                        qjs::js_convert<ResponseImpl>::to_js(ctx.ctx, r));
                   });
    ctx.globals().set("Response", cls.constructor_function());
    // forEach 的 container 参数包装（headers 实例；活迭代器补丁见 install_headers）
    ctx.eval(
        "var __f0 = Headers.prototype.forEach;"
        "Headers.prototype.forEach = function (cb, thisArg) {"
        "  var self = this;"
        "  __f0.call(this, function (value, key) { cb.call(thisArg, value, key, self); }, thisArg);"
        "};");
}

} // namespace qjsbind::web
