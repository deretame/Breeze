// fetch::easy —— reqwest 风格请求层（设计文档 docs/fetch_easy_design.md）
//
// 硬约束：不改 fetchcore 任何现有接口；本层是对 fetch::Client 的纯包装。
// 生命周期与线程契约完全继承 fetch::Client（io 必须比 Client 及在飞请求
// 活得久；只能从跑 io.run() 的线程使用）。
//
// 文件布局（§2）：
//   include/fetch/easy.hpp         伞头（本文件）：Client/ClientBuilder/
//                                  RequestBuilder/Response/Error
//   include/fetch/easy/retry.hpp   重试策略（本文件内联；算子见 easy.hpp 末尾）
//   include/fetch/easy/timeout.hpp 超时组合子（E3 里程碑）
#pragma once

#include <fetch/client.hpp>
#include <fetch/body.hpp>
#include <fetch/scheduler.hpp>
#include <fetch/multipart.hpp>
#include <fetch/easy/form.hpp>
#include <dart_cpp_bridge/runtime.hpp>

#include <exec/when_any.hpp>
#include <ada.h>

#include <stdexec/execution.hpp>

#include <chrono>
#include <cctype>
#include <algorithm>
#include <cstddef>
#include <cstring>
#include <exception>
#include <functional>
#include <initializer_list>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#ifndef FETCH_EASY_NO_JSON
#include <glaze/glaze.hpp>
#endif

namespace fetch {
namespace easy {

// ===================== 4.1 Error =====================

enum class error_kind {
    network,     // 连接/DNS/TLS/读写（包装 boost::system::system_error）
    timeout,     // when_any 中定时器分支胜出
    decode,      // glaze 解析失败 / body 读取失败
    http_status, // error_for_status() 命中 4xx/5xx（带 status()）
    url,         // URL 非法（send 时校验）
    policy,      // fetch::Error（重定向超限/SRI/端口封禁等策略错误）
};

// 可拷贝（KI-051：MSVC 协程传播 move-only 异常会损坏，与 fetch::Error 同一教训）
class Error : public std::exception {
public:
    Error(error_kind kind, std::string message, std::optional<int> status = std::nullopt)
        : kind_(kind), message_(std::move(message)), status_(status)
    {
    }

    error_kind kind() const noexcept { return kind_; }
    std::optional<int> status() const noexcept { return status_; }
    const char* what() const noexcept override { return message_.c_str(); }

    bool is_timeout() const noexcept { return kind_ == error_kind::timeout; }
    bool is_network() const noexcept { return kind_ == error_kind::network; }
    bool is_decode() const noexcept { return kind_ == error_kind::decode; }
    bool is_status() const noexcept { return kind_ == error_kind::http_status; }

private:
    error_kind kind_;
    std::string message_;
    std::optional<int> status_;
};

// ===================== 6.3 retry_policy =====================

struct retry_policy {
    int max_retries = 2; // 额外尝试次数（不含首发）

