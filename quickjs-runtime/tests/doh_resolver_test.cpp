// DoH（RFC 8484）解析器测试（docs/dns_resolver_design.md §4.2）
//
// 覆盖：
//   - wire format 单测（与传输解耦）：查询构造字节正确性（QNAME 编码 / ID /
//     标签 63 字节限制）；响应解析（A/AAAA/CNAME 跳过/指针压缩/真 TTL）；
//     畸形报文（截断 / 指针越界 / 指针环 / RDLENGTH 不符 / RCODE=3 / ID 不符）
//   - 端到端（全部本地化，不打真实外网）：本地 TLS DoH 假 server（POST
//     /dns-query 回手工构造的 dns-message），DohResolver 全链路 + 真 TTL 进
//     缓存（CachingResolver 命中不触网）；fallback（DoH 端口宕 → 系统解析；
//     fallback_to_system=false → 直接抛）；超时回落；Client + Options.dns.doh
//     整链接线
//
// 驱动方式与 dns_resolver_test 相同：counting_scope close+join + poll 循环。
#include <gtest/gtest.h>
#include <fetch/doh_resolver.hpp>
#include <fetch/client.hpp>
#include <fetch/body.hpp> // fetch::read_all
#include <fetch/scheduler.hpp>

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <atomic>
#include <chrono>
#include <cstring>
#include <exception>
#include <fstream>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace {

namespace net = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
using fetch::DnsEntry;
using fetch::DnsResult;

// ---- 测试用 wire 报文构造（与服务端共用）----

void tput16(std::string& out, uint32_t v)
{
    out.push_back(static_cast<char>((v >> 8) & 0xFF));
    out.push_back(static_cast<char>(v & 0xFF));
}

void tput32(std::string& out, uint32_t v)
{
    out.push_back(static_cast<char>((v >> 24) & 0xFF));
    out.push_back(static_cast<char>((v >> 16) & 0xFF));
    out.push_back(static_cast<char>((v >> 8) & 0xFF));
    out.push_back(static_cast<char>(v & 0xFF));
}

struct TestRR {
    uint16_t type; // 1=A 5=CNAME 28=AAAA
    std::string ip;
    uint32_t ttl;
};

// 构造应答报文：header + question 原样回显 + answers（NAME 用 0xC00C 指针压缩，
// 对齐真实 DoH server 形态）。CNAME 的 RDATA 也用指针（0xC00C）。
std::string build_test_response(uint16_t id, std::string_view question,
                                const std::vector<TestRR>& rrs, uint8_t rcode = 0)
{
    std::string out;
    tput16(out, id);
    tput16(out, 0x8180 | rcode); // QR + RD + RA + rcode
    tput16(out, 1);              // QDCOUNT
    tput16(out, rcode == 0 ? static_cast<uint32_t>(rrs.size()) : 0); // ANCOUNT
    tput16(out, 0);
    tput16(out, 0);
    out.append(question);
    if (rcode != 0)
        return out;
    for (const auto& rr : rrs) {
        tput16(out, 0xC00C); // NAME = 指针 → question 的 QNAME
        tput16(out, rr.type);
        tput16(out, 1); // CLASS IN
        tput32(out, rr.ttl);
        if (rr.type == 1) {
            const auto b = net::ip::make_address_v4(rr.ip).to_bytes();
            tput16(out, 4);
            out.append(reinterpret_cast<const char*>(b.data()), 4);
        } else if (rr.type == 28) {
            const auto b = net::ip::make_address_v6(rr.ip).to_bytes();
            tput16(out, 16);
            out.append(reinterpret_cast<const char*>(b.data()), 16);
        } else { // CNAME 等：RDATA = 指针（本测试只用于"跳过"场景）
            tput16(out, 2);
            tput16(out, 0xC00C);
        }
    }
    return out;
}

