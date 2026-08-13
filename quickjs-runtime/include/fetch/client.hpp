// fetchcore —— Client：注入 io_context 的 fetch 核心入口
//
// 管线（每跳重走全链，跳间不共享状态）：
//   data: URL 本地构造 → [Accept-Encoding(最外层) + 用户 use() 中间件 + 传输]
//   → redirect 循环（follow/error/manual）→ SRI 包装 → Response
//
// 生命周期与线程契约（fetch_cpp_decoupling.md §4.2，成文化）：
//   1. Client 不拥有 io；io 必须比 Client 及其在飞请求活得久。
//   2. io 为单线程驱动、无 strand：Client 只能由跑 io.run() 的那根线程使用；
//      唯一跨线程入口是 std::stop_token 触发的 cancel()（只碰 socket）。
//   3. Client 无全局状态、无 TLS 依赖；可在任意作用域构造，多实例共存、
//      多实例可共用一个 io（各自独立的中间件/TLS/代理配置互不干扰）。
//   4. 唯一进程级共享是内嵌 CA X509_STORE（实现细节，不构成实例间耦合）。
#pragma once

#include <fetch/task.hpp>
#include <fetch/body.hpp>
#include <fetch/types.hpp>
#include <fetch/transport.hpp>
#include <fetch/middleware.hpp>
#include <fetch/error.hpp>
#include <fetch/url_check.hpp>
#include <fetch/beast_transport.hpp>
#include <fetch/pooled_transport.hpp>
#include <fetch/scheduler.hpp>

#include <boost/asio/io_context.hpp>