    // 指数退避：delay_n = min(max_delay, base * factor^n)，±jitter 抖动
    std::chrono::milliseconds base_delay{100};
    std::chrono::milliseconds max_delay{10'000};
    double factor = 2.0;
    bool jitter = true;

    bool respect_retry_after = true;   // 429/503 带 Retry-After 时优先采用（封顶 max_delay）
    bool retry_non_idempotent = false; // 默认只重试幂等方法

    // 分类规则（可用回调覆盖；空 = 用默认规则）
    std::function<bool(const Error&)> should_retry_error_override;
    std::function<bool(int)> should_retry_status_override;

    // 默认错误规则：timeout/network 可重试；decode/url/policy/http_status 不可
    bool should_retry_error(error_kind k) const
    {
        if (should_retry_error_override)
            return should_retry_error_override(Error(k, "retry probe"));
        return k == error_kind::timeout || k == error_kind::network;
    }

    // 默认状态码规则：408/429/5xx 可重试，其余不可
    bool should_retry_status(int status) const
    {
        if (should_retry_status_override)
            return should_retry_status_override(status);
        return status == 408 || status == 429 || (status >= 500 && status <= 599);
    }

    // 幂等方法判断（默认只重试幂等方法）
    static bool is_idempotent_method(std::string_view method)
    {
        return method == "GET" || method == "HEAD" || method == "PUT" ||
               method == "DELETE" || method == "OPTIONS";
    }

    // 第 attempt 次重试（0-based）前的等待时长；retry_after 为响应头值（秒）
    std::chrono::milliseconds delay_for(int attempt, std::optional<int> retry_after) const
    {
        if (respect_retry_after && retry_after && *retry_after > 0) {
            // long long 防恶意超大值溢出（有符号 int 溢出是 UB）
            auto d = std::chrono::milliseconds(static_cast<long long>(*retry_after) * 1000);
            return d > max_delay ? max_delay : d;
        }
        double mult = 1.0;
        for (int i = 0; i < attempt; ++i)
            mult *= factor;
        auto d = std::chrono::duration_cast<std::chrono::milliseconds>(base_delay * mult);
        if (d > max_delay)
            d = max_delay;
        if (jitter && attempt > 0) {
            // 确定性伪随机抖动（±20%）：避免重试风暴
            auto seed = static_cast<unsigned>(attempt) * 2654435761u;
            double frac = static_cast<double>(seed % 100) / 100.0 * 0.4 - 0.2;
            d += std::chrono::duration_cast<std::chrono::milliseconds>(d * frac);
        }
        return d;
    }
};

// ===================== 内部设施 =====================

namespace detail {

inline std::string url_encode(std::string_view s)
{
    static const char* hex = "0123456789ABCDEF";
    std::string out;
    out.reserve(s.size());
    for (unsigned char c : s) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            out += static_cast<char>(c);
        } else {
            out += '%';
            out += hex[c >> 4];
            out += hex[c & 15];
        }
    }
    return out;
}

// form-urlencode（application/x-www-form-urlencoded 序列化）：空格 → '+'
// 其余非 unreserved → %XX（与绑定层 UrlSearchParams 序列化惯例一致）
inline std::string form_urlencode(std::string_view s)
{
    std::string out;
    out.reserve(s.size());
    for (unsigned char c : s) {
        if (c == ' ') {
            out += '+';
        } else if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            out += static_cast<char>(c);
        } else {
            out += '%';
            out += "0123456789ABCDEF"[c >> 4];
            out += "0123456789ABCDEF"[c & 15];
        }
    }
    return out;
}

// 把 query 参数拼到 URL 上（form-urlencode；已有 ? 用 & 续接；
// fragment(#...) 必须保持在末尾——query 插在 fragment 之前）
inline std::string append_query(
    std::string url,
    const std::vector<std::pair<std::string, std::string>>& params)
{
    const size_t frag = url.find('#');
    std::string prefix = url.substr(0, frag);
    const std::string suffix = frag == std::string::npos ? "" : url.substr(frag);
    for (const auto& [k, v] : params) {
        prefix += (prefix.find('?') == std::string::npos ? "?" : "&");
        prefix += url_encode(k);
        prefix += "=";
        prefix += url_encode(v);
    }
    return prefix + suffix;
}

// ---- body 消费（异步部分；resp 按值拷入协程帧，不依赖调用方 this 存活）----
inline std_exec::task<std::string> read_text(fetch::Response resp)
{
    co_return co_await fetch::read_all(resp);
}

// 超时版整读（§6.2-5 deadline 全程语义）：剩余预算 ≤ 0 直接抛 timeout；
// 否则 when_any(整读, sleep) 竞速，超时后 cancel() 拆底层连接。
// io 由调用方显式下传（发起线程捕获后固化；消费可能在任意线程，
// 不得在消费时重新 thread_io()——Response 跨线程消费契约，见 review）。
inline std_exec::task<std::string> read_text_deadline(fetch::Response resp,
                                                      boost::asio::io_context& io,
                                                      std::chrono::milliseconds remain)
{
    if (remain.count() <= 0)
        throw Error(error_kind::timeout, "body not consumed within deadline");
    auto env_tok = co_await stdexec::get_stop_token();
    std::stop_source src;
    stdexec::stop_callback_for_t<decltype(env_tok), std::function<void()>> bridge{
        env_tok, [&src] { src.request_stop(); }};
    try {
        co_return co_await exec::when_any(
            fetch::read_all(resp),
            dcb::sleep(remain, dcb::IoContextScheduler(io)) | stdexec::then([]() -> std::string {
                throw Error(error_kind::timeout, "body read timed out");
            }));
    } catch (const Error& e) {
        if (e.is_timeout() && resp.body)
            resp.body->cancel(); // 拆底层连接，挂起的 read 即刻终止（幂等）
        throw;
    } catch (const boost::system::system_error& e) {
        throw Error(error_kind::network, e.what()); // 消费阶段错误分类（§4.1）
    } catch (const fetch::Error& e) {
        throw Error(error_kind::policy, e.what()); // 如 SRI 校验失败
    } catch (const std::exception& e) {
        throw Error(error_kind::decode, e.what());
    }
}

inline std_exec::task<std::vector<std::byte>> read_bytes(fetch::Response resp,
                                                         boost::asio::io_context& io,
                                                         std::chrono::milliseconds remain)
{
    std::string s = co_await read_text_deadline(std::move(resp), io, remain);
    std::vector<std::byte> out(s.size());
    std::memcpy(out.data(), s.data(), s.size());
    co_return out;
}

inline std_exec::task<std::vector<std::byte>> read_bytes_plain(fetch::Response resp)
{
    std::string s = co_await fetch::read_all(resp);
    std::vector<std::byte> out(s.size());
    std::memcpy(out.data(), s.data(), s.size());
    co_return out;
}

#ifndef FETCH_EASY_NO_JSON
template <typename T>
std_exec::task<T> read_json_plain(fetch::Response resp)
{
    std::string s = co_await fetch::read_all(resp);
    auto res = glz::read_json<T>(s);
    if (!res) {
        std::string msg = s.empty() ? std::string("empty body")
                                    : glz::format_error(res.error(), s);
        throw Error(error_kind::decode, "json decode failed: " + msg);
    }
    co_return std::move(*res);
}

template <typename T>
std_exec::task<T> read_json(fetch::Response resp, boost::asio::io_context& io,
                            std::chrono::milliseconds remain)
{
    std::string s = co_await read_text_deadline(std::move(resp), io, remain);
    auto res = glz::read_json<T>(s);
    if (!res) {
        std::string msg = s.empty() ? std::string("empty body")
                                    : glz::format_error(res.error(), s);
        throw Error(error_kind::decode, "json decode failed: " + msg);
    }
    co_return std::move(*res);
}
#endif

} // namespace detail

