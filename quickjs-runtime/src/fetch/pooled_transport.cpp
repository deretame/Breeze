// fetchcore —— PooledTransport 实现（构造便利，逻辑全在 BeastTransport）
#include <fetch/pooled_transport.hpp>
#include <fetch/scheduler.hpp>

#include <memory>
#include <utility>

namespace fetch {

PooledTransport::PooledTransport(TlsOptions tls, PoolOptions pool, DnsOptions dns)
    : BeastTransport(std::move(tls),
                     pool.max_idle_per_host == 0
                         ? nullptr
                         : std::make_shared<ConnectionPool>(fetch::thread_io(),
                                                            std::move(pool)),
                     std::move(dns))
{
}

} // namespace fetch