#include <ada.h>

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace fetch {

// 相对 Location 以当前 URL 为 base 解析（ada：WHATWG 标准解析器；失败抛
// fetch::Error）。ada 原生符合 web 规范：scheme/host 自动小写化、默认端口
// 剥离、非 ASCII/裸 %/| 等宽松解析（wpt redirect-location-escape 覆盖原始
// UTF-8 字节的 Location）——无需手工 relax/normalize。
// 注：绝对 Location 不依赖 base（base 解析失败不影响）。
inline std::string resolve_url(const std::string& loc, const std::string& base)
{
    auto r = ada::parse<ada::url_aggregator>(loc);
    if (!r) {
        // 相对引用：必须带合法 base（ada 的 parse 支持带 base 的相对解析）
        if (base.empty())
            throw Error("fetch: Location 无法解析");
        auto rb = ada::parse<ada::url_aggregator>(base);
        if (!rb)
            throw Error("fetch: base URL 无法解析");
        r = ada::parse<ada::url_aggregator>(loc, &*rb);
        if (!r)
            throw Error("fetch: Location 无法解析");
    }
    return std::string((*r).get_href());
}

class Client {
public:
    // 默认 PooledTransport（TLS 配置取 Options::tls；连接池配置取 Options::pool，
    // max_idle_per_host == 0 时自动退化无池）。io_context 从当前线程的
    // thread_local 获取（须已 fetch::set_thread_io()，见 scheduler.hpp）。
    explicit Client(Options opt = {})
        : io_(fetch::thread_io()), opt_(std::move(opt)),
          transport_(std::make_shared<PooledTransport>(opt_.tls, opt_.pool, opt_.dns))
    {
    }

    // 注入自定义 Transport（TLS/SOCKS5 等由调用方在 transport 上配置；
    // 此时 Options::tls 被忽略）；io_context 同取 thread_local
    Client(std::shared_ptr<Transport> transport, Options opt = {})
        : io_(fetch::thread_io()), opt_(std::move(opt)), transport_(std::move(transport))
    {
    }

    // 注册 C++ 中间件（先注册者在最外层；内建 Accept-Encoding 固定最外层，
    // SOCKS5 选路中间件命中时直接走传输隧道、与位置无关）。
    Client& use(std::shared_ptr<Middleware> mw)
    {
        mws_.push_back(std::move(mw));
        return *this;
    }

    // 主入口：redirect 循环 + SRI + data: + 中间件链 + 传输。
    std_exec::task<Response> fetch(Request req, std::stop_token st = {});

private:
    // 单跳：组装一次链（Accept-Encoding 最外层 + 用户中间件 + 传输）并走链。
    std_exec::task<Response> fetch_once(const Request& req, std::stop_token st);

    boost::asio::io_context& io_;
    Options opt_;
    std::shared_ptr<Transport> transport_;
    std::vector<std::shared_ptr<Middleware>> mws_;
};

inline std_exec::task<Response> Client::fetch_once(const Request& req, std::stop_token st)
{
    check_url_ports(req.url); // 纵深防御（fetch() 循环已检查；防未来新增调用方绕过）
    // 代理中间件固定最内层（append 到 mws_ 末尾 = make_chain 的最内层，紧贴
    // 传输）：请求级 > 实例级 > 进程级在链内解析；用户 use() 的中间件全部在
    // 代理外层执行，前置相位不会被代理命中短路跳过。无条件包裹——进程级/
    // 系统自动代理运行时可变，不能只在构造时判断。
    auto mws = mws_;
    mws.push_back(
        std::make_shared<ProxyMiddleware>(transport_, opt_.proxy, opt_.proxy_routes));
    Handler h = make_chain(mws, transport_);
    if (opt_.auto_decompress) {
        auto ae =
            std::make_shared<AcceptEncodingMiddleware>(opt_.max_decompressed_bytes);
        h = wrap_middleware(ae, std::move(h));
    }
    // BodyLengthMiddleware 强制最内层（紧贴传输）：发送前按实际 body 重写
    // Content-Length，用户中间件对 body 的任何修改都得到正确长度。
    h = wrap_middleware(std::make_shared<BodyLengthMiddleware>(), std::move(h));
    co_return co_await h(req, std::move(st));
}

inline std_exec::task<Response> Client::fetch(Request req, std::stop_token st)
{
    // ---- data: URL：本地构造响应（Node 行为：data URL 可 fetch，type=basic）----
    if (req.url.rfind("data:", 0) == 0) {
        std::string mime, data;
        if (!parse_data_url(req.url, mime, data))
            throw Error("fetch: data URL 解析失败");
        if (req.method == "HEAD")
            data.clear(); // HEAD 响应无 body（wpt scheme-data）
        Response r;
        r.status = 200;
        r.reason = "OK";
        if (!data.empty() || req.method != "HEAD")
            r.body = std::make_shared<BytesBodySource>(std::move(data));
        r.url = req.url;
        r.headers.push_back({"Content-Type", mime});
        co_return r;
    }

    std::string method = req.method;
    std::string url = req.url;
    Headers headers = req.headers;
    std::string body = req.body;
    std::shared_ptr<BodySource> body_stream = req.body_stream;
    size_t body_size = req.body_size;
    const int kMaxRedirects = opt_.max_redirects;
    for (int hop = 0; hop <= kMaxRedirects; ++hop) {
        check_url_ports(url); // 每跳检查（含初始 URL）：blocked 端口 → 抛 Error
        Request rq;
        rq.method = method;
        rq.url = url;
        rq.headers = headers;
        rq.body = body;
        rq.body_stream = body_stream;
        rq.body_size = body_size;
        rq.proxy = req.proxy; // 请求级代理跨重定向跳沿用
        // 重放：流式 body 每跳前回到初始状态（传输层已消费；307/308 保 body 重发）
        if (rq.body_stream)
            rq.body_stream->reset();

        Response resp = co_await fetch_once(rq, st); // 每跳重走全链

        const std::string loc = location_of(resp.headers);
        if (req.redirect == Request::Redirect::error && is_redirect_status(resp.status))
            throw Error("fetch: redirect mode 为 error");
        if (req.redirect == Request::Redirect::manual && is_redirect_status(resp.status)) {
            // opaqueredirect 哨兵：status==0 且 url 空（绑定层据此构造 opaqueredirect）
            Response r;
            co_return r;
        }
        if (req.redirect == Request::Redirect::follow && is_redirect_status(resp.status) &&
            !loc.empty()) {
            if (hop == kMaxRedirects)
                throw Error("fetch: 重定向次数超过 " + std::to_string(kMaxRedirects));
            url = resolve_url(loc, url); // 相对 Location 以当前 URL 为 base 解析
            // 303 一律转 GET；301/302 仅 POST 转 GET
            if (status_requires_get(resp.status, method)) {
                method = "GET";
                body.clear();
                body_stream.reset();
                body_size = 0;
                headers = without_body_headers(headers);
            }
            continue;
        }

        // SRI（M3）：消费末端增量校验——integrity 非空 → 包 IntegritySource
        //（read 时算摘要，EOF 比对；不匹配 → 消费抛异常 → 绑定层 reject TypeError）。
        // 空 body（204/205/304/HEAD）仍走立即校验（v1 语义：null body + integrity → 错误）。
        if (!req.integrity.empty() && resp.body) {
            resp.body = std::make_shared<IntegritySource>(std::move(resp.body), req.integrity);
        } else if (!req.integrity.empty()) {
            check_integrity(req.integrity, resp.status, method, ""); // null body 检查
        }
        resp.url = url;             // 最终 URL（重定向后）
        resp.redirected = hop > 0;  // 规范：经重定向的响应 redirected=true
        co_return resp;
    }
    throw Error("fetch: 重定向次数超过 " + std::to_string(kMaxRedirects));
}

} // namespace fetch