// ===================== 4.4 Response =====================

class Response {
public:
    // io 仅用于 deadline 计时，必须在**发起线程**固化（消费可能在任意线程，
    // 不得在消费时重新 thread_io()）；deadline 为空 = 无超时约束
    Response(fetch::Response resp, boost::asio::io_context& io,
             std::optional<std::chrono::steady_clock::time_point> deadline)
        : resp_(std::move(resp)), io_(&io), deadline_(deadline)
    {
    }

    int status() const noexcept { return resp_.status; }
    bool ok() const noexcept { return status() >= 200 && status() < 300; }
    const fetch::Headers& headers() const noexcept { return resp_.headers; }
    const std::string& url() const noexcept { return resp_.url; }
    bool redirected() const noexcept { return resp_.redirected; }

    // 4xx/5xx → 抛 Error{http_status}，否则返回 *this（便于链式：
    // resp.error_for_status().json<T>()）
    Response& error_for_status() &
    {
        if (status() >= 400)
            throw Error(error_kind::http_status,
                        "http status " + std::to_string(status()), status());
        return *this;
    }

    // body 整读一次；重复消费抛 Error{policy}。消费只依赖自身 BodySource
    //（协程帧自持 resp 拷贝），不依赖本对象存活。受 deadline 约束（§6.2-5
    // 全程语义）：剩余预算耗尽 → 抛 timeout 并 cancel() 拆底层连接。
    std_exec::task<std::string> text()
    {
        if (consumed_)
            throw Error(error_kind::policy, "body already consumed");
        consumed_ = true;
        if (!deadline_)
            return detail::read_text(resp_);
        auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(
            *deadline_ - std::chrono::steady_clock::now());
        return detail::read_text_deadline(resp_, *io_, remain);
    }

    std_exec::task<std::vector<std::byte>> bytes()
    {
        if (consumed_)
            throw Error(error_kind::policy, "body already consumed");
        consumed_ = true;
        if (!deadline_)
            return detail::read_bytes_plain(resp_);
        auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(
            *deadline_ - std::chrono::steady_clock::now());
        return detail::read_bytes(resp_, *io_, remain);
    }

#ifndef FETCH_EASY_NO_JSON
    template <typename T>
    std_exec::task<T> json()
    {
        if (consumed_)
            throw Error(error_kind::policy, "body already consumed");
        consumed_ = true;
        if (!deadline_)
            return detail::read_json_plain<T>(resp_);
        const auto remain = std::chrono::duration_cast<std::chrono::milliseconds>(
            *deadline_ - std::chrono::steady_clock::now());
        return detail::read_json<T>(resp_, *io_, remain);
    }
#endif

    // 逃生舱：底层 fetch::Response（流式 BodySource 在这里）
    const fetch::Response& raw() const noexcept { return resp_; }

