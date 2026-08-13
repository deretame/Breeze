// fetchcore —— DNS 解析器抽象与缓存（docs/dns_resolver_design.md §2/§3）
//
// 要点：
//   - DnsResolver 是与 Transport 同级的可替换接缝；三处建连路径（直连 /
//     SOCKS5 代理地址 / HTTP 代理地址）统一走它。
//   - DnsEntry::ttl 为 optional 是 DoH 预留的核心：getaddrinfo 拿不到 TTL
//     （nullopt），未来 DohResolver 直接填报文真值，接口不变。
//   - 结果整体传递（vector）：H1 修复要求连接层能尝试所有 endpoint；列表
//     顺序即建议尝试顺序（缓存层可按 last_good 排序，§3.3）。
//   - CachingResolver 是装饰器：DohResolver 落地后 CachingResolver{DohResolver{}}
//     组合即用，缓存代码零改动。
// 线程契约：实现必须可跨线程安全调用（stop_token 可能在其他线程触发，与
// Transport 契约一致：include/fetch/transport.hpp:3）。CachingResolver 的缓存
// 本体仅 io 线程访问（与 ConnectionPool 同一契约，debug 构建 assert 守约）。
#pragma once

#include <fetch/task.hpp>

#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/address.hpp>

#include <chrono>
#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace fetch {

// 单个解析结果：已解析的地址 + 可选 TTL。
// 系统解析（getaddrinfo）拿不到 TTL → ttl = nullopt，由缓存层用固定上限（§3.2）。
// DoH 解析 → ttl 取自应答报文的资源记录真实值。
struct DnsEntry {
    boost::asio::ip::address addr;          // v4 或 v6
    std::optional<std::chrono::seconds> ttl; // nullopt = 上游未提供
    bool operator==(const DnsEntry&) const = default;
};

// 一次解析的完整结果集（而非单个地址）：
// - H1 修复要求连接层能尝试所有 endpoint，故接口传递整个列表；
// - 列表顺序即建议尝试顺序（实现可按历史成功率排序，见 §3.3）。
using DnsResult = std::vector<DnsEntry>;

// DNS 解析抽象。实现必须可跨线程安全调用（stop_token 可能在其他线程触发，
// 与 Transport 契约一致：include/fetch/transport.hpp:3）。
struct DnsResolver {
    virtual ~DnsResolver() = default;

    // 解析 host（主机名或字面 IP）+ service（端口字符串）。
    // - host 为字面 IP 时必须短路返回，不发起任何网络查询（§3.1）。
    // - 失败抛 std::exception；st 触发时尽快以 stopped 完成（修复 H2 的责任在实现侧）。
    virtual std_exec::task<DnsResult> resolve(std::string host, std::string service,
                                              std::stop_token st) = 0;

    // 连接层回报"哪个地址连上了"（§3.3 last_good 排序的数据来源）。
    // 默认空实现（SystemResolver 无状态）；CachingResolver 覆写，把地址记进缓存条目。
    virtual void report_success(std::string_view /*host*/, std::string_view /*service*/,
                                const boost::asio::ip::address& /*addr*/)
    {
    }
};

// 缓存策略配置（§2.3）
struct DnsCacheOptions {
    std::chrono::seconds max_ttl{60};     // 上游无 TTL 时的固定上限（对齐 Java
                                          // networkaddress.cache.ttl / Node 默认 30s 量级）；
                                          // 兼作真 TTL 的上限钳制（防异常报文给超大值）
    std::chrono::seconds negative_ttl{5}; // 负缓存（解析失败）时长；防 DNS 抖动放大，
                                          // 又避免一次失败把域名拉黑数分钟
    size_t capacity = 256;                // 条目上限，LRU 淘汰
};

// 包装 asio tcp::resolver（getaddrinfo）。行为等同原三处裸调，外加：
// - 字面 IP 短路（不进缓存不触网）；
// - stop_callback 持 resolver 并 cancel（修复 H2：resolve 阶段可取消）；
// - 结果 ttl 一律 nullopt。
// 未配置缓存时由它直接充当默认实现，零回归面。
class SystemResolver : public DnsResolver {
public:
    explicit SystemResolver(boost::asio::io_context& io) : io_(io) {}

    std_exec::task<DnsResult> resolve(std::string host, std::string service,
                                      std::stop_token st) override;

private:
    boost::asio::io_context& io_;
};

// 包装任意底层 DnsResolver，加内存缓存（§3）：LRU 容量上限 + TTL（真 TTL 优先，
// 无则 max_ttl）+ 负缓存（缓存错误码重放，不缓存异常对象）+ singleflight
//（同 key 解析中后续协程挂起共享结果）+ last_good 排序（连接层经
// report_success 回报，命中时把上次连上的地址排最前）。
// 仅 io 线程访问（与 ConnectionPool 同一契约，免锁；debug 构建 assert 守约）。
class CachingResolver : public DnsResolver {
public:
    CachingResolver(boost::asio::io_context& io, std::shared_ptr<DnsResolver> upstream,
                    DnsCacheOptions opt = {});
    ~CachingResolver() override;

    std_exec::task<DnsResult> resolve(std::string host, std::string service,
                                      std::stop_token st) override;
    void report_success(std::string_view host, std::string_view service,
                        const boost::asio::ip::address& addr) override;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace fetch
