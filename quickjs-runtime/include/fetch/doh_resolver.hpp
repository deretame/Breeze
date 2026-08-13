// fetchcore —— DoH（DNS over HTTPS，RFC 8484）解析器（docs/dns_resolver_design.md §4.2）
//
// 要点：
//   - 查询：HTTPS POST 到配置的 endpoint（如 https://1.1.1.1/dns-query），
//     Content-Type: application/dns-message，body 为 RFC 1035 wire format 查询
//     报文（A 与 AAAA 各发一个查询，合并结果）；响应解析出 A/AAAA 记录及其
//     **真实 TTL** 填入 DnsEntry::ttl（DoH 相对系统解析的核心收益）。
//   - wire format 自行打包/解包（设计文档要求不引新依赖）：build_dns_query /
//     parse_dns_response 为传输无关的自由函数，可独立单测。
//   - 循环依赖：DoH 查询本身走 HTTP→DNS。DohResolver 内部持有专用
//     BeastTransport（自带连接池，复用到 DoH server 的连接），其 DnsOptions 配
//     custom_resolver = SystemResolver——DoH server 域名永远走系统解析，绝不
//     递归进 DohResolver 自己。
//   - 超时：单次查询默认 5s（DohOptions::timeout），超时抛 timed_out 触发
//     fallback 而非拖住请求。
//   - fallback：DohOptions::fallback_to_system（默认 true，对齐 Firefox 语义）：
//     DoH 失败（网络错/超时/RCODE 错）时回落内部 SystemResolver 重试一次。
#pragma once

#include <fetch/dns_resolver.hpp>
#include <fetch/types.hpp> // DohOptions / TlsOptions

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>

namespace fetch {

// ---- RFC 1035 wire format 编解码（自由函数，传输无关，可单测）----

inline constexpr uint16_t kDnsTypeA = 1;
inline constexpr uint16_t kDnsTypeAAAA = 28;

// 构造查询报文：12 字节头（随机 ID 由调用方给）+ QNAME（标签长度前缀编码，
// 单标签 ≤63 字节）+ QTYPE/QCLASS(IN)。host 非法（空/标签超长/总长超 255）
// 抛 fetch::Error。
std::string build_dns_query(std::string_view host, uint16_t qtype, uint16_t id);

// 解析响应报文（严格边界检查——这是解析外部输入，任何越界读都是漏洞）：
//   - 报文 < 12 字节 / ID 与 expect_id 不符 / 非响应（QR=0）→ 抛 fetch::Error；
//   - RCODE=3（NXDOMAIN）→ 抛 system_error(host_not_found)（供缓存层负缓存）；
//     其余 RCODE≠0 → 抛 fetch::Error；
//   - answer 段遍历：跳过 CNAME 等无关类型；NAME 支持 RFC 1035 §4.1.4 指针
//     压缩（0xC0xx，限制跳转次数防环）；A/AAAA 记录要求 RDLENGTH 恰为 4/16，
//     否则抛 fetch::Error（畸形报文，不静默跳过）；TTL 取记录真值填入
//     DnsEntry::ttl（上限钳制在缓存层 max_ttl，本层不重复）。
DnsResult parse_dns_response(std::string_view msg, uint16_t expect_id);

// DoH 解析器。构造须在已 fetch::set_thread_io() 的 io 线程（内部传输取
// thread_local io）；endpoint 必须 https，否则构造抛 fetch::Error。
class DohResolver : public DnsResolver {
public:
    explicit DohResolver(DohOptions opt, TlsOptions tls = {});
    ~DohResolver() override;

    std_exec::task<DnsResult> resolve(std::string host, std::string service,
                                      std::stop_token st) override;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace fetch
