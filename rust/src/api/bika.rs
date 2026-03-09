use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::frb;
use rquickjs_playground::AsyncHostRuntime;
use serde_json::{Value, json};
use std::fs;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};
use tokio::sync::OnceCell;

const BIKA_QJS_BUNDLE: &str = include_str!("../../qjs_bika/dist/bika.bundle.js");
const BIKA_BASE_URL: &str = "https://picaapi.picacomic.com";

static AUTH_CACHE: OnceLock<Mutex<Option<String>>> = OnceLock::new();
static QJS_RUNTIME: OnceCell<AsyncHostRuntime> = OnceCell::const_new();
static QJS_RUNTIME_CREATED: AtomicU64 = AtomicU64::new(0);
static QJS_DISPATCH_TOTAL: AtomicU64 = AtomicU64::new(0);
static QJS_RUNTIME_CALL_COUNT: AtomicU64 = AtomicU64::new(0);

fn auth_cache() -> &'static Mutex<Option<String>> {
    AUTH_CACHE.get_or_init(|| Mutex::new(None))
}

fn auth_cache_path() -> PathBuf {
    if let Ok(path) = std::env::var("BREEZE_BIKA_AUTH_FILE") {
        let trimmed = path.trim();
        if !trimmed.is_empty() {
            return PathBuf::from(trimmed);
        }
    }
    std::env::temp_dir().join("breeze_bika_authorization.txt")
}

fn read_auth_from_disk() -> Option<String> {
    let path = auth_cache_path();
    let raw = fs::read_to_string(path).ok()?;
    let token = raw.trim();
    if token.is_empty() {
        None
    } else {
        Some(token.to_string())
    }
}

fn persist_auth_to_disk(token: &str) -> Result<()> {
    let path = auth_cache_path();
    if let Some(parent) = path.parent()
        && !parent.as_os_str().is_empty()
    {
        fs::create_dir_all(parent).with_context(|| format!("创建授权缓存目录失败: {parent:?}"))?;
    }
    fs::write(&path, token).with_context(|| format!("写入授权缓存失败: {path:?}"))?;
    Ok(())
}

fn set_cached_authorization(token: &str) -> Result<()> {
    let value = token.trim();
    if value.is_empty() {
        return Ok(());
    }

    {
        let mut guard = auth_cache()
            .lock()
            .map_err(|_| anyhow!("授权缓存加锁失败"))?;
        *guard = Some(value.to_string());
    }

    persist_auth_to_disk(value)
}

fn get_cached_authorization() -> Option<String> {
    let mut guard = auth_cache().lock().ok()?;
    if let Some(value) = guard.as_ref() {
        return Some(value.clone());
    }
    let disk = read_auth_from_disk();
    *guard = disk.clone();
    disk
}

fn default_image_quality(image_quality: Option<String>) -> String {
    let raw = image_quality.unwrap_or_else(|| "original".to_string());
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        "original".to_string()
    } else {
        trimmed.to_string()
    }
}

fn default_app_channel() -> String {
    "3".to_string()
}

fn resolve_authorization(input: Option<String>) -> Option<String> {
    match input {
        Some(value) if !value.trim().is_empty() => Some(value.trim().to_string()),
        _ => get_cached_authorization(),
    }
}

fn extract_auth_token(resp: &Value) -> Option<String> {
    let candidates = ["/data/token", "/data/res/token", "/token", "/authorization"];
    for ptr in candidates {
        if let Some(token) = resp.pointer(ptr).and_then(Value::as_str)
            && !token.trim().is_empty()
        {
            return Some(token.trim().to_string());
        }
    }
    None
}

async fn qjs_runtime() -> Result<&'static AsyncHostRuntime> {
    let call_count = QJS_RUNTIME_CALL_COUNT.fetch_add(1, Ordering::SeqCst);
    tracing::info!("qjs_runtime call count: {}", call_count);
    QJS_RUNTIME
        .get_or_try_init(|| async {
            let runtime = AsyncHostRuntime::new(false).map_err(|err| anyhow!(err))?;
            let init_script = format!(
                r#"(async () => {{
  {bundle}
  return "ok";
}})()"#,
                bundle = BIKA_QJS_BUNDLE,
            );
            let task = runtime
                .spawn(init_script)
                .map_err(|err| anyhow!("提交 Bika bundle 初始化任务失败: {err}"))?;
            task.wait_async()
                .await
                .map_err(|err| anyhow!("加载 Bika QJS bundle 失败: {err}"))?;

            let created = QJS_RUNTIME_CREATED.fetch_add(1, Ordering::SeqCst) + 1;
            tracing::info!(created_count = created, "bika qjs host runtime initialized");
            Ok(runtime)
        })
        .await
}

#[cfg(test)]
fn qjs_runtime_created_count() -> u64 {
    QJS_RUNTIME_CREATED.load(Ordering::SeqCst)
}

#[cfg(test)]
fn qjs_dispatch_total() -> u64 {
    QJS_DISPATCH_TOTAL.load(Ordering::SeqCst)
}

