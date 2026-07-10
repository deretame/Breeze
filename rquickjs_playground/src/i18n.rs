//! 错误消息多语言支持
//! Multi-language error message support.

use std::collections::HashMap;
use std::sync::LazyLock;
use std::sync::atomic::{AtomicU8, Ordering};

/// 支持的错误消息语言
/// Supported error-message languages.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorMessageLang {
    /// 中文 / Chinese
    Zh,
    /// 英文 / English
    En,
}

const LANG_ZH: u8 = 0;
const LANG_EN: u8 = 1;

/// 当前语言，默认中文
/// Current language, defaults to Chinese.
static CURRENT_LANG: AtomicU8 = AtomicU8::new(LANG_ZH);

/// 中文消息表（key 为消息模板本身）
/// Chinese message table (keys are the message templates themselves).
static ZH_MESSAGES: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut m = HashMap::new();
    insert_messages(&mut m);
    m
});

/// 英文消息表
/// English message table.
static EN_MESSAGES: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut m = HashMap::new();
    insert_messages_en(&mut m);
    m
});

/// 设置错误消息语言
/// Set error-message language.
///
/// `lang` 支持 `"zh"` 或 `"en"`，其它值会被忽略。
/// `lang` accepts `"zh"` or `"en"`; other values are ignored.
/// 返回是否识别成功 / Returns whether the language was recognized.
pub fn set_error_message_language(lang: &str) -> bool {
    let code = match lang {
        "zh" => LANG_ZH,
        "en" => LANG_EN,
        _ => return false,
    };
    CURRENT_LANG.store(code, Ordering::Relaxed);
    true
}

/// 获取当前错误消息语言
/// Get the current error-message language.
pub fn current_error_message_language() -> ErrorMessageLang {
    match CURRENT_LANG.load(Ordering::Relaxed) {
        LANG_EN => ErrorMessageLang::En,
        _ => ErrorMessageLang::Zh,
    }
}

/// 根据 key 读取当前语言的静态消息
/// Read the static message for the current language by key.
///
/// 如果 key 不存在则返回 key 本身，避免崩溃。
/// If the key is missing, returns the key itself to avoid panics.
pub fn t(key: &str) -> &str {
    let map = match current_error_message_language() {
        ErrorMessageLang::En => &*EN_MESSAGES,
        ErrorMessageLang::Zh => &*ZH_MESSAGES,
    };
    map.get(key).copied().unwrap_or(key)
}

/// 按位置参数拼接消息模板
/// Format a message template with positional arguments.
///
/// 模板使用 `{0}`、`{1}` 等占位符。
/// Templates use `{0}`, `{1}`, etc. placeholders.
pub fn format_message(key: &str, args: &[&dyn std::fmt::Display]) -> String {
    let mut s = t(key).to_string();
    for (i, arg) in args.iter().enumerate() {
        let placeholder = format!("{{{}}}", i);
        s = s.replace(&placeholder, &format!("{}", arg));
    }
    s
}