// ---- 本地 TLS DoH 假 server（tls_echo_server.hpp 同款骨架，响应 dns-message）----
// 收到 POST /dns-query：按 QTYPE 查配置的记录表回手工构造的应答；rcode 可配
// （NXDOMAIN 测试）；response_delay 可配（超时测试）。
class DohTestServer {
public:
    DohTestServer()
    {
        std::string cert, key;
        for (const char* p : {"tests/certs/", "../tests/certs/", "../../tests/certs/"}) {
            std::ifstream f(std::string(p) + "server.crt");
            if (f) {
                cert = std::string(p) + "server.crt";
                key = std::string(p) + "server.key";
                break;
            }
        }
        ctx_ = std::make_shared<net::ssl::context>(net::ssl::context::tls_server);
        ctx_->use_certificate_chain_file(cert);
        ctx_->use_private_key_file(key, net::ssl::context::pem);
        acceptor_ = net::ip::tcp::acceptor(
            io_, net::ip::tcp::endpoint(net::ip::make_address("127.0.0.1"), 0));
        port_ = acceptor_.local_endpoint().port();
        thread_ = std::thread([this] { run(); });
    }
    ~DohTestServer()
    {
        boost::system::error_code ec;
        acceptor_.close(ec);
        if (thread_.joinable())
            thread_.join();
    }

    std::string endpoint() const
    {
        return "https://127.0.0.1:" + std::to_string(port_) + "/dns-query";
    }
    int requests() const { return req_count_.load(); }

    std::map<uint16_t, std::vector<TestRR>> answers; // qtype → 记录表
    std::atomic<uint8_t> rcode{0};
    std::atomic<int> response_delay_ms{0};
    std::atomic<int> body_delay_ms{0}; // 先发头、停顿后再发 body（body 阶段超时回归）

private:
    void run()
    {
        for (;;) {
            boost::system::error_code ec;
            auto s = acceptor_.accept(ec);
            if (ec)
                return;
            std::thread([this, s = std::move(s)]() mutable { handle(std::move(s)); })
                .detach();
        }
    }

    void handle(net::ip::tcp::socket s)
    {
        try {
            net::ssl::stream<net::ip::tcp::socket> stream(std::move(s), *ctx_);
            boost::system::error_code ec;
            stream.handshake(net::ssl::stream_base::server, ec);
            if (ec)
                return;
            beast::flat_buffer buf;
            for (;;) {
                http::request<http::string_body> req;
                http::read(stream, buf, req, ec);
                if (ec)
                    return;
                ++req_count_;
                http::response<http::string_body> res(http::status::ok, req.version());
                const std::string& q = req.body();
                if (req.method() != http::verb::post || req.target() != "/dns-query" ||
                    q.size() < 16) {
                    res.result(http::status::bad_request);
                } else {
                    const uint16_t id = (static_cast<uint8_t>(q[0]) << 8) |
                                        static_cast<uint8_t>(q[1]);
                    const std::string_view question(q.data() + 12, q.size() - 12);
                    // QTYPE = question 末 4 字节的前 2 字节（QNAME, QTYPE, QCLASS）
                    const uint16_t qtype =
                        (static_cast<uint8_t>(question[question.size() - 4]) << 8) |
                        static_cast<uint8_t>(question[question.size() - 3]);
                    std::vector<TestRR> rrs;
                    if (const uint8_t rc = rcode.load(); rc == 0)
                        if (auto it = answers.find(qtype); it != answers.end())
                            rrs = it->second;
                    res.set(http::field::content_type, "application/dns-message");
                    res.body() = build_test_response(id, question, rrs, rcode.load());
                }
                if (const int d = response_delay_ms.load(); d > 0)
                    std::this_thread::sleep_for(std::chrono::milliseconds(d));
                res.prepare_payload();
                if (const int bd = body_delay_ms.load(); bd > 0) {
                    // body 慢滴（body 阶段超时回归用）：先发响应头，停顿后再发 body
                    http::response_serializer<http::string_body> sr{res};
                    http::write_header(stream, sr, ec);
                    if (ec)
                        return;
                    std::this_thread::sleep_for(std::chrono::milliseconds(bd));
                    http::write(stream, sr, ec);
                } else {
                    http::write(stream, res, ec);
                }
                if (ec || req.keep_alive() == false)
                    return;
            }
        } catch (const std::exception&) {
        }
    }

    net::io_context io_;
    std::shared_ptr<net::ssl::context> ctx_;
    net::ip::tcp::acceptor acceptor_{io_};
    uint16_t port_ = 0;
    std::thread thread_;
    std::atomic<int> req_count_{0};
};