    // 取消消费：放弃读取时调（转调 BodySource::cancel，幂等）
    void cancel() noexcept
    {
        if (resp_.body)
            resp_.body->cancel();
    }

private:
    fetch::Response resp_;
    bool consumed_ = false;
    boost::asio::io_context* io_ = nullptr; // 仅 deadline 计时（非拥有）
    std::optional<std::chrono::steady_clock::time_point> deadline_;
};

// ===================== 4.2 Client =====================

class ClientBuilder;
class RequestBuilder;

// 请求默认值快照（Client 持有，构造 RequestBuilder 时值拷入）
struct client_config {
    std::string user_agent;
    fetch::Headers default_headers;
    std::chrono::milliseconds timeout{0}; // 0 = 不超时（默认）
    retry_policy retry;
    bool retry_set = false;
};

class Client {
public:
    static ClientBuilder builder();

    // 由 ClientBuilder::build() 构造；transport 为空 → 默认 BeastTransport。
    // io_context 由内部 fetch::Client 从当前线程 thread_local 取。
    Client(fetch::Options opt, std::shared_ptr<fetch::Transport> transport,
           client_config cfg);

    RequestBuilder get(std::string url);
    RequestBuilder post(std::string url);
    RequestBuilder put(std::string url);
    RequestBuilder patch(std::string url);
    RequestBuilder del(std::string url); // delete 是关键字
    RequestBuilder head(std::string url);

    // 逃生舱：直接暴露底层。fetch() 非常量成员，故返回非 const 引用
    //（设计文档 §4.2 的 const 微调，接口等价）
    fetch::Client& core() noexcept { return core_; }

private:
    friend class RequestBuilder;
    fetch::Client core_;
    client_config cfg_;
};

// ===================== 4.3 RequestBuilder =====================

class RequestBuilder {
public:
    // 值拷入 Client（含 fetch::Client：transport 为 shared_ptr，拷贝轻量）；
    // 默认头先铺，逐请求头后追加；Client 默认 timeout/retry 一并拷入
    //（逐请求 .timeout()/.retry() 覆盖）
    RequestBuilder(Client client, std::string method, std::string url)
        : client_(std::move(client)), method_(std::move(method)), url_(std::move(url))
    {
        for (const auto& h : client_.cfg_.default_headers)
            headers_.push_back(h);
        timeout_ = client_.cfg_.timeout; // Client 默认超时（0 = 不超时）
        retry_ = client_.cfg_.retry;     // Client 默认重试策略
        retry_set_ = client_.cfg_.retry_set;
    }

    RequestBuilder& header(std::string name, std::string value)
    {
        headers_.push_back({std::move(name), std::move(value)});
        return *this;
    }

    // 逐请求 UA 语法糖：等价 .header("User-Agent", v)。替换已有的
    // User-Agent 头（不残留重复项）；覆盖 ClientBuilder::user_agent() 默认值
    //（固化时 has_header 命中即不再填默认；transport 层默认 UA 同样缺省才填）。
    RequestBuilder& user_agent(std::string v)
    {
        headers_.erase(
            std::remove_if(headers_.begin(), headers_.end(),
                           [](const fetch::Header& h) { return fetch::header_name_eq(h.name, "User-Agent"); }),
            headers_.end());
        headers_.push_back({"User-Agent", std::move(v)});
        return *this;
    }

    RequestBuilder& bearer_auth(std::string_view token)
    {
        headers_.push_back({"Authorization", "Bearer " + std::string(token)});
        return *this;
    }

    RequestBuilder& basic_auth(std::string_view user, std::string_view pass)
    {
        headers_.push_back({"Authorization",
                            "Basic " + fetch::base64_encode(std::string(user) + ":" + std::string(pass))});
        return *this;
    }

    // form-urlencode 后拼到 URL（send 时固化）
    RequestBuilder& query(
        std::initializer_list<std::pair<std::string, std::string>> params)
    {
        for (const auto& [k, v] : params)
            query_parts_.emplace_back(k, v);
        return *this;
    }

#ifndef FETCH_EASY_NO_JSON
    // glaze 序列化 + 自动 Content-Type: application/json（仅当未手动设置）
    template <typename T>
    RequestBuilder& json(const T& obj)
    {
        auto res = glz::write_json(obj);
        if (!res) {
            json_error_ = "glaze write_json failed: ";
            json_error_ += res.error().custom_error_message.empty()
                               ? "serialization error"
                               : res.error().custom_error_message;
            return *this;
        }
        body_ = std::move(*res);
        body_set_ = true;
        auto_ct_ = "application/json";
        body_stream_.reset();
        body_size_ = 0;
        return *this;
    }
#endif

