// fetchcore —— PooledTransport：带连接池的 BeastTransport（构造便利）
//
// 设计文档 §7-3（开放问题 3）定为参数化方案：池能力整体由 BeastTransport 承载
// （构造时传入 ConnectionPool），PooledTransport 只作为 easy 层的构造便利存在
// ——避免两套传输代码漂移。`pool.max_idle_per_host == 0` 时退化为无池行为
// （等价 reqwest pool_max_idle_per_host(0) 关闭复用），不必单独实例化 BeastTransport。
#pragma once

#include <fetch/beast_transport.hpp>
#include <fetch/connection_pool.hpp>
#include <fetch/types.hpp>

namespace fetch {

class PooledTransport : public BeastTransport {
public:
    // io_context 从当前线程的 thread_local 获取（须已 fetch::set_thread_io()）。
    // max_idle_per_host == 0 → 不建池（行为等同无池）。dns 透传 BeastTransport 组装。
    explicit PooledTransport(TlsOptions tls = {}, PoolOptions pool = {}, DnsOptions dns = {});
    ~PooledTransport() override = default;
};

} // namespace fetch