async fn run_qjs_dispatch(payload: Value) -> Result<Value> {
    let runtime = qjs_runtime().await?;
    let dispatch_no = QJS_DISPATCH_TOTAL.fetch_add(1, Ordering::SeqCst) + 1;
    let created_now = QJS_RUNTIME_CREATED.load(Ordering::SeqCst);
    tracing::debug!(
        dispatch_no,
        runtime_created_count = created_now,
        "bika qjs dispatch"
    );

    let payload_literal = serde_json::to_string(&payload).context("序列化 QJS payload 失败")?;
    let script = format!(
        r#"(async () => {{
  const payload = {payload};
  const result = await globalThis.__bika_dispatch(payload);
  return JSON.stringify(result);
}})()"#,
        payload = payload_literal,
    );

    let task = runtime
        .spawn(script)
        .map_err(|err| anyhow!("提交 QJS 请求任务失败: {err}"))?;
    let raw = task
        .wait_async()
        .await
        .map_err(|err| anyhow!("执行 QJS 请求失败: {err}"))?;
    serde_json::from_str::<Value>(&raw).context("解析 QJS 返回 JSON 失败")
}

async fn bika_request(
    method: &str,
    url: String,
    body: Option<Value>,
    authorization: Option<String>,
    image_quality: Option<String>,
) -> Result<String> {
    let effective_auth = resolve_authorization(authorization);
    if let Some(token) = effective_auth.as_deref() {
        let _ = set_cached_authorization(token);
    }

    let payload = json!({
        "action": "request",
        "request": {
            "method": method,
            "url": url,
            "body": body,
            "authorization": effective_auth,
            "imageQuality": default_image_quality(image_quality),
            "appChannel": default_app_channel(),
        }
    });

    let value = run_qjs_dispatch(payload).await?;

    if let Some(token) = extract_auth_token(&value) {
        let _ = set_cached_authorization(&token);
    }

    serde_json::to_string(&value).context("序列化响应结果失败")
}

fn build_url(path: &str) -> String {
    format!("{BIKA_BASE_URL}{path}")
}

#[frb]
pub async fn bika_login(username: String, password: String) -> Result<String> {
    bika_request(
        "POST",
        build_url("/auth/sign-in"),
        Some(json!({"email": username, "password": password})),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_register(
    birthday: String,
    email: String,
    gender: String,
    name: String,
    password: String,
) -> Result<String> {
    bika_request(
        "POST",
        build_url("/auth/register"),
        Some(json!({
            "answer1": "4",
            "answer2": "5",
            "answer3": "6",
            "birthday": birthday,
            "email": email,
            "gender": gender,
            "name": name,
            "password": password,
            "question1": "1",
            "question2": "2",
            "question3": "3",
        })),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_categories() -> Result<String> {
    bika_request("GET", build_url("/categories"), None, None, None).await
}

#[frb]
pub async fn bika_get_ranking_list(days: String, kind: String) -> Result<String> {
    let path = if kind == "creator" {
        "/comics/knight-leaderboard".to_string()
    } else if kind == "comic" {
        format!("/comics/leaderboard?tt={days}&ct=VC")
    } else {
        return Err(anyhow!("未知类型"));
    };
    bika_request("GET", build_url(&path), None, None, None).await
}

#[frb]
pub async fn bika_search(
    url: String,
    keyword: String,
    sort: String,
    categories: Vec<String>,
    page_count: i32,
) -> Result<String> {
    if !url.is_empty() {
        let req_url = if url.contains("comics?ca=") {
            let temp = url
                .split("&s")
                .next()
                .map(ToString::to_string)
                .unwrap_or(url);
            format!("{temp}&s={sort}&page={page_count}")
        } else if url == "https://picaapi.picacomic.com/comics/random" {
            url
        } else if url.contains("%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B") {
            format!(
                "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B&s={sort}"
            )
        } else if url
            == "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E6%BF%95%E6%8E%A8%E8%96%A6&s=$sort"
        {
            url
        } else if url.contains("%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9") {
            format!(
                "https://picaapi.picacomic.com/comics?page={page_count}&c=%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9&s={sort}"
            )
        } else if url.contains("%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B") {
            format!(
                "https://picaapi.picacomic.com/comics?page={page_count}&c=%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B&s={sort}"
            )
        } else {
            url
        };

        return bika_request("GET", req_url, None, None, None).await;
    }

    let mut body = json!({ "sort": sort });
    if !keyword.is_empty() {
        body["keyword"] = Value::String(keyword);
    }
    if !categories.is_empty() {
        body["categories"] = serde_json::to_value(categories).context("序列化 categories 失败")?;
    }

    bika_request(
        "POST",
        build_url(&format!("/comics/advanced-search?page={page_count}")),
        Some(body),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_search_keywords() -> Result<String> {
    bika_request("GET", build_url("/keywords"), None, None, None).await
}

#[frb]
pub async fn bika_get_comic_info(
    comic_id: String,
    authorization: Option<String>,
    image_quality: Option<String>,
) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/comics/{comic_id}")),
        None,
        authorization,
        image_quality,
    )
    .await
}

#[frb]
pub async fn bika_favourite_comic(comic_id: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comics/{comic_id}/favourite")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_like_comic(comic_id: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comics/{comic_id}/like")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_comments(comic_id: String, page_count: i32) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/comics/{comic_id}/comments?page={page_count}")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_comments_children(comment_id: String, page_count: i32) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!(
            "/comments/{comment_id}/childrens?page={page_count}"
        )),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_like_comment(comment_id: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comments/{comment_id}/like")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_write_comment(comic_id: String, content: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comics/{comic_id}/comments")),
        Some(json!({"content": content})),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_write_comment_children(comment_id: String, content: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comments/{comment_id}")),
        Some(json!({"content": content})),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_report_comments(comment_id: String) -> Result<String> {
    bika_request(
        "POST",
        build_url(&format!("/comments/{comment_id}/report")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_eps(
    comic_id: String,
    page_count: i32,
    authorization: Option<String>,
    image_quality: Option<String>,
) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/comics/{comic_id}/eps?page={page_count}")),
        None,
        authorization,
        image_quality,
    )
    .await
}

#[frb]
pub async fn bika_get_recommend(comic_id: String) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/comics/{comic_id}/recommendation")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_pages(
    comic_id: String,
    ep_id: i32,
    page_count: i32,
    authorization: Option<String>,
    image_quality: Option<String>,
) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!(
            "/comics/{comic_id}/order/{ep_id}/pages?page={page_count}"
        )),
        None,
        authorization,
        image_quality,
    )
    .await
}

