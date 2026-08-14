//! 进程级全局 tokio runtime。
//!
//! 整个进程只维护一个多线程 runtime（固定 4 个 worker），并把阻塞线程池
//! （`spawn_blocking`）统一收拢到这一个 runtime 上，避免每个 QJS 实例 /
//! FRB 异步上下文各自建 runtime、各自把默认上限 512 的阻塞线程池开满，
//! 造成进程线程数失控。
//!
//! 注意：QJS 每个实例的 current_thread runtime 是 JS 事件循环本身，必须保留；
//! 但它们内部的阻塞任务（fs、hash、blocking handler 等）应通过 [`global_handle`]
//! 的 `spawn_blocking` 路由到这里的共享阻塞池，而不是用各自的阻塞池。
//!
//! 全局 runtime 一旦初始化即存活到进程退出（`OnceLock<Runtime>` 永不 drop），
//! 调用方可以直接 `global_runtime().spawn(...)`，也可以 `global_handle().spawn_blocking(...)`。

use std::sync::OnceLock;

use tokio::runtime::{Handle, Runtime};

static GLOBAL_RT: OnceLock<Runtime> = OnceLock::new();

/// worker 线程数：固定 4 个，负责驱动全部异步 I/O 与任务调度。
const GLOBAL_WORKER_THREADS: usize = 4;

/// 获取进程级全局 runtime（首次访问时懒初始化，仅一次，约毫秒级）。
pub fn global_runtime() -> &'static Runtime {
    GLOBAL_RT.get_or_init(|| {
        // 阻塞线程池上限：机器核数 × 4，并限制在 [8, 128] 之间。
        // 相比 tokio 默认的 512，这既给了 CPU 密集任务足够并发，
        // 又避免了多实例共用时线程数失控。
        let blocking_threads = std::thread::available_parallelism()
            .map(|n| n.get().saturating_mul(4))
            .unwrap_or(32)
            .clamp(8, 128);
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(GLOBAL_WORKER_THREADS)
            .max_blocking_threads(blocking_threads)
            .thread_name("global-tokio")
            .enable_all()
            .build()
            .expect("failed to build the process-global tokio runtime")
    })
}

/// 全局 runtime 的句柄，可自由 `Clone` 并传到任意线程 / crate。
///
/// 在 async 上下文里请用 `handle.spawn_blocking(...)` / `handle.spawn(...)`，
/// 不要对全局 runtime 调用 `block_on`（在 runtime 内部调用会 panic）。
pub fn global_handle() -> Handle {
    global_runtime().handle().clone()
}