    // 手动请求体（逃生舱）：不自动补 Content-Type（auto_ct_ 清空）
    RequestBuilder& body(std::string b)
    {
        body_ = std::move(b);
        body_set_ = true;
        auto_ct_.clear();
        json_error_.clear();
        body_error_.clear();
        body_stream_.reset();
        body_size_ = 0;
        return *this;
    }

    // form-urlencoded body（application/x-www-form-urlencoded）：k=v&k2=v2，
    // 空格 → '+'（与 UrlSearchParams 序列化一致）；自动 Content-Type（缺省才填）
    RequestBuilder& form_urlencoded(
        std::initializer_list<std::pair<std::string, std::string>> params)
    {
        std::string b;
        for (const auto& [k, v] : params) {
            if (!b.empty())
                b += '&';
            b += detail::form_urlencode(k);
            b += '=';
            b += detail::form_urlencode(v);
        }
        body_ = std::move(b);
        body_set_ = true;
        auto_ct_ = "application/x-www-form-urlencoded";
        json_error_.clear();
        body_error_.clear();
        body_stream_.reset();
        body_size_ = 0;
        return *this;
    }

    // 原始字节 body + 自动 Content-Type: application/octet-stream（缺省才填）
    RequestBuilder& octet_stream(std::string data)
    {
        body_ = std::move(data);
        body_set_ = true;
        auto_ct_ = "application/octet-stream";
        json_error_.clear();
        body_error_.clear();
        body_stream_.reset();
        body_size_ = 0;
        return *this;
    }

    // multipart/form-data（reqwest::multipart::Form 风格，见 fetch/easy/form.hpp）：
    // 流式编码（MultipartEncoder，BodySource）——文件 part 不整读进内存，预计算总长
    // 走 Content-Length；自动 Content-Type: multipart/form-data; boundary=...
    //（仅当未手动设置 Content-Type 时；显式 header 永远优先，§7 同 json）。
    // 文件打不开/无大小 → 错误透传到 send 时抛 easy::Error(decode)。
    RequestBuilder& multipart(Form form)
    {
        // 与 .json() 等互斥：auto_ct_ 单字段天然覆盖；残留序列化错误一并清
        json_error_.clear();
        body_error_.clear();
        // 显式 Content-Type 若带 boundary，用它编码——声明与实体一致（review
        // should-fix）；否则生成随机 boundary（send 时缺省才填）
        std::string boundary;
        const auto ct = std::find_if(headers_.begin(), headers_.end(),
                                     [](const fetch::Header& h) {
                                         return fetch::header_name_eq(h.name, "Content-Type");
                                     });
        if (ct != headers_.end())
            boundary = fetch::extract_boundary(ct->value);
        if (boundary.empty())
            boundary = form.boundary();
        // 组装 MultipartEncoder：内存 part（text/bytes）+ 流式文件 part
        std::vector<fetch::MultipartEncoder::Part> mp;
        mp.reserve(form.parts().size() + form.files().size());
        for (const auto& [name, part] : form.parts()) {
            const auto e = part.to_entry();
            mp.push_back({name, e.filename, e.type, e.bytes, {}, e.bytes.size()});
        }
        for (const auto& f : form.files()) {
            const std::string mime = f.mime.empty() ? Form::guess_mime(f.path) : f.mime;
            mp.push_back({f.name, Form::file_basename(f.path), mime, {}, f.path, 0});
        }
        auto enc = fetch::MultipartEncoder::create(boundary, std::move(mp));
        if (!enc) {
            body_error_ = "multipart Form::file 无法打开或获取大小";
            return *this;
        }
        body_size_ = enc->total_size();
        body_stream_ = std::make_shared<fetch::MultipartEncoder>(std::move(*enc));
        body_.clear();
        body_set_ = true;
        auto_ct_ = "multipart/form-data; boundary=" + boundary;
        return *this;
    }

    RequestBuilder& timeout(std::chrono::milliseconds d)
    {
        timeout_ = d;
        timeout_set_ = true;
        return *this;
    }

    RequestBuilder& retry(retry_policy p)
    {
        retry_ = std::move(p);
        retry_set_ = true;
        return *this;
    }

    RequestBuilder& redirect(fetch::Request::Redirect r)
    {
        redirect_ = r;
        return *this;
    }

    RequestBuilder& integrity(std::string sri)
    {
        integrity_ = std::move(sri);
        return *this;
    }