std::string read_cert_file(const char* name)
{
    for (const char* p : {"tests/certs/", "../tests/certs/", "../../tests/certs/"}) {
        std::ifstream f(std::string(p) + name + ".crt");
        if (f)
            return std::string(std::istreambuf_iterator<char>(f),
                               std::istreambuf_iterator<char>());
    }
    return {};
}

// ---- 驱动辅助（同 dns_resolver_test 的 Rig 模式）----
template <class T>
struct Outcome {
    bool done = false;
    bool stopped = false;
    std::optional<T> value;
    std::exception_ptr error;
};

struct Rig {
    net::io_context io;

    Rig() { fetch::set_thread_io(io); }
    ~Rig() { fetch::clear_thread_io(); }

    template <class Sndr>
    void spawn_and(stdexec::counting_scope& scope, Sndr&& sndr)
    {
        stdexec::spawn(static_cast<Sndr&&>(sndr), scope.get_token(),
                       stdexec::prop{stdexec::get_start_scheduler,
                                     fetch::io_scheduler{io}});
    }

    void join(stdexec::counting_scope& scope)
    {
        scope.close();
        bool joined = false;
        struct Rcvr {
            bool* joined;
            net::io_context* io;
            using receiver_concept = stdexec::receiver_t;
            void set_value() noexcept { *joined = true; }
            void set_error(std::exception_ptr) noexcept { *joined = true; }
            void set_stopped() noexcept { *joined = true; }
            auto get_env() const noexcept
            {
                return stdexec::prop{stdexec::get_start_scheduler,
                                     fetch::io_scheduler{*io}};
            }
        };
        auto op = stdexec::connect(scope.join(), Rcvr{&joined, &io});
        stdexec::start(op);
        for (int i = 0; !joined && i < 20000; ++i) {
            io.poll();
            if (!joined)
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        ASSERT_TRUE(joined) << "scope join 超时";
    }

    template <class T>
    Outcome<T> run(std_exec::task<T> work)
    {
        auto out = std::make_shared<Outcome<T>>();
        stdexec::counting_scope scope;
        spawn_and(scope,
                  std::move(work)
                      | stdexec::then([out](T v) mutable noexcept {
                            out->value = std::move(v);
                            out->done = true;
                        })
                      | stdexec::upon_error([out](std::exception_ptr ep) mutable noexcept {
                            out->error = std::move(ep);
                            out->done = true;
                        })
                      | stdexec::upon_stopped([out]() mutable noexcept {
                            out->stopped = true;
                            out->done = true;
                        }));
        join(scope);
        return std::move(*out);
    }
};

std::string error_what(std::exception_ptr ep)
{
    try {
        std::rethrow_exception(ep);
    } catch (const std::exception& e) {
        return e.what();
    }
    return {};
}

// ==================== wire format：查询构造 ====================

TEST(DohWire, BuildQueryBytes)
{
    const std::string q = fetch::build_dns_query("example.com", fetch::kDnsTypeA, 0x1234);
    // header：ID 回显位 + RD=1 + QDCOUNT=1
    ASSERT_EQ(q.size(), 12u + 13u + 4u);
    EXPECT_EQ(static_cast<uint8_t>(q[0]), 0x12);
    EXPECT_EQ(static_cast<uint8_t>(q[1]), 0x34);
    EXPECT_EQ(static_cast<uint8_t>(q[2]), 0x01); // RD
    EXPECT_EQ(static_cast<uint8_t>(q[3]), 0x00);
    EXPECT_EQ(static_cast<uint8_t>(q[4]), 0x00);
    EXPECT_EQ(static_cast<uint8_t>(q[5]), 0x01); // QDCOUNT=1
    for (int i = 6; i < 12; ++i)
        EXPECT_EQ(q[i], '\0');
    // QNAME：7example3com0（标签长度前缀编码）
    const std::string expect_qname = std::string("\x07" "example\x03" "com\x00", 13);
    EXPECT_EQ(q.substr(12, 13), expect_qname);
    // QTYPE=A(1) QCLASS=IN(1)
    EXPECT_EQ(q.substr(25), std::string("\x00\x01\x00\x01", 4));
}

TEST(DohWire, BuildQueryRejectsBadNames)
{
    EXPECT_THROW(fetch::build_dns_query("", 1, 1), fetch::Error);       // 空 host
    EXPECT_THROW(fetch::build_dns_query("a..b", 1, 1), fetch::Error);   // 空标签
    EXPECT_THROW(fetch::build_dns_query(std::string(64, 'x'), 1, 1), fetch::Error); // 标签 >63
    EXPECT_NO_THROW(fetch::build_dns_query(std::string(63, 'x'), 1, 1));
}

// ==================== wire format：响应解析 ====================

TEST(DohWire, ParseAWithPointerCompressionAndTtl)
{
    const std::string q = fetch::build_dns_query("example.com", fetch::kDnsTypeA, 0xABCD);
    const std::string resp =
        build_test_response(0xABCD, std::string_view(q).substr(12),
                            {{1, "93.184.216.34", 300}});
    const DnsResult r = fetch::parse_dns_response(resp, 0xABCD);
    ASSERT_EQ(r.size(), 1u);
    EXPECT_EQ(r[0].addr, net::ip::make_address("93.184.216.34"));
    ASSERT_TRUE(r[0].ttl.has_value());
    EXPECT_EQ(*r[0].ttl, std::chrono::seconds(300)); // 报文真 TTL
}

TEST(DohWire, ParseAaaaAndSkipCname)
{
    const std::string q = fetch::build_dns_query("example.com", fetch::kDnsTypeAAAA, 7);
    const std::string resp = build_test_response(
        7, std::string_view(q).substr(12),
        {{5, "", 60}, // CNAME：跳过
         {28, "2606:2800:220:1:248:1893:25c8:1946", 45}});
    const DnsResult r = fetch::parse_dns_response(resp, 7);
    ASSERT_EQ(r.size(), 1u);
    EXPECT_EQ(r[0].addr, net::ip::make_address("2606:2800:220:1:248:1893:25c8:1946"));
    EXPECT_EQ(*r[0].ttl, std::chrono::seconds(45));
}

TEST(DohWire, ParseNxdomainThrowsHostNotFound)
{
    const std::string q = fetch::build_dns_query("gone.test", 1, 9);
    const std::string resp = build_test_response(9, std::string_view(q).substr(12), {}, 3);
    try {
        fetch::parse_dns_response(resp, 9);
        FAIL() << "NXDOMAIN 应抛错";
    } catch (const boost::system::system_error& e) {
        EXPECT_EQ(e.code(), net::error::make_error_code(net::error::host_not_found));
    }
}

TEST(DohWire, ParseRcodeErrorThrows)
{
    const std::string q = fetch::build_dns_query("x.test", 1, 9);
    const std::string resp = build_test_response(9, std::string_view(q).substr(12), {}, 2);
    EXPECT_THROW(fetch::parse_dns_response(resp, 9), fetch::Error); // SERVFAIL
}

TEST(DohWire, ParseIdMismatchThrows)
{
    const std::string q = fetch::build_dns_query("example.com", 1, 0x1111);
    const std::string resp = build_test_response(0x2222, std::string_view(q).substr(12),
                                                 {{1, "1.2.3.4", 10}});
    EXPECT_THROW(fetch::parse_dns_response(resp, 0x1111), fetch::Error); // ID 回显校验
}

TEST(DohWire, ParseMalformedThrows)
{
    const std::string q = fetch::build_dns_query("example.com", 1, 0x42);
    const auto question = std::string_view(q).substr(12);
    const std::string good =
        build_test_response(0x42, question, {{1, "10.0.0.1", 60}});

    // 截断：不足 12 字节头 / answer 中途截断
    EXPECT_THROW(fetch::parse_dns_response(good.substr(0, 8), 0x42), fetch::Error);
    EXPECT_THROW(fetch::parse_dns_response(good.substr(0, good.size() - 2), 0x42),
                 fetch::Error);
    // 非响应报文（QR=0：原样查询当响应喂进来）
    EXPECT_THROW(fetch::parse_dns_response(q, 0x42), fetch::Error);

    {   // 指针越界：answer NAME = 0xC0 0xFF（target=255 远超报文长）
        std::string bad = good;
        bad[bad.size() - 16] = '\xC0'; // answer NAME 首字节（12+question+0）
        bad[bad.size() - 15] = '\xFF';
        EXPECT_THROW(fetch::parse_dns_response(bad, 0x42), fetch::Error);
    }
    {   // 指针环：question 的 QNAME 改成自指指针
        std::string bad = build_test_response(0x42, question, {{1, "10.0.0.1", 60}});
        bad[12] = '\xC0';
        bad[13] = '\x0C'; // 指向自己
        EXPECT_THROW(fetch::parse_dns_response(bad, 0x42), fetch::Error);
    }
    {   // RDLENGTH 不符：A 记录 rdlen=5
        std::string bad = good;
        const size_t rdlen_pos = bad.size() - 6; // RDLENGTH 字段（rdata 前 2 字节）
        bad[rdlen_pos] = '\x00';
        bad[rdlen_pos + 1] = '\x05';
        EXPECT_THROW(fetch::parse_dns_response(bad, 0x42), fetch::Error);
    }
}

// ==================== 端到端（本地 TLS DoH 假 server） ====================

fetch::TlsOptions test_tls()
{
    fetch::TlsOptions tls;
    tls.extra_trust_pem.push_back(read_cert_file("server"));
    return tls;
}

TEST(DohResolver, EndToEndRealTtl)
{
    Rig rig;
    DohTestServer server;
    server.answers[1] = {{1, "93.184.216.34", 300}};
    server.answers[28] = {{28, "2606:2800:220:1:248:1893:25c8:1946", 60}};

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    fetch::DohResolver r(opt, test_tls());
    auto out = rig.run(r.resolve("example.test", "443", {}));
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    // A + AAAA 各一条，TTL 为报文真值
    ASSERT_EQ(out.value->size(), 2u);
    EXPECT_EQ(out.value->at(0).addr, net::ip::make_address("93.184.216.34"));
    EXPECT_EQ(*out.value->at(0).ttl, std::chrono::seconds(300));
    EXPECT_EQ(out.value->at(1).addr,
              net::ip::make_address("2606:2800:220:1:248:1893:25c8:1946"));
    EXPECT_EQ(*out.value->at(1).ttl, std::chrono::seconds(60));
    EXPECT_EQ(server.requests(), 2); // A、AAAA 各一个查询
}

TEST(DohResolver, CachingLayerUsesRealTtl)
{
    Rig rig;
    DohTestServer server;
    server.answers[1] = {{1, "93.184.216.34", 300}}; // ttl 300 > max_ttl 60

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    fetch::CachingResolver r(rig.io,
                             std::make_shared<fetch::DohResolver>(opt, test_tls()));
    ASSERT_TRUE(rig.run(r.resolve("example.test", "443", {})).value.has_value());
    ASSERT_TRUE(rig.run(r.resolve("example.test", "443", {})).value.has_value());
    // 第二次命中缓存（负缓存/singleflight 同款免费获得）：A+AAAA 只发一轮
    EXPECT_EQ(server.requests(), 2);
}

TEST(DohResolver, CachingLayerZeroTtlReResolves)
{
    Rig rig;
    DohTestServer server;
    server.answers[1] = {{1, "93.184.216.34", 0}}; // 真 TTL=0 → min(0, max_ttl) 立即过期

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    fetch::CachingResolver r(rig.io,
                             std::make_shared<fetch::DohResolver>(opt, test_tls()));
    ASSERT_TRUE(rig.run(r.resolve("example.test", "443", {})).value.has_value());
    ASSERT_TRUE(rig.run(r.resolve("example.test", "443", {})).value.has_value());
    EXPECT_EQ(server.requests(), 4); // 真 TTL 生效：每轮重新解析
}

TEST(DohResolver, NxdomainNegativeCached)
{
    Rig rig;
    DohTestServer server;
    server.rcode = 3; // NXDOMAIN

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    opt.fallback_to_system = false; // 只验证 DoH 路径（fallback 会把名字交给系统解析）
    fetch::CachingResolver r(rig.io,
                             std::make_shared<fetch::DohResolver>(opt, test_tls()));
    auto out1 = rig.run(r.resolve("gone.test", "443", {}));
    ASSERT_TRUE(out1.error != nullptr);
    EXPECT_NE(error_what(out1.error).find("NXDOMAIN"), std::string::npos);
    auto out2 = rig.run(r.resolve("gone.test", "443", {}));
    ASSERT_TRUE(out2.error != nullptr);
    EXPECT_EQ(server.requests(), 1); // 负缓存期间不触网
}

TEST(DohResolver, FallbackToSystemOnDeadServer)
{
    Rig rig;
    fetch::DohOptions opt;
    opt.endpoint = "https://127.0.0.1:1/dns-query"; // 端口未监听 → 连接拒绝
    opt.timeout = std::chrono::milliseconds(1000);
    fetch::DohResolver r(opt, test_tls()); // fallback_to_system 默认 true
    auto out = rig.run(r.resolve("localhost", "80", {}));
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    ASSERT_FALSE(out.value->empty());
    const auto& addr = out.value->front().addr;
    EXPECT_TRUE(addr == net::ip::make_address("127.0.0.1") ||
                addr == net::ip::make_address("::1"));
}

TEST(DohResolver, NoFallbackThrowsOnDeadServer)
{
    Rig rig;
    fetch::DohOptions opt;
    opt.endpoint = "https://127.0.0.1:1/dns-query";
    opt.fallback_to_system = false;
    opt.timeout = std::chrono::milliseconds(1000);
    fetch::DohResolver r(opt, test_tls());
    auto out = rig.run(r.resolve("localhost", "80", {}));
    ASSERT_TRUE(out.error != nullptr);
}

TEST(DohResolver, TimeoutFallsBack)
{
    Rig rig;
    DohTestServer server;
    server.answers[1] = {{1, "93.184.216.34", 300}};
    server.response_delay_ms = 3000; // 响应远慢于超时

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    opt.timeout = std::chrono::milliseconds(200);
    fetch::DohResolver r(opt, test_tls());
    const auto t0 = std::chrono::steady_clock::now();
    auto out = rig.run(r.resolve("localhost", "80", {}));
    const auto elapsed = std::chrono::steady_clock::now() - t0;
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    EXPECT_LT(elapsed, std::chrono::seconds(3)) << "超时应触发 fallback 而非拖住请求";
}

TEST(DohResolver, TimeoutInBodyPhaseFallsBack)
{
    // 回归：deadline 须覆盖 body 阶段（响应头已到、body 慢滴）。修复前
    // request() 返回响应头后即 cancel timer，此场景会拖满 body_delay。
    Rig rig;
    DohTestServer server;
    server.answers[1] = {{1, "93.184.216.34", 300}};
    server.body_delay_ms = 3000; // 头立即发，body 远慢于超时

    fetch::DohOptions opt;
    opt.endpoint = server.endpoint();
    opt.timeout = std::chrono::milliseconds(200);
    fetch::DohResolver r(opt, test_tls());
    const auto t0 = std::chrono::steady_clock::now();
    auto out = rig.run(r.resolve("localhost", "80", {}));
    const auto elapsed = std::chrono::steady_clock::now() - t0;
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error); // fallback 到系统解析
    EXPECT_LT(elapsed, std::chrono::seconds(3)) << "body 阶段超时应触发 fallback 而非拖住请求";
}

