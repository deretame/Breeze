// fetchcore —— DoH 解析器实现（docs/dns_resolver_design.md §4.2）
//
//   - wire format：RFC 1035 查询打包 / 应答解包（自由函数，见头文件注释）。
//   - DohResolver：内部专用 BeastTransport（自带连接池复用 DoH 连接；
//     custom_resolver = SystemResolver 切断循环依赖）+ 超时（stop_source 级联
//     取消 + deadline timer，connect_util.hpp 同款分流）+ fallback_to_system。
#include <fetch/doh_resolver.hpp>

#include <fetch/body.hpp>           // fetch::read_all
#include <fetch/beast_transport.hpp>
#include <fetch/connection_pool.hpp>
#include <fetch/error.hpp>
#include <fetch/scheduler.hpp>

#include <ada.h>
#include <boost/asio.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include "connect_util.hpp" // detail::HandshakeDeadline

#include <algorithm>
#include <chrono>
#include <cstring>
#include <functional>
#include <optional>
#include <random>
#include <stop_token>
#include <utility>
#include <vector>

namespace fetch {

namespace net = boost::asio;

namespace {

// ---- wire 读写小工具（大端；所有读均带边界检查）----

void put16(std::string& out, uint16_t v)
{
    out.push_back(static_cast<char>(v >> 8));
    out.push_back(static_cast<char>(v & 0xFF));
}

void put32(std::string& out, uint32_t v)
{
    out.push_back(static_cast<char>(v >> 24));
    out.push_back(static_cast<char>((v >> 16) & 0xFF));
    out.push_back(static_cast<char>((v >> 8) & 0xFF));
    out.push_back(static_cast<char>(v & 0xFF));
}

uint16_t rd16(std::string_view msg, size_t pos)
{
    if (pos + 2 > msg.size())
        throw Error("DoH: 报文截断（rd16 越界）");
    return static_cast<uint16_t>((static_cast<uint8_t>(msg[pos]) << 8) |
                                 static_cast<uint8_t>(msg[pos + 1]));
}

uint32_t rd32(std::string_view msg, size_t pos)
{
    if (pos + 4 > msg.size())
        throw Error("DoH: 报文截断（rd32 越界）");
    return (static_cast<uint32_t>(static_cast<uint8_t>(msg[pos])) << 24) |
           (static_cast<uint32_t>(static_cast<uint8_t>(msg[pos + 1])) << 16) |
           (static_cast<uint32_t>(static_cast<uint8_t>(msg[pos + 2])) << 8) |
           static_cast<uint32_t>(static_cast<uint8_t>(msg[pos + 3]));
}

// 跳过 NAME（RFC 1035 §4.1.4 指针压缩）：返回 NAME 之后的偏移。
// 指针只用于定位、不跟随展开（本层不需要名字内容），但仍校验指针目标在
// 报文内；jumps 限制跳转次数防指针环。越界/畸形 → 抛 Error。
size_t skip_name(std::string_view msg, size_t pos)
{
    size_t cur = pos;
    int jumps = 0; // 跳转预算：任何合法报文的指针链远小于此
    for (;;) {
        if (cur >= msg.size())
            throw Error("DoH: NAME 越界");
        const uint8_t len = static_cast<uint8_t>(msg[cur]);
        if ((len & 0xC0) == 0xC0) {
            // 压缩指针（2 字节）：只在"首次遇到"时推进返回值
            if (cur + 2 > msg.size())
                throw Error("DoH: 指针截断");
            const size_t target =
                ((static_cast<size_t>(len & 0x3F)) << 8) | static_cast<uint8_t>(msg[cur + 1]);
            if (target >= msg.size())
                throw Error("DoH: 指针越界");
            if (++jumps > 128)
                throw Error("DoH: 指针环");
            if (jumps == 1)
                pos = cur + 2; // 返回偏移 = 首个指针之后
            cur = target;
            continue;
        }
        if ((len & 0xC0) != 0)
            throw Error("DoH: 非法标签长度前缀");
        cur += 1 + len;
        if (cur > msg.size())
            throw Error("DoH: 标签越界");
        if (jumps == 0)
            pos = cur; // 未走指针：返回值跟随实际扫描位置（含根标签 0 字节）
        if (len == 0)
            break;
    }
    return pos;
}

// 查询 ID 生成（随机并校验回显）
uint16_t next_query_id()
{
    static thread_local std::mt19937 rng{std::random_device{}()};
    return static_cast<uint16_t>(rng());
}

} // namespace

// ---- 查询构造（RFC 1035 §4.1）----

std::string build_dns_query(std::string_view host, uint16_t qtype, uint16_t id)
{
    std::string out;
    put16(out, id);
    put16(out, 0x0100); // flags：RD=1（期望递归）
    put16(out, 1);      // QDCOUNT
    put16(out, 0);      // ANCOUNT
    put16(out, 0);      // NSCOUNT
    put16(out, 0);      // ARCOUNT
    // QNAME：标签长度前缀编码（单标签 ≤63 字节；空 host 非法）
    if (host.empty())
        throw Error("DoH: 空 host");
    size_t begin = 0;
    for (size_t i = 0; i <= host.size(); ++i) {
        if (i == host.size() || host[i] == '.') {
            const size_t len = i - begin;
            if (len == 0)
                throw Error("DoH: host 含空标签");
            if (len > 63)
                throw Error("DoH: 标签超过 63 字节");
            out.push_back(static_cast<char>(len));
            out.append(host.substr(begin, len));
            begin = i + 1;
        }
    }
    if (out.size() - 12 + 1 > 255)
        throw Error("DoH: QNAME 超过 255 字节");
    out.push_back('\0');
    put16(out, qtype);
    put16(out, 1); // QCLASS = IN
    return out;
}

// ---- 响应解析（严格边界检查）----

DnsResult parse_dns_response(std::string_view msg, uint16_t expect_id)
{
    if (msg.size() < 12)
        throw Error("DoH: 报文不足 12 字节头");
    if (rd16(msg, 0) != expect_id)
        throw Error("DoH: 响应 ID 与查询不符");
    const uint8_t flags_lo = static_cast<uint8_t>(msg[3]);
    if ((static_cast<uint8_t>(msg[2]) & 0x80) == 0)
        throw Error("DoH: 非响应报文（QR=0）");
    const uint8_t rcode = flags_lo & 0x0F;
    if (rcode == 3)
        throw boost::system::system_error(net::error::make_error_code(net::error::host_not_found),
                                          "DoH: NXDOMAIN");
    if (rcode != 0)
        throw Error("DoH: RCODE=" + std::to_string(rcode));

    const uint16_t qd = rd16(msg, 4);
    const uint16_t an = rd16(msg, 6);
    size_t pos = 12;
    for (uint16_t i = 0; i < qd; ++i) {
        pos = skip_name(msg, pos);
        if (pos + 4 > msg.size())
            throw Error("DoH: question 截断");
        pos += 4; // QTYPE + QCLASS
    }

    DnsResult out;
    for (uint16_t i = 0; i < an; ++i) {
        pos = skip_name(msg, pos);
        if (pos + 10 > msg.size())
            throw Error("DoH: answer 截断");
        const uint16_t type = rd16(msg, pos);
        const uint16_t cls = rd16(msg, pos + 2);
        const uint32_t ttl = rd32(msg, pos + 4);
        const uint16_t rdlen = rd16(msg, pos + 8);
        pos += 10;
        if (pos + rdlen > msg.size())
            throw Error("DoH: RDATA 越界");
        const std::string_view rdata = msg.substr(pos, rdlen);
        pos += rdlen;
        if (cls != 1) // 只认 IN
            continue;
        if (type == kDnsTypeA || type == kDnsTypeAAAA) {
            const size_t want = type == kDnsTypeA ? 4 : 16;
            if (rdlen != want)
                throw Error("DoH: A/AAAA 记录 RDLENGTH 不符");
            // RDATA 是原始字节（4/16），非点分文本：按 bytes_type 构造
            net::ip::address addr;
            if (type == kDnsTypeA) {
                net::ip::address_v4::bytes_type b{};
                std::memcpy(b.data(), rdata.data(), 4);
                addr = net::ip::address_v4(b);
            } else {
                net::ip::address_v6::bytes_type b{};
                std::memcpy(b.data(), rdata.data(), 16);
                addr = net::ip::address_v6(b);
            }
            // TTL 钳制上限在缓存层 max_ttl（§3.2），本层原样填报文真值
            out.push_back({addr, std::chrono::seconds(ttl)});
        }
        // 其余类型（CNAME 等）跳过
    }
    return out;
}

// ---- DohResolver ----

struct DohResolver::Impl {
    DohOptions opt;
    net::io_context& io;
    std::shared_ptr<ConnectionPool> pool;       // 专用池：复用到 DoH server 的连接
    std::shared_ptr<BeastTransport> transport;  // custom_resolver = SystemResolver
    std::shared_ptr<SystemResolver> fallback;   // fallback_to_system 时非空

