use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use anyhow::{Result, anyhow};
use serde_json::{Value, json};

use rquickjs_playground::{
    register_bridge_route_async_handler, register_bridge_route_sync_handler,
};

const CACHE_VALUE_MAX_BYTES: usize = 500 * 1024;
const CACHE_TTL: Duration = Duration::from_secs(30 * 60);

#[derive(Clone)]
struct CacheEntry {
    value: Value,
    expires_at: Instant,
}

fn cache_store() -> &'static Mutex<HashMap<String, CacheEntry>> {
    static STORE: OnceLock<Mutex<HashMap<String, CacheEntry>>> = OnceLock::new();
    STORE.get_or_init(|| Mutex::new(HashMap::new()))
}

fn scoped_key(runtime: &str, key: &str) -> String {
    format!("{runtime}::{key}")
}

fn require_key<'a>(args: &'a [Value], route: &str) -> Result<&'a str> {
    args.first()
        .and_then(Value::as_str)
        .filter(|key| !key.is_empty())
        .ok_or_else(|| anyhow!("{route} 参数无效：缺少 key"))
}

fn value_is_too_large(value: &Value) -> bool {
    serde_json::to_vec(value)
        .map(|bytes| bytes.len() > CACHE_VALUE_MAX_BYTES)
        .unwrap_or(true)
}

fn new_entry(value: Value) -> CacheEntry {
    CacheEntry {
        value,
        expires_at: Instant::now() + CACHE_TTL,
    }
}

fn cache_get(runtime: &str, args: &[Value]) -> Result<Value> {
    let key = require_key(args, "cache.get")?;
    let fallback = args.get(1).cloned().unwrap_or(Value::Null);
    let scoped_key = scoped_key(runtime, key);
    let mut store = cache_store()
        .lock()
        .map_err(|_| anyhow!("cache store lock poisoned"))?;
    let Some(entry) = store.get(&scoped_key).cloned() else {
        return Ok(fallback);
    };
    if entry.expires_at <= Instant::now() {
        store.remove(&scoped_key);
        return Ok(fallback);
    }
    Ok(entry.value)
}

fn cache_set(runtime: &str, args: &[Value]) -> Result<Value> {
    let key = require_key(args, "cache.set")?;
    let value = args.get(1).cloned().unwrap_or(Value::Null);
    if value_is_too_large(&value) {
        return Ok(json!(false));
    }
    cache_store()
        .lock()
        .map_err(|_| anyhow!("cache store lock poisoned"))?
        .insert(scoped_key(runtime, key), new_entry(value));
    Ok(json!(true))
}

fn cache_set_if_absent(runtime: &str, args: &[Value]) -> Result<Value> {
    let key = require_key(args, "cache.set_if_absent")?;
    let value = args.get(1).cloned().unwrap_or(Value::Null);
    if value_is_too_large(&value) {
        return Ok(json!(false));
    }
    let mut store = cache_store()
        .lock()
        .map_err(|_| anyhow!("cache store lock poisoned"))?;
    let scoped_key = scoped_key(runtime, key);
    if let Some(entry) = store.get(&scoped_key)
        && entry.expires_at > Instant::now()
    {
        return Ok(json!(false));
    }
    store.insert(scoped_key, new_entry(value));
    Ok(json!(true))
}

fn cache_compare_and_set(runtime: &str, args: &[Value]) -> Result<Value> {
    let key = require_key(args, "cache.compare_and_set")?;
    let expected = args.get(1).cloned().unwrap_or(Value::Null);
    let next = args.get(2).cloned().unwrap_or(Value::Null);
    if value_is_too_large(&next) {
        return Ok(json!(false));
    }
    let mut store = cache_store()
        .lock()
        .map_err(|_| anyhow!("cache store lock poisoned"))?;
    let scoped_key = scoped_key(runtime, key);
    let matches = store
        .get(&scoped_key)
        .filter(|entry| entry.expires_at > Instant::now())
        .map(|entry| entry.value == expected)
        .unwrap_or(false);
    if !matches {
        return Ok(json!(false));
    }
    store.insert(scoped_key, new_entry(next));
    Ok(json!(true))
}

fn cache_delete(runtime: &str, args: &[Value]) -> Result<Value> {
    let key = require_key(args, "cache.delete")?;
    let deleted = cache_store()
        .lock()
        .map_err(|_| anyhow!("cache store lock poisoned"))?
        .remove(&scoped_key(runtime, key))
        .is_some();
    Ok(json!(deleted))
}

pub fn register_cache_routes() -> Result<()> {
    register_bridge_route_sync_handler("cache.get", |runtime, args| cache_get(&runtime, &args))?;
    register_bridge_route_sync_handler("cache.get.sync", |runtime, args| {
        cache_get(&runtime, &args)
    })?;
    register_bridge_route_sync_handler("cache.set", |runtime, args| cache_set(&runtime, &args))?;
    register_bridge_route_sync_handler("cache.set.sync", |runtime, args| {
        cache_set(&runtime, &args)
    })?;
    register_bridge_route_sync_handler("cache.set_if_absent", |runtime, args| {
        cache_set_if_absent(&runtime, &args)
    })?;
    register_bridge_route_sync_handler("cache.compare_and_set", |runtime, args| {
        cache_compare_and_set(&runtime, &args)
    })?;
    register_bridge_route_sync_handler("cache.delete", |runtime, args| {
        cache_delete(&runtime, &args)
    })?;

    // 服务端 runtime 自身负责生命周期管理；向插件提供与本体兼容的成功响应。
    register_bridge_route_async_handler("runtime.gc", |_, _| async { Ok(json!(true)) })?;
    register_bridge_route_sync_handler("runtime.is_task_group_cancelled", |_, _| Ok(json!(false)))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{cache_compare_and_set, cache_delete, cache_get, cache_set, cache_set_if_absent};

    #[test]
    fn cache_values_are_scoped_and_support_atomic_updates() {
        let runtime = "cache-test-runtime";
        let key = "unique-key";
        let args = vec![json!(key), json!("fallback")];

        assert_eq!(
            cache_get(runtime, &args).expect("cache get"),
            json!("fallback")
        );
        assert_eq!(
            cache_set(runtime, &[json!(key), json!("first")]).expect("cache set"),
            json!(true)
        );
        assert_eq!(
            cache_set_if_absent(runtime, &[json!(key), json!("second")]).expect("set if absent"),
            json!(false)
        );
        assert_eq!(
            cache_get(runtime, &[json!(key), json!(null)]).expect("cache get"),
            json!("first")
        );
        assert_eq!(
            cache_compare_and_set(runtime, &[json!(key), json!("stale"), json!("next")])
                .expect("compare and set"),
            json!(false)
        );
        assert_eq!(
            cache_compare_and_set(runtime, &[json!(key), json!("first"), json!("next")])
                .expect("compare and set"),
            json!(true)
        );
        assert_eq!(
            cache_get(runtime, &[json!(key), json!(null)]).expect("cache get"),
            json!("next")
        );
        assert_eq!(
            cache_get("another-runtime", &[json!(key), json!("isolated")])
                .expect("isolated cache get"),
            json!("isolated")
        );
        assert_eq!(
            cache_delete(runtime, &[json!(key)]).expect("cache delete"),
            json!(true)
        );
        assert_eq!(
            cache_get(runtime, &args).expect("cache get after delete"),
            json!("fallback")
        );
    }
}