    // 惰性：不 co_await / connect 就不发请求。普通函数（非协程）——
    // 协程帧在调用点按值固化全部状态，RequestBuilder 析构不影响在飞请求。
    std_exec::task<Response> send();

private:
    Client client_; // 值拷贝（含 fetch::Client）
    std::string method_;
    std::string url_;
    fetch::Headers headers_;
    std::string body_;
    bool body_set_ = false;
    std::string json_error_; // .json() 序列化失败记录（send 时抛 decode）
    std::string body_error_;          // .multipart() 的 Form::file 失败（send 时抛 decode）
    std::string auto_ct_;             // 非空 = body 来自自动 Content-Type 的方法（json/
                                      // multipart/form_urlencoded/octet_stream；send 时缺省才填）
    std::shared_ptr<fetch::BodySource> body_stream_; // 流式请求体（multipart 流式；nullptr = 无）
    size_t body_size_ = 0;            // 流式体总长（Content-Length；body_stream_ 时 >0）
    std::vector<std::pair<std::string, std::string>> query_parts_;
    std::chrono::milliseconds timeout_{0};
    bool timeout_set_ = false;
    retry_policy retry_;
    bool retry_set_ = false;
    fetch::Request::Redirect redirect_ = fetch::Request::Redirect::follow;
    std::string integrity_;
};

// ===================== 4.2 ClientBuilder =====================

class ClientBuilder {
public:
    ClientBuilder& user_agent(std::string v)
    {
        cfg_.user_agent = std::move(v);
        return *this;
    }

    ClientBuilder& default_header(std::string name, std::string value)
    {
        cfg_.default_headers.push_back({std::move(name), std::move(value)});
        return *this;
    }

    ClientBuilder& timeout(std::chrono::milliseconds d)
    {
        cfg_.timeout = d;
        return *this;
    }

    ClientBuilder& retry(retry_policy p)
    {
        cfg_.retry = std::move(p);
        cfg_.retry_set = true;
        return *this;
    }

    ClientBuilder& options(fetch::Options opt)
    {
        opt_ = std::move(opt);
        return *this;
    }

    // ---- 连接池配置（对齐 reqwest 命名；docs/fetch_connection_pool_design.md §3.10）----
    // 空闲连接超时（nullopt = 永不过期）。默认 90s；若目标服务端 keep-alive 超时
    // 更短（如 nginx 默认 75s），调小本值可减少首包重试（重试由池自动吸收）。
    ClientBuilder& pool_idle_timeout(std::optional<std::chrono::milliseconds> d)
    {
        opt_.pool.idle_timeout = d;
        return *this;
    }

    // 每 host 最大空闲连接数（0 = 关闭连接池，等价 reqwest 的同名语义）。
    ClientBuilder& pool_max_idle_per_host(size_t n)
    {
        opt_.pool.max_idle_per_host = n;
        return *this;
    }

    ClientBuilder& use(std::shared_ptr<fetch::Middleware> mw)
    {
        mws_.push_back(std::move(mw));
        return *this;
    }

    ClientBuilder& transport(std::shared_ptr<fetch::Transport> t)
    {
        transport_ = std::move(t);
        return *this;
    }

    Client build();

private:
    friend class Client;
    ClientBuilder() = default;

    fetch::Options opt_;
    std::shared_ptr<fetch::Transport> transport_;
    client_config cfg_;
    std::vector<std::shared_ptr<fetch::Middleware>> mws_;
};

// ===================== 实现 =====================

inline ClientBuilder Client::builder()
{
    return ClientBuilder();
}

inline Client::Client(fetch::Options opt, std::shared_ptr<fetch::Transport> transport,
                      client_config cfg)
    : core_(transport ? fetch::Client(std::move(transport), std::move(opt))
                      : fetch::Client(std::move(opt))),
      cfg_(std::move(cfg))
{
}

inline Client ClientBuilder::build()
{
    Client c(std::move(opt_), std::move(transport_), std::move(cfg_));
    for (auto& mw : mws_)
        c.core().use(std::move(mw));
    return c;
}

inline RequestBuilder Client::get(std::string url)
{
    return RequestBuilder(*this, "GET", std::move(url));
}

inline RequestBuilder Client::post(std::string url)
{
    return RequestBuilder(*this, "POST", std::move(url));
}

inline RequestBuilder Client::put(std::string url)
{
    return RequestBuilder(*this, "PUT", std::move(url));
}

inline RequestBuilder Client::patch(std::string url)
{
    return RequestBuilder(*this, "PATCH", std::move(url));
}

inline RequestBuilder Client::del(std::string url)
{
    return RequestBuilder(*this, "DELETE", std::move(url));
}

inline RequestBuilder Client::head(std::string url)
{
    return RequestBuilder(*this, "HEAD", std::move(url));
}