#[frb]
pub async fn bika_get_user_profile() -> Result<String> {
    bika_request("GET", build_url("/users/profile"), None, None, None).await
}

#[frb]
pub async fn bika_update_avatar(avatar_base64_string: String) -> Result<String> {
    bika_request(
        "PUT",
        build_url("/users/avatar"),
        Some(json!({"avatar": format!("data:image/jpeg;base64,{avatar_base64_string}")})),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_update_profile(profile: String) -> Result<String> {
    bika_request(
        "PUT",
        build_url("/users/profile"),
        Some(json!({"slogan": profile})),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_update_password(new_password: String, old_password: String) -> Result<String> {
    bika_request(
        "PUT",
        build_url("/users/password"),
        Some(json!({
            "new_password": new_password,
            "old_password": old_password,
        })),
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_favorites(page_count: i32) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/users/favourite?s=dd&page={page_count}")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_get_user_comments(page_count: i32) -> Result<String> {
    bika_request(
        "GET",
        build_url(&format!("/users/my-comments?page={page_count}")),
        None,
        None,
        None,
    )
    .await
}

#[frb]
pub async fn bika_sign_in() -> Result<String> {
    bika_request("POST", build_url("/users/punch-in"), None, None, None).await
}

#[frb]
pub async fn bika_request_raw(
    url: String,
    method: String,
    body_json: Option<String>,
    image_quality: Option<String>,
    authorization: Option<String>,
) -> Result<String> {
    let body = match body_json {
        Some(raw) if !raw.trim().is_empty() => {
            Some(serde_json::from_str::<Value>(&raw).context("解析 body_json 失败")?)
        }
        _ => None,
    };
    bika_request(
        &method.to_uppercase(),
        url,
        body,
        authorization,
        image_quality,
    )
    .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    #[ignore = "需要真实账号与网络环境"]
    async fn live_login_once() {
        let username = std::env::var("BIKA_TEST_USERNAME").expect("缺少 BIKA_TEST_USERNAME");
        let password = std::env::var("BIKA_TEST_PASSWORD").expect("缺少 BIKA_TEST_PASSWORD");

        let raw = bika_login(username, password).await.expect("登录请求失败");
        let value: Value = serde_json::from_str(&raw).expect("响应 JSON 解析失败");
        assert_eq!(value.get("code").and_then(Value::as_i64), Some(200));
    }

    #[tokio::test]
    #[ignore = "需要真实账号与网络环境"]
    async fn live_login_twice_should_reuse_runtime() {
        let username = std::env::var("BIKA_TEST_USERNAME").expect("缺少 BIKA_TEST_USERNAME");
        let password = std::env::var("BIKA_TEST_PASSWORD").expect("缺少 BIKA_TEST_PASSWORD");

        let before_created = qjs_runtime_created_count();
        let before_dispatch = qjs_dispatch_total();

        let _ = bika_login(username.clone(), password.clone())
            .await
            .expect("第一次登录失败");
        let _ = bika_login(username, password)
            .await
            .expect("第二次登录失败");

        let created_delta = qjs_runtime_created_count().saturating_sub(before_created);
        let dispatch_delta = qjs_dispatch_total().saturating_sub(before_dispatch);

        assert_eq!(created_delta, 1, "同一进程内应只初始化一个 QJS runtime");
        assert_eq!(dispatch_delta, 2, "两次登录应对应两次 dispatch");
    }
}
