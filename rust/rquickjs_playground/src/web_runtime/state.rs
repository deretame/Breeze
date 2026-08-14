use super::*;

pub(crate) fn cleanup_stale_fetch_state(pool: &mut HashMap<u64, FetchStateEntry>) {
    let now = Instant::now();
    let before = pool.len();
    pool.retain(|_, entry| now.duration_since(entry.created_at) <= FETCH_STATE_TTL);
    let removed = before.saturating_sub(pool.len());
    if removed > 0 {
        FETCH_STATE_GC_DROPS.fetch_add(removed as u64, Ordering::Relaxed);
    }
}

fn maybe_cleanup_fetch_state_on_op() {
    let seq = FETCH_STATE_OP_SEQ.fetch_add(1, Ordering::Relaxed);
    if seq % STATE_GC_EVERY_OPS != 0 {
        return;
    }
    if let Ok(mut pool) = fetch_state_pool().lock() {
        cleanup_stale_fetch_state(&mut pool);
    }
}

pub fn fetch_state_register(offloaded: bool, native_body: bool) -> u64 {
    let id = FETCH_STATE_ID.fetch_add(1, Ordering::Relaxed);
    if let Ok(mut pool) = fetch_state_pool().lock() {
        cleanup_stale_fetch_state(&mut pool);
        pool.insert(
            id,
            FetchStateEntry {
                state: FetchObjectState {
                    consumed: false,
                    offloaded,
                    offload_taken: false,
                    native_body,
                },
                created_at: Instant::now(),
            },
        );
    }
    id
}

pub fn fetch_state_try_consume(id: u64) -> bool {
    maybe_cleanup_fetch_state_on_op();
    let mut pool = match fetch_state_pool().lock() {
        Ok(guard) => guard,
        Err(_) => {
            FETCH_STATE_REJECTS.fetch_add(1, Ordering::Relaxed);
            return false;
        }
    };
    match pool.get_mut(&id) {
        Some(entry) if !entry.state.consumed => {
            entry.state.consumed = true;
            true
        }
        _ => {
            FETCH_STATE_REJECTS.fetch_add(1, Ordering::Relaxed);
            false
        }
    }
}

pub fn fetch_state_can_clone(id: u64) -> bool {
    maybe_cleanup_fetch_state_on_op();
    let pool = match fetch_state_pool().lock() {
        Ok(guard) => guard,
        Err(_) => return false,
    };
    match pool.get(&id) {
        Some(entry) => {
            let state = &entry.state;
            !state.consumed && !state.offloaded && !state.native_body
        }
        None => false,
    }
}

pub fn fetch_state_take_offloaded(id: u64) -> bool {
    maybe_cleanup_fetch_state_on_op();
    let mut pool = match fetch_state_pool().lock() {
        Ok(guard) => guard,
        Err(_) => {
            FETCH_STATE_REJECTS.fetch_add(1, Ordering::Relaxed);
            return false;
        }
    };
    match pool.get_mut(&id) {
        Some(entry)
            if entry.state.offloaded && !entry.state.offload_taken && !entry.state.consumed =>
        {
            entry.state.offload_taken = true;
            entry.state.consumed = true;
            true
        }
        _ => {
            FETCH_STATE_REJECTS.fetch_add(1, Ordering::Relaxed);
            false
        }
    }
}
