// qjsbind::web —— URL / URLSearchParams（基于 Boost.URL，WHATWG 语义子集）
//
// v1 边界：
//   - URL：绝对/相对（base resolve）解析、各属性读写；origin 用 encoded_origin；
//   - URLSearchParams：构造（string/record/序列 of pairs/另一实例）、增删查改、sort；
//   - entries/keys/values 返回数组（非规范迭代器对象），Symbol.iterator 指向 entries；
//   - searchParams 与 URL.search 双向实时联动（SameObject 缓存 + 回写）。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/binary.hpp> // qjs::Context::js_string / js_utf8（值语义提取）
#include <qjsbind/context.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/web/errors.hpp>

#include <fmt/format.h> // fmt::format（错误消息拼接）
#include <qjsbind/web/utf8.hpp>

#include <boost/url/parse.hpp>
#include <boost/url/url.hpp>

#include <algorithm>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace qjsbind::web {

// ---------- 工具 ----------

inline int hex_value(char c) {
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    return -1;
}

// percent-decode；plus_as_space=true 时 '+' → ' '（application/x-www-form-urlencoded）
inline std::string percent_decode(std::string_view s, bool plus_as_space) {
    std::string out;
    out.reserve(s.size());
    for (size_t i = 0; i < s.size(); ++i) {
        const char c = s[i];
        if (c == '%' && i + 2 < s.size()) {
            const int hi = hex_value(s[i + 1]);
            const int lo = hex_value(s[i + 2]);
            if (hi >= 0 && lo >= 0) {
                out.push_back(static_cast<char>((hi << 4) | lo));
                i += 2;
                continue;
            }
        }
        if (c == '+' && plus_as_space)
            out.push_back(' ');
        else
            out.push_back(c);
    }
    return out;
}

// form 序列化：name=value&...，空格 → '+'，非 unreserved → %XX
inline std::string form_encode(const std::vector<std::pair<std::string, std::string>>& list) {
    std::string out;
    bool first = true;
    for (const auto& [k, v] : list) {
        if (!first)
            out.push_back('&');
        first = false;
        out += percent_encode(k, true);
        out.push_back('=');
        out += percent_encode(v, true);
    }
    return out;
}

// ---------- URLSearchParams ----------

// 联动通过 JS 隐藏属性（URL 对象上 "\x01sp"、searchParams 对象上 "\x01url"）双向引用：
// - JS 属性对 GC 可见 → 不可达环可被周期回收（RtValue 在 opaque 内不可见，会造成泄漏断言）；
// - 拷贝语义天然正确（JS 属性不随 C++ 拷贝复制）。
constexpr const char* kSpOwnerKey = "\x01url"; // searchParams → URL
constexpr const char* kUrlSpKey = "\x01sp";    // URL → searchParams（SameObject 缓存）

struct UrlImpl; // 前向声明（回写用）

struct UrlSearchParamsImpl {
    std::vector<std::pair<std::string, std::string>> list; // 解码后的键值（插入序）

    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> init); // 定义见 url_search_params_from 之后

    static UrlSearchParamsImpl from_query(std::string_view q) {
        UrlSearchParamsImpl out;
        if (!q.empty() && q.front() == '?')
            q.remove_prefix(1);
        size_t pos = 0;
        while (pos <= q.size()) {
            const size_t amp = q.find('&', pos);
            const std::string_view item = q.substr(pos, amp == std::string_view::npos
                                                          ? q.size() - pos
                                                          : amp - pos);
            if (!item.empty()) {
                const size_t eq = item.find('=');
                const std::string_view k = item.substr(0, eq);
                const std::string_view v =
                    eq == std::string_view::npos ? std::string_view{} : item.substr(eq + 1);
                out.list.push_back({percent_decode(k, true), percent_decode(v, true)});
            }
            if (amp == std::string_view::npos)
                break;
            pos = amp + 1;
        }
        return out;
    }

    std::string to_query() const { return form_encode(list); }

    void append(const std::string& name, const std::string& value) {
        list.push_back({name, value});
    }
    void erase(const std::string& name) {
        std::erase_if(list, [&](const auto& p) { return p.first == name; });
    }
    bool has(const std::string& name) const {
        for (const auto& [k, v] : list)
            if (k == name)
                return true;
        return false;
    }
    std::optional<std::string> get(const std::string& name) const {
        for (const auto& [k, v] : list)
            if (k == name)
                return v;
        return std::nullopt;
    }
    std::vector<std::string> get_all(const std::string& name) const {
        std::vector<std::string> out;
        for (const auto& [k, v] : list)
            if (k == name)
                out.push_back(v);
        return out;
    }
    void set(const std::string& name, const std::string& value) {
        bool replaced = false;
        for (size_t i = 0; i < list.size();) {
            if (list[i].first == name) {
                if (!replaced) {
                    list[i].second = value;
                    replaced = true;
                    ++i;
                } else {
                    list.erase(list.begin() + static_cast<std::ptrdiff_t>(i));
                }
            } else {
                ++i;
            }
        }
        if (!replaced)
            list.push_back({name, value});
    }
    void sort() {
        std::stable_sort(list.begin(), list.end(),
                         [](const auto& a, const auto& b) { return a.first < b.first; });
    }
};