    Impl(DohOptions o, TlsOptions tls)
        : opt(std::move(o)), io(fetch::thread_io())
    {
        // 循环依赖（§4.2）：内部传输的 DNS 永远走系统解析，绝不递归进自身。
        // endpoint host 非字面 IP 时经 SystemResolver 解析（配置侧建议字面 IP）。
        DnsOptions inner;
        inner.custom_resolver = std::make_shared<SystemResolver>(io);
        pool = std::make_shared<ConnectionPool>(io, PoolOptions{});
        transport = std::make_shared<BeastTransport>(std::move(tls), pool, std::move(inner));
        if (opt.fallback_to_system)
            fallback = std::make_shared<SystemResolver>(io);
    }

    // 单次 DoH 查询（一个 QTYPE）：超时经内层 stop_source 级联取消传输
    std_exec::task<DnsResult> query_one(const std::string& host, uint16_t qtype,
                                        std::stop_token st)
    {
        const uint16_t id = next_query_id();
        Request req;
        req.method = "POST";
        req.url = opt.endpoint;
        req.headers = {{"Content-Type", "application/dns-message"},
                       {"Accept", "application/dns-message"}};
        req.body = build_dns_query(host, qtype, id);

        // 超时 + 取消：外层 st 与 deadline 都经 tss 取消传输；醒后按
        // fired / 用户取消分流（connect_util.hpp await_op 同款语义）
        std::stop_source tss;
        std::optional<std::stop_callback<std::function<void()>>> cb;
        if (st.stop_possible())
            cb.emplace(st, [tss]() mutable { tss.request_stop(); });
        auto dl = std::make_shared<detail::HandshakeDeadline>(io);
        dl->timer.expires_after(opt.timeout);
        dl->timer.async_wait([dl, tss](boost::system::error_code ec) mutable {
            if (ec)
                return;
            dl->fired.store(true, std::memory_order_release);
            tss.request_stop();
        });
        // deadline 覆盖整个「头 + body」阶段：request 读到响应头即返回，body
        // 由 read_all 流式拉取——若读头后就解除超时，服务端挂住慢滴 body 会把
        // 查询拖死且无 fallback。故 cancel 推迟到 body 读完（或失败分流后）。
        auto res = co_await stdexec::stopped_as_optional(
            transport->request(req, tss.get_token()));
        std::optional<std::string> body;
        if (res && res->status == 200) {
            try {
                body = co_await stdexec::stopped_as_optional(fetch::read_all(*res));
            } catch (...) {
                // body 阶段被取消时可能以异常（而非 stopped）收场，同样分流
                const bool fired = dl->fired.load(std::memory_order_acquire);
                dl->timer.cancel();
                if (fired && !st.stop_requested())
                    throw boost::system::system_error(
                        boost::system::errc::make_error_code(boost::system::errc::timed_out),
                        "DoH: 查询超时（body 阶段）");
                throw;
            }
        }
        dl->timer.cancel(); // 头 + body 全部落定：解除超时
        const bool fired = dl->fired.load(std::memory_order_acquire);
        if (!res || (res->status == 200 && !body)) {
            if (fired && !st.stop_requested())
                throw boost::system::system_error(
                    boost::system::errc::make_error_code(boost::system::errc::timed_out),
                    "DoH: 查询超时");
            co_await stdexec::just_stopped(); // 用户取消 → stopped
        }
        if (res->status != 200)
            throw Error("DoH: HTTP 状态 " + std::to_string(res->status));
        co_return parse_dns_response(*body, id);
    }
};

DohResolver::DohResolver(DohOptions opt, TlsOptions tls)
{
    // endpoint 必须 https（构造期校验，§4.2）；host 建议字面 IP（不强制，
    // 非字面 IP 时经内部 SystemResolver 解析）
    auto url = ada::parse<ada::url_aggregator>(opt.endpoint);
    if (!url)
        throw Error("DoH: endpoint 无法解析: " + opt.endpoint);
    if (url->get_protocol() != "https:")
        throw Error("DoH: endpoint 必须 https: " + opt.endpoint);
    impl_ = std::make_unique<Impl>(std::move(opt), std::move(tls));
}

DohResolver::~DohResolver() = default;

std_exec::task<DnsResult> DohResolver::resolve(std::string host, std::string service,
                                               std::stop_token st)
{
    auto& impl = *impl_; // 调用方持有 shared_ptr<DnsResolver>，生命周期随协程
    // 字面 IP 短路（§3.1）：不发起任何网络查询
    boost::system::error_code ec;
    std::string_view bare(host);
    if (bare.size() >= 2 && bare.front() == '[' && bare.back() == ']')
        bare = bare.substr(1, bare.size() - 2); // IPv6 字面量剥方括号
    if (auto addr = net::ip::make_address(bare, ec); !ec)
        co_return DnsResult{{std::move(addr), std::nullopt}};

    // fallback（对齐 Firefox 语义）：DoH 失败回落系统解析重试一次；
    // 用户取消不 fallback，直接传播 stopped
    std::exception_ptr doh_err;
    DnsResult out;
    try {
        // A 与 AAAA 各发一个查询（先 A 后 AAAA），合并结果
        out = co_await impl.query_one(host, kDnsTypeA, st);
        DnsResult v6 = co_await impl.query_one(host, kDnsTypeAAAA, st);
        out.insert(out.end(), v6.begin(), v6.end());
    } catch (...) {
        doh_err = std::current_exception();
    }
    if (!doh_err && out.empty()) {
        // NODATA（A/AAAA 全空）同样视为失败：触发 fallback / 负缓存
        doh_err = std::make_exception_ptr(boost::system::system_error(
            net::error::make_error_code(net::error::host_not_found),
            "DoH: 无 A/AAAA 记录"));
    }
    if (doh_err) {
        if (!impl.fallback || st.stop_requested())
            std::rethrow_exception(doh_err);
        co_return co_await impl.fallback->resolve(std::move(host), std::move(service), st);
    }
    co_return out;
}

} // namespace fetch