fn insert_messages(m: &mut HashMap<&'static str, &'static str>) {
    m.insert("执行脚本失败", "执行脚本失败");
    m.insert("解析结果失败", "解析结果失败");
    m.insert("创建 AsyncHostRuntime 失败", "创建 AsyncHostRuntime 失败");
    m.insert("native buffer 池加锁失败", "native buffer 池加锁失败");
    m.insert("提交任务失败", "提交任务失败");
    m.insert("base64 解码失败", "base64 解码失败");
    m.insert("序列化路由名失败", "序列化路由名失败");
    m.insert("创建 tokio runtime 失败", "创建 tokio runtime 失败");
    m.insert("bridge 同步路由表锁已损坏", "bridge 同步路由表锁已损坏");
    m.insert("bridge 异步路由表锁已损坏", "bridge 异步路由表锁已损坏");
    m.insert("bridge 阻塞路由表锁已损坏", "bridge 阻塞路由表锁已损坏");
    m.insert("runtime_name 不能为空", "runtime_name 不能为空");
    m.insert("bundle_js 不能为空", "bundle_js 不能为空");
    m.insert("序列化 bundle 名称失败: {0}", "序列化 bundle 名称失败: {0}");
    m.insert("执行失败", "执行失败");
    m.insert("更新 HTTP 配置失败", "更新 HTTP 配置失败");
    m.insert("bridge 请求池加锁失败", "bridge 请求池加锁失败");
    m.insert("http 请求池加锁失败", "http 请求池加锁失败");
    m.insert("fs 请求池加锁失败", "fs 请求池加锁失败");
    m.insert(
        "当前构建未启用 host-fs Cargo 特性",
        "当前构建未启用 host-fs Cargo 特性",
    );
    m.insert(
        "等待任务结果失败: runtime 已关闭",
        "等待任务结果失败: runtime 已关闭",
    );
    m.insert("恢复 HTTP 配置失败", "恢复 HTTP 配置失败");
    m.insert("Body 已被读取", "Body 已被读取");
    m.insert("任务执行失败", "任务执行失败");
    m.insert("参数 {0} 必须是字符串", "参数 {0} 必须是字符串");
    m.insert("数据必须是字节数组", "数据必须是字节数组");
    m.insert("字节数组元素必须是整数", "字节数组元素必须是整数");
    m.insert(
        "字节数组元素必须在 0-255 范围",
        "字节数组元素必须在 0-255 范围",
    );
    m.insert("buffer id 不存在", "buffer id 不存在");
    m.insert("request id 不存在", "request id 不存在");
    m.insert("初始化 hmac 失败", "初始化 hmac 失败");
    m.insert("http event 请求池加锁失败", "http event 请求池加锁失败");
    m.insert("已拦截内网请求: {0}", "已拦截内网请求: {0}");
    m.insert("timer event 请求池加锁失败", "timer event 请求池加锁失败");
    m.insert("fs event 请求池加锁失败", "fs event 请求池加锁失败");
    m.insert("文件上传失败: {0}", "文件上传失败: {0}");
    m.insert(
        "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle",
        "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle",
    );
    m.insert("任务类型不匹配: {0}", "任务类型不匹配: {0}");
    m.insert("eval失败: {0}", "eval失败: {0}");
    m.insert("提交任务失败: 状态锁已损坏", "提交任务失败: 状态锁已损坏");
    m.insert(
        "提交任务失败: 等待器锁已损坏",
        "提交任务失败: 等待器锁已损坏",
    );
    m.insert("提交任务失败: worker 不可用", "提交任务失败: worker 不可用");
    m.insert("序列化 bundle 脚本失败: {0}", "序列化 bundle 脚本失败: {0}");
    m.insert("加载 bundle 失败: {0}", "加载 bundle 失败: {0}");
    m.insert("调用参数必须是 JSON 数组", "调用参数必须是 JSON 数组");
    m.insert(
        "执行一次性 bundle 调用失败: {0}",
        "执行一次性 bundle 调用失败: {0}",
    );
    m.insert("卸载 bundle 失败: {0}", "卸载 bundle 失败: {0}");
    m.insert("读取 bundle 列表失败: {0}", "读取 bundle 列表失败: {0}");
    m.insert(
        "初始化 bundle dispatcher 失败: {0}",
        "初始化 bundle dispatcher 失败: {0}",
    );
    m.insert("序列化调用参数失败: {0}", "序列化调用参数失败: {0}");
    m.insert(
        "等待任务结果失败: 任务句柄已失效",
        "等待任务结果失败: 任务句柄已失效",
    );
    m.insert("序列化函数路径失败: {0}", "序列化函数路径失败: {0}");
    m.insert("系统时间异常", "系统时间异常");
    m.insert("创建临时目录失败", "创建临时目录失败");
    m.insert("创建 runtime 失败", "创建 runtime 失败");
    m.insert("等待脚本结果失败", "等待脚本结果失败");
    m.insert("已拦截内网请求", "已拦截内网请求");
    m.insert("names 必须是数组", "names 必须是数组");
    m.insert(
        "执行 pnpm test:cases:node 失败: {0}",
        "执行 pnpm test:cases:node 失败: {0}",
    );
    m.insert("启动测试服务失败", "启动测试服务失败");
    m.insert("卸载 bridge 自定义路由失败", "卸载 bridge 自定义路由失败");
    m.insert(
        "注册 bridge 同步自定义路由失败",
        "注册 bridge 同步自定义路由失败",
    );
    m.insert(
        "卸载 bridge 同步自定义路由失败",
        "卸载 bridge 同步自定义路由失败",
    );
    m.insert("调用应失败", "调用应失败");
    m.insert("不支持的 bridge 方法: {0}", "不支持的 bridge 方法: {0}");
    m.insert("缺少参数: {0}", "缺少参数: {0}");
    m.insert("参数 {0} 必须是非负整数", "参数 {0} 必须是非负整数");
    m.insert("gzip 压缩失败", "gzip 压缩失败");
    m.insert("参数 a 必须是数字", "参数 a 必须是数字");
    m.insert("参数 b 必须是数字", "参数 b 必须是数字");
    m.insert("bridge 路由已被拒绝: {0}", "bridge 路由已被拒绝: {0}");
    m.insert("request 执行线程异常退出", "request 执行线程异常退出");
    m.insert("AES-128 密钥长度无效", "AES-128 密钥长度无效");
    m.insert("AES-192 密钥长度无效", "AES-192 密钥长度无效");
    m.insert("AES-256 密钥长度无效", "AES-256 密钥长度无效");
    m.insert(
        "AES ECB 密钥长度必须是 16/24/32 字节，当前: {0}",
        "AES ECB 密钥长度必须是 16/24/32 字节，当前: {0}",
    );
    m.insert("AES ECB PKCS7 填充无效", "AES ECB PKCS7 填充无效");
    m.insert(
        "AES CBC 密钥长度必须是 16/24/32 字节，当前: {0}",
        "AES CBC 密钥长度必须是 16/24/32 字节，当前: {0}",
    );
    m.insert("AES-128 GCM 参数无效", "AES-128 GCM 参数无效");
    m.insert("AES-256 GCM 参数无效", "AES-256 GCM 参数无效");
    m.insert(
        "AES GCM 密钥长度必须是 16/32 字节，当前: {0}",
        "AES GCM 密钥长度必须是 16/32 字节，当前: {0}",
    );
    m.insert("不支持的编码: {0}", "不支持的编码: {0}");
    m.insert("HTTP client 状态锁已损坏", "HTTP client 状态锁已损坏");
    m.insert(
        "解析 socks5 代理地址失败: {0}",
        "解析 socks5 代理地址失败: {0}",
    );
    m.insert("http pending 队列已满", "http pending 队列已满");
    m.insert("http 并发控制器不可用", "http 并发控制器不可用");
    m.insert("http 等待并发许可超时", "http 等待并发许可超时");
    m.insert("gzip 压缩失败: {0}", "gzip 压缩失败: {0}");
    m.insert("input id 不存在", "input id 不存在");
    m.insert("extra input id 不存在", "extra input id 不存在");
    m.insert("fs pending 队列已满", "fs pending 队列已满");
    m.insert("fs 并发控制器不可用", "fs 并发控制器不可用");
    m.insert("fs 等待并发许可超时", "fs 等待并发许可超时");
    m.insert("打开备份 zip 失败: {0}", "打开备份 zip 失败: {0}");
    m.insert("读取 zip 失败: {0}", "读取 zip 失败: {0}");
    m.insert("读取输入文件失败: {0}", "读取输入文件失败: {0}");
    m.insert("解析图片失败: {0}", "解析图片失败: {0}");
    m.insert("md5 下载失败: {0}", "md5 下载失败: {0}");
    m.insert("文件下载失败: {0}", "文件下载失败: {0}");
    m.insert("打开文件{0}失败", "打开文件{0}失败");
    m.insert("bundle_name 不能为空", "bundle_name 不能为空");
    m.insert("序列化调用结果失败", "序列化调用结果失败");
    m.insert("序列化一次性调用结果失败", "序列化一次性调用结果失败");
    m.insert("读取 bundle 列表失败: {0}", "读取 bundle 列表失败: {0}");
    m.insert(
        "任务类型不匹配(期望二进制): {0}",
        "任务类型不匹配(期望二进制): {0}",
    );
    m.insert("无法读取字符串", "无法读取字符串");
    m.insert(
        "初始化 AsyncContext 失败: {0}",
        "初始化 AsyncContext 失败: {0}",
    );
    m.insert(
        "初始化 Context 绑定失败: {0}",
        "初始化 Context 绑定失败: {0}",
    );
    m.insert(
        "初始化 AsyncRuntime 失败: {0}",
        "初始化 AsyncRuntime 失败: {0}",
    );
    m.insert(
        "AsyncHostRuntime worker 信号通道不可用",
        "AsyncHostRuntime worker 信号通道不可用",
    );
    m.insert(
        "安装 AsyncHostRuntime 上下文绑定失败: {0}",
        "安装 AsyncHostRuntime 上下文绑定失败: {0}",
    );
    m.insert(
        "安装一次性 Context 绑定失败: {0}",
        "安装一次性 Context 绑定失败: {0}",
    );
    m.insert(
        "一次性 Context slot 不存在: {0}",
        "一次性 Context slot 不存在: {0}",
    );
    m.insert(
        "执行 JS event loop job 失败: {0}",
        "执行 JS event loop job 失败: {0}",
    );
    m.insert(
        "创建 per-instance tokio runtime 失败",
        "创建 per-instance tokio runtime 失败",
    );
    m.insert(
        "初始化 HostRuntime 失败: {0}",
        "初始化 HostRuntime 失败: {0}",
    );
    m.insert("获取 tokio handle 失败", "获取 tokio handle 失败");
    m.insert(
        "初始化 HostRuntime 失败: worker 提前退出",
        "初始化 HostRuntime 失败: worker 提前退出",
    );
    m.insert("触发 GC 失败: worker 不可用", "触发 GC 失败: worker 不可用");
    m.insert("触发 GC 失败: worker 已关闭", "触发 GC 失败: worker 已关闭");
    m.insert("执行 bundle 函数失败: {0}", "执行 bundle 函数失败: {0}");
    m.insert(
        "提交 bundle 调用任务失败: {0}",
        "提交 bundle 调用任务失败: {0}",
    );
    m.insert(
        "读取 bundle 列表失败: 返回值不是数组",
        "读取 bundle 列表失败: 返回值不是数组",
    );
    m.insert(
        "计算一次性 bundle 哈希失败: {0}",
        "计算一次性 bundle 哈希失败: {0}",
    );
    m.insert(
        "解析 JSON 任务结果失败: {0}; payload={1}",
        "解析 JSON 任务结果失败: {0}; payload={1}",
    );
    m.insert(
        "native buffer 不存在或已被消费: {0}",
        "native buffer 不存在或已被消费: {0}",
    );
    m.insert(
        "字节数组第 {0} 项不是无符号整数",
        "字节数组第 {0} 项不是无符号整数",
    );
    m.insert(
        "字节数组第 {0} 项超出范围: {1}",
        "字节数组第 {0} 项超出范围: {1}",
    );
    m.insert(
        "无法将字符串解码为 base64 字节: {0}",
        "无法将字符串解码为 base64 字节: {0}",
    );
    m.insert(
        "不支持的二进制返回类型：期望 nativeBufferId / number[] / base64字符串",
        "不支持的二进制返回类型：期望 nativeBufferId / number[] / base64字符串",
    );
    m.insert("解析 JS 返回 JSON 失败: {0}", "解析 JS 返回 JSON 失败: {0}");
    m.insert(
        "安装 AsyncHostRuntime 绑定失败: {0}",
        "安装 AsyncHostRuntime 绑定失败: {0}",
    );
    m.insert(
        "读取任务结果失败: 状态锁已损坏",
        "读取任务结果失败: 状态锁已损坏",
    );
    m.insert(
        "读取任务结果失败: 任务尚未完成",
        "读取任务结果失败: 任务尚未完成",
    );
    m.insert(
        "读取任务结果失败: 任务不存在",
        "读取任务结果失败: 任务不存在",
    );
    m.insert("读取 case bundle 失败", "读取 case bundle 失败");
    m.insert("序列化 bundle 失败", "序列化 bundle 失败");
    m.insert("序列化 config 失败", "序列化 config 失败");
    m.insert("执行 bundle case 失败", "执行 bundle case 失败");
    m.insert("解析 case 结果失败", "解析 case 结果失败");
    m.insert(
        "case 执行失败: {0}\\nraw={1}",
        "case 执行失败: {0}\\nraw={1}",
    );
    m.insert("未知错误", "未知错误");
    m.insert(
        "pnpm test:cases:node 失败\\nstdout:\\n{0}\\nstderr:\\n{1}",
        "pnpm test:cases:node 失败\\nstdout:\\n{0}\\nstderr:\\n{1}",
    );
    m.insert("构造二进制响应头失败", "构造二进制响应头失败");
    m.insert("构造响应头失败", "构造响应头失败");
    m.insert("构造自定义响应头失败", "构造自定义响应头失败");
    m.insert("构造额外响应头失败", "构造额外响应头失败");
    m.insert("注册 bridge 自定义路由失败", "注册 bridge 自定义路由失败");
    m.insert(
        "注册 bridge 异步自定义路由失败",
        "注册 bridge 异步自定义路由失败",
    );
    m.insert(
        "注册 bridge 阻塞自定义路由失败",
        "注册 bridge 阻塞自定义路由失败",
    );
    m.insert(
        "卸载 bridge 阻塞自定义路由失败",
        "卸载 bridge 阻塞自定义路由失败",
    );
    m.insert("events 必须是数组", "events 必须是数组");
    m.insert("A中B", "A中B");
    m.insert("无法 clone", "无法 clone");
    m.insert("未收到第 1 条日志回调", "未收到第 1 条日志回调");
    m.insert("未收到第 2 条日志回调", "未收到第 2 条日志回调");
    m.insert("未收到第 3 条日志回调", "未收到第 3 条日志回调");
    m.insert("任务应被 dropped", "任务应被 dropped");
    m.insert("多任务并发耗时异常: {0}ms", "多任务并发耗时异常: {0}ms");
    m.insert("异步等待任务 panic", "异步等待任务 panic");
    m.insert("任务执行失败: {0}", "任务执行失败: {0}");
    m.insert(
        "独立 async 等待者并发耗时异常: {0}ms",
        "独立 async 等待者并发耗时异常: {0}ms",
    );
    m.insert(
        "wait handle 并发耗时异常: {0}ms",
        "wait handle 并发耗时异常: {0}ms",
    );
    m.insert("解析 typed 结果失败", "解析 typed 结果失败");
    m.insert("warmup task1 join 失败", "warmup task1 join 失败");
    m.insert("warmup task1 执行失败", "warmup task1 执行失败");
    m.insert("warmup task2 join 失败", "warmup task2 join 失败");
    m.insert("warmup task2 执行失败", "warmup task2 执行失败");
    m.insert("task1 join 失败", "task1 join 失败");
    m.insert("task1 执行失败", "task1 执行失败");
    m.insert("task2 join 失败", "task2 join 失败");
    m.insert("task2 执行失败", "task2 执行失败");
    m.insert(
        "bundle_call_once 仍然被串行化，耗时={0}ms",
        "bundle_call_once 仍然被串行化，耗时={0}ms",
    );
    m.insert("缺少调用上下文: {0}", "缺少调用上下文: {0}");
    m.insert("缺少逻辑源码名: {0}", "缺少逻辑源码名: {0}");
    m.insert("缺少 targetType: {0}", "缺少 targetType: {0}");
    m.insert("缺少 ownerKeys: {0}", "缺少 ownerKeys: {0}");
    m.insert("缺少 rootKeys: {0}", "缺少 rootKeys: {0}");
    m.insert(
        "runtime 销毁后 wait 不应被无限阻塞",
        "runtime 销毁后 wait 不应被无限阻塞",
    );
    m.insert(
        "runtime 销毁后任务应返回错误",
        "runtime 销毁后任务应返回错误",
    );
    m.insert("runtime 已关闭", "runtime 已关闭");
    m.insert("绑定测试端口失败", "绑定测试端口失败");
    m.insert("读取地址失败", "读取地址失败");
    m.insert("发送测试地址失败", "发送测试地址失败");
    m.insert("接收测试地址失败", "接收测试地址失败");
    m.insert(
        "sourcemap 应解析到 src/index.ts:143:12，实际错误: {0}",
        "sourcemap 应解析到 src/index.ts:143:12，实际错误: {0}",
    );
    m.insert("bridge 运行时配置锁已损坏", "bridge 运行时配置锁已损坏");
    m.insert("bridge 调用失败", "bridge 调用失败");
    m.insert("bridge 路由名不能为空", "bridge 路由名不能为空");
    m.insert(
        "bridge blocking 路由任务 join 失败: {0}",
        "bridge blocking 路由任务 join 失败: {0}",
    );
    m.insert("解析宿主返回 JSON 失败", "解析宿主返回 JSON 失败");
    m.insert("调用失败", "调用失败");
    m.insert("bridge 参数过大: {0} > {1}", "bridge 参数过大: {0} > {1}");
    m.insert("解析 bridge args JSON 失败", "解析 bridge args JSON 失败");
    m.insert("args 必须是数组", "args 必须是数组");
    m.insert(
        "bridge bytes 参数缺少 nativeBufferId",
        "bridge bytes 参数缺少 nativeBufferId",
    );
    m.insert(
        "bridge bytes 参数 nativeBufferId 不存在: {0}",
        "bridge bytes 参数 nativeBufferId 不存在: {0}",
    );
    m.insert("gzip 解压失败", "gzip 解压失败");
    m.insert(
        "bridge 返回二进制过大: {0} > {1}",
        "bridge 返回二进制过大: {0} > {1}",
    );
    m.insert("bridge pending 队列已满", "bridge pending 队列已满");
    m.insert("解密结果不是有效 UTF-8", "解密结果不是有效 UTF-8");
    m.insert(
        "dispatch_crypto_route 被传入非 crypto 路由: {0}",
        "dispatch_crypto_route 被传入非 crypto 路由: {0}",
    );
    m.insert(
        "AES ECB 密文长度必须是 16 的倍数",
        "AES ECB 密文长度必须是 16 的倍数",
    );
    m.insert("AES ECB 解密结果为空", "AES ECB 解密结果为空");
    m.insert("AES-128 CBC 参数无效", "AES-128 CBC 参数无效");
    m.insert("AES-128 CBC 加密失败", "AES-128 CBC 加密失败");
    m.insert("AES-192 CBC 参数无效", "AES-192 CBC 参数无效");
    m.insert("AES-192 CBC 加密失败", "AES-192 CBC 加密失败");
    m.insert("AES-256 CBC 参数无效", "AES-256 CBC 参数无效");
    m.insert("AES-256 CBC 加密失败", "AES-256 CBC 加密失败");
    m.insert("AES-128 CBC 参数无效: {0}", "AES-128 CBC 参数无效: {0}");
    m.insert("AES-128 CBC 解密失败: {0}", "AES-128 CBC 解密失败: {0}");
    m.insert("AES-192 CBC 参数无效: {0}", "AES-192 CBC 参数无效: {0}");
    m.insert("AES-192 CBC 解密失败: {0}", "AES-192 CBC 解密失败: {0}");
    m.insert("AES-256 CBC 参数无效: {0}", "AES-256 CBC 参数无效: {0}");
    m.insert("AES-256 CBC 解密失败: {0}", "AES-256 CBC 解密失败: {0}");
    m.insert("AES-128 GCM 加密失败", "AES-128 GCM 加密失败");
    m.insert("AES-256 GCM 加密失败", "AES-256 GCM 加密失败");
    m.insert("AES-128 GCM 解密失败", "AES-128 GCM 解密失败");
    m.insert("AES-256 GCM 解密失败", "AES-256 GCM 解密失败");
    m.insert("生成随机字节失败", "生成随机字节失败");
    m.insert("参数 {0} 必须是布尔值", "参数 {0} 必须是布尔值");
    m.insert("参数 {0} 超出 u32 范围", "参数 {0} 超出 u32 范围");
    m.insert("参数 {0} 必须是整数", "参数 {0} 必须是整数");
    m.insert("writeFile 参数无效", "writeFile 参数无效");
    m.insert("mkdir 参数无效", "mkdir 参数无效");
    m.insert("readdir 参数无效", "readdir 参数无效");
    m.insert("rm 参数无效", "rm 参数无效");
    m.insert("rename 参数无效", "rename 参数无效");
    m.insert("copyFile 参数无效", "copyFile 参数无效");
    m.insert("cp 参数无效", "cp 参数无效");
    m.insert("symlink 参数无效", "symlink 参数无效");
    m.insert("link 参数无效", "link 参数无效");
    m.insert("truncate 参数无效", "truncate 参数无效");
    m.insert("chmod 参数无效", "chmod 参数无效");
    m.insert("utimes 参数无效", "utimes 参数无效");
    m.insert("不支持的 fs 异步操作: {0}", "不支持的 fs 异步操作: {0}");
    m.insert("缺少 kind 字段", "缺少 kind 字段");
    m.insert("bytes 数据格式错误", "bytes 数据格式错误");
    m.insert(
        "bytes 数据必须是 0-255 的整数",
        "bytes 数据必须是 0-255 的整数",
    );
    m.insert(
        "bytes 数据必须在 0-255 范围内",
        "bytes 数据必须在 0-255 范围内",
    );
    m.insert("text 数据格式错误", "text 数据格式错误");
    m.insert("不支持的 kind: {0}", "不支持的 kind: {0}");
    m.insert("文件或目录不存在", "文件或目录不存在");
    m.insert("当前平台不支持符号链接", "当前平台不支持符号链接");
    m.insert("当前平台不支持 chmod", "当前平台不支持 chmod");
    m.insert("源路径不存在", "源路径不存在");
    m.insert("目标路径已存在", "目标路径已存在");
    m.insert(
        "目标路径已存在，且未启用 force",
        "目标路径已存在，且未启用 force",
    );
    m.insert(
        "复制目录时必须启用 recursive",
        "复制目录时必须启用 recursive",
    );
    m.insert("无法创建唯一临时目录", "无法创建唯一临时目录");
    m.insert(
        "解析 host formdata plan JSON 失败",
        "解析 host formdata plan JSON 失败",
    );
    m.insert(
        "不支持的 formdata plan kind: {0}",
        "不支持的 formdata plan kind: {0}",
    );
    m.insert(
        "base64 解码 formdata 字段失败",
        "base64 解码 formdata 字段失败",
    );
    m.insert("formdata 文本字段缺少 value", "formdata 文本字段缺少 value");
    m.insert(
        "formdata 二进制字段缺少 dataB64",
        "formdata 二进制字段缺少 dataB64",
    );
    m.insert(
        "设置 formdata part Content-Type 失败: {0}",
        "设置 formdata part Content-Type 失败: {0}",
    );
    m.insert(
        "不支持的 formdata 字段类型: {0}",
        "不支持的 formdata 字段类型: {0}",
    );
    m.insert("解析 HTTP 代理地址失败: {0}", "解析 HTTP 代理地址失败: {0}");
    m.insert("创建 HTTP client 失败", "创建 HTTP client 失败");
    m.insert("解析 HTTP method 失败", "解析 HTTP method 失败");
    m.insert("解析 HTTP headers JSON 失败", "解析 HTTP headers JSON 失败");
    m.insert(
        "formdata 请求缺少 body payload",
        "formdata 请求缺少 body payload",
    );
    m.insert(
        "request body nativeBufferId 不存在: {0}",
        "request body nativeBufferId 不存在: {0}",
    );
    m.insert("发送 HTTP 请求失败", "发送 HTTP 请求失败");
    m.insert("解析 HTTP 响应头失败", "解析 HTTP 响应头失败");
    m.insert("读取 HTTP 响应体字节失败", "读取 HTTP 响应体字节失败");
    m.insert("读取 HTTP 响应体失败", "读取 HTTP 响应体失败");
    m.insert("解析 URL 失败: {0}", "解析 URL 失败: {0}");
    m.insert("URL 缺少 host: {0}", "URL 缺少 host: {0}");
    m.insert("解析域名失败: {0}", "解析域名失败: {0}");
    m.insert(
        "创建 native buffer gc 线程失败",
        "创建 native buffer gc 线程失败",
    );
    m.insert("解析字节数组 JSON 失败", "解析字节数组 JSON 失败");
    m.insert("xor 需要第二个输入参数", "xor 需要第二个输入参数");
    m.insert("xor 两个输入长度必须一致", "xor 两个输入长度必须一致");
    m.insert("gzip 解压失败: {0}", "gzip 解压失败: {0}");
    m.insert("不支持的 native op: {0}", "不支持的 native op: {0}");
    m.insert("解析 steps JSON 失败", "解析 steps JSON 失败");
    m.insert("steps 必须是数组", "steps 必须是数组");
    m.insert("steps 元素必须是对象", "steps 元素必须是对象");
    m.insert("steps 元素缺少 op 字段", "steps 元素缺少 op 字段");
    m.insert("steps 不能为空", "steps 不能为空");
    m.insert("size 必须是非负整数", "size 必须是非负整数");
    m.insert("iterations 必须大于 0", "iterations 必须大于 0");
    m.insert("keyLen 必须是非负整数", "keyLen 必须是非负整数");
    m.insert("native buffer id 不存在", "native buffer id 不存在");
    m.insert("base64 解码失败: {0}", "base64 解码失败: {0}");
    m.insert(
        "创建日志直连 HTTP client 失败",
        "创建日志直连 HTTP client 失败",
    );
    m.insert(
        "日志直连 HTTP client 初始化后必须可读取",
        "日志直连 HTTP client 初始化后必须可读取",
    );
    m.insert(
        "日志直连 HTTP client 并发初始化后必须可读取",
        "日志直连 HTTP client 并发初始化后必须可读取",
    );
    m.insert(
        "创建 log-forward tokio runtime 失败",
        "创建 log-forward tokio runtime 失败",
    );
    m.insert(
        "[qjs-log-http] 转发失败: {0}",
        "[qjs-log-http] 转发失败: {0}",
    );
    m.insert(
        "[qjs-log-http] 日志直连 HTTP client 不可用，跳过日志转发",
        "[qjs-log-http] 日志直连 HTTP client 不可用，跳过日志转发",
    );
    m.insert("创建 log worker 失败", "创建 log worker 失败");
    m.insert("timer pending 队列已满", "timer pending 队列已满");
    m.insert("fs 执行任务异常退出", "fs 执行任务异常退出");
    m.insert("log worker 不可用: {0}", "log worker 不可用: {0}");
    m.insert("创建备份 zip 文件失败: {0}", "创建备份 zip 文件失败: {0}");
    m.insert(
        "向 zip 添加数据目录失败: {0}",
        "向 zip 添加数据目录失败: {0}",
    );
    m.insert(
        "向 zip 添加下载目录失败: {0}",
        "向 zip 添加下载目录失败: {0}",
    );
    m.insert("完成 zip 写入失败", "完成 zip 写入失败");
    m.insert("zip 备份任务执行失败", "zip 备份任务执行失败");
    m.insert("备份包中缺少 config.json", "备份包中缺少 config.json");
    m.insert("读取 config.json 失败", "读取 config.json 失败");
    m.insert("读取备份配置任务执行失败", "读取备份配置任务执行失败");
    m.insert("创建解压目录失败: {0}", "创建解压目录失败: {0}");
    m.insert("读取 zip 第 {0} 个条目失败", "读取 zip 第 {0} 个条目失败");
    m.insert("发现非法 zip 条目路径: {0}", "发现非法 zip 条目路径: {0}");
    m.insert("创建目录失败: {0}", "创建目录失败: {0}");
    m.insert("创建父目录失败: {0}", "创建父目录失败: {0}");
    m.insert("创建文件失败: {0}", "创建文件失败: {0}");
    m.insert("读取 zip 条目失败: {0}", "读取 zip 条目失败: {0}");
    m.insert("写入文件失败: {0}", "写入文件失败: {0}");
    m.insert("zip 解压任务执行失败", "zip 解压任务执行失败");
    m.insert("读取目录失败: {0}", "读取目录失败: {0}");
    m.insert("读取目录项失败: {0}", "读取目录项失败: {0}");
    m.insert("向 zip 添加目录失败: {0}", "向 zip 添加目录失败: {0}");
    m.insert("递归添加目录失败: {0}", "递归添加目录失败: {0}");
    m.insert("向 zip 添加文件失败: {0}", "向 zip 添加文件失败: {0}");
    m.insert("打开文件失败: {0}", "打开文件失败: {0}");
    m.insert("创建 zip 条目失败: {0}", "创建 zip 条目失败: {0}");
    m.insert("读取文件失败: {0}", "读取文件失败: {0}");
    m.insert("写入 zip 条目失败: {0}", "写入 zip 条目失败: {0}");
    m.insert("写入 WebP 文件失败: {0}", "写入 WebP 文件失败: {0}");
    m.insert("写入 PNG 文件失败: {0}", "写入 PNG 文件失败: {0}");
    m.insert("WebDAV 连接测试失败: {0}", "WebDAV 连接测试失败: {0}");
    m.insert("WebDAV 服务请求失败: {0}", "WebDAV 服务请求失败: {0}");
    m.insert("文件删除失败: {0}", "文件删除失败: {0}");
    m.insert("文件删除失败，状态码: {0}", "文件删除失败，状态码: {0}");
    m.insert("WebDAV 配置不完整", "WebDAV 配置不完整");
    m.insert("构建 HTTP 客户端失败: {0}", "构建 HTTP 客户端失败: {0}");
    m.insert("构建 WebDAV 客户端失败: {0}", "构建 WebDAV 客户端失败: {0}");
    m.insert("目录创建失败，状态码: {0}", "目录创建失败，状态码: {0}");
    m.insert("目录创建失败: {0}", "目录创建失败: {0}");
    m.insert("文件不存在，状态码: {0}", "文件不存在，状态码: {0}");
    m.insert("文件下载失败，状态码: {0}", "文件下载失败，状态码: {0}");
    m.insert("文件下载失败，重试次数用尽", "文件下载失败，重试次数用尽");
    m.insert("文件上传失败，状态码: {0}", "文件上传失败，状态码: {0}");
    m.insert("远端路径不能为空", "远端路径不能为空");
    m.insert("创建tar文件失败", "创建tar文件失败");
    m.insert(
        "将comic_info_string.json添加到压缩包失败",
        "将comic_info_string.json添加到压缩包失败",
    );
    m.insert(
        "将processed_comic_info_string.json添加到压缩包失败",
        "将processed_comic_info_string.json添加到压缩包失败",
    );
    m.insert("获取{0}的元数据失败", "获取{0}的元数据失败");
    m.insert("将{0}添加到压缩包失败", "将{0}添加到压缩包失败");
    m.insert("完成压缩包失败", "完成压缩包失败");
    m.insert("创建ZIP文件失败", "创建ZIP文件失败");
    m.insert("创建comic_info.json条目失败", "创建comic_info.json条目失败");
    m.insert("写入comic_info.json失败", "写入comic_info.json失败");
    m.insert(
        "创建processed_comic_info.json条目失败",
        "创建processed_comic_info.json条目失败",
    );
    m.insert(
        "写入processed_comic_info.json失败",
        "写入processed_comic_info.json失败",
    );
    m.insert("创建ZIP条目{0}失败", "创建ZIP条目{0}失败");
    m.insert("读取文件{0}失败", "读取文件{0}失败");
    m.insert("写入ZIP条目{0}失败", "写入ZIP条目{0}失败");
    m.insert("完成ZIP文件失败", "完成ZIP文件失败");
    m.insert("ZIP任务执行失败", "ZIP任务执行失败");
    m.insert("ZIP压缩失败", "ZIP压缩失败");
    m.insert("写入压缩流数据失败", "写入压缩流数据失败");
    m.insert("刷写压缩流失败", "刷写压缩流失败");
    m.insert("压缩线程池调度失败", "压缩线程池调度失败");
    m.insert(
        "Brotli 解压失败：数据可能损坏或非标准格式",
        "Brotli 解压失败：数据可能损坏或非标准格式",
    );
    m.insert("解压线程池调度失败", "解压线程池调度失败");
    m.insert("创建解压目标目录失败: {0}", "创建解压目标目录失败: {0}");
    m.insert("7z 解压失败: {0}", "7z 解压失败: {0}");
    m.insert("7z 解压任务执行失败", "7z 解压任务执行失败");
    m.insert(
        "opencc config 必须是 OpenCC 配置文件名，例如 t2s.json",
        "opencc config 必须是 OpenCC 配置文件名，例如 t2s.json",
    );
    m.insert(
        "不支持的 OpenCC 转换配置: {0} ({1})",
        "不支持的 OpenCC 转换配置: {0} ({1})",
    );
    m.insert("初始化 OpenCC 失败: {0}", "初始化 OpenCC 失败: {0}");
    m.insert("opencc 参数必须是 JSON 对象", "opencc 参数必须是 JSON 对象");
    m.insert("opencc 参数缺少 text 字段", "opencc 参数缺少 text 字段");
    m.insert(
        "opencc 参数缺少 config 字段，例如 t2s.json",
        "opencc 参数缺少 config 字段，例如 t2s.json",
    );
    m.insert(
        "cache.get 参数无效: 缺少 key",
        "cache.get 参数无效: 缺少 key",
    );
    m.insert(
        "cache.set 参数无效: 缺少 key",
        "cache.set 参数无效: 缺少 key",
    );
    m.insert(
        "cache.set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "cache.set_if_absent 参数无效: 缺少 key",
        "cache.set_if_absent 参数无效: 缺少 key",
    );
    m.insert(
        "cache.set_if_absent 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.set_if_absent 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "cache.compare_and_set 参数无效: 缺少 key",
        "cache.compare_and_set 参数无效: 缺少 key",
    );
    m.insert(
        "cache.compare_and_set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.compare_and_set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "提交 QJS 初始化任务失败: {0}",
        "提交 QJS 初始化任务失败: {0}",
    );
    m.insert(
        "等待 QJS 初始化任务失败: {0}",
        "等待 QJS 初始化任务失败: {0}",
    );
    m.insert(
        "runtime '{0}' 已存在且配置不匹配 (existing: fs={1}; requested: fs={2})",
        "runtime '{0}' 已存在且配置不匹配 (existing: fs={1}; requested: fs={2})",
    );
    m.insert(
        "新建了一个 qjs 实例: {0} (fs={1})，thread id : {2}",
        "新建了一个 qjs 实例: {0} (fs={1})，thread id : {2}",
    );
    m.insert(
        "复用 qjs 实例并替换 bundle: {0} -> {1}",
        "复用 qjs 实例并替换 bundle: {0} -> {1}",
    );
    m.insert(
        "新建 qjs 实例并加载 bundle: {0} -> {1} (fs={2})",
        "新建 qjs 实例并加载 bundle: {0} -> {1} (fs={2})",
    );
    m.insert("调用参数不是合法 JSON", "调用参数不是合法 JSON");
    m.insert("已取消", "已取消");
    m.insert("被取消", "被取消");
    m.insert("任务取消", "任务取消");
    m.insert("用户取消", "用户取消");
    m.insert("解析 JS 返回 JSON 失败", "解析 JS 返回 JSON 失败");
    m.insert(
        "QJS 任务被取消(解析返回体): {0}",
        "QJS 任务被取消(解析返回体): {0}",
    );
    m.insert("加载 QJS bundle 失败: {0}", "加载 QJS bundle 失败: {0}");
    m.insert(
        "卸载旧 bundle 失败({0}): {1}",
        "卸载旧 bundle 失败({0}): {1}",
    );
    m.insert(
        "QJS 任务被取消(等待结果): {0}",
        "QJS 任务被取消(等待结果): {0}",
    );
    m.insert("fn_path 不能为空", "fn_path 不能为空");
    m.insert("bundle_url 不能为空", "bundle_url 不能为空");
    m.insert("创建 bundle 下载客户端失败", "创建 bundle 下载客户端失败");
    m.insert("下载 bundle 失败: {0}", "下载 bundle 失败: {0}");
    m.insert(
        "下载 bundle 返回非成功状态: {0}",
        "下载 bundle 返回非成功状态: {0}",
    );
    m.insert(
        "读取 Brotli bundle 响应失败: {0}",
        "读取 Brotli bundle 响应失败: {0}",
    );
    m.insert(
        "解压 Brotli bundle 失败: {0}",
        "解压 Brotli bundle 失败: {0}",
    );
    m.insert("bundle 不是合法 UTF-8: {0}", "bundle 不是合法 UTF-8: {0}");
    m.insert("读取 bundle 文本失败: {0}", "读取 bundle 文本失败: {0}");
    m.insert("任务不存在: {0}", "任务不存在: {0}");
    m.insert("清空当前 bundle 失败: {0}", "清空当前 bundle 失败: {0}");
    m.insert("序列化当前 bundle 信息失败", "序列化当前 bundle 信息失败");
    m.insert(
        "销毁 qjs 实例并取消任务: runtime={0}, task_count={1}",
        "销毁 qjs 实例并取消任务: runtime={0}, task_count={1}",
    );
    m.insert("序列化 qjs 调试快照失败", "序列化 qjs 调试快照失败");
    m.insert(
        "取消任务失败: runtime 不可用",
        "取消任务失败: runtime 不可用",
    );
    m.insert("设置 http 代理失败: {0}", "设置 http 代理失败: {0}");
    m.insert("设置 socks5 代理失败: {0}", "设置 socks5 代理失败: {0}");
    m.insert("设置 TLS 校验开关失败: {0}", "设置 TLS 校验开关失败: {0}");
    m.insert(
        "max_args_json_bytes 超出 usize 范围",
        "max_args_json_bytes 超出 usize 范围",
    );
    m.insert(
        "max_return_binary_bytes 超出 usize 范围",
        "max_return_binary_bytes 超出 usize 范围",
    );
    m.insert(
        "配置 bridge runtime 失败: {0}",
        "配置 bridge runtime 失败: {0}",
    );
    m.insert("序列化 bridge 参数失败", "序列化 bridge 参数失败");
    m.insert(
        "{0} Dart 回调超时 (timeout_ms={1})",
        "{0} Dart 回调超时 (timeout_ms={1})",
    );
    m.insert("opencc 需要一个 JSON 参数", "opencc 需要一个 JSON 参数");
    m.insert(
        "cache.delete 参数无效: 缺少 key",
        "cache.delete 参数无效: 缺少 key",
    );
    m.insert("任务已取消", "任务已取消");
}