// 判断 JS 值是否为已绑定的 URLSearchParamsImpl 实例
inline bool is_url_search_params_instance(JSContext* ctx, JSValueConst v) {
    if (!JS_IsObject(v))
        return false;
    auto& reg = qjs::registry_of(ctx);
    if (!reg.is_registered<UrlSearchParamsImpl>())
        return false;
    return reg.id_of<UrlSearchParamsImpl>(ctx) == JS_GetClassID(v);
}

// JS init 参数 → 键值对列表（前向声明，供 qjs_init；定义见后）
inline UrlSearchParamsImpl url_search_params_from(JSContext* ctx, JSValueConst init);

// params 修改 → owner URL.search 回写（定义见 UrlImpl 之后）
inline void notify_change(JSContext* ctx, JSValueConst sp_js, const UrlSearchParamsImpl& p);

// qjs_init 类外定义（依赖 url_search_params_from）
inline void UrlSearchParamsImpl::qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> init) {
    if (init)
        *this = url_search_params_from(ctx, init->raw());
}

// JS init 参数 → 键值对列表（string / URLSearchParams 实例 / record / 序列 of pairs）
inline UrlSearchParamsImpl url_search_params_from(JSContext* ctx, JSValueConst init) {
    if (JS_IsUndefined(init) || JS_IsNull(init))
        return {};
    if (JS_IsString(init)) {
        // Context 成员：js_string（值语义提取，嵌入 '\0' 保留）
        auto s = qjs::Context(ctx).js_string(init);
        if (!s)
            throw qjs::js_error(ctx, JS_GetException(ctx));
        return UrlSearchParamsImpl::from_query(*s);
    }
    if (is_url_search_params_instance(ctx, init)) {
        const auto* other = qjs::registry_of(ctx).opaque<UrlSearchParamsImpl>(ctx, init);
        return *other;
    }
    if (JS_IsArray(init)) {
        UrlSearchParamsImpl out;
        // init 是借用值：dup 后交由 arr 接管（否则调用方析构 double-free）
        qjs::Array arr(ctx, JS_DupValue(ctx, init));
        for (std::size_t i = 0; i < arr.length(); ++i) {
            qjs::Value item = arr.get(i);
            if (!item.is_array()) {
                throw_type_error(ctx, "URLSearchParams: 序列项不是 [name, value] 数组");
            }
            qjs::Array pair(std::move(item)); // 移动接管 item 的唯一引用
            qjs::Value k = pair.get(0);
            qjs::Value v = pair.get(1);
            out.list.push_back({k.as<std::string>(), v.as<std::string>()});
        }
        return out;
    }
    if (JS_IsObject(init)) {
        UrlSearchParamsImpl out;
        JSPropertyEnum* props = nullptr;
        uint32_t nprops = 0;
        if (JS_GetOwnPropertyNames(ctx, &props, &nprops, init,
                                   JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY) < 0)
            throw qjs::js_error(ctx, JS_GetException(ctx));
        for (uint32_t i = 0; i < nprops; ++i) {
            qjs::Value key(ctx, JS_AtomToString(ctx, props[i].atom));
            qjs::Value val(ctx, JS_GetProperty(ctx, init, props[i].atom));
            out.list.push_back({key.as<std::string>(), val.as<std::string>()});
        }
        js_free(ctx, props);
        return out;
    }
    throw_type_error(ctx, "URLSearchParams: 不支持的 init 参数");
}

