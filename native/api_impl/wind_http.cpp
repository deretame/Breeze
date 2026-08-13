// WindHttpClient：fetch::easy（fetchcore）实现的 HTTP 客户端桥接。
//
// 线程契约：fetch::easy 只能从跑 io.run() 且已 fetch::set_thread_io() 的
// 线程使用。BRIDGE_ASYNC 协程体恒在 dcb io 线程执行，因此：
//   - 每个协程入口 ensure_fetch_io()（thread_local，幂等，只设一次）；
//   - 底层 easy::Client 惰性构造于首次请求（不能在 Dart 调用线程的构造
//     函数里建——BeastTransport 构造时要从 thread_local 取 io_context）；
//   - 析构把 client post 回 io 线程释放（socket/连接池不跨线程析构）。
#include "bridge_api.h"

#include <fetch/easy.hpp>
#include <fetch/types.hpp>

#include <boost/asio/post.hpp>

#include <chrono>
#include <cctype>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <utility>

namespace {

// thread_local，io 线程上只需设置一次
void ensure_fetch_io()
{
    if (!fetch::has_thread_io()) {
        fetch::set_thread_io(dcb::Runtime::instance().io());
    }
}

// 重名 header 以 ", " 合并（对齐 reqwest 行为），key 保留首次出现的大小写
std::unordered_map<std::string, std::string> to_header_map(const fetch::Headers& headers)
{
    std::unordered_map<std::string, std::string> out;
    std::unordered_map<std::string, std::string> lower_to_key;
    for (const auto& h : headers) {
        std::string lower = h.name;
        for (auto& c : lower)
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        auto it = lower_to_key.find(lower);
        if (it == lower_to_key.end()) {
            lower_to_key.emplace(lower, h.name);
            out.emplace(h.name, h.value);
        } else {
            out[it->second] += ", " + h.value;
        }
    }
    return out;
}

std::int64_t content_length_of(const fetch::Headers& headers)
{
    for (const auto& h : headers) {
        if (fetch::header_name_eq(h.name, "Content-Length")) {
            try {
                return std::stoll(h.value);
            } catch (...) {
                return -1;
            }
        }
    }
    return -1;
}

} // namespace

WindHttpClient::WindHttpClient(
    std::unordered_map<std::string, std::string> default_headers,
    std::int64_t timeout_ms, bool follow_redirects, std::string proxy,
    bool tls_verify, std::string user_agent)
    : default_headers_(std::move(default_headers))
    , timeout_ms_(timeout_ms)
    , follow_redirects_(follow_redirects)
    , proxy_(std::move(proxy))
    , tls_verify_(tls_verify)
    , user_agent_(std::move(user_agent))
{
}

WindHttpClient::~WindHttpClient()
{
    if (!client_)
        return;
    // 连接池 / socket 必须在 io 线程释放；Dart 侧 NativeFinalizer 触发
    // drop 的线程不确定，post 回 io 线程销毁。runtime 已停则放任泄漏
    //（进程退出路径，无实际影响）。
    auto client = std::move(client_);
    try {
        boost::asio::post(dcb::Runtime::instance().io(),
                          [c = std::move(client)]() mutable { c.reset(); });
    } catch (...) {
    }
}

fetch::easy::Client& WindHttpClient::ensure_client()
{
    if (client_)
        return *client_;
    fetch::Options opt;
    opt.tls.verify = tls_verify_;
    if (proxy_.empty()) {
        // 空 = 强制直连（"*" 直连路由优先于实例级/进程级代理）
        opt.proxy_routes = {{"*", std::nullopt}};
    } else {
        auto p = fetch::Proxy::parse(proxy_);
        if (!p)
            throw std::runtime_error("invalid proxy: " + proxy_);
        opt.proxy = *p;
    }
    auto builder = fetch::easy::Client::builder().options(std::move(opt));
    if (timeout_ms_ > 0)
        builder.timeout(std::chrono::milliseconds{timeout_ms_});
    for (const auto& [k, v] : default_headers_)
        builder.default_header(k, v);
    if (!user_agent_.empty())
        builder.user_agent(user_agent_);
    client_ = std::make_shared<fetch::easy::Client>(builder.build());
    return *client_;
}

fetch::easy::RequestBuilder WindHttpClient::make_request(std::string url,
                                                         const WindFetchInit& init)
{
    auto& client = ensure_client();
    fetch::easy::RequestBuilder rb(client, init.method.empty() ? "GET" : init.method,
                                   std::move(url));
    for (const auto& [k, v] : init.headers)
        rb.header(k, v);
    if (!init.body.empty()) {
        rb.body(std::string(reinterpret_cast<const char*>(init.body.data()),
                            init.body.size()));
    }
    if (init.timeout_ms > 0)
        rb.timeout(std::chrono::milliseconds{init.timeout_ms});
    const bool follow = init.follow_redirects.value_or(follow_redirects_);
    rb.redirect(follow ? fetch::Request::Redirect::follow
                       : fetch::Request::Redirect::passthrough);
    return rb;
}

stdexec::task<WindFetchResponse> WindHttpClient::fetch(std::string url,
                                                       WindFetchInit init)
{
    ensure_fetch_io();
    auto rb = make_request(std::move(url), init);
    auto resp = co_await rb.send();
    auto bytes = co_await resp.bytes();

    WindFetchResponse out;
    out.status = resp.status();
    out.status_text = resp.raw().reason;
    out.headers = to_header_map(resp.headers());
    out.url = std::string(resp.url());
    out.redirected = resp.redirected();
    out.body.resize(bytes.size());
    if (!bytes.empty())
        std::memcpy(out.body.data(), bytes.data(), bytes.size());
    co_return out;
}

stdexec::task<void> WindHttpClient::download(
    std::string url, std::string save_path, WindFetchInit init,
    std::optional<dcb::StreamSink<WindDownloadProgress>> progress)
{
    ensure_fetch_io();
    auto rb = make_request(std::move(url), init);
    auto resp = co_await rb.send();

    namespace fs = std::filesystem;
    const fs::path target(save_path);
    const fs::path part = target.string() + ".part";
    std::ofstream out(part, std::ios::binary | std::ios::trunc);
    if (!out)
        throw std::runtime_error("download: cannot open " + part.string());

    const std::int64_t total = content_length_of(resp.headers());
    std::int64_t received = 0;
    auto& body = resp.raw().body;
    if (body) {
        for (;;) {
            auto chunk = co_await body->read();
            if (!chunk)
                break;
            out.write(chunk->data(), static_cast<std::streamsize>(chunk->size()));
            if (!out)
                throw std::runtime_error("download: write failed: " + part.string());
            received += static_cast<std::int64_t>(chunk->size());
            if (progress)
                progress->add(WindDownloadProgress{received, total});
        }
    }
    out.close();

    std::error_code ec;
    fs::remove(target, ec); // Windows 上 rename 不覆盖已存在的目标
    fs::rename(part, target, ec);
    if (ec)
        throw std::runtime_error("download: rename failed: " + ec.message());
}