namespace detail {

// 单次请求 + 超时（§6.2）：when_any(请求, sleep)。
// - 定时器走 dcb::sleep + IoContextScheduler(io)（io 线程完成，保持单线程契约）
// - 分支签名对齐：定时器分支 then 返回 fetch::Response（永不正常返回）
// - 取消桥接：env 的 inplace_stop_token → std::stop_source（§6.2-4），
//   when_any 判负 → 传输层 socket cancel（Client 文档化取消路径）
// - d <= 0：零开销直通（不组 when_any）
inline std_exec::task<fetch::Response> with_timeout(fetch::Client& core,
                                                    boost::asio::io_context& io,
                                                    fetch::Request req,
                                                    std::chrono::milliseconds d)
{
    if (d.count() <= 0)
        co_return co_await core.fetch(std::move(req));
    auto env_tok = co_await stdexec::get_stop_token();
    std::stop_source src;
    auto bridge_fn = [&src] { src.request_stop(); };
    stdexec::stop_callback_for_t<decltype(env_tok), decltype(bridge_fn)> bridge{
        env_tok, std::move(bridge_fn)};
    co_return co_await exec::when_any(
        core.fetch(std::move(req), src.get_token()),
        dcb::sleep(d, dcb::IoContextScheduler(io)) | stdexec::then([]() -> fetch::Response {
            throw Error(error_kind::timeout, "request timed out");
        }));
}

// 重试（§6.3）：工厂形态——sender 是单发的，重试必须「重新构造一个新操作」，
// 故算子吃工厂（每次调用产出一次全新尝试）而非吃 sender。协程循环落地：
//   - 状态码可重试 → 按 Retry-After/退避等待后进入下一轮
//   - Error 可重试（timeout/network）→ 退避后下一轮
//   - set_stopped 不经 catch：沿协程链传播，绝不重试
template <typename Factory>
std_exec::task<Response> retry(Factory make_attempt, retry_policy policy)
{
    auto& io = fetch::thread_io(); // 退避定时器用；入口捕获，协程内固定
    for (int attempt = 0;; ++attempt) {
        std::chrono::milliseconds delay{0};
        try {
            Response resp = co_await make_attempt();
            if (!policy.should_retry_status(resp.status()) || attempt >= policy.max_retries)
                co_return resp;
            // 状态码可重试：先按 Retry-After/退避等待，再进入下一轮
            std::optional<int> retry_after;
            if (policy.respect_retry_after) {
                for (const auto& h : resp.headers())
                    if (fetch::header_name_eq(h.name, "Retry-After")) {
                        try {
                            retry_after = std::stoi(h.value);
                        } catch (...) {
                        }
                        break;
                    }
            }
            delay = policy.delay_for(attempt, retry_after);
        } catch (const Error& e) {
            if (!policy.should_retry_error(e.kind()) || attempt >= policy.max_retries)
                throw;
            delay = policy.delay_for(attempt, std::nullopt);
        }
        // 协程限制：co_await 不能在 catch handler 内——退避统一放 try 外
        co_await dcb::sleep(delay, dcb::IoContextScheduler(io));
    }
}

// 单次尝试：固化 Request → 校验 → fetch（E3：带超时）。io 在发起线程入口
// 取 thread_local（send 链第一步，发起线程已 set）并显式下传——协程恢复后
// 不再重新 thread_io()（见 read_* 注释）。
inline std_exec::task<Response> attempt_once(
    Client client, std::string method, std::string url,
    fetch::Headers headers, std::string body, bool body_set,
    std::shared_ptr<fetch::BodySource> body_stream, size_t body_size,
    std::string json_error, std::string body_error, std::string auto_ct,
    fetch::Request::Redirect redirect,
    std::string integrity,
    std::vector<std::pair<std::string, std::string>> query_parts,
    std::string user_agent, std::chrono::milliseconds timeout)
{
    auto& io = fetch::thread_io();
    // 1. URL 校验（§4.3：send 时校验，错误出口统一在 co_await 处）
    url = append_query(std::move(url), query_parts);
    auto parsed = ada::parse<ada::url_aggregator>(url);
    if (!parsed)
        throw Error(error_kind::url, "invalid URL: " + url);
    const std::string_view scheme = parsed->get_protocol();
    if (scheme != "http:" && scheme != "https:" && scheme != "data:")
        throw Error(error_kind::url, "unsupported scheme: " + std::string(scheme));
    // userinfo（user:pass@）显式拒绝（L4，与 transport 层 parse_url 一致；
    // 对齐 WHATWG fetch "URL includes credentials"）
    if (!parsed->get_username().empty() || !parsed->get_password().empty())
        throw Error(error_kind::url,
                    "URL includes credentials, use the Authorization header instead: " + url);

    // 2. GET/HEAD 禁 body（与 fetchcore 语义对齐；含流式 body）
    if ((method == "GET" || method == "HEAD") && ((body_set && !body.empty()) || body_stream))
        throw Error(error_kind::policy, "GET/HEAD must not carry a body");

    // 3. .json() / .multipart() 序列化或读取失败 → send 时统一抛 decode
    if (!json_error.empty())
        throw Error(error_kind::decode, std::move(json_error));
    if (!body_error.empty())
        throw Error(error_kind::decode, std::move(body_error));

    // 4. 固化 fetch::Request（默认头已铺；User-Agent 缺省才填）
    fetch::Request req;
    req.method = std::move(method);
    req.url = std::move(url);
    req.headers = std::move(headers);
    if (!user_agent.empty() && !fetch::has_header(req.headers, "User-Agent"))
        req.headers.push_back({"User-Agent", std::move(user_agent)});
    // 自动 Content-Type（.json()/.multipart()/.form_urlencoded()/.octet_stream()）：
    // 仅在缺省时填（显式设置永远优先，§7）
    if (!auto_ct.empty() && !fetch::has_header(req.headers, "Content-Type"))
        req.headers.push_back({"Content-Type", auto_ct});
    req.body = std::move(body);
    req.body_stream = std::move(body_stream);
    req.body_size = body_size;
    req.integrity = std::move(integrity);
    req.redirect = redirect;

    // 5. 发请求（错误分类映射，§4.1：catch 顺序即分类顺序；带超时 E3）
    fetch::Response resp;
    try {
        resp = co_await detail::with_timeout(client.core(), io, std::move(req), timeout);
    } catch (const Error&) {
        throw; // 本层错误原样传播
    } catch (const boost::system::system_error& e) {
        throw Error(error_kind::network, e.what());
    } catch (const fetch::Error& e) {
        throw Error(error_kind::policy, e.what());
    } catch (const std::exception& e) {
        throw Error(error_kind::decode, e.what());
    }
    // deadline 全程语义（§6.2-5）：请求发出 → body 消费完
    std::optional<std::chrono::steady_clock::time_point> deadline;
    if (timeout.count() > 0)
        deadline = std::chrono::steady_clock::now() + timeout;
    co_return Response(std::move(resp), io, deadline);
}

} // namespace detail