// ---- Client + Options.dns.doh 整链接线（BeastTransport 组装链，§5）----

// 一次性 HTTP server（同 dns_resolver_test 的 OneShotServer）
class OneShotServer {
public:
    explicit OneShotServer(net::io_context& io)
        : acceptor_(io, net::ip::tcp::endpoint(net::ip::make_address("127.0.0.1"), 0))
    {
        do_accept();
    }
    uint16_t port() const { return acceptor_.local_endpoint().port(); }

private:
    void do_accept()
    {
        acceptor_.async_accept([this](boost::system::error_code ec, net::ip::tcp::socket s) {
            if (ec)
                return;
            auto sock = std::make_shared<net::ip::tcp::socket>(std::move(s));
            auto buf = std::make_shared<net::streambuf>();
            net::async_read_until(*sock, *buf, "\r\n\r\n",
                                  [sock, buf](boost::system::error_code, size_t) {
                                      static const char kResp[] =
                                          "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n"
                                          "Connection: close\r\n\r\nok";
                                      net::async_write(*sock, net::buffer(kResp, sizeof(kResp) - 1),
                                                       [sock](boost::system::error_code, size_t) {});
                                  });
            do_accept();
        });
    }
    net::ip::tcp::acceptor acceptor_;
};

TEST(DohResolver, ClientViaDnsOptionsDoh)
{
    Rig rig;
    DohTestServer doh_server;
    doh_server.answers[1] = {{1, "127.0.0.1", 300}}; // 任意域名 → 回环
    OneShotServer http_server(rig.io);

    fetch::Options opt;
    opt.tls = test_tls();
    fetch::DohOptions doh;
    doh.endpoint = doh_server.endpoint();
    opt.dns.doh = doh; // CachingResolver{DohResolver} 组装链（§5）

    fetch::Client client(std::move(opt));
    auto out = rig.run([&]() -> std_exec::task<int> {
        fetch::Request req;
        req.url = "http://doh-e2e.test:" + std::to_string(http_server.port()) + "/";
        auto resp = co_await client.fetch(std::move(req), {});
        if (resp.body) {
            const std::string drained = co_await fetch::read_all(resp);
            EXPECT_EQ(drained, "ok");
        }
        co_return resp.status;
    }());
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    EXPECT_EQ(*out.value, 200);
    EXPECT_GE(doh_server.requests(), 1); // 解析确实走了 DoH
}

