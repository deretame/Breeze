//! Rust 侧错误消息国际化（fluent-rs 实现）
//! Rust-side error message internationalization (fluent-rs implementation).

use std::collections::HashMap;
use std::sync::LazyLock;

use fluent_bundle::concurrent::FluentBundle;
use fluent_bundle::{FluentArgs, FluentResource, FluentValue};
use unic_langid::{LanguageIdentifier, langid};

/// 默认 locale
/// Default locale.
pub const DEFAULT_LOCALE: LanguageIdentifier = langid!("zh-CN");

/// 中文 FTL 资源
/// Chinese FTL resource.
const ZH_FTL: &str = include_str!("../locales/zh-CN/messages.ftl");

/// 英文 FTL 资源
/// English FTL resource.
const EN_FTL: &str = include_str!("../locales/en-US/messages.ftl");

/// 支持的 locale 列表
/// List of supported locales.
pub const SUPPORTED_LOCALES: &[LanguageIdentifier] = &[langid!("zh-CN"), langid!("en-US")];

/// 国际化状态容器
/// Internationalization state container.
pub struct I18n {
    bundles: HashMap<LanguageIdentifier, FluentBundle<FluentResource>>,
    current: LanguageIdentifier,
}

impl I18n {
    fn new() -> Self {
        let mut bundles = HashMap::new();
        bundles.insert(langid!("zh-CN"), create_bundle(langid!("zh-CN"), ZH_FTL));
        bundles.insert(langid!("en-US"), create_bundle(langid!("en-US"), EN_FTL));
        Self {
            bundles,
            current: DEFAULT_LOCALE,
        }
    }

    fn bundle(&self) -> &FluentBundle<FluentResource> {
        self.bundles.get(&self.current).unwrap_or_else(|| {
            self.bundles
                .get(&DEFAULT_LOCALE)
                .expect("default bundle exists")
        })
    }
}

static I18N: LazyLock<std::sync::RwLock<I18n>> =
    LazyLock::new(|| std::sync::RwLock::new(I18n::new()));

fn create_bundle(locale: LanguageIdentifier, ftl: &str) -> FluentBundle<FluentResource> {
    let resource = match FluentResource::try_new(ftl.to_string()) {
        Ok(res) => res,
        Err((_, errors)) => {
            eprintln!("FTL parse errors for {locale}:");
            for err in &errors {
                eprintln!("  {err:?}");
            }
            panic!("FTL resource should be valid");
        }
    };
    let mut bundle = FluentBundle::new_concurrent(vec![locale]);
    bundle.add_resource_overriding(resource);
    bundle
}

fn with_i18n<T>(f: impl FnOnce(&I18n) -> T) -> T {
    let i18n = I18N.read().unwrap_or_else(|e| e.into_inner());
    f(&i18n)
}

/// 设置当前 locale。
/// Set the current locale.
///
/// `locale` 应为 BCP-47 字符串，例如 `"zh-CN"`、`"en-US"`。
/// `locale` should be a BCP-47 string, e.g. `"zh-CN"`, `"en-US"`.
/// 不支持的 locale 会回退到 `DEFAULT_LOCALE`。
/// Unsupported locales fall back to `DEFAULT_LOCALE`.
/// 返回实际生效的 locale。
/// Returns the locale that actually took effect.
pub fn set_locale(locale: &str) -> Result<LanguageIdentifier, String> {
    let locale: LanguageIdentifier = locale
        .parse()
        .map_err(|e| format!("invalid locale '{locale}': {e}"))?;
    let mut i18n = I18N.write().unwrap_or_else(|e| e.into_inner());
    i18n.current = if i18n.bundles.contains_key(&locale) {
        locale
    } else {
        DEFAULT_LOCALE
    };
    Ok(i18n.current.clone())
}

/// 获取当前 locale。
/// Get the current locale.
pub fn current_locale() -> LanguageIdentifier {
    with_i18n(|i18n| i18n.current.clone())
}

fn format_message(
    bundle: &FluentBundle<FluentResource>,
    id: &str,
    args: Option<&FluentArgs>,
) -> String {
    let message = bundle.get_message(id);
    if let Some(message) = message {
        if let Some(pattern) = message.value() {
            let mut errors = Vec::new();
            let value = bundle.format_pattern(pattern, args, &mut errors);
            return value.to_string();
        }
    }
    id.to_string()
}

/// 无参翻译。
/// Translate a message without arguments.
pub fn tr(id: &str) -> String {
    with_i18n(|i18n| format_message(i18n.bundle(), id, None))
}

/// 带具名参数翻译。
/// Translate a message with named arguments.
///
/// `args` 为元组切片 `(name, value)`，其中 `value` 会被格式化为字符串。
/// `args` is a slice of `(name, value)` tuples; `value` is formatted as a string.
pub fn tr_args(id: &str, args: &[(&str, &str)]) -> String {
    let mut fluent_args = FluentArgs::new();
    for (key, value) in args {
        fluent_args.set(*key, FluentValue::from(*value));
    }
    with_i18n(|i18n| format_message(i18n.bundle(), id, Some(&fluent_args)))
}

/// Fluent 风格翻译宏。
/// Fluent-style translation macro.
///
/// 无参：`tr!("message-id")`
/// Without arguments: `tr!("message-id")`
///
/// 带具名参数：`tr!("message-id", name = value, count = n)`
/// With named arguments: `tr!("message-id", name = value, count = n)`
#[macro_export]
macro_rules! tr {
    ($id:expr) => {
        $crate::i18n::tr($id)
    };
    ($id:expr, $($key:ident = $value:expr),+ $(,)?) => {{
        let keys: Vec<&'static str> = vec![$( stringify!($key) ),+];
        let values: Vec<String> = vec![$( format!("{}", $value) ),+];
        let args: Vec<(&str, &str)> = keys
            .into_iter()
            .zip(values.iter().map(|s| s.as_str()))
            .collect();
        $crate::i18n::tr_args($id, &args)
    }};
}