// JS 数组（每项 [name, value] 或 name）构造（entries/keys/values 的 v1 返回形态）
inline qjs::Value pairs_to_js_array(JSContext* ctx,
                                    const std::vector<std::pair<std::string, std::string>>& list,
                                    bool keys_only) {
    qjs::Array arr(ctx, JS_NewArray(ctx));
    std::size_t idx = 0;
    for (const auto& [k, v] : list) {
        if (keys_only) {
            arr.set(idx++, qjs::Value(ctx, JS_NewString(ctx, k.c_str())));
        } else {
            qjs::Array pair(ctx, JS_NewArray(ctx));
            pair.set(0, qjs::Value(ctx, JS_NewString(ctx, k.c_str())));
            pair.set(1, qjs::Value(ctx, JS_NewString(ctx, v.c_str())));
            arr.set(idx++, qjs::Value(std::move(pair)));
        }
    }
    return qjs::Value(std::move(arr));
}

inline void install_url_search_params(qjs::Context& ctx) {
    auto cls = qjs::class_<UrlSearchParamsImpl>(ctx, "URLSearchParams")
                   .constructor<qjs::Opt<qjs::Value>>()
                   .method("append",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self,
                              const std::string& n, const std::string& v) {
                               self->append(n, v);
                               notify_change(ctx.ctx, self.js, *self); // 联动回写 owner URL
                           })
                   .method("delete",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self,
                              const std::string& n) {
                               self->erase(n);
                               notify_change(ctx.ctx, self.js, *self);
                           })
                   .method("has", &UrlSearchParamsImpl::has)
                   .method("get", [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self,
                                     const std::string& name) -> qjs::Value {
                       const auto v = self->get(name);
                       return v ? qjs::Value(ctx.ctx, JS_NewString(ctx.ctx, v->c_str()))
                                : qjs::Value(ctx.ctx, JS_NULL);
                   })
                   .method("getAll", &UrlSearchParamsImpl::get_all)
                   .method("set",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self,
                              const std::string& n, const std::string& v) {
                               self->set(n, v);
                               notify_change(ctx.ctx, self.js, *self);
                           })
                   .method("sort",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self) {
                               self->sort();
                               notify_change(ctx.ctx, self.js, *self);
                           })
                   .method("toString", &UrlSearchParamsImpl::to_query)
                   .method("entries",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self) -> qjs::Value {
                               return pairs_to_js_array(ctx.ctx, self->list, false);
                           })
                   .method("keys", [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self) -> qjs::Value {
                       return pairs_to_js_array(ctx.ctx, self->list, true);
                   })
                   .method("values", [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self) -> qjs::Value {
                       std::vector<std::string> vals;
                       for (const auto& [k, v] : self->list)
                           vals.push_back(v);
                       qjs::Array arr(ctx.ctx, JS_NewArray(ctx.ctx));
                       std::size_t i = 0;
                       for (const auto& v : vals)
                           arr.set(i++, qjs::Value(ctx.ctx, JS_NewString(ctx.ctx, v.c_str())));
                       return qjs::Value(std::move(arr));
                   })
                   .method("forEach",
                           [](qjs::Ctx ctx, qjs::This<UrlSearchParamsImpl> self, qjs::Function cb,
                              qjs::Opt<qjs::Value> this_arg) {
                               for (const auto& [k, v] : self->list) {
                                   // args 以 RAII Value 持有（借用 raw()），调用后自动释放
                                   qjs::Context cx(ctx.ctx);
                                   qjs::Value a0 = cx.to_js(v);
                                   qjs::Value a1 = cx.to_js(k);
                                   qjs::Value a2(ctx.ctx, JS_DupValue(
                                       ctx.ctx, this_arg ? this_arg->raw() : JS_UNDEFINED));
                                   JSValue args[3] = {a0.raw(), a1.raw(), a2.raw()};
                                   qjs::Value r = cb.call_raw(3, args);
                                   if (r.is_exception())
                                       throw qjs::js_error(ctx.ctx, JS_GetException(ctx.ctx));
                               }
                           });
    ctx.globals().set("URLSearchParams", cls.constructor_function());
    // Symbol.iterator（vcpkg quickjs.h 无公共 atom 常量，JS 侧补丁最稳）
    ctx.eval(
        "URLSearchParams.prototype[Symbol.iterator] = function* () { yield* this.entries(); };"
        "URLSearchParams.prototype[Symbol.toStringTag] = 'URLSearchParams';");
}