inline std_exec::task<Response> RequestBuilder::send()
{
    // 全部状态在调用点按值拷入协程帧（本对象可立即析构）
    const bool idempotent = retry_policy::is_idempotent_method(method_);
    if (retry_set_ && (retry_.retry_non_idempotent || idempotent)) {
        // 重试：工厂每次重建完整 Request（body 值语义可安全重放，§6.3）
        auto client = client_;
        auto method = method_;
        auto url = url_;
        auto headers = headers_;
        auto body = body_;
        auto body_set = body_set_;
        auto body_stream = body_stream_;
        auto body_size = body_size_;
        auto json_error = json_error_;
        auto body_error = body_error_;
        auto auto_ct = auto_ct_;
        auto redirect = redirect_;
        auto integrity = integrity_;
        auto query_parts = query_parts_;
        auto user_agent = client_.cfg_.user_agent;
        auto timeout = timeout_;
        auto policy = retry_;
        return detail::retry(
            [=] {
                return detail::attempt_once(client, method, url, headers, body, body_set,
                                            body_stream, body_size,
                                            json_error, body_error, auto_ct,
                                            redirect, integrity,
                                            query_parts, user_agent, timeout);
            },
            std::move(policy));
    }
    return detail::attempt_once(
        client_, method_, url_, headers_, body_, body_set_,
        body_stream_, body_size_,
        json_error_, body_error_, auto_ct_, redirect_, integrity_, query_parts_,
        client_.cfg_.user_agent, timeout_);
}

// ===================== 一次性用法（§3 快速上手） =====================

inline RequestBuilder get(std::string url)
{
    return Client::builder().build().get(std::move(url));
}

// ===================== 6.3 公开重试算子 =====================
// easy::retry(factory, policy)：factory 每次调用产出一次全新尝试
//（sender 单发，重试必须重新构造操作）。超时是每次尝试独立计时（§6.4：
// 组合顺序 = retry 包住带超时的单次尝试；要总预算语义请在最外层再组
// when_any）。set_stopped 沿协程链传播，绝不重试。
template <typename Factory>
std_exec::task<Response> retry(Factory make_attempt, retry_policy policy)
{
    return detail::retry(std::move(make_attempt), std::move(policy));
}

} // namespace easy
} // namespace fetch