fn insert_messages_en(m: &mut HashMap<&'static str, &'static str>) {
    m.insert("执行脚本失败", "Failed to execute script");
    m.insert("解析结果失败", "Failed to parse result");
    m.insert(
        "创建 AsyncHostRuntime 失败",
        "Failed to create AsyncHostRuntime",
    );
    m.insert(
        "native buffer 池加锁失败",
        "Failed to lock native buffer pool",
    );
    m.insert("提交任务失败", "Failed to submit task");
    m.insert("base64 解码失败", "base64 decode failed");
    m.insert("序列化路由名失败", "Failed to serialize route name");
    m.insert("创建 tokio runtime 失败", "Failed to create tokio runtime");
    m.insert(
        "bridge 同步路由表锁已损坏",
        "Bridge sync route table lock is poisoned",
    );
    m.insert(
        "bridge 异步路由表锁已损坏",
        "Bridge async route table lock is poisoned",
    );
    m.insert(
        "bridge 阻塞路由表锁已损坏",
        "Bridge blocking route table lock is poisoned",
    );
    m.insert("runtime_name 不能为空", "runtime_name cannot be empty");
    m.insert("bundle_js 不能为空", "bundle_js cannot be empty");
    m.insert(
        "序列化 bundle 名称失败: {0}",
        "Failed to serialize bundle name: {0}",
    );
    m.insert("执行失败", "Execution failed");
    m.insert("更新 HTTP 配置失败", "Failed to update HTTP config");
    m.insert(
        "bridge 请求池加锁失败",
        "Failed to lock bridge request pool",
    );
    m.insert("http 请求池加锁失败", "Failed to lock HTTP request pool");
    m.insert("fs 请求池加锁失败", "Failed to lock fs request pool");
    m.insert(
        "当前构建未启用 host-fs Cargo 特性",
        "Current build does not enable the host-fs Cargo feature",
    );
    m.insert(
        "等待任务结果失败: runtime 已关闭",
        "Failed to wait for task result: runtime is closed",
    );
    m.insert("恢复 HTTP 配置失败", "Failed to restore HTTP config");
    m.insert("Body 已被读取", "Body has already been read");
    m.insert("任务执行失败", "Task execution failed");
    m.insert("参数 {0} 必须是字符串", "Argument {0} must be a string");
    m.insert("数据必须是字节数组", "Data must be a byte array");
    m.insert(
        "字节数组元素必须是整数",
        "Byte array elements must be integers",
    );
    m.insert(
        "字节数组元素必须在 0-255 范围",
        "Byte array elements must be in the 0-255 range",
    );
    m.insert("buffer id 不存在", "buffer id does not exist");
    m.insert("request id 不存在", "request id does not exist");
    m.insert("初始化 hmac 失败", "Failed to initialize hmac");
    m.insert(
        "http event 请求池加锁失败",
        "Failed to lock HTTP event request pool",
    );
    m.insert("已拦截内网请求: {0}", "Blocked intranet request: {0}");
    m.insert(
        "timer event 请求池加锁失败",
        "Failed to lock timer event request pool",
    );
    m.insert(
        "fs event 请求池加锁失败",
        "Failed to lock fs event request pool",
    );
    m.insert("文件上传失败: {0}", "File upload failed: {0}");
    m.insert(
        "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle",
        "Current runtime has no bundle loaded, please call qjs_replace_bundle first",
    );
    m.insert("任务类型不匹配: {0}", "Task type mismatch: {0}");
    m.insert("eval失败: {0}", "eval failed: {0}");
    m.insert(
        "提交任务失败: 状态锁已损坏",
        "Failed to submit task: state lock is poisoned",
    );
    m.insert(
        "提交任务失败: 等待器锁已损坏",
        "Failed to submit task: waiter lock is poisoned",
    );
    m.insert(
        "提交任务失败: worker 不可用",
        "Failed to submit task: worker unavailable",
    );
    m.insert(
        "序列化 bundle 脚本失败: {0}",
        "Failed to serialize bundle script: {0}",
    );
    m.insert("加载 bundle 失败: {0}", "Failed to load bundle: {0}");
    m.insert(
        "调用参数必须是 JSON 数组",
        "Call arguments must be a JSON array",
    );
    m.insert(
        "执行一次性 bundle 调用失败: {0}",
        "Failed to execute one-shot bundle call: {0}",
    );
    m.insert("卸载 bundle 失败: {0}", "Failed to unload bundle: {0}");
    m.insert(
        "读取 bundle 列表失败: {0}",
        "Failed to read bundle list: {0}",
    );
    m.insert(
        "初始化 bundle dispatcher 失败: {0}",
        "Failed to initialize bundle dispatcher: {0}",
    );
    m.insert(
        "序列化调用参数失败: {0}",
        "Failed to serialize call arguments: {0}",
    );
    m.insert(
        "等待任务结果失败: 任务句柄已失效",
        "Failed to wait for task result: task handle is invalid",
    );
    m.insert(
        "序列化函数路径失败: {0}",
        "Failed to serialize function path: {0}",
    );
    m.insert("系统时间异常", "System time anomaly");
    m.insert("创建临时目录失败", "Failed to create temporary directory");
    m.insert("创建 runtime 失败", "Failed to create runtime");
    m.insert("等待脚本结果失败", "Failed to wait for script result");
    m.insert("已拦截内网请求", "Blocked intranet request");
    m.insert("names 必须是数组", "names must be an array");
    m.insert(
        "执行 pnpm test:cases:node 失败: {0}",
        "Failed to execute pnpm test:cases:node: {0}",
    );
    m.insert("启动测试服务失败", "Failed to start test service");
    m.insert(
        "卸载 bridge 自定义路由失败",
        "Failed to unregister bridge custom route",
    );
    m.insert(
        "注册 bridge 同步自定义路由失败",
        "Failed to register bridge sync custom route",
    );
    m.insert(
        "卸载 bridge 同步自定义路由失败",
        "Failed to unregister bridge sync custom route",
    );
    m.insert("调用应失败", "Call should have failed");
    m.insert(
        "不支持的 bridge 方法: {0}",
        "Unsupported bridge method: {0}",
    );
    m.insert("缺少参数: {0}", "Missing argument: {0}");
    m.insert(
        "参数 {0} 必须是非负整数",
        "Argument {0} must be a non-negative integer",
    );
    m.insert("gzip 压缩失败", "gzip compression failed");
    m.insert("参数 a 必须是数字", "Argument a must be a number");
    m.insert("参数 b 必须是数字", "Argument b must be a number");
    m.insert("bridge 路由已被拒绝: {0}", "Bridge route rejected: {0}");
    m.insert(
        "request 执行线程异常退出",
        "request execution thread panicked",
    );
    m.insert("AES-128 密钥长度无效", "AES-128 key length invalid");
    m.insert("AES-192 密钥长度无效", "AES-192 key length invalid");
    m.insert("AES-256 密钥长度无效", "AES-256 key length invalid");
    m.insert(
        "AES ECB 密钥长度必须是 16/24/32 字节，当前: {0}",
        "AES ECB key length must be 16/24/32 bytes, current: {0}",
    );
    m.insert("AES ECB PKCS7 填充无效", "AES ECB PKCS7 padding invalid");
    m.insert(
        "AES CBC 密钥长度必须是 16/24/32 字节，当前: {0}",
        "AES CBC key length must be 16/24/32 bytes, current: {0}",
    );
    m.insert("AES-128 GCM 参数无效", "AES-128 GCM parameters invalid");
    m.insert("AES-256 GCM 参数无效", "AES-256 GCM parameters invalid");
    m.insert(
        "AES GCM 密钥长度必须是 16/32 字节，当前: {0}",
        "AES GCM key length must be 16/32 bytes, current: {0}",
    );
    m.insert("不支持的编码: {0}", "Unsupported encoding: {0}");
    m.insert(
        "HTTP client 状态锁已损坏",
        "HTTP client state lock is poisoned",
    );
    m.insert(
        "解析 socks5 代理地址失败: {0}",
        "Failed to parse socks5 proxy address: {0}",
    );
    m.insert("http pending 队列已满", "HTTP pending queue is full");
    m.insert(
        "http 并发控制器不可用",
        "HTTP concurrency controller unavailable",
    );
    m.insert(
        "http 等待并发许可超时",
        "Timed out waiting for HTTP concurrency permit",
    );
    m.insert("gzip 压缩失败: {0}", "gzip compression failed: {0}");
    m.insert("input id 不存在", "input id does not exist");
    m.insert("extra input id 不存在", "extra input id does not exist");
    m.insert("fs pending 队列已满", "fs pending queue is full");
    m.insert(
        "fs 并发控制器不可用",
        "fs concurrency controller unavailable",
    );
    m.insert(
        "fs 等待并发许可超时",
        "Timed out waiting for fs concurrency permit",
    );
    m.insert("打开备份 zip 失败: {0}", "Failed to open backup zip: {0}");
    m.insert("读取 zip 失败: {0}", "Failed to read zip: {0}");
    m.insert("读取输入文件失败: {0}", "Failed to read input file: {0}");
    m.insert("解析图片失败: {0}", "Failed to parse image: {0}");
    m.insert("md5 下载失败: {0}", "md5 download failed: {0}");
    m.insert("文件下载失败: {0}", "File download failed: {0}");
    m.insert("打开文件{0}失败", "Failed to open file {0}");
    m.insert("bundle_name 不能为空", "bundle_name cannot be empty");
    m.insert("序列化调用结果失败", "Failed to serialize call result");
    m.insert(
        "序列化一次性调用结果失败",
        "Failed to serialize one-shot call result",
    );
    m.insert(
        "读取 bundle 列表失败: {0}",
        "Failed to read bundle list: {0}",
    );
    m.insert(
        "任务类型不匹配(期望二进制): {0}",
        "Task type mismatch (expected binary): {0}",
    );
    m.insert("无法读取字符串", "Cannot read string");
    m.insert(
        "初始化 AsyncContext 失败: {0}",
        "Failed to initialize AsyncContext: {0}",
    );
    m.insert(
        "初始化 Context 绑定失败: {0}",
        "Failed to initialize Context bindings: {0}",
    );
    m.insert(
        "初始化 AsyncRuntime 失败: {0}",
        "Failed to initialize AsyncRuntime: {0}",
    );
    m.insert(
        "AsyncHostRuntime worker 信号通道不可用",
        "AsyncHostRuntime worker signal channel unavailable",
    );
    m.insert(
        "安装 AsyncHostRuntime 上下文绑定失败: {0}",
        "Failed to install AsyncHostRuntime context bindings: {0}",
    );
    m.insert(
        "安装一次性 Context 绑定失败: {0}",
        "Failed to install one-shot Context bindings: {0}",
    );
    m.insert(
        "一次性 Context slot 不存在: {0}",
        "One-shot Context slot does not exist: {0}",
    );
    m.insert(
        "执行 JS event loop job 失败: {0}",
        "Failed to execute JS event loop job: {0}",
    );
    m.insert(
        "创建 per-instance tokio runtime 失败",
        "Failed to create per-instance tokio runtime",
    );
    m.insert(
        "初始化 HostRuntime 失败: {0}",
        "Failed to initialize HostRuntime: {0}",
    );
    m.insert("获取 tokio handle 失败", "Failed to get tokio handle");
    m.insert(
        "初始化 HostRuntime 失败: worker 提前退出",
        "Failed to initialize HostRuntime: worker exited early",
    );
    m.insert(
        "触发 GC 失败: worker 不可用",
        "Failed to trigger GC: worker unavailable",
    );
    m.insert(
        "触发 GC 失败: worker 已关闭",
        "Failed to trigger GC: worker closed",
    );
    m.insert(
        "执行 bundle 函数失败: {0}",
        "Failed to execute bundle function: {0}",
    );
    m.insert(
        "提交 bundle 调用任务失败: {0}",
        "Failed to submit bundle call task: {0}",
    );
    m.insert(
        "读取 bundle 列表失败: 返回值不是数组",
        "Failed to read bundle list: return value is not an array",
    );
    m.insert(
        "计算一次性 bundle 哈希失败: {0}",
        "Failed to compute one-shot bundle hash: {0}",
    );
    m.insert(
        "解析 JSON 任务结果失败: {0}; payload={1}",
        "Failed to parse JSON task result: {0}; payload={1}",
    );
    m.insert(
        "native buffer 不存在或已被消费: {0}",
        "native buffer does not exist or has been consumed: {0}",
    );
    m.insert(
        "字节数组第 {0} 项不是无符号整数",
        "Byte array item {0} is not an unsigned integer",
    );
    m.insert(
        "字节数组第 {0} 项超出范围: {1}",
        "Byte array item {0} out of range: {1}",
    );
    m.insert(
        "无法将字符串解码为 base64 字节: {0}",
        "Cannot decode string as base64 bytes: {0}",
    );
    m.insert(
        "不支持的二进制返回类型：期望 nativeBufferId / number[] / base64字符串",
        "Unsupported binary return type: expected nativeBufferId / number[] / base64 string",
    );
    m.insert(
        "解析 JS 返回 JSON 失败: {0}",
        "Failed to parse JS return JSON: {0}",
    );
    m.insert(
        "安装 AsyncHostRuntime 绑定失败: {0}",
        "Failed to install AsyncHostRuntime bindings: {0}",
    );
    m.insert(
        "读取任务结果失败: 状态锁已损坏",
        "Failed to read task result: state lock is poisoned",
    );
    m.insert(
        "读取任务结果失败: 任务尚未完成",
        "Failed to read task result: task not yet completed",
    );
    m.insert(
        "读取任务结果失败: 任务不存在",
        "Failed to read task result: task does not exist",
    );
    m.insert("读取 case bundle 失败", "Failed to read case bundle");
    m.insert("序列化 bundle 失败", "Failed to serialize bundle");
    m.insert("序列化 config 失败", "Failed to serialize config");
    m.insert("执行 bundle case 失败", "Failed to execute bundle case");
    m.insert("解析 case 结果失败", "Failed to parse case result");
    m.insert(
        "case 执行失败: {0}\\nraw={1}",
        "Case execution failed: {0}\\nraw={1}",
    );
    m.insert("未知错误", "Unknown error");
    m.insert(
        "pnpm test:cases:node 失败\\nstdout:\\n{0}\\nstderr:\\n{1}",
        "pnpm test:cases:node failed\\nstdout:\\n{0}\\nstderr:\\n{1}",
    );
    m.insert(
        "构造二进制响应头失败",
        "Failed to construct binary response headers",
    );
    m.insert("构造响应头失败", "Failed to construct response headers");
    m.insert(
        "构造自定义响应头失败",
        "Failed to construct custom response headers",
    );
    m.insert(
        "构造额外响应头失败",
        "Failed to construct extra response headers",
    );
    m.insert(
        "注册 bridge 自定义路由失败",
        "Failed to register bridge custom route",
    );
    m.insert(
        "注册 bridge 异步自定义路由失败",
        "Failed to register bridge async custom route",
    );
    m.insert(
        "注册 bridge 阻塞自定义路由失败",
        "Failed to register bridge blocking custom route",
    );
    m.insert(
        "卸载 bridge 阻塞自定义路由失败",
        "Failed to unregister bridge blocking custom route",
    );
    m.insert("events 必须是数组", "events must be an array");
    m.insert("A中B", "B in A");
    m.insert("无法 clone", "Cannot clone");
    m.insert("未收到第 1 条日志回调", "Did not receive log callback 1");
    m.insert("未收到第 2 条日志回调", "Did not receive log callback 2");
    m.insert("未收到第 3 条日志回调", "Did not receive log callback 3");
    m.insert("任务应被 dropped", "Task should be dropped");
    m.insert(
        "多任务并发耗时异常: {0}ms",
        "Abnormal multi-task concurrent elapsed time: {0}ms",
    );
    m.insert("异步等待任务 panic", "Async wait for task panicked");
    m.insert("任务执行失败: {0}", "Task execution failed: {0}");
    m.insert(
        "独立 async 等待者并发耗时异常: {0}ms",
        "Abnormal independent async waiter concurrent elapsed time: {0}ms",
    );
    m.insert(
        "wait handle 并发耗时异常: {0}ms",
        "Abnormal wait handle concurrent elapsed time: {0}ms",
    );
    m.insert("解析 typed 结果失败", "Failed to parse typed result");
    m.insert("warmup task1 join 失败", "Warmup task1 join failed");
    m.insert("warmup task1 执行失败", "Warmup task1 execution failed");
    m.insert("warmup task2 join 失败", "Warmup task2 join failed");
    m.insert("warmup task2 执行失败", "Warmup task2 execution failed");
    m.insert("task1 join 失败", "task1 join failed");
    m.insert("task1 执行失败", "task1 execution failed");
    m.insert("task2 join 失败", "task2 join failed");
    m.insert("task2 执行失败", "task2 execution failed");
    m.insert(
        "bundle_call_once 仍然被串行化，耗时={0}ms",
        "bundle_call_once is still serialized, elapsed={0}ms",
    );
    m.insert("缺少调用上下文: {0}", "Missing call context: {0}");
    m.insert("缺少逻辑源码名: {0}", "Missing logic source name: {0}");
    m.insert("缺少 targetType: {0}", "Missing targetType: {0}");
    m.insert("缺少 ownerKeys: {0}", "Missing ownerKeys: {0}");
    m.insert("缺少 rootKeys: {0}", "Missing rootKeys: {0}");
    m.insert(
        "runtime 销毁后 wait 不应被无限阻塞",
        "wait should not be blocked indefinitely after runtime is destroyed",
    );
    m.insert(
        "runtime 销毁后任务应返回错误",
        "Tasks should return an error after runtime is destroyed",
    );
    m.insert("runtime 已关闭", "Runtime is closed");
    m.insert("绑定测试端口失败", "Failed to bind test port");
    m.insert("读取地址失败", "Failed to read address");
    m.insert("发送测试地址失败", "Failed to send test address");
    m.insert("接收测试地址失败", "Failed to receive test address");
    m.insert(
        "sourcemap 应解析到 src/index.ts:143:12，实际错误: {0}",
        "sourcemap should resolve to src/index.ts:143:12, actual error: {0}",
    );
    m.insert(
        "bridge 运行时配置锁已损坏",
        "Bridge runtime config lock is poisoned",
    );
    m.insert("bridge 调用失败", "Bridge call failed");
    m.insert("bridge 路由名不能为空", "Bridge route name cannot be empty");
    m.insert(
        "bridge blocking 路由任务 join 失败: {0}",
        "Bridge blocking route task join failed: {0}",
    );
    m.insert("解析宿主返回 JSON 失败", "Failed to parse host return JSON");
    m.insert("调用失败", "Call failed");
    m.insert(
        "bridge 参数过大: {0} > {1}",
        "Bridge argument too large: {0} > {1}",
    );
    m.insert(
        "解析 bridge args JSON 失败",
        "Failed to parse bridge args JSON",
    );
    m.insert("args 必须是数组", "args must be an array");
    m.insert(
        "bridge bytes 参数缺少 nativeBufferId",
        "Bridge bytes argument missing nativeBufferId",
    );
    m.insert(
        "bridge bytes 参数 nativeBufferId 不存在: {0}",
        "Bridge bytes argument nativeBufferId does not exist: {0}",
    );
    m.insert("gzip 解压失败", "gzip decompression failed");
    m.insert(
        "bridge 返回二进制过大: {0} > {1}",
        "Bridge return binary too large: {0} > {1}",
    );
    m.insert("bridge pending 队列已满", "Bridge pending queue is full");
    m.insert(
        "解密结果不是有效 UTF-8",
        "Decryption result is not valid UTF-8",
    );
    m.insert(
        "dispatch_crypto_route 被传入非 crypto 路由: {0}",
        "dispatch_crypto_route received a non-crypto route: {0}",
    );
    m.insert(
        "AES ECB 密文长度必须是 16 的倍数",
        "AES ECB ciphertext length must be a multiple of 16",
    );
    m.insert("AES ECB 解密结果为空", "AES ECB decryption result is empty");
    m.insert("AES-128 CBC 参数无效", "AES-128 CBC parameters invalid");
    m.insert("AES-128 CBC 加密失败", "AES-128 CBC encryption failed");
    m.insert("AES-192 CBC 参数无效", "AES-192 CBC parameters invalid");
    m.insert("AES-192 CBC 加密失败", "AES-192 CBC encryption failed");
    m.insert("AES-256 CBC 参数无效", "AES-256 CBC parameters invalid");
    m.insert("AES-256 CBC 加密失败", "AES-256 CBC encryption failed");
    m.insert(
        "AES-128 CBC 参数无效: {0}",
        "AES-128 CBC parameters invalid: {0}",
    );
    m.insert(
        "AES-128 CBC 解密失败: {0}",
        "AES-128 CBC decryption failed: {0}",
    );
    m.insert(
        "AES-192 CBC 参数无效: {0}",
        "AES-192 CBC parameters invalid: {0}",
    );
    m.insert(
        "AES-192 CBC 解密失败: {0}",
        "AES-192 CBC decryption failed: {0}",
    );
    m.insert(
        "AES-256 CBC 参数无效: {0}",
        "AES-256 CBC parameters invalid: {0}",
    );
    m.insert(
        "AES-256 CBC 解密失败: {0}",
        "AES-256 CBC decryption failed: {0}",
    );
    m.insert("AES-128 GCM 加密失败", "AES-128 GCM encryption failed");
    m.insert("AES-256 GCM 加密失败", "AES-256 GCM encryption failed");
    m.insert("AES-128 GCM 解密失败", "AES-128 GCM decryption failed");
    m.insert("AES-256 GCM 解密失败", "AES-256 GCM decryption failed");
    m.insert("生成随机字节失败", "Failed to generate random bytes");
    m.insert("参数 {0} 必须是布尔值", "Argument {0} must be a boolean");
    m.insert("参数 {0} 超出 u32 范围", "Argument {0} exceeds u32 range");
    m.insert("参数 {0} 必须是整数", "Argument {0} must be an integer");
    m.insert("writeFile 参数无效", "writeFile argument invalid");
    m.insert("mkdir 参数无效", "mkdir argument invalid");
    m.insert("readdir 参数无效", "readdir argument invalid");
    m.insert("rm 参数无效", "rm argument invalid");
    m.insert("rename 参数无效", "rename argument invalid");
    m.insert("copyFile 参数无效", "copyFile argument invalid");
    m.insert("cp 参数无效", "cp argument invalid");
    m.insert("symlink 参数无效", "symlink argument invalid");
    m.insert("link 参数无效", "link argument invalid");
    m.insert("truncate 参数无效", "truncate argument invalid");
    m.insert("chmod 参数无效", "chmod argument invalid");
    m.insert("utimes 参数无效", "utimes argument invalid");
    m.insert(
        "不支持的 fs 异步操作: {0}",
        "Unsupported fs async operation: {0}",
    );
    m.insert("缺少 kind 字段", "Missing kind field");
    m.insert("bytes 数据格式错误", "bytes data format error");
    m.insert(
        "bytes 数据必须是 0-255 的整数",
        "bytes data must be integers in 0-255",
    );
    m.insert(
        "bytes 数据必须在 0-255 范围内",
        "bytes data must be in the 0-255 range",
    );
    m.insert("text 数据格式错误", "text data format error");
    m.insert("不支持的 kind: {0}", "Unsupported kind: {0}");
    m.insert("文件或目录不存在", "File or directory does not exist");
    m.insert(
        "当前平台不支持符号链接",
        "Symbolic links are not supported on this platform",
    );
    m.insert(
        "当前平台不支持 chmod",
        "chmod is not supported on this platform",
    );
    m.insert("源路径不存在", "Source path does not exist");
    m.insert("目标路径已存在", "Destination path already exists");
    m.insert(
        "目标路径已存在，且未启用 force",
        "Destination path already exists and force is not enabled",
    );
    m.insert(
        "复制目录时必须启用 recursive",
        "recursive must be enabled when copying a directory",
    );
    m.insert(
        "无法创建唯一临时目录",
        "Cannot create unique temporary directory",
    );
    m.insert(
        "解析 host formdata plan JSON 失败",
        "Failed to parse host formdata plan JSON",
    );
    m.insert(
        "不支持的 formdata plan kind: {0}",
        "Unsupported formdata plan kind: {0}",
    );
    m.insert(
        "base64 解码 formdata 字段失败",
        "Failed to base64 decode formdata field",
    );
    m.insert(
        "formdata 文本字段缺少 value",
        "formdata text field missing value",
    );
    m.insert(
        "formdata 二进制字段缺少 dataB64",
        "formdata binary field missing dataB64",
    );
    m.insert(
        "设置 formdata part Content-Type 失败: {0}",
        "Failed to set formdata part Content-Type: {0}",
    );
    m.insert(
        "不支持的 formdata 字段类型: {0}",
        "Unsupported formdata field type: {0}",
    );
    m.insert(
        "解析 HTTP 代理地址失败: {0}",
        "Failed to parse HTTP proxy address: {0}",
    );
    m.insert("创建 HTTP client 失败", "Failed to create HTTP client");
    m.insert("解析 HTTP method 失败", "Failed to parse HTTP method");
    m.insert(
        "解析 HTTP headers JSON 失败",
        "Failed to parse HTTP headers JSON",
    );
    m.insert(
        "formdata 请求缺少 body payload",
        "formdata request missing body payload",
    );
    m.insert(
        "request body nativeBufferId 不存在: {0}",
        "Request body nativeBufferId does not exist: {0}",
    );
    m.insert("发送 HTTP 请求失败", "Failed to send HTTP request");
    m.insert(
        "解析 HTTP 响应头失败",
        "Failed to parse HTTP response headers",
    );
    m.insert(
        "读取 HTTP 响应体字节失败",
        "Failed to read HTTP response body bytes",
    );
    m.insert("读取 HTTP 响应体失败", "Failed to read HTTP response body");
    m.insert("解析 URL 失败: {0}", "Failed to parse URL: {0}");
    m.insert("URL 缺少 host: {0}", "URL missing host: {0}");
    m.insert("解析域名失败: {0}", "Failed to parse domain: {0}");
    m.insert(
        "创建 native buffer gc 线程失败",
        "Failed to create native buffer gc thread",
    );
    m.insert("解析字节数组 JSON 失败", "Failed to parse byte array JSON");
    m.insert(
        "xor 需要第二个输入参数",
        "xor requires a second input argument",
    );
    m.insert(
        "xor 两个输入长度必须一致",
        "xor inputs must have the same length",
    );
    m.insert("gzip 解压失败: {0}", "gzip decompression failed: {0}");
    m.insert("不支持的 native op: {0}", "Unsupported native op: {0}");
    m.insert("解析 steps JSON 失败", "Failed to parse steps JSON");
    m.insert("steps 必须是数组", "steps must be an array");
    m.insert("steps 元素必须是对象", "steps elements must be objects");
    m.insert("steps 元素缺少 op 字段", "steps elements missing op field");
    m.insert("steps 不能为空", "steps cannot be empty");
    m.insert("size 必须是非负整数", "size must be a non-negative integer");
    m.insert("iterations 必须大于 0", "iterations must be greater than 0");
    m.insert(
        "keyLen 必须是非负整数",
        "keyLen must be a non-negative integer",
    );
    m.insert("native buffer id 不存在", "native buffer id does not exist");
    m.insert("base64 解码失败: {0}", "base64 decode failed: {0}");
    m.insert(
        "创建日志直连 HTTP client 失败",
        "Failed to create log direct HTTP client",
    );
    m.insert(
        "日志直连 HTTP client 初始化后必须可读取",
        "Log direct HTTP client must be readable after initialization",
    );
    m.insert(
        "日志直连 HTTP client 并发初始化后必须可读取",
        "Log direct HTTP client must be readable after concurrent initialization",
    );
    m.insert(
        "创建 log-forward tokio runtime 失败",
        "Failed to create log-forward tokio runtime",
    );
    m.insert(
        "[qjs-log-http] 转发失败: {0}",
        "[qjs-log-http] forwarding failed: {0}",
    );
    m.insert(
        "[qjs-log-http] 日志直连 HTTP client 不可用，跳过日志转发",
        "[qjs-log-http] log direct HTTP client unavailable, skipping log forwarding",
    );
    m.insert("创建 log worker 失败", "Failed to create log worker");
    m.insert("timer pending 队列已满", "timer pending queue is full");
    m.insert("fs 执行任务异常退出", "FS task execution thread panicked");
    m.insert("log worker 不可用: {0}", "Log worker unavailable: {0}");
    m.insert(
        "创建备份 zip 文件失败: {0}",
        "Failed to create backup zip file: {0}",
    );
    m.insert(
        "向 zip 添加数据目录失败: {0}",
        "Failed to add data directory to zip: {0}",
    );
    m.insert(
        "向 zip 添加下载目录失败: {0}",
        "Failed to add download directory to zip: {0}",
    );
    m.insert("完成 zip 写入失败", "Failed to finish zip write");
    m.insert("zip 备份任务执行失败", "Zip backup task execution failed");
    m.insert(
        "备份包中缺少 config.json",
        "Backup package missing config.json",
    );
    m.insert("读取 config.json 失败", "Failed to read config.json");
    m.insert(
        "读取备份配置任务执行失败",
        "Failed to execute backup config read task",
    );
    m.insert(
        "创建解压目录失败: {0}",
        "Failed to create extraction directory: {0}",
    );
    m.insert("读取 zip 第 {0} 个条目失败", "Failed to read zip entry {0}");
    m.insert(
        "发现非法 zip 条目路径: {0}",
        "Found illegal zip entry path: {0}",
    );
    m.insert("创建目录失败: {0}", "Failed to create directory: {0}");
    m.insert(
        "创建父目录失败: {0}",
        "Failed to create parent directory: {0}",
    );
    m.insert("创建文件失败: {0}", "Failed to create file: {0}");
    m.insert("读取 zip 条目失败: {0}", "Failed to read zip entry: {0}");
    m.insert("写入文件失败: {0}", "Failed to write file: {0}");
    m.insert(
        "zip 解压任务执行失败",
        "Zip extraction task execution failed",
    );
    m.insert("读取目录失败: {0}", "Failed to read directory: {0}");
    m.insert("读取目录项失败: {0}", "Failed to read directory entry: {0}");
    m.insert(
        "向 zip 添加目录失败: {0}",
        "Failed to add directory to zip: {0}",
    );
    m.insert(
        "递归添加目录失败: {0}",
        "Failed to recursively add directory: {0}",
    );
    m.insert("向 zip 添加文件失败: {0}", "Failed to add file to zip: {0}");
    m.insert("打开文件失败: {0}", "Failed to open file: {0}");
    m.insert("创建 zip 条目失败: {0}", "Failed to create zip entry: {0}");
    m.insert("读取文件失败: {0}", "Failed to read file: {0}");
    m.insert("写入 zip 条目失败: {0}", "Failed to write zip entry: {0}");
    m.insert("写入 WebP 文件失败: {0}", "Failed to write WebP file: {0}");
    m.insert("写入 PNG 文件失败: {0}", "Failed to write PNG file: {0}");
    m.insert(
        "WebDAV 连接测试失败: {0}",
        "WebDAV connection test failed: {0}",
    );
    m.insert(
        "WebDAV 服务请求失败: {0}",
        "WebDAV service request failed: {0}",
    );
    m.insert("文件删除失败: {0}", "File deletion failed: {0}");
    m.insert(
        "文件删除失败，状态码: {0}",
        "File deletion failed, status code: {0}",
    );
    m.insert("WebDAV 配置不完整", "WebDAV configuration incomplete");
    m.insert(
        "构建 HTTP 客户端失败: {0}",
        "Failed to build HTTP client: {0}",
    );
    m.insert(
        "构建 WebDAV 客户端失败: {0}",
        "Failed to build WebDAV client: {0}",
    );
    m.insert(
        "目录创建失败，状态码: {0}",
        "Directory creation failed, status code: {0}",
    );
    m.insert("目录创建失败: {0}", "Directory creation failed: {0}");
    m.insert(
        "文件不存在，状态码: {0}",
        "File does not exist, status code: {0}",
    );
    m.insert(
        "文件下载失败，状态码: {0}",
        "File download failed, status code: {0}",
    );
    m.insert(
        "文件下载失败，重试次数用尽",
        "File download failed, retry attempts exhausted",
    );
    m.insert(
        "文件上传失败，状态码: {0}",
        "File upload failed, status code: {0}",
    );
    m.insert("远端路径不能为空", "Remote path cannot be empty");
    m.insert("创建tar文件失败", "Failed to create tar file");
    m.insert(
        "将comic_info_string.json添加到压缩包失败",
        "Failed to add comic_info_string.json to archive",
    );
    m.insert(
        "将processed_comic_info_string.json添加到压缩包失败",
        "Failed to add processed_comic_info_string.json to archive",
    );
    m.insert("获取{0}的元数据失败", "Failed to get metadata for {0}");
    m.insert("将{0}添加到压缩包失败", "Failed to add {0} to archive");
    m.insert("完成压缩包失败", "Failed to finish archive");
    m.insert("创建ZIP文件失败", "Failed to create ZIP file");
    m.insert(
        "创建comic_info.json条目失败",
        "Failed to create comic_info.json entry",
    );
    m.insert("写入comic_info.json失败", "Failed to write comic_info.json");
    m.insert(
        "创建processed_comic_info.json条目失败",
        "Failed to create processed_comic_info.json entry",
    );
    m.insert(
        "写入processed_comic_info.json失败",
        "Failed to write processed_comic_info.json",
    );
    m.insert("创建ZIP条目{0}失败", "Failed to create ZIP entry {0}");
    m.insert("读取文件{0}失败", "Failed to read file {0}");
    m.insert("写入ZIP条目{0}失败", "Failed to write ZIP entry {0}");
    m.insert("完成ZIP文件失败", "Failed to finish ZIP file");
    m.insert("ZIP任务执行失败", "ZIP task execution failed");
    m.insert("ZIP压缩失败", "ZIP compression failed");
    m.insert(
        "写入压缩流数据失败",
        "Failed to write compressed stream data",
    );
    m.insert("刷写压缩流失败", "Failed to flush compressed stream");
    m.insert(
        "压缩线程池调度失败",
        "Compression thread pool scheduling failed",
    );
    m.insert(
        "Brotli 解压失败：数据可能损坏或非标准格式",
        "Brotli decompression failed: data may be corrupted or non-standard format",
    );
    m.insert(
        "解压线程池调度失败",
        "Decompression thread pool scheduling failed",
    );
    m.insert(
        "创建解压目标目录失败: {0}",
        "Failed to create decompression target directory: {0}",
    );
    m.insert("7z 解压失败: {0}", "7z decompression failed: {0}");
    m.insert(
        "7z 解压任务执行失败",
        "7z decompression task execution failed",
    );
    m.insert(
        "opencc config 必须是 OpenCC 配置文件名，例如 t2s.json",
        "opencc config must be an OpenCC config file name, e.g. t2s.json",
    );
    m.insert(
        "不支持的 OpenCC 转换配置: {0} ({1})",
        "Unsupported OpenCC conversion config: {0} ({1})",
    );
    m.insert(
        "初始化 OpenCC 失败: {0}",
        "Failed to initialize OpenCC: {0}",
    );
    m.insert(
        "opencc 参数必须是 JSON 对象",
        "opencc argument must be a JSON object",
    );
    m.insert(
        "opencc 参数缺少 text 字段",
        "opencc argument missing text field",
    );
    m.insert(
        "opencc 参数缺少 config 字段，例如 t2s.json",
        "opencc argument missing config field, e.g. t2s.json",
    );
    m.insert(
        "cache.get 参数无效: 缺少 key",
        "cache.get argument invalid: missing key",
    );
    m.insert(
        "cache.set 参数无效: 缺少 key",
        "cache.set argument invalid: missing key",
    );
    m.insert(
        "cache.set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.set skipped oversized write: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "cache.set_if_absent 参数无效: 缺少 key",
        "cache.set_if_absent argument invalid: missing key",
    );
    m.insert(
        "cache.set_if_absent 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.set_if_absent skipped oversized write: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "cache.compare_and_set 参数无效: 缺少 key",
        "cache.compare_and_set argument invalid: missing key",
    );
    m.insert(
        "cache.compare_and_set 跳过超限写入: runtime={0}, key={1}, max_bytes={2}",
        "cache.compare_and_set skipped oversized write: runtime={0}, key={1}, max_bytes={2}",
    );
    m.insert(
        "提交 QJS 初始化任务失败: {0}",
        "Failed to submit QJS initialization task: {0}",
    );
    m.insert(
        "等待 QJS 初始化任务失败: {0}",
        "Failed to wait for QJS initialization task: {0}",
    );
    m.insert(
        "runtime '{0}' 已存在且配置不匹配 (existing: fs={1}; requested: fs={2})",
        "runtime '{0}' already exists with mismatched config (existing: fs={1}; requested: fs={2})",
    );
    m.insert(
        "新建了一个 qjs 实例: {0} (fs={1})，thread id : {2}",
        "Created a new qjs instance: {0} (fs={1}), thread id: {2}",
    );
    m.insert(
        "复用 qjs 实例并替换 bundle: {0} -> {1}",
        "Reused qjs instance and replaced bundle: {0} -> {1}",
    );
    m.insert(
        "新建 qjs 实例并加载 bundle: {0} -> {1} (fs={2})",
        "Created new qjs instance and loaded bundle: {0} -> {1} (fs={2})",
    );
    m.insert("调用参数不是合法 JSON", "Call arguments are not valid JSON");
    m.insert("已取消", "Canceled");
    m.insert("被取消", "Cancelled");
    m.insert("任务取消", "Task cancelled");
    m.insert("用户取消", "User cancelled");
    m.insert("解析 JS 返回 JSON 失败", "Failed to parse JS return JSON");
    m.insert(
        "QJS 任务被取消(解析返回体): {0}",
        "QJS task cancelled (parsing return body): {0}",
    );
    m.insert(
        "加载 QJS bundle 失败: {0}",
        "Failed to load QJS bundle: {0}",
    );
    m.insert(
        "卸载旧 bundle 失败({0}): {1}",
        "Failed to unload old bundle ({0}): {1}",
    );
    m.insert(
        "QJS 任务被取消(等待结果): {0}",
        "QJS task cancelled (waiting for result): {0}",
    );
    m.insert("fn_path 不能为空", "fn_path cannot be empty");
    m.insert("bundle_url 不能为空", "bundle_url cannot be empty");
    m.insert(
        "创建 bundle 下载客户端失败",
        "Failed to create bundle download client",
    );
    m.insert("下载 bundle 失败: {0}", "Failed to download bundle: {0}");
    m.insert(
        "下载 bundle 返回非成功状态: {0}",
        "Bundle download returned non-success status: {0}",
    );
    m.insert(
        "读取 Brotli bundle 响应失败: {0}",
        "Failed to read Brotli bundle response: {0}",
    );
    m.insert(
        "解压 Brotli bundle 失败: {0}",
        "Failed to decompress Brotli bundle: {0}",
    );
    m.insert(
        "bundle 不是合法 UTF-8: {0}",
        "Bundle is not valid UTF-8: {0}",
    );
    m.insert(
        "读取 bundle 文本失败: {0}",
        "Failed to read bundle text: {0}",
    );
    m.insert("任务不存在: {0}", "Task does not exist: {0}");
    m.insert(
        "清空当前 bundle 失败: {0}",
        "Failed to clear current bundle: {0}",
    );
    m.insert(
        "序列化当前 bundle 信息失败",
        "Failed to serialize current bundle info",
    );
    m.insert(
        "销毁 qjs 实例并取消任务: runtime={0}, task_count={1}",
        "Destroyed qjs instance and cancelled tasks: runtime={0}, task_count={1}",
    );
    m.insert(
        "序列化 qjs 调试快照失败",
        "Failed to serialize qjs debug snapshot",
    );
    m.insert(
        "取消任务失败: runtime 不可用",
        "Failed to cancel task: runtime unavailable",
    );
    m.insert("设置 http 代理失败: {0}", "Failed to set HTTP proxy: {0}");
    m.insert(
        "设置 socks5 代理失败: {0}",
        "Failed to set socks5 proxy: {0}",
    );
    m.insert(
        "设置 TLS 校验开关失败: {0}",
        "Failed to set TLS verification switch: {0}",
    );
    m.insert(
        "max_args_json_bytes 超出 usize 范围",
        "max_args_json_bytes exceeds usize range",
    );
    m.insert(
        "max_return_binary_bytes 超出 usize 范围",
        "max_return_binary_bytes exceeds usize range",
    );
    m.insert(
        "配置 bridge runtime 失败: {0}",
        "Failed to configure bridge runtime: {0}",
    );
    m.insert(
        "序列化 bridge 参数失败",
        "Failed to serialize bridge arguments",
    );
    m.insert(
        "{0} Dart 回调超时 (timeout_ms={1})",
        "{0} Dart callback timed out (timeout_ms={1})",
    );
    m.insert(
        "opencc 需要一个 JSON 参数",
        "opencc requires a JSON argument",
    );
    m.insert(
        "cache.delete 参数无效: 缺少 key",
        "cache.delete argument invalid: missing key",
    );
    m.insert("任务已取消", "Task cancelled");
}

/// 无参数消息宏（返回 &str）
/// Macro for parameterless messages (returns &str).
#[macro_export]
macro_rules! i18n {
    ($key:expr) => {
        $crate::i18n::t($key)
    };
}

/// 带位置参数拼接的消息宏（返回 String）
/// Macro for messages with positional arguments (returns String).
#[macro_export]
macro_rules! i18n_fmt {
    ($key:expr $(, $arg:expr)* $(,)?) => {{
        let args: &[&dyn std::fmt::Display] = &[$(&$arg),*];
        $crate::i18n::format_message($key, args)
    }};
}
