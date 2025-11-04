use std::collections::HashMap;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};

/// Rust 端内存跟踪器
pub struct MemoryTracker {
    /// 当前分配的总内存
    total_allocated: AtomicUsize,
    /// 峰值内存使用
    peak_allocated: AtomicUsize,
    /// 分配次数
    allocation_count: AtomicUsize,
    /// 释放次数
    deallocation_count: AtomicUsize,
    /// 按标签分类的内存使用
    tagged_allocations: Mutex<HashMap<String, usize>>,
}

impl MemoryTracker {
    pub fn new() -> Self {
        Self {
            total_allocated: AtomicUsize::new(0),
            peak_allocated: AtomicUsize::new(0),
            allocation_count: AtomicUsize::new(0),
            deallocation_count: AtomicUsize::new(0),
            tagged_allocations: Mutex::new(HashMap::new()),
        }
    }

    /// 记录内存分配
    pub fn record_allocation(&self, size: usize, tag: Option<&str>) {
        let new_total = self.total_allocated.fetch_add(size, Ordering::Relaxed) + size;
        self.allocation_count.fetch_add(1, Ordering::Relaxed);

        // 更新峰值
        let mut peak = self.peak_allocated.load(Ordering::Relaxed);
        while new_total > peak {
            match self.peak_allocated.compare_exchange_weak(
                peak,
                new_total,
                Ordering::Relaxed,
                Ordering::Relaxed,
            ) {
                Ok(_) => break,
                Err(x) => peak = x,
            }
        }

        // 记录标签分配
        if let Some(tag) = tag {
            if let Ok(mut tagged) = self.tagged_allocations.lock() {
                *tagged.entry(tag.to_string()).or_insert(0) += size;
            }
        }
    }

    /// 记录内存释放
    pub fn record_deallocation(&self, size: usize, tag: Option<&str>) {
        self.total_allocated.fetch_sub(size, Ordering::Relaxed);
        self.deallocation_count.fetch_add(1, Ordering::Relaxed);

        // 更新标签分配
        if let Some(tag) = tag {
            if let Ok(mut tagged) = self.tagged_allocations.lock() {
                if let Some(current) = tagged.get_mut(tag) {
                    *current = current.saturating_sub(size);
                    if *current == 0 {
                        tagged.remove(tag);
                    }
                }
            }
        }
    }

    /// 获取当前内存使用情况
    pub fn get_memory_info(&self) -> MemoryInfo {
        let tagged = self
            .tagged_allocations
            .lock()
            .map(|guard| guard.clone())
            .unwrap_or_default();

        MemoryInfo {
            total_allocated: self.total_allocated.load(Ordering::Relaxed),
            peak_allocated: self.peak_allocated.load(Ordering::Relaxed),
            allocation_count: self.allocation_count.load(Ordering::Relaxed),
            deallocation_count: self.deallocation_count.load(Ordering::Relaxed),
            tagged_allocations: tagged,
        }
    }

    /// 重置统计信息
    pub fn reset(&self) {
        self.total_allocated.store(0, Ordering::Relaxed);
        self.peak_allocated.store(0, Ordering::Relaxed);
        self.allocation_count.store(0, Ordering::Relaxed);
        self.deallocation_count.store(0, Ordering::Relaxed);
        if let Ok(mut tagged) = self.tagged_allocations.lock() {
            tagged.clear();
        }
    }
}

#[derive(Debug, Clone)]
pub struct MemoryInfo {
    pub total_allocated: usize,
    pub peak_allocated: usize,
    pub allocation_count: usize,
    pub deallocation_count: usize,
    pub tagged_allocations: HashMap<String, usize>,
}

impl MemoryInfo {
    pub fn format_bytes(bytes: usize) -> String {
        if bytes < 1024 {
            format!("{} B", bytes)
        } else if bytes < 1024 * 1024 {
            format!("{:.1} KB", bytes as f64 / 1024.0)
        } else if bytes < 1024 * 1024 * 1024 {
            format!("{:.1} MB", bytes as f64 / (1024.0 * 1024.0))
        } else {
            format!("{:.1} GB", bytes as f64 / (1024.0 * 1024.0 * 1024.0))
        }
    }
}

impl std::fmt::Display for MemoryInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "=== Rust Memory Usage ===")?;
        writeln!(
            f,
            "Total Allocated: {}",
            Self::format_bytes(self.total_allocated)
        )?;
        writeln!(
            f,
            "Peak Allocated: {}",
            Self::format_bytes(self.peak_allocated)
        )?;
        writeln!(f, "Allocations: {}", self.allocation_count)?;
        writeln!(f, "Deallocations: {}", self.deallocation_count)?;

        if !self.tagged_allocations.is_empty() {
            writeln!(f, "Tagged Allocations:")?;
            for (tag, size) in &self.tagged_allocations {
                writeln!(f, "  {}: {}", tag, Self::format_bytes(*size))?;
            }
        }

        Ok(())
    }
}

// 全局内存跟踪器实例
lazy_static::lazy_static! {
    pub static ref MEMORY_TRACKER: MemoryTracker = MemoryTracker::new();
}

/// 便捷宏：跟踪内存分配
#[macro_export]
macro_rules! track_allocation {
    ($size:expr) => {
        crate::memory::memory_tracker::MEMORY_TRACKER.record_allocation($size, None)
    };
    ($size:expr, $tag:expr) => {
        crate::memory::memory_tracker::MEMORY_TRACKER.record_allocation($size, Some($tag))
    };
}

/// 便捷宏：跟踪内存释放
#[macro_export]
macro_rules! track_deallocation {
    ($size:expr) => {
        crate::memory::memory_tracker::MEMORY_TRACKER.record_deallocation($size, None)
    };
    ($size:expr, $tag:expr) => {
        crate::memory::memory_tracker::MEMORY_TRACKER.record_deallocation($size, Some($tag))
    };
}

/// RAII 内存跟踪器
pub struct TrackedAllocation {
    size: usize,
    tag: Option<String>,
}

impl TrackedAllocation {
    pub fn new(size: usize, tag: Option<&str>) -> Self {
        MEMORY_TRACKER.record_allocation(size, tag);
        Self {
            size,
            tag: tag.map(|s| s.to_string()),
        }
    }
}

impl Drop for TrackedAllocation {
    fn drop(&mut self) {
        MEMORY_TRACKER.record_deallocation(self.size, self.tag.as_deref());
    }
}