// ==================== 真实外网 E2E（阿里公共 DNS）====================
// 默认跳过：CI/离线环境不能依赖外网。DOH_E2E=1 开启（同 3proxy 测试的
// QJS_TEST_3PROXY 环境变量开关模式）。
bool doh_e2e_enabled()
{
    const char* env = std::getenv("DOH_E2E");
    return env && *env && std::string_view(env) != "0";
}

// 真实 DoH 查询的公共断言：非空结果 + 至少一条 A 记录 + 真 TTL + 地址合法
void expect_real_doh_result(const DnsResult& r)
{
    ASSERT_FALSE(r.empty());
    bool has_a = false;
    for (const auto& e : r) {
        EXPECT_TRUE(e.addr.is_v4() || e.addr.is_v6());
        ASSERT_TRUE(e.ttl.has_value()) << "DoH 应答必须带真 TTL";
        EXPECT_GT(e.ttl->count(), 0);
        if (e.addr.is_v4())
            has_a = true;
    }
    EXPECT_TRUE(has_a) << "应至少有一条 A 记录";
}

TEST(DohResolverE2E, AliDnsLiteralIpEndpoint)
{
    if (!doh_e2e_enabled())
        GTEST_SKIP() << "DOH_E2E 未设置，跳过真实外网 E2E（DOH_E2E=1 开启）";

    Rig rig;
    fetch::DohOptions opt;
    opt.endpoint = "https://223.5.5.5/dns-query"; // 字面 IP，不走 bootstrap
    opt.fallback_to_system = false;               // 纯验 DoH 路径
    opt.timeout = std::chrono::milliseconds(15000); // 真实外网延迟放宽
    fetch::DohResolver r(opt);                    // 默认 TLS：嵌入 Mozilla CA
    auto out = rig.run(r.resolve("www.aliyun.com", "443", {}));
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    expect_real_doh_result(*out.value);
}

TEST(DohResolverE2E, AliDnsDomainEndpoint)
{
    if (!doh_e2e_enabled())
        GTEST_SKIP() << "DOH_E2E 未设置，跳过真实外网 E2E（DOH_E2E=1 开启）";

    Rig rig;
    fetch::DohOptions opt;
    // 域名形式 endpoint：内部经 SystemResolver bootstrap 解析 dns.alidns.com
    opt.endpoint = "https://dns.alidns.com/dns-query";
    opt.fallback_to_system = false;
    opt.timeout = std::chrono::milliseconds(15000);
    fetch::DohResolver r(opt);
    auto out = rig.run(r.resolve("www.taobao.com", "443", {}));
    ASSERT_TRUE(out.value.has_value()) << error_what(out.error);
    expect_real_doh_result(*out.value);
}

} // namespace