// ---------- URL ----------

struct UrlImpl {
    boost::urls::url u; // 绝对 URL

    // 拷贝/赋值：JS 隐藏属性不复制（new URL(u) 是新实例，searchParams 各自创建）
    UrlImpl() = default;
    UrlImpl(const UrlImpl& o) : u(o.u) {}
    UrlImpl& operator=(const UrlImpl& o) {
        u = o.u;
        return *this;
    }
    UrlImpl(UrlImpl&&) noexcept = default;
    UrlImpl& operator=(UrlImpl&&) noexcept = default;

    void qjs_init(JSContext* ctx, qjs::Opt<qjs::Value> url, qjs::Opt<qjs::Value> base) {
        // 字符串取 UTF-16 单元转 UTF-8：孤立代理 → U+FFFD（WHATWG URL 行为；
        // JS_ToCString 保留 CESU-8 不替换，编码结果与浏览器不一致）
        // Context 成员：js_utf8（值语义提取）
        std::string url_str, base_str;
        if (url && !url->is_undefined() && !url->is_null()) {
            if (auto s = qjs::Context(ctx).js_utf8(url->raw()))
                url_str = std::move(*s);
        }
        if (base && !base->is_undefined() && !base->is_null()) {
            if (auto s = qjs::Context(ctx).js_utf8(base->raw()))
                base_str = std::move(*s);
        }
        *this = parse(ctx, url_str, base_str);
    }

    // WHATWG 解析：绝对引用直接用；相对引用必须带 base（无 base → TypeError）
    // boost 严格语法拒绝的字符（非 ASCII、| 等 WHATWG 允许的）→ 宽松编码重试。
    // 注意：parse_uri_reference 返回的 url_view 借用输入字符串，relax 结果必须
    // 存活到 url_view 使用完毕（否则悬垂）。
    static UrlImpl parse(JSContext* ctx, std::string_view str, std::string_view base) {
        std::string relaxed_storage;
        auto r = boost::urls::parse_uri_reference(str);
        if (r.has_error()) {
            relaxed_storage = relax_url_chars(str);
            r = boost::urls::parse_uri_reference(relaxed_storage);
            if (r.has_error()) {
                throw_type_error(ctx, fmt::format("URL: 无法解析 '{}'", str));
            }
        }
        UrlImpl out;
        if (r->has_scheme()) {
            out.u = boost::urls::url(*r);
        } else {
            if (base.empty())
                throw_type_error(ctx, "URL: 相对引用缺少 base");
            std::string base_relaxed;
            auto rb = boost::urls::parse_uri_reference(base);
            if (rb.has_error()) {
                base_relaxed = relax_url_chars(base);
                rb = boost::urls::parse_uri_reference(base_relaxed);
            }
            if (rb.has_error())
                throw_type_error(ctx, "URL: base 无法解析");
            out.u = boost::urls::url(*rb);
            auto res = out.u.resolve(*r);
            if (res.has_error())
                throw_type_error(ctx, "URL: 相对解析失败");
        }
        return out;
    }

    // 宽松编码：scheme://authority 保留；path/query/fragment 的非 ASCII 字节与
    // WHATWG 不允许的 ASCII（|、空格、控制字符等）→ percent-encode
    static std::string relax_url_chars(std::string_view url) {
        size_t auth_end = 0;
        const size_t scheme_end = url.find("://");
        if (scheme_end != std::string_view::npos) {
            const size_t path_start = url.find_first_of("/?#", scheme_end + 3);
            auth_end = path_start == std::string_view::npos ? url.size() : path_start;
        }
        const char* hexd = "0123456789ABCDEF";
        auto is_safe = [](unsigned char c) {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
                   c == '-' || c == '.' || c == '_' || c == '~' || c == '!' || c == '$' ||
                   c == '&' || c == '\'' || c == '(' || c == ')' || c == '*' || c == '+' ||
                   c == ',' || c == ';' || c == '=' || c == ':' || c == '@' || c == '/' ||
                   c == '?' || c == '#' || c == '[' || c == ']';
        };
        auto is_hex = [](char c) {
            return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
        };
        std::string out;
        for (size_t i = 0; i < url.size(); ++i) {
            const unsigned char c = url[i];
            // 裸 %（后非 2 hex）也编码为 %25（boost 严格语法拒绝裸 %）
            const bool pct_ok = c == '%' && i + 2 < url.size() && is_hex(url[i + 1]) &&
                                is_hex(url[i + 2]);
            if (i < auth_end || is_safe(c) || pct_ok) {
                out.push_back(static_cast<char>(c));
            } else {
                out.push_back('%');
                out.push_back(hexd[c >> 4]);
                out.push_back(hexd[c & 0xF]);
            }
        }
        return out;
    }

