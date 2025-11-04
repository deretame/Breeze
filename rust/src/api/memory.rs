use crate::memory::MEMORY_TRACKER;

/// 获取 Rust 端内存使用情况
pub fn get_rust_memory_info() -> RustMemoryInfo {
    let info = MEMORY_TRACKER.get_memory_info();

    RustMemoryInfo {
        total_allocated: info.total_allocated as u64,
        peak_allocated: info.peak_allocated as u64,
        allocation_count: info.allocation_count as u64,
        deallocation_count: info.deallocation_count as u64,
        tagged_allocations: info
            .tagged_allocations
            .into_iter()
            .map(|(k, v)| TaggedAllocation {
                tag: k,
                size: v as u64,
            })
            .collect(),
    }
}

/// 重置 Rust 内存统计
pub fn reset_rust_memory_stats() {
    MEMORY_TRACKER.reset();
}

/// 获取 Rust 内存使用的格式化字符串
pub fn get_rust_memory_summary() -> String {
    let info = MEMORY_TRACKER.get_memory_info();
    format!("{}", info)
}

#[derive(Debug, Clone)]
pub struct RustMemoryInfo {
    pub total_allocated: u64,
    pub peak_allocated: u64,
    pub allocation_count: u64,
    pub deallocation_count: u64,
    pub tagged_allocations: Vec<TaggedAllocation>,
}

#[derive(Debug, Clone)]
pub struct TaggedAllocation {
    pub tag: String,
    pub size: u64,
}