    std::string href() const { return u.buffer(); }
    std::string protocol() const { return std::string(u.scheme()) + ":"; }
    std::string hostname() const { return std::string(u.encoded_host()); }
    std::string host() const { return std::string(u.encoded_host_and_port()); }
    // WHATWG：默认端口（http 80 / https 443）显示为空
    std::string port() const {
        const std::string p(u.port());
        const std::string s(u.scheme());
        if ((s == "http" && p == "80") || (s == "https" && p == "443"))
            return "";
        return p;
    }
    std::string pathname() const { return std::string(u.encoded_path()); }
    std::string search() const {
        return u.has_query() ? "?" + std::string(u.encoded_query()) : "";
    }
    std::string hash() const {
        return u.has_fragment() ? "#" + std::string(u.encoded_fragment()) : "";
    }
    std::string origin() const { return std::string(u.encoded_origin()); }
    std::string to_string() const { return href(); }

    // params → URL 回写（不触发反向同步，params 是数据源）
    void set_search_raw(const std::string& q) {
        if (q.empty())
            u.remove_query();
        else
            u.set_encoded_query(q);
    }

    // URL.search 变化后同步缓存的 searchParams 对象（live 语义；self_js = URL 的 JS 值）
    void sync_search_params(JSContext* ctx, JSValueConst self_js) {
        // Context 成员：get_property（RAII，析构自动 free）
        qjs::Value sp = qjs::Context(ctx).get_property(self_js, kUrlSpKey);
        if (!sp.is_undefined()) {
            if (auto* p = qjs::registry_of(ctx).opaque<UrlSearchParamsImpl>(ctx, sp.raw()))
                p->list = UrlSearchParamsImpl::from_query(search()).list;
        }
    }

    // ---- setters（WHATWG 语义子集）----
    void set_href(JSContext* ctx, const std::string& v, JSValueConst self_js) {
        u = parse(ctx, v, "").u;
        sync_search_params(ctx, self_js);
    }
    void set_protocol(const std::string& v) {
        std::string s = v;
        if (!s.empty() && s.back() == ':')
            s.pop_back();
        u.set_scheme(s);
    }
    void set_hostname(const std::string& v) { u.set_encoded_host(v); }
    void set_host(const std::string& v) {
        // "host:port" → 拆开设置（v1：按最后一个 ':' 拆，IPv6 场景简化）
        const size_t colon = v.rfind(':');
        if (colon == std::string::npos) {
            u.set_encoded_host(v);
        } else {
            u.set_encoded_host(v.substr(0, colon));
            u.set_port(v.substr(colon + 1));
        }
    }
    void set_port(const std::string& v) {
        if (v.empty())
            u.remove_port();
        else
            u.set_port(v);
    }
    void set_pathname(const std::string& v) { u.set_encoded_path(v); }
    void set_search(JSContext* ctx, const std::string& v, JSValueConst self_js) {
        std::string s = v;
        if (!s.empty() && s.front() == '?')
            s.erase(0, 1);
        if (s.empty())
            u.remove_query();
        else
            u.set_encoded_query(s);
        sync_search_params(ctx, self_js); // live：缓存的 searchParams 同步新值
    }
    void set_hash(const std::string& v) {
        std::string s = v;
        if (!s.empty() && s.front() == '#')
            s.erase(0, 1);
        if (s.empty())
            u.remove_fragment();
        else
            u.set_encoded_fragment(s);
    }
};

// params 修改 → owner URL.search 回写（sp_js = searchParams 的 JS 值）
inline void notify_change(JSContext* ctx, JSValueConst sp_js, const UrlSearchParamsImpl& p) {
    // Context 成员：get_property（RAII，析构自动 free）
    qjs::Value owner = qjs::Context(ctx).get_property(sp_js, kSpOwnerKey);
    if (!owner.is_undefined()) {
        if (auto* url = qjs::registry_of(ctx).opaque<UrlImpl>(ctx, owner.raw()))
            url->set_search_raw(p.to_query());
    }
}

inline void install_url(qjs::Context& ctx) {
    install_url_search_params(ctx);
    auto cls = qjs::class_<UrlImpl>(ctx, "URL")
                   .constructor<qjs::Opt<qjs::Value>, qjs::Opt<qjs::Value>>()
                   .getter("href", [](qjs::This<UrlImpl> self) { return self->href(); })
                   .setter("href", [](qjs::Ctx ctx, qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_href(ctx.ctx, v, self.js); // 解析失败 → TypeError
                   })
                   .getter("protocol", [](qjs::This<UrlImpl> self) { return self->protocol(); })
                   .setter("protocol", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_protocol(v);
                   })
                   .getter("host", [](qjs::This<UrlImpl> self) { return self->host(); })
                   .setter("host", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_host(v);
                   })
                   .getter("hostname", [](qjs::This<UrlImpl> self) { return self->hostname(); })
                   .setter("hostname", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_hostname(v);
                   })
                   .getter("port", [](qjs::This<UrlImpl> self) { return self->port(); })
                   .setter("port", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_port(v);
                   })
                   .getter("pathname", [](qjs::This<UrlImpl> self) { return self->pathname(); })
                   .setter("pathname", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_pathname(v);
                   })
                   .getter("search", [](qjs::This<UrlImpl> self) { return self->search(); })
                   .setter("search", [](qjs::Ctx ctx, qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_search(ctx.ctx, v, self.js);
                   })
                   .getter("hash", [](qjs::This<UrlImpl> self) { return self->hash(); })
                   .setter("hash", [](qjs::This<UrlImpl> self, const std::string& v) {
                       self->set_hash(v);
                   })
                   .getter("origin", [](qjs::This<UrlImpl> self) { return self->origin(); })
                   .getter("searchParams",
                           [](qjs::Ctx ctx, qjs::This<UrlImpl> self) -> qjs::Value {
                               // SameObject + 双向联动：URL 上挂隐藏属性缓存 searchParams；
                               // searchParams 上挂 owner 隐藏属性（JS 属性 GC 可见，环可回收）
                               qjs::Context cx(ctx.ctx);
                               qjs::Value sp = cx.get_property(self.js, kUrlSpKey);
                               if (sp.is_undefined()) {
                                   UrlSearchParamsImpl p =
                                       UrlSearchParamsImpl::from_query(self->search());
                                   sp = qjs::Value(ctx.ctx, qjs::js_convert<UrlSearchParamsImpl>::to_js(ctx.ctx, p));
                                   // set_property 转移所有权：dup 后挂
                                   cx.set_property(sp.raw(), kSpOwnerKey,
                                                   qjs::Value(ctx.ctx, JS_DupValue(ctx.ctx, self.js)));
                                   cx.set_property(self.js, kUrlSpKey,
                                                   qjs::Value(ctx.ctx, JS_DupValue(ctx.ctx, sp.raw())));
                               }
                               return sp; // 转移所有权（新引用）
                           })
                   .method("toString", [](qjs::This<UrlImpl> self) { return self->to_string(); })
                   .method("toJSON", [](qjs::This<UrlImpl> self) { return self->to_string(); })
                   .static_method("parse", [](qjs::Ctx ctx, const std::string& url,
                                              qjs::Opt<qjs::Value> base) -> qjs::Value {
                       // 规范：URL.parse(url, base)——解析失败返回 null（不抛）
                       try {
                           UrlImpl u =
                               UrlImpl::parse(ctx.ctx, url, base ? base->as<std::string>() : "");
                           return qjs::Value(ctx.ctx,
                                            qjs::js_convert<UrlImpl>::to_js(ctx.ctx, u));
                       } catch (const qjs::js_error&) {
                           return qjs::Value(ctx.ctx, JS_NULL);
                       }
                   });

    // v1 不做 Symbol.iterator 补丁（entries/keys/values 返回数组已满足 fetch 场景；
    // 注意：不可用 ctx.eval 做原型补丁——异常会污染 current_exception）
    ctx.globals().set("URL", cls.constructor_function());
}

} // namespace qjsbind::web
